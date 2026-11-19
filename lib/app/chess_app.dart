import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_config.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_language.dart';
import 'app_services.dart';
import 'brand_intro_gate.dart';

class ChessApp extends StatefulWidget {
  const ChessApp({
    super.key,
    required this.services,
    this.initialLocation,
    this.showIntro = false,
  });
  final bool showIntro;
  final AppServices services;
  final String? initialLocation;
  @override
  State<ChessApp> createState() => _ChessAppState();
}

class _ChessAppState extends State<ChessApp> {
  late final GoRouter router = createRouter(widget.initialLocation);
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    services: widget.services,
    child: ListenableBuilder(
      listenable: Listenable.merge([
        widget.services.theme,
        widget.services.comfort,
        widget.services.language,
      ]),
      builder: (context, _) => MaterialApp.router(
        title: AppConfig.name,
        debugShowCheckedModeBanner: false,
        locale: widget.services.language.locale,
        supportedLocales: AppLanguage.values.map((l) => Locale(l.code)),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.build(
          Brightness.light,
          colorTheme: widget.services.theme.colorTheme,
        ),
        darkTheme: AppTheme.build(
          Brightness.dark,
          colorTheme: widget.services.theme.colorTheme,
        ),
        themeMode: widget.services.theme.mode,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.disableAnimationsOf(context) ||
                (widget.services.comfort?.reducedMotion ?? false),
          ),
          child: widget.showIntro
              ? BrandIntroGate(child: child ?? const SizedBox.shrink())
              : child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
