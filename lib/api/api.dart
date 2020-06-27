import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class Response {
  Response(this.statusCode, this.headers, this.body);

  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
}

class Api {
  Api(this._accessToken);

  _Me me() => _Me(this);
  _Playlists playlists(String id) => _Playlists(this, id);

  Future<Response> _get(String endpoint, {Map<String, String> args}) async {
    final url = Uri.https(_DOMAIN, endpoint, args);
    final response =
        await http.get(url, headers: {"Authorization": "Bearer $_accessToken"});
    final body = jsonDecode(response.body);
    final r = Response(response.statusCode, response.headers, body);
    if (response.statusCode / 100 != 2) {
      log.severe(
        "[_get] HTTP GET (${response.statusCode}): $endpoint",
        response.body,
      );
    }
    return r;
  }

  Future<Response> _delete(String endpoint, {Map<String, String> args}) async {
    final url = Uri.https(_DOMAIN, endpoint, args);
    final response = await http
        .delete(url, headers: {"Authorization": "Bearer $_accessToken"});
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};
    final r = Response(response.statusCode, response.headers, body);
    if (response.statusCode / 100 != 2) {
      log.severe(
        "[_delete] HTTP DELETE (${response.statusCode}): $endpoint",
        response.body,
      );
    }
    return r;
  }

  Future<Response> _deleteBody(String endpoint, String body) async {
    final url = Uri.https(_DOMAIN, endpoint);
    final req = http.Request("DELETE", url)
      ..headers.addAll({
        "Authorization": "Bearer $_accessToken",
        "Content-Type": "application/json",
      });
    req.body = body;
    final response =
        await http.Response.fromStream(await http.Client().send(req));
    final responseBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};
    final r = Response(response.statusCode, response.headers, responseBody);
    if (response.statusCode / 100 != 2) {
      log.severe(
        "[_deleteBody] HTTP DELETE (${response.statusCode}): $endpoint",
        response.body,
      );
    }
    return r;
  }

  static const _DOMAIN = "api.spotify.com";
  final String _accessToken;

  final log = Logger("api.Api");
}

class _Me {
  _Me(this._api);

  /// Get detailed profile information about the current user (including the
  /// current user’s username)
  ///
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/users-profile/get-current-users-profile/
  Future<Response> get() async {
    const endpoint = "v1/me";
    try {
      return await _api._get(endpoint);
    } catch (e) {
      log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  _MeAlbums albums() => _MeAlbums(_api, this);
  _MePlaylists playlists() => _MePlaylists(_api, this);
  _MeTracks tracks() => _MeTracks(_api, this);

  Api _api;

  final log = Logger("api._Me");
}

class _MeAlbums {
  _MeAlbums(this._api, this._me);

  /// Get a list of the albums saved in the current Spotify user’s ‘Your Music’
  /// library
  ///
  /// @param limit
  /// @param offset
  /// @param market
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-albums/
  Future<Response> get({int limit, int offset, String market}) async {
    const endpoint = "v1/me/albums";
    try {
      return await _api._get(endpoint, args: {
        if (limit != null) "limit": _toString(limit),
        if (offset != null) "offset": _toString(offset),
        if (market != null) "market": _toString(market),
      });
    } catch (e) {
      log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  Api _api;
  // ignore: unused_field
  _Me _me;

  final log = Logger("api._MeAlbums");
}

class _MePlaylists {
  _MePlaylists(this._api, this._me);

  /// Get a list of the playlists owned or followed by the current Spotify user
  ///
  /// @param limit
  /// @param offset
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/playlists/get-a-list-of-current-users-playlists/
  Future<Response> get({int limit, int offset}) async {
    const endpoint = "v1/me/playlists";
    try {
      return await _api._get(endpoint, args: {
        if (limit != null) "limit": _toString(limit),
        if (offset != null) "offset": _toString(offset),
      });
    } catch (e) {
      log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  Api _api;
  // ignore: unused_field
  _Me _me;

  final log = Logger("api._MePlaylists");
}

class _MeTracks {
  _MeTracks(this._api, this._me);

  /// Get a list of the songs saved in the current Spotify user’s ‘Your Music’
  /// library
  ///
  /// @param limit
  /// @param offset
  /// @param market
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/library/get-users-saved-tracks/
  Future<Response> get({int limit, int offset, String market}) async {
    const endpoint = "v1/me/tracks";
    try {
      return await _api._get(endpoint, args: {
        if (limit != null) "limit": _toString(limit),
        if (offset != null) "offset": _toString(offset),
        if (market != null) "market": _toString(market),
      });
    } catch (e) {
      log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  Future<Response> delete({List<String> ids}) async {
    const endpoint = "v1/me/tracks";
    try {
      return await _api._delete(endpoint, args: {
        if (ids != null) "ids": ids.join(","),
      });
    } catch (e) {
      log.severe("[delete] Failed while delete", e);
      rethrow;
    }
  }

  Api _api;
  // ignore: unused_field
  _Me _me;

  final log = Logger("api._MeTracks");
}

class _Playlists {
  _Playlists(this._api, this._id);

  /// Get a playlist owned by a Spotify user
  ///
  /// @param fields
  /// @param market
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlist/
  Future<Response> get({String fields, String market}) async {
    final endpoint = "v1/playlists/$_id";
    try {
      return await _api._get(endpoint, args: {
        if (fields != null) "fields": _toString(fields),
        if (market != null) "market": _toString(market),
      });
    } catch (e) {
      log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  _PlaylistsTracks tracks() => _PlaylistsTracks(_api, this);

  Api _api;
  // ignore: unused_field
  String _id;

  final log = Logger("api._Playlists");
}

class _PlaylistsTracks {
  _PlaylistsTracks(this._api, this._playlists);

  /// Get full details of the tracks of a playlist owned by a Spotify user
  ///
  /// @param fields
  /// @param limit
  /// @param offset
  /// @param market
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/playlists/get-playlists-tracks/
  Future<Response> get(
      {String fields, int limit, int offset, String market}) async {
    final endpoint = "v1/playlists/${_playlists._id}/tracks";
    try {
      return await _api._get(endpoint, args: {
        if (fields != null) "fields": _toString(fields),
        if (limit != null) "limit": _toString(limit),
        if (offset != null) "offset": _toString(offset),
        if (market != null) "market": _toString(market),
      });
    } catch (e) {
      log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  /// Remove one or more items from a user’s playlist
  ///
  /// @param tracks
  /// @return
  /// @see https://developer.spotify.com/documentation/web-api/reference/playlists/remove-tracks-playlist/
  Future<Response> delete({List<Map<String, dynamic>> tracks}) async {
    final endpoint = "v1/playlists/${_playlists._id}/tracks";
    try {
      final body = {"tracks": <Map<String, dynamic>>[]};
      for (final t in tracks) {
        final obj = {
          "uri": t["uri"].toString(),
          if (t.containsKey("positions"))
            "positions": t["positions"] as List<int>,
        };
        body["tracks"].add(obj);
      }
      return await _api._deleteBody(endpoint, jsonEncode(body));
    } catch (e) {
      log.severe("[delete] Failed while delete", e);
      rethrow;
    }
  }

  Api _api;
  _Playlists _playlists;

  final log = Logger("api._PlaylistsTracks");
}

_toString(v) {
  if (v is DateTime) {
    final f = DateFormat("yyyy-MM-dd'T'HH:mm:ssZ");
    return f.format(v);
  } else {
    return v.toString();
  }
}
