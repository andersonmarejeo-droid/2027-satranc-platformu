import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Used only when there is no previous page (for example a direct link).
String parentMenuFor(String path) {
  if (path.startsWith('/history/')) return '/history';
  if (path.startsWith('/challenge/')) return '/challenges';
  return switch (path) {
    '/game' || '/matchmaking' => '/play',
    '/settings' || '/registration' || '/history' || '/safety' => '/profile',
    '/challenges' => '/social',
    _ when path.startsWith('/online-match/') => '/play',
    _ => '/',
  };
}

/// maybePop also handles open dialogs and a page's save-before-leaving guard.
Future<void> requestMenuBack(BuildContext context) async {
  final router = GoRouter.of(context);
  final handled = await router.routerDelegate.popRoute();
  if (!handled && context.mounted) {
    router.go(parentMenuFor(router.routeInformationProvider.value.uri.path));
  }
}

class MenuBackScope extends StatelessWidget {
  const MenuBackScope({super.key, required this.child, this.onBack});
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: onBack == null && GoRouter.of(context).canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        if (onBack != null) {
          onBack!();
          return;
        }
        final router = GoRouter.of(context);
        router.go(
          parentMenuFor(router.routeInformationProvider.value.uri.path),
        );
      }
    },
    child: child,
  );
}

class MenuBackButton extends StatelessWidget {
  const MenuBackButton({super.key});
  @override
  Widget build(BuildContext context) =>
      BackButton(onPressed: () => requestMenuBack(context));
}
