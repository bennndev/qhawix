import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// Circular avatar showing the initials of [name] (at most two letters).
/// Decorative: the person's name is always written next to it, so it is
/// excluded from the semantics tree.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name});

  final String name;

  /// First letter of the first two words, upper case; empty names give "?".
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w.characters.first.toUpperCase());
    final text = letters.join();
    return text.isEmpty ? '?' : text;
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: space.iconXl,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.accentTint,
            shape: const CircleBorder(),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                initialsOf(name),
                style: context.text.labelLarge?.copyWith(
                  color: colors.accentDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
