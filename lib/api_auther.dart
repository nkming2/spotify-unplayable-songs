import 'package:flutter/foundation.dart';
import 'package:spotify_removed_tracks/pref.dart';

import 'android/api_auther.dart' if (dart.library.html) 'web/api_auther.dart'
    as impl;
import 'api/api.dart';

abstract class ApiAuther {
  factory ApiAuther.inst() {
    return _inst;
  }

  Future<Response> run(Future<Response> fn(Api api)) async {
    final response = await fn(Api(token()));
    if (response.statusCode == 400 || response.statusCode == 401) {
      // Auth needed
      await auth();
      return await fn(Api(token()));
    } else {
      return response;
    }
  }

  static const clientId = "";
  static const redirectUri = "http://localhost:39393";
  static const scopes = [
    "user-library-read",
    "user-library-modify",
    "playlist-read-private",
    "playlist-modify-public",
    "playlist-modify-private",
  ];

  ApiAuther();

  @protected
  Future<void> auth();

  @protected
  String token() {
    return Pref.get().getSpotifyAccessToken("");
  }

  static final ApiAuther _inst = impl.ApiAutherImpl();
}
