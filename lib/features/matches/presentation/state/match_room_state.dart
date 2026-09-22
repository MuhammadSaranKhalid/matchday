import 'package:equatable/equatable.dart';

import '../../domain/entities/match_room_snapshot.dart';

enum MatchRoomNavigation { scoring, result }

class MatchRoomState extends Equatable {
  const MatchRoomState({
    required this.snapshot,
    this.isRefreshing = false,
    this.isCommandPending = false,
    this.isRealtimeConnected = true,
    this.navigation,
    this.navigationRevision,
    this.nonBlockingError,
    this.selectedStrikerId,
    this.selectedNonStrikerId,
    this.selectedBowlerId,
  });

  final MatchRoomSnapshot snapshot;
  final bool isRefreshing;
  final bool isCommandPending;
  final bool isRealtimeConnected;
  final MatchRoomNavigation? navigation;
  final int? navigationRevision;
  final Object? nonBlockingError;
  final String? selectedStrikerId;
  final String? selectedNonStrikerId;
  final String? selectedBowlerId;

  MatchRoomState copyWith({
    MatchRoomSnapshot? snapshot,
    bool? isRefreshing,
    bool? isCommandPending,
    bool? isRealtimeConnected,
    MatchRoomNavigation? Function()? navigation,
    int? Function()? navigationRevision,
    Object? Function()? nonBlockingError,
    String? Function()? selectedStrikerId,
    String? Function()? selectedNonStrikerId,
    String? Function()? selectedBowlerId,
  }) => MatchRoomState(
    snapshot: snapshot ?? this.snapshot,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isCommandPending: isCommandPending ?? this.isCommandPending,
    isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
    navigation: navigation == null ? this.navigation : navigation(),
    navigationRevision:
        navigationRevision == null
            ? this.navigationRevision
            : navigationRevision(),
    nonBlockingError:
        nonBlockingError == null ? this.nonBlockingError : nonBlockingError(),
    selectedStrikerId:
        selectedStrikerId == null
            ? this.selectedStrikerId
            : selectedStrikerId(),
    selectedNonStrikerId:
        selectedNonStrikerId == null
            ? this.selectedNonStrikerId
            : selectedNonStrikerId(),
    selectedBowlerId:
        selectedBowlerId == null ? this.selectedBowlerId : selectedBowlerId(),
  );

  @override
  List<Object?> get props => [
    snapshot,
    isRefreshing,
    isCommandPending,
    isRealtimeConnected,
    navigation,
    navigationRevision,
    nonBlockingError,
    selectedStrikerId,
    selectedNonStrikerId,
    selectedBowlerId,
  ];
}
