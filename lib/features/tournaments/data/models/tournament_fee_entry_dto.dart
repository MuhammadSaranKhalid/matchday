import '../../domain/entities/tournament_fee_entry.dart';

/// Wire shape of one `tournament_fee_ledger(...)` row (artboard 24c).
///
/// Hand-rolled to match the other tournament RPC projections: the row is flat
/// and the mapping is a straight read, so codegen would buy a build step and
/// nothing else.
class TournamentFeeEntryDto {
  const TournamentFeeEntryDto(this._row);

  final Map<String, dynamic> _row;

  factory TournamentFeeEntryDto.fromJson(Map<String, dynamic> json) =>
      TournamentFeeEntryDto(json);

  /// Postgres `numeric` arrives as a String over the wire more often than not.
  static double _num(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  TournamentFeeEntry toEntity() => TournamentFeeEntry(
        registrationId: _row['registration_id'] as String,
        teamId: _row['team_id'] as String,
        teamName: _row['team_name'] as String? ?? 'Unknown team',
        teamMonogram: _row['team_monogram'] as String?,
        teamLogoUrl: _row['team_logo_url'] as String?,
        entryFee: _num(_row['entry_fee']),
        amountPaid: _num(_row['amount_paid']),
        channel: PaymentChannel.fromWire(_row['payment_channel'] as String?),
        reference: _row['payment_reference'] as String?,
        recordedAt: _row['payment_recorded_at'] == null
            ? null
            : DateTime.tryParse(_row['payment_recorded_at'] as String)
                ?.toLocal(),
        recordedByName: _row['recorded_by_name'] as String?,
      );
}
