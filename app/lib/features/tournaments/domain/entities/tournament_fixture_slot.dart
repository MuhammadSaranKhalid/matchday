import 'package:equatable/equatable.dart';

/// Side of a pairing slot (Side A = Home / Top, Side B = Away / Bottom).
enum FixtureSlotSide {
  a('A', 'Side A'),
  b('B', 'Side B');

  const FixtureSlotSide(this.wire, this.label);
  final String wire;
  final String label;

  static FixtureSlotSide fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ?? FixtureSlotSide.a;
}

/// Discriminator for where a fixture slot obtains its competitor.
enum FixtureSlotSourceType {
  entry('entry', 'Direct Entry'),
  seed('seed', 'Seed Placement'),
  fixtureWinner('fixture_winner', 'Fixture Winner'),
  fixtureLoser('fixture_loser', 'Fixture Loser'),
  groupRank('group_rank', 'Group Rank'),
  stageRank('stage_rank', 'Stage Rank'),
  bye('bye', 'Bye');

  const FixtureSlotSourceType(this.wire, this.label);
  final String wire;
  final String label;

  static FixtureSlotSourceType fromWire(String? wire) =>
      values.where((t) => t.wire == wire).firstOrNull ??
      FixtureSlotSourceType.entry;
}

/// Strongly-typed source definition for a fixture slot.
sealed class FixtureSlotSource extends Equatable {
  const FixtureSlotSource();

  FixtureSlotSourceType get type;

  const factory FixtureSlotSource.entry(String entryId) = EntrySlotSource;
  const factory FixtureSlotSource.seed(int seed) = SeedSlotSource;
  const factory FixtureSlotSource.fixtureWinner(String fixtureId) =
      FixtureWinnerSlotSource;
  const factory FixtureSlotSource.fixtureLoser(String fixtureId) =
      FixtureLoserSlotSource;
  const factory FixtureSlotSource.groupRank({
    required String groupId,
    required int rank,
  }) = GroupRankSlotSource;
  const factory FixtureSlotSource.stageRank({
    required String stageId,
    required int rank,
  }) = StageRankSlotSource;
  const factory FixtureSlotSource.bye() = ByeSlotSource;
}

class EntrySlotSource extends FixtureSlotSource {
  const EntrySlotSource(this.entryId);
  final String entryId;

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.entry;

  @override
  List<Object?> get props => [entryId];
}

class SeedSlotSource extends FixtureSlotSource {
  const SeedSlotSource(this.seed);
  final int seed;

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.seed;

  @override
  List<Object?> get props => [seed];
}

class FixtureWinnerSlotSource extends FixtureSlotSource {
  const FixtureWinnerSlotSource(this.fixtureId);
  final String fixtureId;

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.fixtureWinner;

  @override
  List<Object?> get props => [fixtureId];
}

class FixtureLoserSlotSource extends FixtureSlotSource {
  const FixtureLoserSlotSource(this.fixtureId);
  final String fixtureId;

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.fixtureLoser;

  @override
  List<Object?> get props => [fixtureId];
}

class GroupRankSlotSource extends FixtureSlotSource {
  const GroupRankSlotSource({required this.groupId, required this.rank});
  final String groupId;
  final int rank;

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.groupRank;

  @override
  List<Object?> get props => [groupId, rank];
}

class StageRankSlotSource extends FixtureSlotSource {
  const StageRankSlotSource({required this.stageId, required this.rank});
  final String stageId;
  final int rank;

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.stageRank;

  @override
  List<Object?> get props => [stageId, rank];
}

class ByeSlotSource extends FixtureSlotSource {
  const ByeSlotSource();

  @override
  FixtureSlotSourceType get type => FixtureSlotSourceType.bye;

  @override
  List<Object?> get props => [];
}

/// One of two competitor positions (Side A or Side B) within a TournamentFixture.
class TournamentFixtureSlot extends Equatable {
  const TournamentFixtureSlot({
    required this.fixtureSlotId,
    required this.fixtureId,
    required this.tournamentId,
    required this.stageId,
    required this.side,
    required this.source,
    this.resolvedEntryId,
    this.resolvedAt,
    this.resolutionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String fixtureSlotId;
  final String fixtureId;
  final String tournamentId;
  final String stageId;
  final FixtureSlotSide side;
  final FixtureSlotSource source;
  final String? resolvedEntryId;
  final DateTime? resolvedAt;
  final String? resolutionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        fixtureSlotId,
        fixtureId,
        tournamentId,
        stageId,
        side,
        source,
        resolvedEntryId,
        resolvedAt,
        resolutionReason,
        createdAt,
        updatedAt,
      ];
}
