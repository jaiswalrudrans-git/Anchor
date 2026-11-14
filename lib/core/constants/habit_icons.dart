import 'package:flutter/material.dart';

/// Fixed catalog of 24 curated habit icons and lookup helper.
class HabitIcons {
  HabitIcons._();

  static const String defaultKey = 'check_circle';

  static const Map<String, IconData> catalog = {
    'check_circle': Icons.check_circle,
    'fitness_center': Icons.fitness_center,
    'menu_book': Icons.menu_book,
    'water_drop': Icons.water_drop,
    'self_improvement': Icons.self_improvement,
    'code': Icons.code,
    'bedtime': Icons.bedtime,
    'directions_run': Icons.directions_run,
    'restaurant': Icons.restaurant,
    'school': Icons.school,
    'edit_note': Icons.edit_note,
    'savings': Icons.savings,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'language': Icons.language,
    'spa': Icons.spa,
    'directions_bike': Icons.directions_bike,
    'wb_sunny': Icons.wb_sunny,
    'no_food': Icons.no_food,
    'phone_disabled': Icons.phone_disabled,
    'timer': Icons.timer,
    'favorite': Icons.favorite,
    'psychology': Icons.psychology,
    'cleaning_services': Icons.cleaning_services,
  };

  /// Returns the corresponding [IconData] or falls back to [Icons.check_circle].
  static IconData getIcon(String? key) {
    if (key == null) return catalog[defaultKey]!;
    return catalog[key] ?? catalog[defaultKey]!;
  }

  /// List of all 24 icon keys in display order.
  static List<String> get allKeys => catalog.keys.toList();
}
