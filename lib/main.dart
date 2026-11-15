import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'app_bootstrap.dart';

import 'config/env.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Env.loadStoredConfig();

  await Env.persistBuildDefinesIfNeeded();



  runApp(

    const ProviderScope(

      child: AppBootstrap(),

    ),

  );

}


