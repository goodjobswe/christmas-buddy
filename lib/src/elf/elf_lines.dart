import 'dart:math';

import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/season.dart';

/// What Pip the elf says on the home screen. All lines are original.
/// `{sleeps}` is replaced with the number of sleeps left.
class ElfLines {
  static const name = 'Pip';

  static const List<String> _lines = [
    'Only {sleeps} sleeps to go. I have already packed my mittens.',
    'I am hiding somewhere new today. Warmer, warmer, colder, no, warmer!',
    'Snow tastes best straight from the sky. Do not tell the reindeer.',
    'I counted the stars last night and lost track at forty-two.',
    'The tree gets one more bauble every day. I am in charge of the wonky ones.',
    'Cocoa first, then presents. Those are the rules of the North Pole.',
    'If you see a mitten on the roof, it is mine. I was practising jumps.',
    'The snowman winked at me. I am fairly sure he winked at me.',
    'My hat has a bell so Santa can find me. It has never once worked.',
    'Every window in the village is glowing. That is my favourite time of day.',
    'I wrapped a present so well that I forgot what was inside.',
    'Careful where you step. Some of these snowflakes are my friends.',
    'I tried to sing to the reindeer. They asked for a different elf.',
    '{sleeps} sleeps left and my list still says "find the good scissors".',
    'The lamp post is warm if you hug it. Not that I have tried.',
    'I wrote your name on the nice list in my best handwriting.',
    'Sleighs are just sledges that went to a good school.',
    'Somewhere out there a gingerbread man is thinking about you.',
    'I hid so well yesterday that even I could not find me.',
    'The moon is up early tonight. It wants to see the tree too.',
    'You found the app. Now find the elf. I believe in you.',
    'The chimney smoke is doing loops today. That means good news.',
    'If it snows on your nose, make a wish. I made three.',
    'I polished the star myself. Well, I polished most of it.',
    'Reindeer cannot whistle. I have tested this extensively.',
    'Do not worry about the naughty list. It is mostly blank this year.',
    '{sleeps} more sleeps. That is {sleeps} more bedtime stories.',
    'The snow got deeper overnight. My boots are very pleased.',
    'Santa says patience is a gift. I say so is a bicycle.',
    'I keep a spare candy cane behind my ear for emergencies.',
    'When the last bauble is up, keep an eye on the top of the tree.',
    'I once raced a snowflake to the ground. It cheated.',
    'Pssst. Tap around. I might be closer than you think.',
    'A good elf never reveals a hiding spot. A great elf giggles a bit.',
    'The village bakery is open. I can smell it from up here.',
    'Merry almost Christmas from me and my slightly bent hat.',
    'The kids in the village keep waving at me. It is very hard to stay hidden.',
    'Those two in the beanies are not me. Nice try though.',
    'The church bell rings at six. I know because it rang right in my ear.',
    'Someone left a letter in the postbox for Santa. I did not read it. Much.',
    'The woodpile is warmer than it looks. Ask me how I know.',
    'That signpost says North Pole is that way. It is wrong, but it is trying.',
    'I saw a shooting star. I wished for a bigger hat.',
    'When the sky goes green and purple, that is the elves painting up north.',
    'The reindeer came down to the village to look at the tree. Do not tell Santa.',
    'A bird sat on my hat for ten minutes. I did not move. Champion hider.',
    'The bench by the lamp is the best seat in the village. Also the coldest.',
    'If you hear giggling, it is not the snow.',
    'The house with the blue walls makes the best cocoa. I have compared.',
    'I dusted every roof with snow this morning. You are welcome.',
    'Careful near the fence. The red bird bites. Well, pecks. Firmly.',
    'The mountains look small from here. They are not small. I checked.',
    'I hid in the tree once and came out smelling of pine for a week.',
    'Every present under the tree has been shaken. For science.',
    'There is a spot in the village that nobody has ever found me in. Not saying where.',
    'I keep a snowball in my pocket in case of emergencies. It has never been an emergency.',
  ];

