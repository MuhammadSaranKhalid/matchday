import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/tournaments/data/models/tournament_entry_dto.dart';
import 'package:matchday/features/tournaments/data/models/tournament_entry_payment_dto.dart';
import 'package:matchday/features/tournaments/data/models/tournament_squad_member_dto.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_entry.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_entry_payment.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_registration.dart';
import 'package:matchday/features/tournaments/domain/entities/tournament_squad_member.dart';

void main() {
  group('Phase 3 — Frozen Domain Separation Invariants', () {
    test('1. Registration != Entry != Squad != Match Lineup != Payment', () {

      // Registration is an application request
      final reg = TournamentRegistration(
        registrationId: 'reg-001',
        tournamentId: 't-001',
        teamId: 'team-001',
        registeredAt: DateTime(2026, 9, 20),
        status: TournamentRegistrationStatus.approved,
        squadProposal: const [],
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 25),
        message: 'Looking forward to the competition',
        decidedBy: 'user-organizer',
        decidedAt: DateTime(2026, 9, 25),
      );

      // Entry is an accepted competitive participant
      final entry = TournamentEntry(
        entryId: 'entry-001',
        tournamentId: 't-001',
        teamId: 'team-001',
        registrationId: reg.registrationId,
        status: TournamentEntryStatus.active,
        entrySource: 'application',
        squadState: TournamentSquadState.editable,
        acceptedBy: 'user-organizer',
        acceptedAt: DateTime(2026, 9, 25),
        createdAt: DateTime(2026, 9, 25),
        updatedAt: DateTime(2026, 9, 25),
      );

      // Squad is the eligible person set representing the Entry
      final squadMember = TournamentSquadMember(
        squadMemberId: 'sqm-001',
        entryId: entry.entryId,
        tournamentId: 't-001',
        userId: 'user-player-1',
        membershipStatus: TournamentSquadMembershipStatus.active,
        addedBy: 'user-team-mgr',
        addedAt: DateTime(2026, 9, 26),
        createdAt: DateTime(2026, 9, 26),
        updatedAt: DateTime(2026, 9, 26),
      );

      // Payment is an immutable historical financial transaction
      final payment = TournamentEntryPayment(
        paymentId: 'pay-001',
        entryId: entry.entryId,
        tournamentId: 't-001',
        amount: 2500.0,
        paymentChannel: 'bank_transfer',
        paymentReference: 'TXN-98765',
        recordedBy: 'user-organizer',
        recordedAt: DateTime(2026, 9, 27),
        isVoid: false,
        createdAt: DateTime(2026, 9, 27),
      );

      expect(reg.registrationId, equals('reg-001'));
      expect(entry.entryId, equals('entry-001'));
      expect(entry.registrationId, equals(reg.registrationId));
      expect(squadMember.entryId, equals(entry.entryId));
      expect(payment.entryId, equals(entry.entryId));

      // Separate identities and semantics
      expect(entry.entryId, isNot(equals(reg.registrationId)));
      expect(squadMember.squadMemberId, isNot(equals(entry.entryId)));
      expect(payment.paymentId, isNot(equals(entry.entryId)));
    });

    test('2. Acceptance != Payment: Entry can be active while unpaid', () {
      final entry = TournamentEntry(
        entryId: 'entry-002',
        tournamentId: 't-002',
        teamId: 'team-002',
        status: TournamentEntryStatus.active,
        entrySource: 'invitation',
        squadState: TournamentSquadState.editable,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final payments = <TournamentEntryPayment>[];
      final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);

      expect(entry.isActive, isTrue);
      expect(totalPaid, equals(0.0));
      // Unpaid status does not destroy active competitive acceptance
      expect(entry.status, equals(TournamentEntryStatus.active));
    });

    test('3. Withdrawal Semantics Split: Registration vs Entry', () {
      // A. Application withdrawn before acceptance
      final withdrawnApp = TournamentRegistration(
        registrationId: 'reg-003',
        tournamentId: 't-001',
        teamId: 'team-003',
        registeredAt: DateTime(2026, 9, 20),
        status: TournamentRegistrationStatus.withdrawn,
        squadProposal: const [],
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 21),
      );
      expect(withdrawnApp.status, equals(TournamentRegistrationStatus.withdrawn));
      expect(withdrawnApp.isApproved, isFalse);

      // B. Post-approval competitive Entry withdrawal
      final historicalApprovedApp = TournamentRegistration(
        registrationId: 'reg-004',
        tournamentId: 't-001',
        teamId: 'team-004',
        registeredAt: DateTime(2026, 9, 20),
        status: TournamentRegistrationStatus.approved,
        squadProposal: const [],
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 22),
        decidedBy: 'user-org',
        decidedAt: DateTime(2026, 9, 22),
      );

      final withdrawnEntry = TournamentEntry(
        entryId: 'entry-004',
        tournamentId: 't-001',
        teamId: 'team-004',
        registrationId: historicalApprovedApp.registrationId,
        status: TournamentEntryStatus.withdrawn,
        entrySource: 'application',
        squadState: TournamentSquadState.editable,
        withdrawnAt: DateTime(2026, 9, 28),
        withdrawalReason: 'Player injuries',
        createdAt: DateTime(2026, 9, 22),
        updatedAt: DateTime(2026, 9, 28),
      );

      // Registration remains approved historically!
      expect(historicalApprovedApp.status, equals(TournamentRegistrationStatus.approved));
      // Entry is withdrawn
      expect(withdrawnEntry.status, equals(TournamentEntryStatus.withdrawn));
      expect(withdrawnEntry.isWithdrawn, isTrue);
    });

    test('4. Squad State (Editable vs Frozen) is independent from Entry Set Lock', () {
      final entryEditable = TournamentEntry(
        entryId: 'entry-005',
        tournamentId: 't-001',
        teamId: 'team-005',
        status: TournamentEntryStatus.active,
        entrySource: 'application',
        squadState: TournamentSquadState.editable,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final entryFrozen = TournamentEntry(
        entryId: 'entry-005',
        tournamentId: 't-001',
        teamId: 'team-005',
        status: TournamentEntryStatus.active,
        entrySource: 'application',
        squadState: TournamentSquadState.frozen,
        squadFrozenAt: DateTime(2026, 10, 1, 12, 0),
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1, 12, 0),
      );

      expect(entryEditable.isSquadFrozen, isFalse);
      expect(entryFrozen.isSquadFrozen, isTrue);
      expect(entryFrozen.squadFrozenAt, isNotNull);
    });
  });

  group('Phase 3 — DTO Parsing & Entity Mapping', () {
    test('5. TournamentEntryDto decodes json correctly and maps toEntity', () {
      final json = {
        'entry_id': 'e-100',
        'tournament_id': 't-100',
        'team_id': 'tm-100',
        'registration_id': 'r-100',
        'status': 'active',
        'entry_source': 'application',
        'squad_state': 'editable',
        'accepted_by': 'u-org',
        'accepted_at': '2026-10-01T00:00:00.000Z',
        'created_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-10-01T00:00:00.000Z',
        'teams': {
          'team_name': 'Lahore Qalandars',
          'logo_url': 'https://example.com/logo.png',
        },
      };

      final dto = TournamentEntryDto.fromJson(json);
      expect(dto.entryId, equals('e-100'));
      expect(dto.teamName, equals('Lahore Qalandars'));

      final entity = dto.toEntity();
      expect(entity.entryId, equals('e-100'));
      expect(entity.tournamentId, equals('t-100'));
      expect(entity.teamId, equals('tm-100'));
      expect(entity.registrationId, equals('r-100'));
      expect(entity.status, equals(TournamentEntryStatus.active));
      expect(entity.squadState, equals(TournamentSquadState.editable));
      expect(entity.teamName, equals('Lahore Qalandars'));
      expect(entity.teamLogoUrl, equals('https://example.com/logo.png'));
    });

    test('6. TournamentSquadMemberDto decodes json and maps toEntity', () {
      final json = {
        'squad_member_id': 'sq-200',
        'entry_id': 'e-100',
        'tournament_id': 't-100',
        'user_id': 'u-player',
        'membership_status': 'active',
        'added_by': 'u-mgr',
        'added_at': '2026-10-01T01:00:00.000Z',
        'created_at': '2026-10-01T01:00:00.000Z',
        'updated_at': '2026-10-01T01:00:00.000Z',
        'profiles': {
          'display_name': 'Babar Azam',
          'username': 'babar_azam',
          'avatar_url': 'https://example.com/babar.png',
        },
      };

      final dto = TournamentSquadMemberDto.fromJson(json);
      expect(dto.displayName, equals('Babar Azam'));

      final entity = dto.toEntity();
      expect(entity.squadMemberId, equals('sq-200'));
      expect(entity.userId, equals('u-player'));
      expect(entity.membershipStatus, equals(TournamentSquadMembershipStatus.active));
      expect(entity.displayName, equals('Babar Azam'));
      expect(entity.username, equals('babar_azam'));
      expect(entity.avatarUrl, equals('https://example.com/babar.png'));
    });

    test('7. TournamentEntryPaymentDto decodes json and maps toEntity', () {
      final json = {
        'payment_id': 'p-300',
        'entry_id': 'e-100',
        'tournament_id': 't-100',
        'amount': 3000.0,
        'payment_channel': 'cash',
        'payment_reference': 'RCPT-100',
        'recorded_by': 'u-org',
        'recorded_at': '2026-10-01T02:00:00.000Z',
        'is_void': false,
        'created_at': '2026-10-01T02:00:00.000Z',
      };

      final dto = TournamentEntryPaymentDto.fromJson(json);
      expect(dto.amount, equals(3000.0));
      expect(dto.paymentChannel, equals('cash'));

      final entity = dto.toEntity();
      expect(entity.paymentId, equals('p-300'));
      expect(entity.amount, equals(3000.0));
      expect(entity.paymentChannel, equals('cash'));
      expect(entity.paymentReference, equals('RCPT-100'));
      expect(entity.isVoid, isFalse);
    });

    test('8. Payment Ledger accumulation derivation', () {
      final payments = [
        TournamentEntryPayment(
          paymentId: 'p-1',
          entryId: 'e-100',
          tournamentId: 't-100',
          amount: 2000.0,
          paymentChannel: 'cash',
          recordedAt: DateTime(2026, 10, 1),
          isVoid: false,
          createdAt: DateTime(2026, 10, 1),
        ),
        TournamentEntryPayment(
          paymentId: 'p-2',
          entryId: 'e-100',
          tournamentId: 't-100',
          amount: 3000.0,
          paymentChannel: 'bank_transfer',
          recordedAt: DateTime(2026, 10, 2),
          isVoid: false,
          createdAt: DateTime(2026, 10, 2),
        ),
        TournamentEntryPayment(
          paymentId: 'p-3',
          entryId: 'e-100',
          tournamentId: 't-100',
          amount: 1000.0,
          paymentChannel: 'cash',
          recordedAt: DateTime(2026, 10, 3),
          isVoid: true, // voided payment
          createdAt: DateTime(2026, 10, 3),
        ),
      ];

      // Only valid non-void payments count toward cumulative total
      final validPayments = payments.where((p) => !p.isVoid);
      final totalPaid = validPayments.fold(0.0, (sum, p) => sum + p.amount);

      expect(totalPaid, equals(5000.0));
    });
  });
}
