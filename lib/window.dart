import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_devtools/state.dart';
import 'package:provider/provider.dart';

class IADWindow extends StatefulWidget {
  final Widget child;
  const IADWindow({super.key, required this.child});

  @override
  State<IADWindow> createState() => _IADWindowState();
}

class _IADWindowState extends State<IADWindow>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  double _windowWidth = 400;
  double _windowHeight = 350;
  Offset _offset = Offset(0, 200);
  Offset _startPosition = Offset.zero;
  Offset _startLocalPosition = Offset.zero;

  Offset resizeStartPos = Offset.zero;
  double resizeStartHeight = 0;
  double resizeStartWidth = 0;
  bool resizing = false;
  bool moving = false;

  bool _inited = false;

  late final AnimationController _animationCtrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 150),
    value: 1,
  );

  @override
  void initState() {
    context.read<IADState>().addListener(listener);
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    context.read<IADState>().removeListener(listener);
    _animationCtrl.dispose();
    super.dispose();
  }

  void listener() {
    final isOpened = context.read<IADState>().isOpened;

    if (!isOpened) {
      _animationCtrl.forward();
    } else {
      _animationCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_inited) {
      _inited = true;
      _windowWidth = MediaQuery.sizeOf(context).width - 40;
      _windowHeight = MediaQuery.sizeOf(context).height / 2;
      _offset = Offset(
          20,
          MediaQuery.sizeOf(context).height / 2 -
              MediaQuery.viewPaddingOf(context).bottom);
    }

    super.build(context);
    final isOpened = context.select((IADState state) => state.isOpened);

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: IgnorePointer(
        ignoring: !isOpened,
        child: Material(
          color: Colors.transparent,
          textStyle: Theme.of(context).textTheme.bodySmall,
          child: AnimatedBuilder(
            animation: _animationCtrl,
            builder: (context, child) {
              return Container(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  ),
                  borderRadius:
                      BorderRadius.circular(8 + (_animationCtrl.value * 200)),
                ),
                child: 1 - _animationCtrl.value == 0
                    ? const SizedBox()
                    : Opacity(opacity: 1 - _animationCtrl.value, child: child),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: _windowWidth,
                  height: _windowHeight,
                  padding: const EdgeInsets.only(top: 20),
                  child: widget.child,
                ),

                // position handle
                _buildRepositionHandle(),
                _buildResizeHandle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepositionHandle() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _repositionGesture(
        child: Container(
          height: 20,
          color: Colors.grey.shade100,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: moving ? Colors.green : Colors.grey.shade400,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  width: moving ? 90 : 80,
                  height: moving ? 7 : 6,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() {
                    context.read<IADState>().isOpened = false;
                  }),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: Colors.red.shade400),
                    child: Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          resizeStartPos = details.globalPosition;
          resizeStartHeight = _windowHeight;
          resizeStartWidth = _windowWidth;
          resizing = true;
        },
        onPanUpdate: (details) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final screenHeight = mediaQuery.size.height;
          final padding = mediaQuery.padding;

          setState(() {
            double deltaX = details.globalPosition.dx - resizeStartPos.dx;
            double deltaY = details.globalPosition.dy - resizeStartPos.dy;
            double newWidth = max(100, resizeStartWidth + deltaX);
            double newHeight = max(50, resizeStartHeight + deltaY);

            // 边界检查，不允许超出屏幕
            newWidth = min(newWidth, screenWidth - _offset.dx - padding.right);
            newHeight =
                min(newHeight, screenHeight - _offset.dy - padding.bottom);

            _windowWidth = newWidth;
            _windowHeight = newHeight;
          });
        },
        onPanEnd: (details) {
          resizing = false;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
            ),
            width: 14,
            height: 14,
            child: Transform.rotate(
              angle: -45,
              child: Icon(Icons.expand_more_rounded, size: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _repositionGesture({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        if (!resizing) {
          _startPosition = _offset;
          _startLocalPosition = details.localPosition;
          setState(() {
            moving = true;
          });
        }
      },
      onPanUpdate: (details) {
        if (!resizing && moving) {
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
              min(newOffsetX, screenWidth - _windowWidth - padding.right));
          newOffsetY = max(padding.top,
              min(newOffsetY, screenHeight - _windowHeight - padding.bottom));

          setState(() {
            _offset = Offset(newOffsetX, newOffsetY);
          });
        }
      },
      onPanEnd: (details) {
        setState(() {
          moving = false;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: child,
      ),
    );
  }
}
