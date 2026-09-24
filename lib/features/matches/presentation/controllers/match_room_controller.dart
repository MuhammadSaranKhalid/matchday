import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/match_room_snapshot.dart';
import '../../domain/repositories/matches_repository.dart';
import '../providers/matches_providers.dart';
import '../state/match_room_state.dart';

part 'match_room_controller.g.dart';

@riverpod
class MatchRoomController extends _$MatchRoomController {
  StreamSubscription<MatchRoomSnapshot>? _subscription;

  MatchesRepository get _repository => ref.read(matchesRepositoryProvider);

  @override
  Future<MatchRoomState> build(String matchId) async {
    final first = Completer<MatchRoomState>();
    _subscription = _repository
        .watchMatchRoom(MatchId(matchId))
        .listen(
          (snapshot) {
            if (!first.isCompleted) {
              first.complete(_stateForSnapshot(snapshot));
            } else {
              _adoptRealtime(snapshot);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!first.isCompleted) {
              first.completeError(error, stackTrace);
            } else {
              _update(
                (current) => current.copyWith(nonBlockingError: () => error),
              );
            }
          },
        );
    ref.onDispose(() => _subscription?.cancel());
    return first.future;
  }

  void selectStriker(String? id) => _update((value) {
    if (id != null && id == value.selectedNonStrikerId) {
      return value.copyWith(
        selectedStrikerId: () => id,
        selectedNonStrikerId: () => null,
      );
    }
    return value.copyWith(selectedStrikerId: () => id);
  });

  void selectNonStriker(String? id) => _update((value) {
    if (id != null && id == value.selectedStrikerId) {
      return value.copyWith(
        selectedStrikerId: () => null,
        selectedNonStrikerId: () => id,
      );
    }
    return value.copyWith(selectedNonStrikerId: () => id);
  });

  void selectBowler(String? id) =>
      _update((value) => value.copyWith(selectedBowlerId: () => id));

  void swapBatters() => _update(
    (value) => value.copyWith(
      selectedStrikerId: () => value.selectedNonStrikerId,
      selectedNonStrikerId: () => value.selectedStrikerId,
    ),
  );

  void tapOpener(String id) {
    _update((current) {
      final striker = current.selectedStrikerId;
      final nonStriker = current.selectedNonStrikerId;
      final (String? nextStriker, String? nextNonStriker) = switch ((
        striker,
        nonStriker,
      )) {
        (null, _) => (id, nonStriker == id ? null : nonStriker),
        (_, null) => (striker == id ? null : striker, id),
        _ => (id, nonStriker == id ? striker : nonStriker),
      };
      return current.copyWith(
        selectedStrikerId: () => nextStriker,
        selectedNonStrikerId: () => nextNonStriker,
      );
    });
  }

  Future<Either<Failure, Unit>> submitToss({
    required String wonByTeamId,
    required TossDecision decision,
    String? face,
  }) async {
    _update(
      (value) =>
          value.copyWith(isCommandPending: true, nonBlockingError: () => null),
    );
    final result = await _repository.recordToss(
      id: MatchId(matchId),
      wonBy: TeamId(wonByTeamId),
      decision: decision,
      face: face,
    );
    await result.fold(
      (failure) async =>
          _update((value) => value.copyWith(nonBlockingError: () => failure)),
      (_) => refresh(),
    );
    _update((value) => value.copyWith(isCommandPending: false));
    return result;
  }

  Future<Either<Failure, MatchRoomSnapshot>> startMatch() async {
    final current = state.value;
    if (current == null ||
        current.selectedStrikerId == null ||
        current.selectedNonStrikerId == null ||
        current.selectedBowlerId == null) {
      return const Left(
        ValidationFailure('Select striker, non-striker, and bowler'),
      );
    }
    if (current.selectedStrikerId == current.selectedNonStrikerId) {
      return const Left(
        ValidationFailure('Striker and non-striker must be different players'),
      );
    }
    return _command(
      () => _repository.startMatch(
        id: MatchId(matchId),
        strikerId: current.selectedStrikerId!,
        nonStrikerId: current.selectedNonStrikerId!,
        bowlerId: current.selectedBowlerId!,
      ),
    );
  }

