import '../../domain/entities/tournament_entry_payment.dart';

/// Wire DTO for `public.tournament_entry_payments` rows.
class TournamentEntryPaymentDto {
  const TournamentEntryPaymentDto({
    required this.paymentId,
    required this.entryId,
    required this.tournamentId,
    required this.amount,
    required this.paymentChannel,
    required this.recordedAt,
    required this.isVoid,
    required this.createdAt,
    this.paymentReference,
    this.recordedBy,
    this.voidReason,
    this.voidedAt,
    this.voidedBy,
  });

  final String paymentId;
  final String entryId;
  final String tournamentId;
  final double amount;
  final String paymentChannel;
  final String? paymentReference;
  final String? recordedBy;
  final String recordedAt;
  final bool isVoid;
  final String? voidReason;
  final String? voidedAt;
  final String? voidedBy;
  final String createdAt;

  factory TournamentEntryPaymentDto.fromJson(Map<String, dynamic> json) {
    return TournamentEntryPaymentDto(
      paymentId: json['payment_id'] as String,
      entryId: json['entry_id'] as String,
      tournamentId: json['tournament_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentChannel: json['payment_channel'] as String? ?? 'cash',
      paymentReference: json['payment_reference'] as String?,
      recordedBy: json['recorded_by'] as String?,
      recordedAt: json['recorded_at'] as String? ?? DateTime.now().toIso8601String(),
      isVoid: json['is_void'] as bool? ?? false,
      voidReason: json['void_reason'] as String?,
      voidedAt: json['voided_at'] as String?,
      voidedBy: json['voided_by'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  TournamentEntryPayment toEntity() => TournamentEntryPayment(
        paymentId: paymentId,
        entryId: entryId,
        tournamentId: tournamentId,
        amount: amount,
        paymentChannel: paymentChannel,
        paymentReference: paymentReference,
        recordedBy: recordedBy,
        recordedAt: DateTime.parse(recordedAt),
        isVoid: isVoid,
        voidReason: voidReason,
        voidedAt: voidedAt != null ? DateTime.parse(voidedAt!) : null,
        voidedBy: voidedBy,
        createdAt: DateTime.parse(createdAt),
      );
}
