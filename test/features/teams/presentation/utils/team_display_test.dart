import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/teams/presentation/utils/team_display.dart';
import 'package:matchday/features/teams/presentation/utils/team_share.dart';

void main() {
  group('teamCrestMonogram', () {
    test('one word takes its first two letters', () {
      expect(teamCrestMonogram('Ravens'), 'RA');
    });

    test('two and three words take initials', () {
      expect(teamCrestMonogram('Lahore Lions'), 'LL');
      expect(teamCrestMonogram('Dera Sports Stars'), 'DSS');
    });

    test('four or more words stop at three initials', () {
      expect(teamCrestMonogram('Model Town Sports Complex XI'), 'MTS');
    });

    test('an owner override wins over derivation', () {
      expect(teamCrestMonogram('Lahore Lions', override: 'LLC'), 'LLC');
      expect(teamCrestMonogram('Lahore Lions', override: '  ll '), 'LL');
    });

    test('a blank override falls back to derivation', () {
      expect(teamCrestMonogram('Lahore Lions', override: '   '), 'LL');
    });

    test('maxLetters trims for the small discs', () {
      // At 22px three letters is a smudge, so the crest asks for one.
      expect(teamCrestMonogram('Dera Sports Stars', maxLetters: 1), 'D');
      expect(teamCrestMonogram('Ravens', maxLetters: 1), 'R');
    });

    test('non-Latin names keep their first grapheme only', () {
      // Stacking three Urdu graphemes reads as noise, and initials are not a
      // convention in the script.
      expect(teamCrestMonogram('لاہور شیرز').length, 1);
    });

    test('an empty name degrades rather than throwing', () {
      expect(teamCrestMonogram('   '), '–');
    });
  });

  group('teamShareLink', () {
    test('uses the one host and the team letter', () {
      expect(
        teamShareLink('abc-123'),
        'https://joinmatchday.com/t/abc-123',
      );
    });
  });
}
