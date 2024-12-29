import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:in_app_devtools/abstract/feature.dart';
import 'package:in_app_devtools/state.dart';
import 'package:provider/provider.dart';

class LogFeature extends IADFeature {
  final List<(Color, String)> _logs = [];
  final int maxLines;
  bool get iadEnabled => state.isEnabled;

  LogFeature({this.maxLines = 5000})
      : super(
          title: 'Log',
          icon: const Icon(Icons.terminal_outlined),
        );

  log(String log) {
    if (!iadEnabled) return;
    if (_logs.length >= maxLines) {
      _logs.removeAt(0);
    }
    _logs.add((Colors.white, log));
    notifyListeners();
  }

  clear() {
    _logs.clear();
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: this,
      child: const _Log(),
    );
  }

  @override
  void init(IADState state) {}
}

class _Log extends StatefulWidget {
  const _Log();

  @override
  State<_Log> createState() => _LogState();
}

class _LogState extends State<_Log> {
  bool isVisible = true;
  final ScrollController _scrollController = ScrollController();

  void onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (isVisible == true) {
        setState(() {
          isVisible = false;
        });
      }
    } else {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isVisible == false) {
          setState(() {
            isVisible = true;
          });
        }
      }
    }
  }

  @override
  void initState() {
    _scrollController.addListener(onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87.withAlpha(150),
      floatingActionButton: isVisible
          ? FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                );
                setState(() {
                  isVisible = false;
                });
              },
              child: Icon(Icons.arrow_downward_outlined),
            )
          : null,
      body: Stack(
        children: [
          SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Selector<LogFeature, List<(Color, String)>>(
              shouldRebuild: (_, __) => true,
              builder: (context, logs, child) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return Text(
                      logs[index].$2,
                      style: TextStyle(
                        fontFamily: "monospace",
                        fontSize: 11,
                        color: logs[index].$1,
                      ),
                    );
                  },
                  itemCount: logs.length,
                );
              },
              selector: (context, state) => state._logs,
            ),
          ),
          Opacity(
            opacity: 0.7,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.clean_hands_outlined),
                  label: Text("Clear"),
                  onPressed: () {
                    context.read<LogFeature>().clear();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
