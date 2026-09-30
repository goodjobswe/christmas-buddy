import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:christmas_buddy/src/elf/elf_painter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final website = Uri.parse('https://goodjob.nu');
  static final source = Uri.parse('https://github.com/goodjobswe/christmas-buddy');

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $uri')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade900);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Center(child: AnimatedElf(height: 130, pose: ElfPose.wave)),
          const SizedBox(height: 8),
          const Text(
            'Christmas Buddy',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Rochester', fontSize: 42, color: ElfColors.red),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => Text(
              snapshot.hasData ? 'Version ${snapshot.data!.version}' : '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Count the sleeps until Christmas with Pip the elf in a cosy '
            'village that changes with the seasons. Find his new hiding spot each day, watch the tree fill '
            'with decorations through December, and keep track of Santa\'s list.',
            style: body,
          ),
          const SizedBox(height: 16),
          const _Heading('How to play'),
          _Bullet('Find Pip. He hides somewhere new every day, all year round. Tap around and watch for warmer and colder.', body),
          _Bullet('In December each find counts on the advent calendar. On the 24th he waits by the star.', body),
          _Bullet('Keep Santa\'s nice and naughty lists up to date, and tick off the presents as they are sorted.', body),
          _Bullet('Choose a season in Settings, or let the village follow the year automatically.', body),
          _Bullet('In winter, blow the snow sideways with a finger, and turn on a daily reminder so you never lose count.', body),
          const SizedBox(height: 16),
          const _Heading('Credits'),
          Text('Made by goodjob.', style: body),
          const SizedBox(height: 8),
          Text(
            'Fonts: Open Sans and Rochester, from Google Fonts under their open '
            'licences. The carols are traditional melodies in the public domain.',
            style: body,
          ),
          const SizedBox(height: 8),
          Text('The source code is open under the MIT licence.', style: body),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => _open(context, website),
                child: const Text('goodjob.nu'),
              ),
              OutlinedButton.icon(
                onPressed: () => _open(context, source),
                icon: const Icon(Icons.code),
                label: const Text('Source code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Rochester', fontSize: 28, color: ElfColors.red),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
