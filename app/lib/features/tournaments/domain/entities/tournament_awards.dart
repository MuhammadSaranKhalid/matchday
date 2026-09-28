import 'package:meta/meta.dart';

/// Recipient of an individual tournament award.
@immutable
class AwardRecipient {
  const AwardRecipient({
    required this.playerId,
    required this.playerName,
    required this.metricLabel,
    required this.metricValue,
    this.playerPhotoUrl,
    this.teamName,
    this.teamCrestColor,
    this.isUnclaimed = false,
  });

  final String playerId;
  final String playerName;
  final String metricLabel;
  final String metricValue;
  final String? playerPhotoUrl;
  final String? teamName;
  final String? teamCrestColor;
  final bool isUnclaimed;

  factory AwardRecipient.fromJson(Map<String, dynamic> json) => AwardRecipient(
        playerId: json['player_id'] as String? ?? '',
        playerName: json['player_name'] as String? ?? 'Player',
        metricLabel: json['metric_label'] as String? ?? '',
        metricValue: json['metric_value'] as String? ?? '',
        playerPhotoUrl: json['player_photo_url'] as String?,
        teamName: json['team_name'] as String?,
        teamCrestColor: json['team_crest_color'] as String?,
        isUnclaimed: json['is_unclaimed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'metric_label': metricLabel,
        'metric_value': metricValue,
        if (playerPhotoUrl != null) 'player_photo_url': playerPhotoUrl,
        if (teamName != null) 'team_name': teamName,
        if (teamCrestColor != null) 'team_crest_color': teamCrestColor,
        'is_unclaimed': isUnclaimed,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AwardRecipient &&
          other.playerId == playerId &&
          other.metricValue == metricValue;

  @override
  int get hashCode => Object.hash(playerId, metricValue);
}

/// Tournament awards model (auto-calculated from match deliveries and confirmed by organizer).
@immutable
class TournamentAwards {
  const TournamentAwards({
    this.playerOfTheTournament,
    this.bestBatsman,
    this.bestBowler,
    this.bestStrikeRate,
    this.bestBowlingFigures,
    this.customAwards = const {},
  });

  final AwardRecipient? playerOfTheTournament;
  final AwardRecipient? bestBatsman;
  final AwardRecipient? bestBowler;
  final AwardRecipient? bestStrikeRate;
  final AwardRecipient? bestBowlingFigures;
  final Map<String, AwardRecipient> customAwards;

  factory TournamentAwards.fromJson(Map<String, dynamic> json) {
    AwardRecipient? parseAward(String key) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) {
        return AwardRecipient.fromJson(raw);
      }
      return null;
    }

    final custom = <String, AwardRecipient>{};
    final customRaw = json['custom_awards'];
    if (customRaw is Map<String, dynamic>) {
      for (final entry in customRaw.entries) {
        if (entry.value is Map<String, dynamic>) {
          custom[entry.key] =
              AwardRecipient.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    }

    return TournamentAwards(
      playerOfTheTournament: parseAward('player_of_tournament'),
      bestBatsman: parseAward('best_batsman'),
      bestBowler: parseAward('best_bowler'),
      bestStrikeRate: parseAward('best_strike_rate'),
      bestBowlingFigures: parseAward('best_bowling_figures'),
      customAwards: custom,
    );
  }

  Map<String, dynamic> toJson() => {
        if (playerOfTheTournament != null)
          'player_of_tournament': playerOfTheTournament!.toJson(),
        if (bestBatsman != null) 'best_batsman': bestBatsman!.toJson(),
        if (bestBowler != null) 'best_bowler': bestBowler!.toJson(),
        if (bestStrikeRate != null) 'best_strike_rate': bestStrikeRate!.toJson(),
        if (bestBowlingFigures != null)
          'best_bowling_figures': bestBowlingFigures!.toJson(),
        if (customAwards.isNotEmpty)
          'custom_awards': customAwards
              .map((key, value) => MapEntry(key, value.toJson())),
      };
}
