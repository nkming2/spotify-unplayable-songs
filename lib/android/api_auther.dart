import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:spotify_removed_tracks/api_auther.dart';
import 'package:spotify_removed_tracks/pref.dart';

class ApiAutherImpl extends ApiAuther {
  @override
  auth() async {
    return _platform.invokeMethod("auth").then((result) {
      final accessToken = result["accessToken"];
      final expiresIn = result["expiresIn"];
      // Spotify OAuth response
      log.info("[auth] access_token: $accessToken, expires_in: $expiresIn");
      Pref.get().setSpotifyAccessToken(accessToken);
    });
  }

  final log = Logger("android.ApiAutherImpl");

  static const _platform =
      const MethodChannel("com.nkming.spotify_removed_tracks/ApiAuther");
}
