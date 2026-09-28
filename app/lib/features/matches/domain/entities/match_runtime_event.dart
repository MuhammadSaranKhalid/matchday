import 'package:equatable/equatable.dart';

enum MatchRuntimeEventType {
  matchChanged('match_changed'),
  participantsChanged('participants_changed'),
  inningsChanged('innings_changed'),
  matchCompleted('match_completed');

  const MatchRuntimeEventType(this.wire);
  final String wire;

  static MatchRuntimeEventType? tryParse(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

class MatchRuntimeEvent extends Equatable {
  const MatchRuntimeEvent({
    required this.eventId,
    required this.matchId,
    required this.revision,
    required this.type,
    required this.occurredAt,
    this.inningsNumber,
  });

  factory MatchRuntimeEvent.fromJson(Map<String, dynamic> json) {
    final type = MatchRuntimeEventType.tryParse(
      json['eventType'] ?? json['event_type'],
    );
    if (type == null) throw const FormatException('Unknown match event type');
    return MatchRuntimeEvent(
      eventId: (json['eventId'] ?? json['event_id'] ?? '').toString(),
      matchId: (json['matchId'] ?? json['match_id'] ?? '').toString(),
      revision: _wireInt(json['revision']),
      type: type,
      occurredAt:
          DateTime.tryParse(
            (json['occurredAt'] ?? json['occurred_at'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      inningsNumber: _wireNullableInt(
        json['inningsNumber'] ?? json['innings_number'],
      ),
    );
  }

  final String eventId;
  final String matchId;
  final int revision;
  final MatchRuntimeEventType type;
  final int? inningsNumber;
  final DateTime occurredAt;

  @override
  List<Object?> get props => [
    eventId,
    matchId,
    revision,
    type,
    inningsNumber,
    occurredAt,
  ];
}

int _wireInt(Object? value) => switch (value) {
  final int value => value,
  final num value => value.toInt(),
  final String value => int.tryParse(value) ?? 0,
  _ => 0,
};

int? _wireNullableInt(Object? value) => value == null ? null : _wireInt(value);
