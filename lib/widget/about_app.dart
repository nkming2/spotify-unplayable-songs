import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutApp extends StatefulWidget {
  static const routeName = "/about";

  AboutApp({Key key}) : super(key: key);

  static const String title = "About App";

  @override
  createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> {
  @override
  initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  build(context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AboutApp.title)),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) => _buildContent(context, snapshot),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
    if (!snapshot.hasData) {
      return Container();
    }

    return ListView(children: [
      ListTile(
        title: Text("Version"),
        subtitle: Text(snapshot.data.version),
      ),
      ListTile(
        title: Text("Source code"),
        subtitle: Text(_sourceRepo),
        onTap: () async {
          await launch(_sourceRepo);
        },
      ),
    ]);
  }

  static const String _sourceRepo = "https://gitlab.com/nkming2/spotify-unplayable-songs";

  Future<PackageInfo> _packageInfo;

  final log = Logger("widget.about_app._AboutAppState");
}
