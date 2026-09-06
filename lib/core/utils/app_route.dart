import 'package:flutter/material.dart';

/// 画面遷移で使う軽いスライド＋フェード（250ms）の[PageRouteBuilder]。
///
/// 右からわずかにスライドしながらフェードインする。
/// `Navigator.of(context).push(appRoute(builder: (_) => NextScreen()))` の
/// ように[MaterialPageRoute]の代わりに使う。
PageRouteBuilder<T> appRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
