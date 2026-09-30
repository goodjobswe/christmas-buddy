/// The app's idea of "now".
///
/// For screenshots and manual testing a fake start date can be baked into a
/// build, after which the clock keeps running from that moment:
///
///   flutter run --dart-define=FAKE_DATE=2026-12-20T18:30:00
///
/// Release builds made without the define use the real clock.
const _fakeDate = String.fromEnvironment('FAKE_DATE');
final DateTime? _fakeStart = _fakeDate.isEmpty ? null : DateTime.tryParse(_fakeDate);
final DateTime _realStart = DateTime.now();

DateTime appNow() {
  final fake = _fakeStart;
  if (fake == null) return DateTime.now();
  return fake.add(DateTime.now().difference(_realStart));
}