  static const List<String> christmasLines = [
    'It is Christmas! I am coming out of hiding for cocoa.',
    'Merry Christmas! The star is up and so am I, far too early.',
    'Santa made it. I helped. Mostly with the cookies.',
    'Merry Christmas! Give someone a hug from Pip.',
    'Did you see the sleigh cross the moon? I waved. I am sure he saw.',
  ];

  /// Lines Pip says when found, picked at random.
  static const List<String> foundLines = [
    'You found me! I was so quiet, too.',
    'Aha, sharp eyes! Same time tomorrow?',
    'Found already? I need better hiding spots.',
    'Hooray! That deserves a jingle.',
    'You got me! I was admiring the view.',
    'Well spotted! Did someone give me away?',
  ];

  static const List<String> _popUpLines = [
    'Peekaboo! Was it the hat sticking out?',
    'Cosy in here, and you still spotted me.',
    'I was tucked in so well. You are good at this.',
    'A bit sooty, but very happy to see you!',
  ];

  static const List<String> _peekOutLines = [
    'Boo! I was right behind that the whole time.',
    'A fine hiding place, spoiled by a fine finder.',
    'You saw my boots, did you not? It is always the boots.',
  ];

  static const List<String> _tumbleLines = [
    'Whoa, steady! You made me wobble.',
    'Careful, it is slippery up here!',
    'I nearly slid off. Worth it for the view.',
  ];

  static const List<String> _jumpLines = [
    'Yes! Found me! Time for a victory jump.',
    'The view is great up here. Even better with company.',
    'You found me, so I get to jump. Elf rules.',
  ];

  /// Shown when the elf is tapped again after being found today.
  static const List<String> againLines = [
    'Still here! Come back tomorrow for a new spot.',
    'Yes, yes, it is me. Hello again!',
    'You already found me today. Showing off, are we?',
  ];

  static const warmer = 'Warmer...';
  static const colder = 'Colder...';
  static const hot = 'Very warm!';
  static const cold = 'Freezing cold.';

  static String pick(
    Random random, {
    required int sleeps,
    required bool isChristmas,
    Season season = Season.winter,
  }) {
    final seasonal = switch (season) {
      Season.spring => const [
        'The flowers are waking up. I have been awake for ages. Mostly.',
        'A blossom landed on my hat. I am calling it a disguise.',
        'Spring is here, but I am still counting. {sleeps} sleeps to go!',
        'I planted a jelly bean. Still waiting for the jelly bean tree.',
        'The birds are helping me hide. Their singing is a distraction.',
      ],
      Season.summer => const [
        'I counted the fireflies. Then they moved. Starting again.',
        'Even elves take summer holidays. Mine includes hiding.',
        'Ice cream now, Christmas later. {sleeps} sleeps later, to be exact.',
        'The flowers are taller than my boots. Excellent hiding weather.',
        'Santa is wearing sandals today. Please do not tell anyone.',
      ],
      Season.autumn => const [
        'I tried to catch every falling leaf. I may need a bigger hat.',
        'The pumpkins are keeping my hiding spot a secret.',
        'Crunchy leaves, cosy evenings, and {sleeps} sleeps until Christmas.',
        'I found an acorn in my pocket. The squirrels are investigating.',
        'The village is wearing its autumn colours. I kept my green hat.',
      ],
      Season.winter => _lines,
    };
    final list = isChristmas ? christmasLines : seasonal;
    final line = list[random.nextInt(list.length)];
    return line.replaceAll('{sleeps}', '$sleeps');
  }

  static String pickFound(Random random) =>
      foundLines[random.nextInt(foundLines.length)];

  /// A found line that fits how Pip reacts in his spot.
  static String foundLineFor(ElfReaction reaction, Random random) {
    final list = switch (reaction) {
      ElfReaction.wave => foundLines,
      ElfReaction.popUp => _popUpLines,
      ElfReaction.peekOut => _peekOutLines,
      ElfReaction.tumble => _tumbleLines,
      ElfReaction.jump => _jumpLines,
    };
    return list[random.nextInt(list.length)];
  }

  static String pickAgain(Random random) =>
      againLines[random.nextInt(againLines.length)];
}
