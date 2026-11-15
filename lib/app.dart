import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'core/models/accessibility_settings.dart';

import 'core/providers/accessibility_providers.dart';

import 'core/router/app_router.dart';

import 'core/theme/app_theme.dart';



class MemoriaVivaApp extends ConsumerWidget {

  const MemoriaVivaApp({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(routerProvider);

    final settings =

        ref.watch(accessibilitySettingsProvider).value ??

        const AppAccessibilitySettings();



    return MaterialApp.router(

      title: 'Memoria Viva',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.build(settings),

      locale: const Locale('es'),

      supportedLocales: const [Locale('es')],

      localizationsDelegates: const [

        GlobalMaterialLocalizations.delegate,

        GlobalWidgetsLocalizations.delegate,

        GlobalCupertinoLocalizations.delegate,

      ],

      routerConfig: router,

    );

  }

}


