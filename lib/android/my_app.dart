import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:spotify_removed_tracks/main.dart';
import 'package:spotify_removed_tracks/widget/removed_track.dart';

class MyAppImpl extends MyApp {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: getTitle(),
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      initialRoute: RemovedTrack.routeName,
      routes: getRouter(),
    );
  }
}
