import 'package:equatable/equatable.dart';

/// Historical financial record for a tournament entry payment.
class TournamentEntryPayment extends Equatable {
  const TournamentEntryPayment({
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
  final DateTime recordedAt;
  final bool isVoid;
  final String? voidReason;
  final DateTime? voidedAt;
  final String? voidedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        paymentId,
        entryId,
        tournamentId,
        amount,
        paymentChannel,
        paymentReference,
        recordedBy,
        recordedAt,
        isVoid,
        voidReason,
        voidedAt,
        voidedBy,
        createdAt,
      ];
}
