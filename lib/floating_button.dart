import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_devtools/in_app_devtools.dart';
import 'package:provider/provider.dart';

class IADFloatingButton extends StatefulWidget {
  const IADFloatingButton({super.key});

  @override
  State<IADFloatingButton> createState() => _IADFloatingButtonState();
}

class _IADFloatingButtonState extends State<IADFloatingButton> {
  final double _width = 50;
  final double _height = 50;
  Offset _offset = Offset(0, 200);
  Offset _startPosition = Offset.zero;
  Offset _startLocalPosition = Offset.zero; // 鼠标相对于窗口的初始偏移量

  bool _moving = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: _repositionGesture(
        child: Selector<IADState, bool>(
          builder: (context, enabled, child) {
            return AnimatedCrossFade(
              alignment: Alignment.centerLeft,
              layoutBuilder:
                  (topChild, topChildKey, bottomChild, bottomChildKey) => Stack(
                children: [
                  Positioned(
                    key: bottomChildKey,
                    child: bottomChild,
                  ),
                  Positioned(
                    key: topChildKey,
                    child: topChild,
                  ),
                ],
              ),
              firstChild: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_width / 2),
                  onTap: () => context.read<IADState>().toggle(),
                  child: Container(
                    width: _width,
                    height: _height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bug_report),
                  ),
                ),
              ),
              secondChild: const SizedBox(),
              crossFadeState: enabled
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 150),
            );
          },
          selector: (context, state) {
            return state.isEnabled;
          },
        ),
      ),
    );
  }

  Widget _repositionGesture({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        _startPosition = _offset;
        _startLocalPosition = details.localPosition;
        setState(() {
          _moving = true;
        });
      },
      onPanUpdate: (details) {
        if (_moving) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final screenHeight = mediaQuery.size.height;
          final padding = mediaQuery.padding;

          double newOffsetX = _startPosition.dx +
              (details.localPosition.dx - _startLocalPosition.dx);
          double newOffsetY = _startPosition.dy +
              (details.localPosition.dy - _startLocalPosition.dy);

          // 边界检查
          newOffsetX = max(padding.left,
              min(newOffsetX, screenWidth - _width - padding.right));
          newOffsetY = max(padding.top,
              min(newOffsetY, screenHeight - _height - padding.bottom));

          setState(() {
            _offset = Offset(newOffsetX, newOffsetY);
          });
        }
      },
      onPanEnd: (details) {
        setState(() {
          _moving = false;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: child,
      ),
    );
  }
}
