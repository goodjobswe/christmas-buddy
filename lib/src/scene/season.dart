import 'package:flutter/material.dart';

/// The village follows a northern-hemisphere calendar.
enum Season {
  spring('Spring'),
  summer('Summer'),
  autumn('Autumn'),
  winter('Winter');

  const Season(this.label);
  final String label;

  static Season forDate(DateTime date) => switch (date.month) {
    3 || 4 || 5 => spring,
    6 || 7 || 8 => summer,
    9 || 10 || 11 => autumn,
    _ => winter,
  };

  List<Color> get sky => switch (this) {
    spring => const [Color(0xFF171A39), Color(0xFF4B537B), Color(0xFFB28B9A)],
    summer => const [Color(0xFF102C46), Color(0xFF3D6F88), Color(0xFFF0BB86)],
    autumn => const [Color(0xFF231831), Color(0xFF69465C), Color(0xFFC88559)],
    winter => const [Color(0xFF070D26), Color(0xFF141F4A), Color(0xFF2E4078)],
  };
  Color get ground => switch (this) {
    spring => const Color(0xFF8DB67D),
    summer => const Color(0xFF729B63),
    autumn => const Color(0xFFB19762),
    winter => const Color(0xFFE6EDF8),
  };
  Color get groundShade => switch (this) {
    spring => const Color(0xFF729868),
    summer => const Color(0xFF567E50),
    autumn => const Color(0xFF91754E),
    winter => const Color(0xFFCBD8EC),
  };
  Color get groundHighlight => switch (this) {
    spring => const Color(0xFFA6C995),
    summer => const Color(0xFF91B57A),
    autumn => const Color(0xFFC4AA74),
    winter => const Color(0xFFF7FAFF),
  };
  Color get farMountain => switch (this) {
    spring => const Color(0xFF78849A),
    summer => const Color(0xFF718E99),
    autumn => const Color(0xFF9C7D86),
    winter => const Color(0xFF3E5088),
  };
  Color get nearMountain => switch (this) {
    spring => const Color(0xFF506F72),
    summer => const Color(0xFF496F73),
    autumn => const Color(0xFF705F68),
    winter => const Color(0xFF2C3D70),
  };
  Color get accent => switch (this) {
    spring => const Color(0xFFF4B8D0),
    summer => const Color(0xFFFFDA7A),
    autumn => const Color(0xFFDA853D),
    winter => Colors.white,
  };
}
