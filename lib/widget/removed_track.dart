import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:logging/logging.dart';
import 'package:spotify_removed_tracks/api/api.dart';
import 'package:spotify_removed_tracks/api/api_util.dart';
import 'package:spotify_removed_tracks/api_auther.dart';
import 'package:spotify_removed_tracks/asset_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Minimum count of items to add per each call of _next()
const _minItemsToAddPerRun = 12;
// When to trigger a query
const _visibleItemThreshold = 8;

class RemovedTrack extends StatefulWidget {
  static const routeName = "/";

  RemovedTrack({Key key}) : super(key: key);

  static const String title = "Spotify Unplayable Songs";

  @override
  createState() => _RemovedTrackState();
}

class _RemovedTrackState extends State<RemovedTrack> {
  @override
  initState() {
    super.initState();
    _queryPlaylists().then((playlists) {
      log.fine(
          "[initState] ${playlists.length} playlists queried: [${playlists.map((l) => l["name"]).join(", ")}]");
      setState(() {
        _playlists.clear();
        _playlists.add(_LikedSongPlaylist());
        for (final p in playlists) {
          _playlists.add(_UserPlaylist(p));
        }
      });
      _dataIterator = _generateData().iterator;
      _next();
    }).catchError((e) {
      log.severe("[initState] Exception while _queryPlaylists: $e");
      _scaffoldKey.currentState?.showSnackBar(SnackBar(
        content: Text("$e"),
      ));
    });
  }

