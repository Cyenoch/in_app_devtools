import 'package:flutter/material.dart';
import 'package:in_app_devtools/abstract/feature.dart';
import 'package:provider/provider.dart';

class IADState extends ChangeNotifier {
  List<IADFeature> _features;
  List<IADFeature> get features => _features;
  set features(List<IADFeature> value) {
    for (final item in value) {
      item.state = this;
    }
    _features = value;
    notifyListeners();
  }

  bool _isOpened = false;
  bool get isOpened => _isOpened;
  set isOpened(bool value) {
    _isOpened = value;
    notifyListeners();
  }

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) {
    _isEnabled = value;
    notifyListeners();
  }

  IADState({
    bool? intitialOpen,
    List<IADFeature> initialFeatures = const [],
  })  : _isOpened = intitialOpen ?? false,
        _features = initialFeatures {
    for (final item in initialFeatures) {
      item.state = this;
    }
  }

  void toggle() {
    isOpened = !isOpened;
    notifyListeners();
    for (var element in features) {
      element.onIADEnabledToggle(isOpened);
    }
  }

  static IADState of(BuildContext context) {
    return context.read<IADState>();
  }
}
