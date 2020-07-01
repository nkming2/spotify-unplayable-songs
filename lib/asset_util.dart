import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AssetUtil {
  static String listPlaceholder(BuildContext context) {
    return "themed_assets/${Theme.of(context).brightness == Brightness.light ? 'light' : 'dark'}/list_placeholder.png";
  }
}
