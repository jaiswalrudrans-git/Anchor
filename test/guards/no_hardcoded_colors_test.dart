import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zero Hardcoded Colors & Theme Leaks Guard', () {
    test('All lib/ Dart files (except theme.dart) contain zero hardcoded colors', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final violations = <String>[];

      // Regex patterns
      final colorHexRegex = RegExp(r'Color\(0x[0-9a-fA-F]+\)');
      final colorFromARGBRegex = RegExp(r'Color\.fromARGB\(');
      final colorRGBORegex = RegExp(r'Color\.fromRGBO\(');
      // Colors.<name> except Colors.transparent
      final colorsEnumRegex = RegExp(r'\bColors\.(?!transparent\b)[a-zA-Z]+');
      final appColorsRegex = RegExp(r'\bAppColors\.[a-zA-Z]+');
      final brightnessRegex = RegExp(r'\bBrightness\.(light|dark)\b');
      final themeDataLightDarkRegex = RegExp(r'\bThemeData\.(light|dark)\(');

      for (final file in libDir.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;

        // Skip theme.dart where palette tokens are defined
        final normalizedPath = file.path.replaceAll(r'\', '/');
        if (normalizedPath.endsWith('lib/core/constants/theme.dart')) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNum = i + 1;

          // Skip comments
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
            continue;
          }

          // 1. Color(0x...)
          if (colorHexRegex.hasMatch(line)) {
            violations.add('$normalizedPath:$lineNum - Hardcoded Color(0x...): $trimmed');
          }

          // 2. Color.fromARGB(...)
          if (colorFromARGBRegex.hasMatch(line)) {
            violations.add('$normalizedPath:$lineNum - Hardcoded Color.fromARGB: $trimmed');
          }

          // 3. Color.fromRGBO(...)
          if (colorRGBORegex.hasMatch(line)) {
            violations.add('$normalizedPath:$lineNum - Hardcoded Color.fromRGBO: $trimmed');
          }

          // 4. Colors.<name> except transparent
          final colorsMatch = colorsEnumRegex.firstMatch(line);
          if (colorsMatch != null) {
            violations.add('$normalizedPath:$lineNum - Hardcoded Material color (${colorsMatch.group(0)}): $trimmed');
          }

          // 5. AppColors.<token> (deprecated legacy color palette)
          final appColorsMatch = appColorsRegex.firstMatch(line);
          if (appColorsMatch != null) {
            violations.add('$normalizedPath:$lineNum - Legacy AppColors token (${appColorsMatch.group(0)}): $trimmed');
          }

          // 6. Brightness.light / Brightness.dark (only permitted in main.dart at MaterialApp root)
          if (!normalizedPath.endsWith('lib/main.dart')) {
            final brightnessMatch = brightnessRegex.firstMatch(line);
            if (brightnessMatch != null) {
              violations.add('$normalizedPath:$lineNum - Brightness check outside theme.dart (${brightnessMatch.group(0)}): $trimmed');
            }
          }

          // 7. ThemeData.light / ThemeData.dark
          final themeDataMatch = themeDataLightDarkRegex.firstMatch(line);
          if (themeDataMatch != null) {
            violations.add('$normalizedPath:$lineNum - Hardcoded ThemeData constructor (${themeDataMatch.group(0)}): $trimmed');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} hardcoded color/theme violations outside theme.dart:\n\n${violations.join('\n')}',
        );
      }
    });
  });
}
