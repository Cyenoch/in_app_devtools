import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_devtools/abstract/feature.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class _Request {
  final Uri uri;
  final String method;
  final Map<String, dynamic> headers;
  final dynamic data;
  final DateTime timestamp;
  const _Request({
    required this.uri,
    required this.method,
    required this.headers,
    required this.data,
    required this.timestamp,
  });
}

class _Response {
  final int statusCode;
  final Map<String, dynamic> headers;
  final String? statusMessage;
  final String? message;
  final dynamic data;
  final DateTime timestamp;
  final Duration duration;
  const _Response({
    required this.statusCode,
    required this.headers,
    required this.data,
    this.statusMessage,
    this.message,
    required this.timestamp,
    required this.duration,
  });
}

const kColorMap = {
  'GET': Colors.green,
  'POST': Colors.blue,
  'PUT': Colors.orange,
  'DELETE': Colors.red,
  'PATCH': Colors.purple,
  'HEAD': Colors.grey,
  'OPTIONS': Colors.teal,
};

typedef Requests = SplayTreeMap<int, (_Request, _Response?)>;

class DioFeature extends IADFeature implements Interceptor {
  final Requests _requests = SplayTreeMap((a, b) => b.compareTo(a));
  final Dio dio;
  final int maxRequests;
  int _id = 0;
  bool get iadEnabled => state.isEnabled;

  DioFeature({required this.dio, this.maxRequests = 1000})
      : super(
          title: 'Dio',
          icon: const Icon(Icons.traffic_outlined),
        ) {
    dio.interceptors.add(this);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!iadEnabled) {
      handler.next(options);
      return;
    }
    if (_requests.length >= maxRequests) {
      _requests.remove(_requests.lastKey());
    }
    options.extra['iad_id'] = _id++;
    handler.next(options);
    _requests[options.extra['iad_id'] as int] = (
      _Request(
        uri: options.uri,
        method: options.method,
        headers: options.headers,
        data: options.data,
        timestamp: DateTime.timestamp(),
      ),
      null
    );
    notifyListeners();
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra['iad_id'] as int;
    final request = _requests[id]?.$1;
    handler.next(response);
    if (request == null) {
      return;
    }
    final response0 = _Response(
      statusCode: response.statusCode ?? -1,
      headers: response.headers.map,
      data: response.data,
      statusMessage: response.statusMessage,
      timestamp: DateTime.timestamp(),
      duration: request.timestamp.difference(DateTime.timestamp()),
    );
    _requests[id] = (request, response0);
    notifyListeners();
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra['iad_id'] as int;
    final request = _requests[id]?.$1;
    handler.next(err);
    if (request == null) {
      return;
    }
    final response0 = _Response(
      statusCode: err.response?.statusCode ?? -1,
      headers: err.response?.headers.map ?? {},
      data: err.response?.data,
      statusMessage: err.response?.statusMessage,
      message: err.message,
      timestamp: DateTime.timestamp(),
      duration: request.timestamp.difference(DateTime.timestamp()),
    );
    _requests[id] = (request, response0);
    notifyListeners();
  }

  void clear() {
    _requests.clear();
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: this,
      child: _DioFeature(),
    );
  }
}

class _DioFeature extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          context.read<DioFeature>().clear();
        },
        child: Icon(Icons.delete_forever_outlined),
      ),
      body: Selector<DioFeature, Requests>(selector: (context, state) {
        return state._requests;
      }, shouldRebuild: (prev, curr) {
        return true;
      }, builder: (context, requests, child) {
        if (requests.isEmpty) {
          return Center(
            child: Text('No requests',
                style: Theme.of(context).textTheme.bodySmall),
          );
        }
        return ListView.separated(
          itemBuilder: (context, index) {
            final (request, response) = requests.values.elementAt(index);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              minTileHeight: 40,
              minVerticalPadding: 4,
              title: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RequestMethodIndicator(method: request.method, textSize: 11),
                  Text(request.uri.path.isNotEmpty ? request.uri.path : '/'),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return _DioDetails(request: request, response: response);
                }));
              },
              subtitle: Text(
                DateFormat('yyyy/MM/dd hh:mm:ss:S')
                    .format(request.timestamp.toLocal()),
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: response == null
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                  : Text(
                      response.statusCode.toString(),
                      style: TextStyle(
                        color: _statusColor(response.statusCode),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            );
          },
          separatorBuilder: (context, index) {
            return const Divider(height: 1);
          },
          itemCount: requests.length,
        );
      }),
    );
  }
}

