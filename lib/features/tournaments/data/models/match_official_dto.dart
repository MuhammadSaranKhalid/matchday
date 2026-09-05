import '../../domain/entities/match_official.dart';

/// Wire shape of one `tournament_match_officials(...)` row (artboard 27j).
class MatchOfficialDto {
  const MatchOfficialDto(this._row);

  final Map<String, dynamic> _row;

  factory MatchOfficialDto.fromJson(Map<String, dynamic> json) =>
      MatchOfficialDto(json);

  /// Null when the row carries a role this app does not model — a referee on
  /// a fixture imported from elsewhere, say. Dropping the row is better than
  /// inventing a role for it.
  MatchOfficial? toEntity() {
    final role = OfficialRole.fromWire(_row['role'] as String?);
    if (role == null) return null;
    return MatchOfficial(
      userId: _row['user_id'] as String,
      displayName: _row['display_name'] as String? ?? 'Unknown',
      username: _row['username'] as String?,
      avatarUrl: _row['avatar_url'] as String?,
      role: role,
      clubName: _row['club_name'] as String?,
      isNeutral: _row['is_neutral'] as bool? ?? true,
      assignedAt: _row['assigned_at'] == null
          ? null
          : DateTime.tryParse(_row['assigned_at'] as String)?.toLocal(),
    );
  }
}

/// Wire shape of one `tournament_official_candidates(...)` row (artboard 27j).
class OfficialCandidateDto {
  const OfficialCandidateDto(this._row);

  final Map<String, dynamic> _row;

  factory OfficialCandidateDto.fromJson(Map<String, dynamic> json) =>
      OfficialCandidateDto(json);

  static int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;

  OfficialCandidate toEntity() => OfficialCandidate(
        userId: _row['user_id'] as String,
        displayName: _row['display_name'] as String? ?? 'Unknown',
        username: _row['username'] as String?,
        avatarUrl: _row['avatar_url'] as String?,
        clubName: _row['club_name'] as String?,
        isNeutral: _row['is_neutral'] as bool? ?? true,
        matchesOfficiated: _int(_row['matches_officiated']),
        busyOn: _row['busy_on'] as String?,
      );
}
