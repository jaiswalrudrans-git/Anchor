import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/utils/streak_utils.dart';

void main() {
  group('StreakUtils - currentStreak', () {
    final today = DateTime(2026, 11, 14); // Friday/Saturday in Nov 2026
    final yesterday = DateTime(2026, 11, 13);
    final dayBeforeYesterday = DateTime(2026, 11, 12);

    test('returns 0 when no logs exist', () {
      expect(StreakUtils.currentStreak({}, today), 0);
    });

    test('returns 1 when only today is logged', () {
      final logged = {today};
      expect(StreakUtils.currentStreak(logged, today), 1);
    });

    test('returns 2 when today and yesterday are logged', () {
      final logged = {today, yesterday};
      expect(StreakUtils.currentStreak(logged, today), 2);
    });

    test('returns consecutive streak ending yesterday when today is NOT logged', () {
      // An unlogged today does not zero the streak until the day is over
      final logged = {
        yesterday,
        dayBeforeYesterday,
        DateTime(2026, 11, 11),
      };
      expect(StreakUtils.currentStreak(logged, today), 3);
    });

    test('returns 0 when neither today nor yesterday is logged (streak broken)', () {
      final logged = {
        dayBeforeYesterday,
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 10),
      };
      expect(StreakUtils.currentStreak(logged, today), 0);
    });

    test('stops counting at a gap', () {
      final logged = {
        today,
        yesterday,
        // Gap on Nov 12
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 10),
      };
      expect(StreakUtils.currentStreak(logged, today), 2);
    });

    test('calculates long streak across month boundary', () {
      // Oct 20 to Nov 14 (inclusive) = 12 days in Oct (20..31) + 14 days in Nov (1..14) = 26 days
      final logged = <DateTime>{};
      for (int day = 20; day <= 31; day++) {
        logged.add(DateTime(2026, 10, day));
      }
      for (int day = 1; day <= 14; day++) {
        logged.add(DateTime(2026, 11, day));
      }

      expect(StreakUtils.currentStreak(logged, today), 26);
    });

    test('calculates long streak across month boundary ending yesterday', () {
      // Oct 25 to Nov 13 (inclusive) = 7 days in Oct (25..31) + 13 days in Nov (1..13) = 20 days
      final logged = <DateTime>{};
      for (int day = 25; day <= 31; day++) {
        logged.add(DateTime(2026, 10, day));
      }
      for (int day = 1; day <= 13; day++) {
        logged.add(DateTime(2026, 11, day));
      }

      expect(StreakUtils.currentStreak(logged, today), 20);
    });

    test('handles DateTime with non-zero time components cleanly', () {
      final logged = {
        DateTime(2026, 11, 14, 18, 45),
        DateTime(2026, 11, 13, 9, 15),
      };
      expect(StreakUtils.currentStreak(logged, DateTime(2026, 11, 14, 23, 59)), 2);
    });
  });

  group('StreakUtils - missedDays', () {
    final start = DateTime(2026, 11, 1);
    final end = DateTime(2026, 11, 30);

    test('created on first day of month with no logs counts all 30 days as missed', () {
      final created = DateTime(2026, 11, 1);
      final missed = StreakUtils.missedDays(
        logged: {},
        start: start,
        end: end,
        createdDate: created,
      );
      expect(missed, 30);
    });

    test('created mid-month counts only days from creation date', () {
      final created = DateTime(2026, 11, 15);
      // Days from Nov 15 through Nov 30 = 16 days
      final missed = StreakUtils.missedDays(
        logged: {},
        start: start,
        end: end,
        createdDate: created,
      );
      expect(missed, 16);
    });

    test('all logged days in range yields 0 missed days', () {
      final created = DateTime(2026, 11, 1);
      final logged = List.generate(30, (i) => DateTime(2026, 11, i + 1)).toSet();

      final missed = StreakUtils.missedDays(
        logged: logged,
        start: start,
        end: end,
        createdDate: created,
      );
      expect(missed, 0);
    });

    test('alternating pattern correctly counts unlogged days', () {
      final created = DateTime(2026, 11, 1);
      // Log even days: 2, 4, 6... 30 (15 logged, 15 missed)
      final logged = List.generate(15, (i) => DateTime(2026, 11, (i + 1) * 2)).toSet();

      final missed = StreakUtils.missedDays(
        logged: logged,
        start: start,
        end: end,
        createdDate: created,
      );
      expect(missed, 15);
    });

    test('returns 0 if start and end are strictly before creation date', () {
      final created = DateTime(2026, 11, 15);
      final missed = StreakUtils.missedDays(
        logged: {},
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 10),
        createdDate: created,
      );
      expect(missed, 0);
    });
  });

  group('StreakUtils - rebounds', () {
    test('alternating pattern produces rebounds for every logged day after missed day', () {
      final created = DateTime(2026, 11, 1);
      // Day 1: missed
      // Day 2: logged -> rebound 1
      // Day 3: missed
      // Day 4: logged -> rebound 2
      // Day 5: missed
      // Day 6: logged -> rebound 3
      final logged = {
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 6),
      };

      final r = StreakUtils.rebounds(
        logged: logged,
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 10),
        createdDate: created,
      );
      expect(r, 3);
    });

    test('returns 0 rebounds when all days are logged', () {
      final created = DateTime(2026, 11, 1);
      final logged = List.generate(10, (i) => DateTime(2026, 11, i + 1)).toSet();

      final r = StreakUtils.rebounds(
        logged: logged,
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 10),
        createdDate: created,
      );
      expect(r, 0);
    });

    test('returns 0 rebounds when no days are logged', () {
      final created = DateTime(2026, 11, 1);
      final r = StreakUtils.rebounds(
        logged: {},
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 10),
        createdDate: created,
      );
      expect(r, 0);
    });

    test('does not count rebound if previous day is before creation date', () {
      // Created on Nov 10. Nov 9 was before creation. Nov 10 logged.
      // D-1 was not part of the habit lifecycle, so Nov 10 is NOT a rebound.
      final created = DateTime(2026, 11, 10);
      final logged = {
        DateTime(2026, 11, 10), // Not a rebound
        DateTime(2026, 11, 12), // Nov 11 was missed, Nov 12 logged -> Rebound!
      };

      final r = StreakUtils.rebounds(
        logged: logged,
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 15),
        createdDate: created,
      );
      expect(r, 1);
    });
  });

  group('StreakUtils - weekStats', () {
    final monday = DateTime(2026, 11, 9); // Monday of week Nov 9 - Nov 15
    final created = DateTime(2026, 11, 1);

    test('partial current week (e.g. today is Thursday Nov 12)', () {
      final today = DateTime(2026, 11, 12); // Thursday
      // Mon (9) logged, Tue (10) missed, Wed (11) logged, Thu (12) logged
      final logged = {
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 12),
      };

      final stats = StreakUtils.weekStats(
        logged: logged,
        weekStart: monday,
        today: today,
        createdDate: created,
      );

      expect(stats.eligibleDays, 4); // Mon, Tue, Wed, Thu
      expect(stats.completions, 3);
      expect(stats.missed, 1);
      expect(stats.rebounds, 1); // Nov 11 after Nov 10 miss
      expect(stats.percentage, 75.0);
    });

    test('past full week counts all 7 days as eligible', () {
      final today = DateTime(2026, 11, 20); // Week is in the past
      final logged = {
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 12),
        DateTime(2026, 11, 13),
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 15),
      };

      final stats = StreakUtils.weekStats(
        logged: logged,
        weekStart: monday,
        today: today,
        createdDate: created,
      );

      expect(stats.eligibleDays, 7);
      expect(stats.completions, 7);
      expect(stats.missed, 0);
      expect(stats.rebounds, 0);
      expect(stats.percentage, 100.0);
    });

    test('creation week only counts days on or after creation', () {
      // Created on Wednesday Nov 11. Today is Sunday Nov 15.
      final midWeekCreated = DateTime(2026, 11, 11);
      final today = DateTime(2026, 11, 15);
      // Logged Wed(11), Fri(13), Sat(14)
      final logged = {
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 13),
        DateTime(2026, 11, 14),
      };

      final stats = StreakUtils.weekStats(
        logged: logged,
        weekStart: monday,
        today: today,
        createdDate: midWeekCreated,
      );

      // Eligible: Wed, Thu, Fri, Sat, Sun = 5 days
      expect(stats.eligibleDays, 5);
      expect(stats.completions, 3);
      expect(stats.missed, 2);
      expect(stats.rebounds, 1); // Fri 13 after Thu 12 missed
      expect(stats.percentage, 60.0);
    });

    test('empty week yields 0 completions and 0 percentage', () {
      final today = DateTime(2026, 11, 20);
      final stats = StreakUtils.weekStats(
        logged: {},
        weekStart: monday,
        today: today,
        createdDate: created,
      );

      expect(stats.eligibleDays, 7);
      expect(stats.completions, 0);
      expect(stats.missed, 7);
      expect(stats.percentage, 0.0);
    });

    test('week crossing a month boundary (Oct 26 - Nov 1)', () {
      final octMonday = DateTime(2026, 10, 26);
      final today = DateTime(2026, 11, 1);
      final earlyCreated = DateTime(2026, 10, 1);

      // Logged Oct 26, 27, 28, 29, 30, 31, Nov 1
      final logged = {
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 28),
        DateTime(2026, 10, 29),
        DateTime(2026, 10, 30),
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
      };

      final stats = StreakUtils.weekStats(
        logged: logged,
        weekStart: octMonday,
        today: today,
        createdDate: earlyCreated,
      );

      expect(stats.eligibleDays, 7);
      expect(stats.completions, 7);
      expect(stats.percentage, 100.0);
    });
  });

  group('StreakUtils - monthStats', () {
    test('calculates completions, missed days through yesterday, and rebounds', () {
      final monthStart = DateTime(2026, 11, 1);
      final today = DateTime(2026, 11, 14); // Nov 14
      final created = DateTime(2026, 11, 5);

      // Logged: Nov 5, Nov 7, Nov 8, Nov 10, Nov 14 (today)
      final logged = {
        DateTime(2026, 11, 5),
        DateTime(2026, 11, 7),
        DateTime(2026, 11, 8),
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 14),
      };

      final stats = StreakUtils.monthStats(
        logged: logged,
        monthStart: monthStart,
        today: today,
        createdDate: created,
      );

      // Completions this month: 5
      expect(stats.completions, 5);

      // Missed through yesterday (Nov 13) from creation (Nov 5):
      // Window: Nov 5..13 = 9 days.
      // Logged in window: Nov 5, 7, 8, 10 = 4 days.
      // Missed = 9 - 4 = 5 days (Nov 6, 9, 11, 12, 13).
      expect(stats.missedDays, 5);

      // Rebounds:
      // Nov 7 (Nov 6 missed) -> 1
      // Nov 10 (Nov 9 missed) -> 2
      // Nov 14 (Nov 13 missed) -> 3
      expect(stats.rebounds, 3);
    });
  });

  group('StreakUtils - dayStatus', () {
    final today = DateTime(2026, 11, 14);
    final created = DateTime(2026, 11, 10);

    test('before creation date is notApplicable', () {
      expect(
        StreakUtils.dayStatus(
          date: DateTime(2026, 11, 9),
          today: today,
          createdDate: created,
          isLogged: false,
        ),
        HabitDayStatus.notApplicable,
      );
    });

    test('after today is future', () {
      expect(
        StreakUtils.dayStatus(
          date: DateTime(2026, 11, 15),
          today: today,
          createdDate: created,
          isLogged: false,
        ),
        HabitDayStatus.future,
      );
    });

    test('today logged is completed', () {
      expect(
        StreakUtils.dayStatus(
          date: today,
          today: today,
          createdDate: created,
          isLogged: true,
        ),
        HabitDayStatus.completed,
      );
    });

    test('today unlogged is incomplete', () {
      expect(
        StreakUtils.dayStatus(
          date: today,
          today: today,
          createdDate: created,
          isLogged: false,
        ),
        HabitDayStatus.incomplete,
      );
    });

    test('past logged is completed', () {
      expect(
        StreakUtils.dayStatus(
          date: DateTime(2026, 11, 11),
          today: today,
          createdDate: created,
          isLogged: true,
        ),
        HabitDayStatus.completed,
      );
    });

    test('past unlogged is incomplete', () {
      expect(
        StreakUtils.dayStatus(
          date: DateTime(2026, 11, 11),
          today: today,
          createdDate: created,
          isLogged: false,
        ),
        HabitDayStatus.incomplete,
      );
    });
  });
}
