// Renders the scene, the home screen and the app icons to PNG files so they
// can be looked at without a device. Skipped unless RENDER_OUT is set:
//
//   RENDER_OUT=C:\some\folder flutter test test/tools/render_test.dart
//
// With RENDER_ICONS=1 as well, the icon and splash images are written into
// assets/icon/, ready for `dart run flutter_launcher_icons` and
// `dart run flutter_native_splash:create`.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:christmas_buddy/main.dart';
import 'package:christmas_buddy/src/audio/audio_controller.dart';
import 'package:christmas_buddy/src/elf/elf_painter.dart';
import 'package:christmas_buddy/src/scene/christmas_scene.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';
import 'package:christmas_buddy/src/theme.dart';

final _out = Platform.environment['RENDER_OUT'];
final _icons = Platform.environment['RENDER_ICONS'] == '1';

Future<void> _loadFonts() async {
  for (final (family, file) in [
    ('Rochester', 'assets/fonts/Rochester-Regular.ttf'),
    ('OpenSans', 'assets/fonts/OpenSans-Regular.ttf'),
  ]) {
    final loader = FontLoader(family)..addFont(rootBundle.load(file));
    await loader.load();
  }
}

Future<void> _save(WidgetTester tester, GlobalKey key, String path, {double pixelRatio = 1}) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render scenes and home screen', (tester) async {
    final out = _out!;
    Directory(out).createSync(recursive: true);
    await _loadFonts();

    final cases = [
      ('scene_phone_day0', const Size(411, 890), 0, 12),
      ('scene_phone_day5', const Size(411, 890), 5, 4),
      ('scene_phone_day12', const Size(411, 890), 12, 11),
      ('scene_phone_day24', const Size(411, 890), 24, 23),
      ('scene_small_day18', const Size(360, 640), 18, 17),
      ('scene_tablet_day20', const Size(800, 1280), 20, 19),
    ];
    for (final (name, size, day, spot) in cases) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: ChristmasScene(day: day, elfSpotIndex: spot, showElf: true, flakeCount: 0, animate: false),
          ),
        ),
      );
      await tester.pump();
      await _save(tester, key, '$out/$name.png');
    }

    // Every hiding spot on one sheet, so they can be checked at a glance.
    for (var i = 0; i < 24; i++) {
      final key = GlobalKey();
      const size = Size(411, 890);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: ChristmasScene(day: i + 1, elfSpotIndex: i, showElf: true, flakeCount: 0, animate: false),
          ),
        ),
      );
      await tester.pump();
      await _save(tester, key, '$out/spot_${i.toString().padLeft(2, '0')}.png');
    }

    // The full home screen with fonts, snow and the overlay.
    SharedPreferences.setMockInitialValues({'christmas_day': 24});
    final settings = await AppSettings.load(countryCode: 'SE');
    final lists = SantaListStore(await SharedPreferences.getInstance());
    const size = Size(411, 890);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    await tester.pumpWidget(ChristmasBuddyApp(settings: settings, lists: lists, audio: AudioController(enabled: false)));
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final home = find.byType(RepaintBoundary).first;
    await tester.runAsync(() async {
      final boundary = tester.renderObject(home) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/home.png').writeAsBytesSync(data!.buffer.asUint8List());
    });

    // Other screens.
    for (final (route, name) in [('/list', 'list'), ('/calendar', 'calendar'), ('/settings', 'settings'), ('/about', 'about')]) {
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final boundary = tester.renderObject(find.byType(RepaintBoundary).first) as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
      navigator.pop();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  }, skip: _out == null);

  testWidgets('render app icons', (tester) async {
    const size = Size(1024, 1024);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    Directory('assets/icon').createSync(recursive: true);

    for (final (name, painter) in [
      ('icon', const AppIconPainter(mode: AppIconMode.full)),
      ('icon_foreground', const AppIconPainter(mode: AppIconMode.foreground)),
      ('splash', const AppIconPainter(mode: AppIconMode.splash)),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: CustomPaint(size: size, painter: painter)));
      await tester.pump();
      await _save(tester, key, 'assets/icon/$name.png');
      if (_out != null) await _save(tester, key, '$_out/$name.png');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  }, skip: !_icons);
}

enum AppIconMode { full, foreground, splash }

/// Pip peeking over a snow bank. The same drawing feeds the iOS icon, the
/// Android adaptive foreground and the splash image.
class AppIconPainter extends CustomPainter {
  const AppIconPainter({required this.mode});

  final AppIconMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (mode == AppIconMode.splash) {
      const painter = ElfPainter(pose: ElfPose.wave, t: 0.2);
      final height = s * 0.72;
      final width = height / ElfPainter.aspect;
      painter.paintInto(canvas, Rect.fromLTWH((s - width) / 2, (s - height) / 2, width, height));
      return;
    }

    if (mode == AppIconMode.full) {
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1437), nightBlue, Color(0xFF243B78)],
          ).createShader(rect),
      );
      final random = math.Random(7);
      final star = Paint();
      for (var i = 0; i < 60; i++) {
        star.color = Colors.white.withValues(alpha: 0.35 + random.nextDouble() * 0.6);
        canvas.drawCircle(
          Offset(random.nextDouble() * s, random.nextDouble() * s * 0.75),
          s * (0.003 + random.nextDouble() * 0.006),
          star,
        );
      }
    }

    // A gold star as an accent, inside the adaptive safe zone.
    final starCenter = Offset(s * 0.27, s * 0.26);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? s * 0.07 : s * 0.03;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = starCenter + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawCircle(
      starCenter,
      s * 0.14,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xAAFFD75E), const Color(0x00FFD75E)],
        ).createShader(Rect.fromCircle(center: starCenter, radius: s * 0.14)),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD75E));

    // Pip, cropped by the snow bank in front of him.
    final scale = mode == AppIconMode.full ? 0.62 : 0.52;
    final width = s * scale;
    final height = width * ElfPainter.aspect;
    const headFraction = 58 / 160;
    final top = s * 0.5 - headFraction * height;
    const ElfPainter(pose: ElfPose.idle).paintInto(canvas, Rect.fromLTWH((s - width) / 2, top, width, height));

    final bankTop = mode == AppIconMode.full ? s * 0.80 : s * 0.76;
    final bank = Paint()..color = const Color(0xFFF2F6FD);
    canvas.drawCircle(Offset(s * 0.5, bankTop + s * 0.62), s * 0.66, bank);
    canvas.drawCircle(Offset(s * 0.12, bankTop + s * 0.30), s * 0.30, bank);
    canvas.drawCircle(Offset(s * 0.90, bankTop + s * 0.34), s * 0.34, bank);
  }

  @override
  bool shouldRepaint(AppIconPainter old) => old.mode != mode;
}
