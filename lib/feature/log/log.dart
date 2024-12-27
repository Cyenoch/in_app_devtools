import 'package:flutter/material.dart';
import 'package:in_app_devtools/abstract/feature.dart';
import 'package:provider/provider.dart';

class LogFeature extends IADFeature {
  final List<(Color, String)> _logs = [];
  bool get iadEnabled => state.isEnabled;

  LogFeature()
      : super(
          title: 'Log',
          icon: const Icon(Icons.terminal_outlined),
        );

  log(String log) {
    if (!iadEnabled) return;
    _logs.add((Colors.white, log));
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: this,
      child: const _Log(),
    );
  }
}

class _Log extends StatelessWidget {
  const _Log();

  @override
  Widget build(BuildContext context) {
    return SelectableRegion(
      focusNode: FocusNode(),
      selectionControls: materialTextSelectionControls,
      child: Selector<LogFeature, List<(Color, String)>>(
        shouldRebuild: (_, __) => true,
        builder: (context, logs, child) {
          return ColoredBox(
            color: Colors.black87,
            child: ListView.builder(
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
            ),
          );
        },
        selector: (context, state) => state._logs,
      ),
    );
  }
}
