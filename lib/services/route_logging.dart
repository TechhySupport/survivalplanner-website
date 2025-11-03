import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final ValueNotifier<String?> currentScreenName = ValueNotifier<String?>(null);

mixin ScreenLogger<T extends StatefulWidget> on State<T> implements RouteAware {
  String get screenName => T.toString();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    debugPrint('[NAV] pushed: $screenName');
    currentScreenName.value = screenName;
  }

  @override
  void didPop() {
    debugPrint('[NAV] popped: $screenName');
  }

  @override
  void didPushNext() {
    debugPrint('[NAV] covered by next: $screenName');
    currentScreenName.value = null;
  }

  @override
  void didPopNext() {
    debugPrint('[NAV] revealed: $screenName');
    currentScreenName.value = screenName;
  }
}

class ScreenDebugBanner extends StatelessWidget {
  const ScreenDebugBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(
      valueListenable: currentScreenName,
      builder: (context, name, _) {
        if (name == null || name.isEmpty) return const SizedBox.shrink();
        return IgnorePointer(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        );
      },
    );
  }
}
