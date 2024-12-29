import 'package:flutter/material.dart';
import 'package:in_app_devtools/state.dart';

abstract class IADFeature extends ChangeNotifier {
  final String title;
  final Widget icon;
  late final IADState state;

  IADFeature({
    required this.title,
    required this.icon,
  });

  void init(IADState state);

  Widget build(BuildContext context);
}
