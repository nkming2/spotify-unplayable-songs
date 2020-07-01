import 'dart:convert';
import 'dart:html';

import 'package:spotify_removed_tracks/api_auther.dart';
import 'package:spotify_removed_tracks/pref.dart';
import 'package:uuid/uuid.dart';

class ApiAutherImpl extends ApiAuther {
  static const clientId = "";
  static const redirectUri = "http://localhost:39393";
  static const scopes = [
    "user-library-read",
    "user-library-modify",
    "playlist-read-private",
    "playlist-modify-public",
    "playlist-modify-private",
  ];

  @override
  auth() async {
    final id = Uuid().v4().replaceAll("-", "");
    final from = Uri.base.fragment;
    final state = makeState(id, from);
    Pref.get().setSpotifyOauthId(id);
    final url = "https://accounts.spotify.com/authorize"
        "?client_id=$clientId"
        "&response_type=token"
        "&redirect_uri=${Uri.encodeQueryComponent(redirectUri)}"
        "&scope=${Uri.encodeQueryComponent(scopes.join(' '))}"
        "&state=$state";
    window.location.assign(url);
  }

  static String makeState(String id, String from) {
    final stateMap = <String, dynamic>{
      "id": id,
      "from": from,
    };
    final stateJson = jsonEncode(stateMap);
    return base64Encode(utf8.encode(stateJson));
  }

  static Map<String, dynamic> parseState(String stateStr) {
    final stateJson = utf8.decode(base64Decode(stateStr));
    return jsonDecode(stateJson);
  }
}