  @override
  build(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      body: Builder(builder: (context) => _buildContent(context)),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (_isPickerMode) {
      final pickedCount = _pickedItems.values
          .map((e) => e.length)
          .fold(0, (previousValue, element) => previousValue + element);
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _pickedItems.clear();
              _isPickerMode = false;
            });
          },
        ),
        title: Text("$pickedCount selected"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Remove selected",
            onPressed: () {
              _removeSelected().then((_) {
                _scaffoldKey.currentState?.showSnackBar(SnackBar(
                  content: Text("$pickedCount items removed"),
                ));
              }).catchError((e) {
                _scaffoldKey.currentState?.showSnackBar(SnackBar(
                  content: Text("$e"),
                  action: _buildSnackBarReloadAction(),
                ));
              });
              setState(() {
                for (final e in _pickedItems.entries) {
                  e.key.tracks.removeWhere((t) => e.value.contains(t));
                }
                _pickedItems.clear();
                _isPickerMode = false;
              });
            },
          )
        ],
      );
    } else {
      return AppBar(
        title: const Text(RemovedTrack.title),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (!_hasNext && _countTracks() == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              width: 96,
              height: 96,
              image: AssetImage(AssetUtil.listPlaceholder(context)),
            ),
            SizedBox(height: 16),
            Text(
              "All your favorites are good",
              style:
                  Theme.of(context).textTheme.headline5.copyWith(fontSize: 20),
            ),
          ],
        ),
      );
    } else {
      final body = <Widget>[
        CustomScrollView(
          slivers: _buildSubLists(context),
        ),
      ];
      if (_isQuerying) {
        // Add a progress bar
        body.add(Align(
          alignment: Alignment.topLeft,
          child: LinearProgressIndicator(
            value: null,
          ),
        ));
      }
      return Stack(children: body);
    }
  }

  List<Widget> _buildSubLists(BuildContext context) {
    final lists = _playlists
        .where((l) => l.tracks.isNotEmpty)
        .map((l) => _buildSubList(context, l))
        .toList();
    if (_isQuerying) {
      lists.add(SliverToBoxAdapter(
        child: ListTile(
          title: Center(
            child: Text(
              "Querying data from Spotify...",
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ),
      ));
    }
    return lists;
  }

  Widget _buildSubList(BuildContext context, _Playlist list) {
    return Container(
      child: SliverStickyHeader(
        header: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.centerLeft,
          child: Text(list.name, style: Theme.of(context).textTheme.subtitle1),
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _buildRow(context, list, list.tracks[i]),
            childCount: list.tracks.length,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, _Playlist parent, _Track track) {
    final images = track.meta["album"]["images"] as List;
    final img = ApiUtil.selectAlbumImage(images, 128);
    Widget coverArtWidget;
    if (kIsWeb) {
      // CachedNetworkImage doesn't work due to dependency on sqflite, and a
      // proper browser would already do the caching for us anyway
      coverArtWidget = Image.network(
        img["url"],
        fit: BoxFit.contain,
      );
    } else {
      coverArtWidget = CachedNetworkImage(
        imageUrl: img["url"],
        fit: BoxFit.contain,
      );
    }

    final leadingWidget = Stack(children: [coverArtWidget]);
    if (_pickedItems[parent]?.contains(track) == true) {
      leadingWidget.children.add(
        Container(color: Theme.of(context).accentColor.withOpacity(0.75)),
      );
      leadingWidget.children.add(Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.check_circle,
          color: Colors.white,
        ),
      ));
    }

    final itemWidget = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56.0,
        height: 56.0,
        child: leadingWidget,
      ),
      title: Text(track.meta["name"]),
      subtitle:
          Text([for (final a in track.meta["artists"]) a["name"]].join(", ")),
      onLongPress: () {
        if (!_isPickerMode) {
          setState(() {
            _isPickerMode = true;
            _pick(parent, track);
          });
        }
      },
      onTap: () {
        if (_isPickerMode) {
          setState(() {
            _togglePick(parent, track);
          });
        }
      },
    );

    return Dismissible(
      background: Container(color: Colors.red[700]),
      key: parent.createTrackKeyBuilder().create(track),
      onDismissed: (direction) {
        // It's best to put this in confirmDismiss, but it'll throw if user
        // scrolled away...
        _removeTracks(parent, [track]).then((_) {
          _scaffoldKey.currentState?.showSnackBar(SnackBar(
            content: Text("1 item removed"),
          ));
        }).catchError((e) {
          _scaffoldKey.currentState?.showSnackBar(SnackBar(
            content: Text("$e"),
            action: _buildSnackBarReloadAction(),
          ));
        });
        setState(() {
          parent.tracks.remove(track);
        });
      },
      child: VisibilityDetector(
        key: parent.createTrackKeyBuilder().create(track),
        onVisibilityChanged: (VisibilityInfo info) {
          if (!_isQuerying &&
              info.visibleFraction == 1 &&
              _lastItemKeys.contains(info.key)) {
            _next();
          }
        },
        child: itemWidget,
      ),
    );
  }

  SnackBarAction _buildSnackBarReloadAction() {
    return SnackBarAction(
      label: "Reload",
      onPressed: () {
        setState(() {
          _reloadTracks();
        });
      },
    );
  }

  Future<void> _next() async {
    final instanceId = _instanceId;
    return _doNext().then((_) {
      // Make sure we only handle the results from current instance
      if (_instanceId != instanceId) {
        return;
      }
      _updateLastItemKey();
    });
  }

  Future<void> _doNext() async {
    if (_isQuerying) {
      log.info("[_doNext] Another query ongoing");
      return Future.error("");
    }
    setState(() {
      _isQuerying = true;
    });
    try {
      int count = 0;
      while (true) {
        final data = await _queryNext();
        if (data == null) {
          return;
        } else if (data.tracks.isEmpty) {
          log.fine("[_doNext] Empty result, query next");
        } else {
          log.fine(
              "[_doNext] ${data.tracks.length} items added to playlist #${data.listIndex} ${_playlists[data.listIndex].name}");
          setState(() {
            _playlists[data.listIndex].tracks.addAll(
                data.tracks.map((t) => _playlists[data.listIndex].asTrack(t)));
          });
          count += data.tracks.length;
          if (count >= _minItemsToAddPerRun) {
            return;
          }
        }
      }
    } finally {
      setState(() {
        _isQuerying = false;
      });
    }
  }

  void _updateLastItemKey() {
    _lastItemKeys.clear();
    for (final l in _playlists.reversed) {
      for (final t in l.tracks.reversed) {
        _lastItemKeys.add(l.createTrackKeyBuilder().create(t));
        if (_lastItemKeys.length >= _visibleItemThreshold) {
          return;
        }
      }
    }
  }

  Future<_QueryData> _queryNext() async {
    if (_dataIterator.moveNext()) {
      final data = await _dataIterator.current;
      if (data == null) {
        return null;
      }
      final items = _QueryData.empty(data.listIndex);
      for (final t in data.tracks) {
        if (!t["is_playable"]) {
          items.tracks.add(t);
        }
      }
      return items;
    } else {
      _hasNext = false;
      return null;
    }
  }

  Iterable<Future<_QueryData>> _generateData() sync* {
    var listI = 0;
    var offset = 0;
    var shouldRun = true;
    while (shouldRun && listI < _playlists.length) {
      final query = _playlists[listI].createQuerier().query(offset);
      yield query.then((body) {
        if (body == null) {
          shouldRun = false;
          return null;
        }
        List<Map<String, dynamic>> items =
            body["items"].cast<Map<String, dynamic>>();
        offset += items.length;
        final thisListI = listI;
        if (body["next"] == null) {
          listI += 1;
          offset = 0;
        }
        return _QueryData(
            thisListI, items.map((e) => e["track"] as Map<String, dynamic>));
      }).catchError((e) {
        log.severe("[_generateData] Exception while query: $e");
        _scaffoldKey.currentState?.showSnackBar(SnackBar(
          content: Text("$e"),
          action: _buildSnackBarReloadAction(),
        ));
        shouldRun = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _queryPlaylists() async {
    var offset = 0;
    var product = <Map<String, dynamic>>[];
    while (true) {
      try {
        final response =
            await ApiAuther.inst().run((api) => api.me().playlists().get(
                  limit: 50,
                  offset: offset,
                ));
        if (response.statusCode != 200) {
          log.severe("[_queryPlaylists] Failed requesting server: $response");
          throw HttpException(
              "Failed querying data from Spotify server: ${response.statusCode}");
        }
        final body = response.body;
        product += body["items"].cast<Map<String, dynamic>>();
        offset += body["limit"];
        if (body["next"] == null) {
          return product;
        }
      } catch (error) {
        log.severe("[_queryPlaylists] Exception requesting server: $error");
        throw HttpException("Failed querying data from Spotify server");
      }
    }
  }

  void _togglePick(_Playlist parent, _Track track) {
    if (_pickedItems[parent] == null) {
      _pick(parent, track);
      return;
    }

    final found = _pickedItems[parent].indexOf(track);
    if (found == -1) {
      _pick(parent, track);
    } else {
      _unpick(parent, found);
      if (_pickedItems.isEmpty) {
        _isPickerMode = false;
      }
    }
  }

  void _pick(_Playlist parent, _Track track) {
    if (_pickedItems[parent] == null) {
      _pickedItems[parent] = <_Track>[];
    }
    _pickedItems[parent].add(track);
  }

  void _unpick(_Playlist parent, int position) {
    _pickedItems[parent].removeAt(position);
    if (_pickedItems[parent].isEmpty) {
      _pickedItems.remove(parent);
    }
  }

  Future<void> _removeTracks(_Playlist parent, List<_Track> tracks) async {
    final deleter = parent.createDeleter();
    deleter.pushAll(tracks.iterator);
    try {
      final response = await deleter.delete();
      if (response.statusCode == 200) {
      } else {
        log.severe(
            "[_removeTracks] Failed removing ${tracks.length} items: (${response.statusCode}) ${response.body}");
        throw ("Failed removing ${tracks.length} items: ${response.statusCode}");
      }
    } catch (e) {
      log.severe("[_removeTracks] Exception while delete: $e");
      rethrow;
    }
  }

  Future<void> _removeSelected() async {
    final futures = <Future>[];
    for (final e in _pickedItems.entries) {
      futures.add(_removeTracks(e.key, e.value));
    }
    return await Future.wait(futures);
  }

  int _countTracks() {
    int count = 0;
    for (final l in _playlists) {
      count += l.tracks.length;
    }
    return count;
  }

  void _reloadTracks() {
    _instanceId += 1;
    for (final l in _playlists) {
      l.tracks.clear();
    }
    _pickedItems.clear();
    _isPickerMode = false;

    _isQuerying = false;
    _hasNext = true;
    _dataIterator = _generateData().iterator;
    _next();
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _playlists = <_Playlist>[];
  Iterator<Future<_QueryData>> _dataIterator;
  final _lastItemKeys = <ValueKey<String>>[];
  bool _isQuerying = false;
  int _instanceId = 0;
  bool _hasNext = true;

  bool _isPickerMode = false;
  final _pickedItems = <_Playlist, List<_Track>>{};

  final log = Logger("widget.removed_track._RemovedTrackState");
}

abstract class _Playlist {
  String get name;
  _PlaylistQuerier createQuerier();
  _TrackDeleter createDeleter();
  _KeyBuilder createTrackKeyBuilder();
  _Track asTrack(Map<String, dynamic> queryData);

  final tracks = <_Track>[];
}

class _LikedSongPlaylist extends _Playlist {
  @override
  get name => "Liked Songs";

  @override
  createQuerier() => _LikedSongPlaylistQuerier();

  @override
  createDeleter() => _LikedSongTrackDeleter();

  @override
  createTrackKeyBuilder() => _LikedSongKeyBuilder();

  @override
  asTrack(queryData) => _LikedSongTrack(queryData);
}

class _UserPlaylist extends _Playlist {
  _UserPlaylist(this.meta);

  @override
  get name => meta["name"];

  @override
  createQuerier() => _UserPlaylistQuerier(this);

  @override
  createDeleter() => _UserPlaylistTrackDeleter(this);

  @override
  createTrackKeyBuilder() => _UserKeyBuilder(this);

  @override
  asTrack(queryData) => _UserPlaylistTrack(queryData);

  final Map<String, dynamic> meta;
}

abstract class _PlaylistQuerier {
  Future<dynamic> query(int offset);
}

class _LikedSongPlaylistQuerier extends _PlaylistQuerier {
  @override
  query(offset) async {
    log.info("[query] Query new data (offset: $offset)");
    try {
      final response =
          await ApiAuther.inst().run((api) => api.me().tracks().get(
                limit: 50,
                offset: offset,
                market: "from_token",
              ));
      if (response.statusCode != 200) {
        log.severe("[query] Failed requesting server: $response");
        throw HttpException(
            "Failed querying data from Spotify server: ${response.statusCode}");
      } else {
        return response.body;
      }
    } catch (error) {
      log.severe("[query] Exception requesting server: $error");
      throw HttpException("Failed querying data from Spotify server");
    }
  }

  final log = Logger("widget.removed_track._LikedSongPlaylistQuerier");
}

class _UserPlaylistQuerier extends _PlaylistQuerier {
  _UserPlaylistQuerier(this._playlist);

  @override
  query(offset) async {
    log.info(
        "[query] Query new data from playlist ${_playlist.name} (offset: $offset)");
    try {
      final response = await ApiAuther.inst()
          .run((api) => api.playlists(_playlist.meta["id"]).tracks().get(
                limit: 50,
                offset: offset,
                market: "from_token",
              ));
      if (response.statusCode != 200) {
        log.severe("[query] Failed requesting server: $response");
        throw HttpException(
            "Failed querying data from Spotify server: ${response.statusCode}");
      } else {
        return response.body;
      }
    } catch (error) {
      log.severe("[query] Exception requesting server: $error");
      throw HttpException("Failed querying data from Spotify server");
    }
  }

  _UserPlaylist _playlist;

  final log = Logger("widget.removed_track._UserPlaylistQuerier");
}

abstract class _TrackDeleter {
  void push(_Track track);

  void pushAll(Iterator<_Track> it) {
    while (it.moveNext()) {
      push(it.current);
    }
  }

  Future<Response> delete();
}

class _LikedSongTrackDeleter extends _TrackDeleter {
  @override
  push(track) {
    if (track is! _LikedSongTrack) {
      throw UnsupportedError("track is not of _LikedSongTrack type");
    }
    _tracks.add(track);
  }

  @override
  delete() async {
    final ids = _tracks.map((t) => t.meta["id"]).toList().cast<String>();
    log.info("[delete] Remove track(s) (ids: ${ids.join(", ")})");
    return ApiAuther.inst().run((api) => api.me().tracks().delete(
          ids: ids,
        ));
  }

  final _tracks = <_LikedSongTrack>[];

  final log = Logger("widget.removed_track._LikedSongTrackDeleter");
}

class _UserPlaylistTrackDeleter extends _TrackDeleter {
  _UserPlaylistTrackDeleter(this._playlist);

  @override
  push(track) {
    if (track is! _UserPlaylistTrack) {
      throw UnsupportedError("track is not of _UserPlaylistTrack type");
    }
    if (!_playlist.tracks.contains(track)) {
      throw StateError(
          "track is not contained in the associated playlist ${_playlist.name}");
    }
    _tracks.add(track);
  }

  @override
  delete() async {
    final tracks = _tracks.map((t) => {"uri": t.meta["uri"]}).toList();
    log.info(
        "[delete] Remove track(s) from playlist ${_playlist.name} (uris: ${tracks.map((t) => t["uri"]).join(", ")})");
    return ApiAuther.inst()
        .run((api) => api.playlists(_playlist.meta["id"]).tracks().delete(
              tracks: tracks,
            ));
  }

  _UserPlaylist _playlist;
  final _tracks = <_UserPlaylistTrack>[];

  final log = Logger("widget.removed_track._UserPlaylistTrackDeleter");
}

abstract class _KeyBuilder {
  ValueKey<String> create(_Track track);
}

class _LikedSongKeyBuilder extends _KeyBuilder {
  @override
  // Just some random chars
  create(track) => Key("@@@@@@+${track.meta["id"]}");
}

class _UserKeyBuilder extends _KeyBuilder {
  _UserKeyBuilder(this._playlist);

  @override
  create(track) => Key("${_playlist.meta["id"]}+${track.meta["id"]}");

  _UserPlaylist _playlist;
}

abstract class _Track {
  _Track(this.meta);

  final Map<String, dynamic> meta;
}

class _LikedSongTrack extends _Track {
  _LikedSongTrack(meta) : super(meta);
}

class _UserPlaylistTrack extends _Track {
  _UserPlaylistTrack(meta) : super(meta);
}

class _QueryData {
  _QueryData.empty(this.listIndex);

  _QueryData(this.listIndex, tracks) {
    this.tracks.addAll(tracks);
  }

  int listIndex;
  final tracks = <Map<String, dynamic>>[];
}
