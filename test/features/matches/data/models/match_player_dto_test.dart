// Identity resolution at the match_players boundary.
//
// The bug these guard: names used to be looked up against the *team roster*
// in the presentation layer. The XI and the roster are different sets — a
// guest, a substitute, or anyone since removed from the roster is in
// match_players with no roster row to name them — so those players rendered
// as "Player 3f2a" on the scoring screen and in the openers picker, and the
// monogram derived from that string was "P3".
//
// Resolving from the embedded PostgREST joins instead means the lineup names
// itself, independent of roster membership.
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/data/models/match_player_dto.dart';

Map<String, dynamic> _row({
  String? profileId,
  String? unclaimedId,
  Map<String, dynamic>? profile,
  Map<String, dynamic>? unclaimed,
}) =>
    {
      'match_player_id': 'mp1',
      'match_id': 'm1',
      'team_side': 'a',
      'profile_id': profileId,
      'unclaimed_id': unclaimedId,
      'profile': profile,
      'unclaimed': unclaimed,
    };

void main() {
  group('claimed players', () {
    test('take their name and avatar from the profiles join', () {
      final dto = MatchPlayerDto.fromJson(_row(
        profileId: 'u1',
        profile: {
          'display_name': 'Imran Khan',
          'username': 'imran',
          'profile_photo_url': 'https://cdn/avatars/u1/a.jpg',
        },
      ));

      expect(dto.displayName, 'Imran Khan');
      expect(dto.photoUrl, 'https://cdn/avatars/u1/a.jpg');
      expect(dto.toEntity().displayName, 'Imran Khan');
      expect(dto.toEntity().photoUrl, 'https://cdn/avatars/u1/a.jpg');
    });

    test('fall back to the username when display_name is blank', () {
      final dto = MatchPlayerDto.fromJson(_row(
        profileId: 'u1',
        profile: {'display_name': '   ', 'username': 'imran'},
      ));

      expect(dto.displayName, 'imran');
    });

    test('render the monogram when no photo was uploaded', () {
      final dto = MatchPlayerDto.fromJson(_row(
        profileId: 'u1',
        profile: {'display_name': 'Imran Khan', 'profile_photo_url': null},
      ));

      expect(dto.photoUrl, isNull);
    });

    test('treat an empty photo url as absent, not as a broken image', () {
      final dto = MatchPlayerDto.fromJson(_row(
        profileId: 'u1',
        profile: {'display_name': 'Imran Khan', 'profile_photo_url': '  '},
      ));

      expect(dto.photoUrl, isNull);
    });
  });

  group('unclaimed placeholders', () {
    test('take their name from the unclaimed join and never have a photo', () {
      // unclaimed_players has no photo column by design: the person has not
      // joined yet. The monogram is the final rendering, not a loading state.
      final dto = MatchPlayerDto.fromJson(_row(
        unclaimedId: 'x1',
        unclaimed: {'display_name': 'Village Keeper'},
      ));

      expect(dto.displayName, 'Village Keeper');
      expect(dto.photoUrl, isNull);
    });
  });

  group('degraded rows', () {
    test('a suspended profile still yields a usable name', () {
      // profiles SELECT is filtered to account_status = 'active', so the
      // embed comes back null for a suspended account. A blank tile in the
      // bowler picker is worse than a placeholder.
      final dto = MatchPlayerDto.fromJson(_row(profileId: 'u1'));

      expect(dto.displayName, 'Player');
      expect(dto.photoUrl, isNull);
    });

    test('a missing unclaimed join is labelled as offline, not as "Player"', () {
      final dto = MatchPlayerDto.fromJson(_row(unclaimedId: 'x1'));

      expect(dto.displayName, 'Offline player');
    });

    test('the name is never empty, whatever the joins contain', () {
      final dto = MatchPlayerDto.fromJson(_row(
        profileId: 'u1',
        profile: {'display_name': '', 'username': ''},
      ));

      expect(dto.displayName, isNotEmpty);
    });
  });
}
