import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:spotify_removed_tracks/android/my_app.dart'
    if (dart.library.html) 'package:spotify_removed_tracks/web/my_app.dart'
    as impl;

import 'pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    dev.log("${record.level.name} ${record.time}: ${record.message}",
        name: "${record.loggerName}", level: record.level.value);
  });
  await Pref.init();

  runApp(impl.MyAppImpl());
}

abstract class MyApp extends StatelessWidget {
  @protected
  String getTitle() => "Spotify Unplayable Songs";

  @protected
  ThemeData getLightTheme() => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
      );

  @protected
  ThemeData getDarkTheme() => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
      );
}
