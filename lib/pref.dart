import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  static Future<void> init() async {
    return SharedPreferences.getInstance().then((pref) {
      _inst._pref = pref;
    });
  }

  static SharedPreferences get() {
    return _inst._pref;
  }

  Pref._();

  static final _inst = Pref._();
  SharedPreferences _pref;
}

extension PrefHelper on SharedPreferences {
  Future<bool> setSpotifyAccessToken(String value) {
    return this.setString("spotifyAccessToken", value);
  }

  String getSpotifyAccessToken(String defVal) {
    return getString("spotifyAccessToken") ?? defVal;
  }

  Future<bool> resetSpotifyAccessToken() {
    return this.remove("spotifyAccessToken");
  }

  Future<bool> setSpotifyOauthId(String value) {
    return this.setString("spotifyOauthId", value);
  }

  String getSpotifyOauthId(String defVal) {
    return getString("spotifyOauthId") ?? defVal;
  }

  Future<bool> resetSpotifyOauthId() {
    return this.remove("spotifyOauthId");
  }
}
