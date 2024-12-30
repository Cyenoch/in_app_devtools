import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_devtools/in_app_devtools.dart';

final Dio dio = Dio();

void main() {
  final logFeature = LogFeature();
  final iadState = IADState(initialFeatures: [
    logFeature,
    DioFeature(dio: dio),
  ]);

  runZoned(() {
    runApp(IADProvider(state: iadState, child: MainApp(iadState: iadState)));
  }, zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      logFeature.log(line);
      parent.print(zone, line);
    },
  ));
}

class MainApp extends StatelessWidget {
  final IADState iadState;
  const MainApp({super.key, required this.iadState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => routerWrapper(context, child, iadState),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  context.iadState.isEnabled = !context.iadState.isEnabled;
                },
                child: Text('Open IAD'),
              ),
              ElevatedButton(
                onPressed: () {
                  dio.get('https://pokeapi.co/api/v2/ability').then((value) {
                    print("?? $value");
                  });

                  dio.post('https://pokeapi.co/api/v2/ability',
                      data: {'test': 'map'}).then((value) {});

                  dio
                      .post('https://pokeapi.co/api/v2/ability',
                          data: FormData.fromMap({'form': 'data'}))
                      .then((value) {});
                },
                child: Text('Send Request'),
              ),
              ElevatedButton(
                  onPressed: () {
                    print('log!!!\nlog!!!!!! ${Random().nextInt(100)}');
                  },
                  child: Text('Log')),
            ],
          ),
        ),
      ),
    );
  }
}
