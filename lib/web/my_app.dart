import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_removed_tracks/main.dart';
import 'package:spotify_removed_tracks/pref.dart';
import 'package:spotify_removed_tracks/web/api_auther.dart';
import 'package:spotify_removed_tracks/widget/removed_track.dart';

class MyAppImpl extends MyApp {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: getTitle(),
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      initialRoute: RemovedTrack.routeName,
      routes: _router,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    log.info("[_onGenerateRoute] Route: ${settings.name}");
    Route<dynamic> route = _routePostOauth(settings);
    return route ?? MaterialPageRoute(builder: (context) => RemovedTrack());
  }

  Route<dynamic> _routePostOauth(RouteSettings settings) {
    final fragments = _parseUriFragments(settings);
    final accessToken = fragments["access_token"];
    final tokenType = fragments["token_type"];
    final expiresIn = fragments["expires_in"];
    final state = fragments["state"];
    if (accessToken == null ||
        tokenType == null ||
        expiresIn == null ||
        state == null) {
      return null;
    }
    // Spotify OAuth response
    log.info("[_routePostOauth] "
        "access_token: $accessToken, token_type: $tokenType, "
        "expires_in: $expiresIn, state: $state");
    try {
      final stateMap = ApiAutherImpl.parseState(state);
      if (stateMap["id"] != Pref.get().getSpotifyOauthId("")) {
        log.severe(
            "[_routePostOauth] Invalid state from OAuth response, ignored");
        return null;
      }
      Pref.get().resetSpotifyOauthId();
      final from = stateMap["from"];
      if (!_router.containsKey(from)) {
        return null;
      }
      return MaterialPageRoute(
          builder: (context) => _PersistPage(
                accessToken: accessToken,
                redirect: from,
              ));
    } catch (e) {
      log.severe("[_routePostOauth] Exception while parseState: $e");
      return null;
    }
  }

  Map<String, String> _parseUriFragments(RouteSettings settings) {
    var hash = settings.name;
    if (settings.name.startsWith("/")) {
      hash = hash.substring(1);
    }
    final data = hash.split("&");
    final pairs = <String, String>{};
    for (final d in data) {
      final s = d.split("=");
      if (s.length != 2) {
        continue;
      }
      pairs[s[0]] = s[1];
    }
    return pairs;
  }

  final _router = <String, WidgetBuilder>{
    RemovedTrack.routeName: (context) => RemovedTrack(),
  };

  final log = Logger("web.MyAppImpl");
}

class _PersistPage extends StatefulWidget {
  _PersistPage({String accessToken, String redirect, Key key})
      : this._accessToken = accessToken,
        this._redirect = redirect,
        super(key: key);

  _PersistPageState createState() => _PersistPageState();

  final String _accessToken;
  final String _redirect;
}

class _PersistPageState extends State<_PersistPage> {
  @override
  void initState() {
    log.info(
        "[initState] Persisting token, then redirect to ${widget._redirect}");
    super.initState();
    _persistSpotifyAuth(widget._accessToken).then((_) {
      Navigator.pushReplacementNamed(context, widget._redirect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  Future<void> _persistSpotifyAuth(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setSpotifyAccessToken(accessToken);
  }

  final log = Logger("web._PersistPageState");
}
