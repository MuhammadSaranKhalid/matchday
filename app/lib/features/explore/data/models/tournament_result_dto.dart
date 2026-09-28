import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/tournament_result.dart';

part 'tournament_result_dto.freezed.dart';
part 'tournament_result_dto.g.dart';

/// One row from `search-all`'s tournament group (and the browse list).
///
/// `location` arrives as the raw jsonb column — `{city, lat, lng}` — because
/// the function selects it whole. Only `city` is read today; lat/lng are
/// there for the proximity ordering that lands with coordinate capture.
@freezed
abstract class TournamentResultDto with _$TournamentResultDto {
  const factory TournamentResultDto({
    @JsonKey(name: 'tournament_id') required String tournamentId,
    @JsonKey(name: 'tournament_name') required String tournamentName,
    @JsonKey(name: 'tournament_type') required String tournamentType,
    required String status,
    @JsonKey(name: 'banner_image_url') String? bannerImageUrl,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    Map<String, dynamic>? location,
    // numeric(10,2) can arrive as either a JSON number or a string depending
    // on the driver, so it is decoded loosely and coerced in toEntity.
    @JsonKey(name: 'entry_fee') Object? entryFee,
    @JsonKey(name: 'max_teams') int? maxTeams,
    @JsonKey(name: 'approved_teams_count') int? approvedTeamsCount,
  }) = _TournamentResultDto;

  const TournamentResultDto._();

  factory TournamentResultDto.fromJson(Map<String, dynamic> json) =>
      _$TournamentResultDtoFromJson(json);

  TournamentResult toEntity() => TournamentResult(
        tournamentId: tournamentId,
        name: tournamentName,
        type: tournamentType,
        status: status,
        bannerImageUrl: bannerImageUrl,
        logoUrl: logoUrl,
        startDate: _parse(startDate),
        endDate: _parse(endDate),
        city: location?['city'] as String?,
        entryFee: _num(entryFee),
        maxTeams: maxTeams,
        approvedTeamsCount: approvedTeamsCount ?? 0,
      );

  /// Dates arrive as ISO 8601 `date` strings. A malformed one must not take
  /// the whole result list down — a cup with an unreadable date still renders.
  static DateTime? _parse(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  static double? _num(Object? raw) => switch (raw) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s),
        _ => null,
      };
}