  Future<Either<Failure, MatchRoomSnapshot>> addParticipant({
    required MatchTeamSide side,
    required String displayName,
  }) => _command(
    () => _repository.addMatchParticipant(
      id: MatchId(matchId),
      side: side,
      displayName: displayName,
      idempotencyKey: const Uuid().v4(),
    ),
  );

  Future<void> refresh() async {
    _update(
      (value) =>
          value.copyWith(isRefreshing: true, nonBlockingError: () => null),
    );
    final result = await _repository.getMatchRoom(MatchId(matchId));
    result.fold(
      (failure) => _update(
        (value) => value.copyWith(
          isRefreshing: false,
          nonBlockingError: () => failure,
        ),
      ),
      (snapshot) {
        _adoptCanonical(snapshot);
        _update((value) => value.copyWith(isRefreshing: false));
      },
    );
  }

  void consumeNavigation() => _update(
    (value) =>
        value.copyWith(navigation: () => null, navigationRevision: () => null),
  );

  Future<Either<Failure, MatchRoomSnapshot>> _command(
    Future<Either<Failure, MatchRoomSnapshot>> Function() operation,
  ) async {
    _update(
      (value) =>
          value.copyWith(isCommandPending: true, nonBlockingError: () => null),
    );
    final result = await operation();
    result.fold(
      (failure) => _update(
        (value) => value.copyWith(
          isCommandPending: false,
          nonBlockingError: () => failure,
        ),
      ),
      (snapshot) {
        _adoptCanonical(snapshot);
        _update((value) => value.copyWith(isCommandPending: false));
      },
    );
    return result;
  }

  MatchRoomState _stateForSnapshot(MatchRoomSnapshot snapshot) {
    final navigation = _navigationFor(snapshot.match.status);
    return MatchRoomState(
      snapshot: snapshot,
      navigation: navigation,
      navigationRevision: navigation == null ? null : snapshot.revision,
    );
  }

  MatchRoomState _mergeSnapshot(
    MatchRoomState current,
    MatchRoomSnapshot snapshot,
  ) {
    final eligible =
        snapshot.participants.map((player) => player.id.value).toSet();
    final navigation =
        current.navigation ?? _navigationFor(snapshot.match.status);
    final nextStriker = eligible.contains(current.selectedStrikerId)
        ? current.selectedStrikerId
        : null;
    var nextNonStriker = eligible.contains(current.selectedNonStrikerId)
        ? current.selectedNonStrikerId
        : null;
    if (nextStriker != null && nextStriker == nextNonStriker) {
      nextNonStriker = null;
    }
    return current.copyWith(
      snapshot: snapshot,
      navigation: () => navigation,
      navigationRevision: () => navigation == null ? null : snapshot.revision,
      nonBlockingError: () => null,
      selectedStrikerId: () => nextStriker,
      selectedNonStrikerId: () => nextNonStriker,
      selectedBowlerId:
          () =>
              eligible.contains(current.selectedBowlerId)
                  ? current.selectedBowlerId
                  : null,
    );
  }

  void _adoptRealtime(MatchRoomSnapshot snapshot) {
    _update((current) {
      if (snapshot.revision <= current.snapshot.revision) return current;
      return _mergeSnapshot(current, snapshot);
    });
  }

  void _adoptCanonical(MatchRoomSnapshot snapshot) {
    _update((current) {
      if (snapshot.revision < current.snapshot.revision) return current;
      return _mergeSnapshot(current, snapshot);
    });
  }

  MatchRoomNavigation? _navigationFor(MatchStatus status) => switch (status) {
    MatchStatus.live ||
    MatchStatus.inningsBreak => MatchRoomNavigation.scoring,
    MatchStatus.completed ||
    MatchStatus.cancelled => MatchRoomNavigation.result,
    _ => null,
  };

  void _update(MatchRoomState Function(MatchRoomState) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}