class _DioDetails extends StatelessWidget {
  final _Request request;
  final _Response? response;
  const _DioDetails({
    required this.request,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  _RequestMethodIndicator(method: request.method, textSize: 15),
                  Text(request.uri.path.isEmpty ? '/' : request.uri.path),
                ],
              ),
              Text(request.uri.host, style: TextStyle(fontSize: 12)),
            ],
          ),
          bottom: PreferredSize(
              preferredSize: Size(double.maxFinite, 32),
              child: TabBar(
                textScaler: TextScaler.linear(0.65),
                tabs: [
                  Tab(
                    text: 'Request',
                    icon: Icon(Icons.send, size: 14),
                    height: 32,
                  ),
                  Tab(
                    text: 'Response',
                    icon: Icon(Icons.reply, size: 14),
                    height: 32,
                  ),
                ],
              )),
        ),
        body: TabBarView(children: [
          SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Text("${request.uri}"),
                const Divider(),
                Text(
                  'Request Headers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _headersRender(context, request.headers),
                ),
                const Divider(),
                Row(
                  children: [
                    Text(
                      'Request Body',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: request.data.toString(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          }
                        });
                      },
                      child: Text("Copy"),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _bodyRender(context, request.data),
                ),
              ],
            ),
          ),
          SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Text('Status Code: ${response?.statusCode}',
                    style: TextStyle(
                        color: _statusColor(response?.statusCode ?? -1))),
                Text("Status Message: ${response?.statusMessage ?? 'N/A'}"),
                Text("Message: ${response?.message ?? 'N/A'}"),
                const Divider(),
                Text(
                  'Response Headers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _headersRender(context, response?.headers ?? {}),
                ),
                const Divider(),
                Row(
                  children: [
                    Text(
                      'Response Body',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: response?.data.toString() ?? '',
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          }
                        });
                      },
                      child: Text("Copy"),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _bodyRender(context, response?.data ?? {}),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _headersRender(BuildContext context, Map headers) {
    return headers.isEmpty
        ? Text('EMPTY')
        : ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: headers.length,
            itemBuilder: (context, index) {
              final header = headers.entries.elementAt(index);
              return Text.rich(TextSpan(
                children: [
                  TextSpan(
                    text: "${header.key}:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.8)),
                  ),
                  TextSpan(
                    text: " ${header.value}",
                  ),
                ],
              ));
            },
            shrinkWrap: true,
          );
  }

  Widget _bodyRender(BuildContext context, dynamic body) {
    switch (body) {
      case null:
        return Text('NULL');
      case String data:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(data),
        );
      case Map map:
        return map.isEmpty
            ? Text('EMPTY MAP')
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(JsonEncoder.withIndent('  ').convert(map)),
              );
      case FormData data:
        final fields = data.fields;
        final files = data.files;
        return fields.isEmpty && files.isEmpty
            ? Text('EMPTY FORM DATA')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("FIELDS:"),
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: fields.length,
                    itemBuilder: (context, index) {
                      final field = fields.elementAt(index);
                      return Text.rich(TextSpan(
                        children: [
                          TextSpan(
                            text: "${field.key}:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.8)),
                          ),
                          TextSpan(
                            text: " ${field.value}",
                          ),
                        ],
                      ));
                    },
                    shrinkWrap: true,
                  ),
                  if (files.isNotEmpty) const SizedBox(height: 4),
                  if (files.isNotEmpty) Text("FILES:"),
                  if (files.isNotEmpty)
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files.elementAt(index);
                        return Text.rich(TextSpan(
                          children: [
                            TextSpan(
                              text: "${file.key}:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.8)),
                            ),
                            TextSpan(
                              text:
                                  "Name: ${file.value.filename}\nSize: ${file.value.length}\nContentType: ${file.value.contentType.toString()}",
                            ),
                          ],
                        ));
                      },
                      shrinkWrap: true,
                    ),
                ],
              );
      default:
        return Text("RUNTIME TYPE: ${body.runtimeType}");
    }
  }
}

class _RequestMethodIndicator extends StatelessWidget {
  final String method;
  final double textSize;
  const _RequestMethodIndicator({required this.method, this.textSize = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: kColorMap[method],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(method,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          )),
    );
  }
}

Color _statusColor(int statusCode) {
  if (statusCode == -1) return Colors.grey;
  return statusCode >= 200 && statusCode < 300
      ? Colors.green
      : statusCode >= 300 && statusCode < 400
          ? Colors.orange
          : Colors.red;
}
