import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the widget under [boundaryKey] to a PNG and opens the share
/// sheet. No storage permission is needed this way.
Future<bool> shareScene(GlobalKey boundaryKey, {required String text}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return false;
  final image = await boundary.toImage(pixelRatio: 2);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) return false;
  final file = XFile.fromData(
    data.buffer.asUint8List(),
    mimeType: 'image/png',
    name: 'christmas_buddy.png',
  );
  final result = await SharePlus.instance.share(
    ShareParams(text: text, files: [file]),
  );
  return result.status != ShareResultStatus.unavailable;
}
