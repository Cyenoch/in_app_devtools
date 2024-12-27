import 'package:flutter/widgets.dart';
import 'package:in_app_devtools/state.dart';
export 'state.dart';
export 'router_wrapper.dart';
export 'floating_button.dart';
export 'feature/dio/dio.dart';
export 'feature/log/log.dart';

extension IADX on BuildContext {
  IADState get iadState => IADState.of(this);
}
