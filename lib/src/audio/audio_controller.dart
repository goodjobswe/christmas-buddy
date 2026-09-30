import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// The short sounds the app plays.
enum Sfx {
  jingle('sfx_jingle.mp3'),
  chime('sfx_chime.mp3'),
  wave('sfx_wave.mp3'),
  puff('sfx_puff.mp3');

  const Sfx(this.file);
  final String file;
}

/// Plays the carol playlist in a shuffled loop and the sound effects.
/// Music pauses while the app is in the background. With [enabled] false
/// (widget tests) nothing touches the platform.
class AudioController with WidgetsBindingObserver {
  AudioController({this.enabled = true}) {
    if (!enabled) return;
    WidgetsBinding.instance.addObserver(this);
    final music = _music = AudioPlayer(playerId: 'music');
    final sfx = _sfx = AudioPlayer(playerId: 'sfx');
    music.setReleaseMode(ReleaseMode.stop);
    music.setPlayerMode(PlayerMode.mediaPlayer);
    music.setVolume(0.55);
    music.setAudioContext(_context(AndroidContentType.music));
    music.onPlayerComplete.listen((_) => _playNext());
    sfx.setPlayerMode(PlayerMode.lowLatency);
    sfx.setAudioContext(_context(AndroidContentType.sonification));
  }

  static const tracks = [
    'music_jingle_bells.mp3',
    'music_we_wish_you.mp3',
    'music_deck_the_halls.mp3',
    'music_silent_night.mp3',
    'music_o_christmas_tree.mp3',
    'music_good_king_wenceslas.mp3',
  ];

  static AudioContext _context(AndroidContentType type) {
    return AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: type,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      // Ambient already mixes with other apps and respects the mute switch.
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const {},
      ),
    );
  }

  final bool enabled;
  AudioPlayer? _music;
  AudioPlayer? _sfx;
  final _random = math.Random();
  final List<String> _order = [];
  int _index = -1;
  bool _musicOn = false;
  bool _soundOn = true;
  bool _inBackground = false;

  bool get musicOn => _musicOn;

  Future<void> setMusicOn(bool on) async {
    if (_musicOn == on) return;
    _musicOn = on;
    final music = _music;
    if (music == null) return;
    if (on) {
      if (music.state == PlayerState.paused) {
        await music.resume();
      } else {
        await _playNext();
      }
    } else {
      await music.pause();
    }
  }

  // ignore: avoid_setters_without_getters
  set soundOn(bool on) => _soundOn = on;

  Future<void> _playNext() async {
    final music = _music;
    if (music == null || !_musicOn || _inBackground) return;
    if (_order.isEmpty || _index >= _order.length - 1) {
      final last = _order.isEmpty ? null : _order.last;
      _order
        ..clear()
        ..addAll(tracks)
        ..shuffle(_random);
      // Do not play the same carol twice in a row across shuffles.
      if (_order.length > 1 && _order.first == last) {
        _order.add(_order.removeAt(0));
      }
      _index = -1;
    }
    _index++;
    await music.play(AssetSource('audio/${_order[_index]}'));
  }

  /// Skips to the next carol, if music is on.
  Future<void> next() async {
    final music = _music;
    if (music == null || !_musicOn) return;
    await music.stop();
    await _playNext();
  }

  Future<void> play(Sfx sfx) async {
    final player = _sfx;
    if (player == null || !_soundOn) return;
    await player.stop();
    await player.play(AssetSource('audio/${sfx.file}'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final music = _music;
    if (music == null) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _inBackground = true;
        if (_musicOn) music.pause();
      case AppLifecycleState.resumed:
        _inBackground = false;
        if (_musicOn) {
          if (music.state == PlayerState.paused) {
            music.resume();
          } else {
            _playNext();
          }
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void dispose() {
    if (!enabled) return;
    WidgetsBinding.instance.removeObserver(this);
    _music?.dispose();
    _sfx?.dispose();
  }
}
