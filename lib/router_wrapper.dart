import 'package:flutter/material.dart';
import 'package:in_app_devtools/abstract/feature.dart';
import 'package:in_app_devtools/in_app_devtools.dart';
import 'package:in_app_devtools/window.dart';
import 'package:provider/provider.dart';

class IADProvider extends StatelessWidget {
  final Widget child;
  final IADState state;
  const IADProvider({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<IADState>.value(
      value: state,
      child: child,
    );
  }
}

Widget routerWrapper(
    BuildContext context, Widget? child, IADState? initialState) {
  return Stack(
    children: [
      child!,
      const IADFloatingButton(),
      IADWindow(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(0.8),
            viewPadding: const EdgeInsets.all(0),
            viewInsets: const EdgeInsets.all(0),
            systemGestureInsets: const EdgeInsets.all(0),
            padding: const EdgeInsets.all(0),
          ),
          child: HeroControllerScope(
            controller: HeroController(createRectTween: (begin, end) {
              return MaterialRectArcTween(begin: begin, end: end);
            }),
            child: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (context) {
                  return _IADPanel();
                });
              },
            ),
          ),
        ),
      ),
    ],
  );
}

class _IADPanel extends StatelessWidget {
  const _IADPanel();

  @override
  Widget build(BuildContext context) {
    return Selector<IADState, List<IADFeature>>(
      builder: (context, features, child) {
        return DefaultTabController(
          length: features.length,
          initialIndex: 0,
          child: Scaffold(
            appBar: TabBar(
              isScrollable: true,
              padding: const EdgeInsets.all(0),
              labelPadding: const EdgeInsets.all(0),
              indicatorPadding: const EdgeInsets.all(0),
              tabs: features
                  .map((feature) => Tab(
                        icon: feature.icon,
                        text: feature.title,
                        iconMargin: const EdgeInsets.symmetric(horizontal: 8),
                        height: 44,
                      ))
                  .toList(),
            ),
            body: TabBarView(
              children:
                  features.map((feature) => feature.build(context)).toList(),
            ),
          ),
        );
      },
      selector: (_, state) => state.features,
    );
  }
}
