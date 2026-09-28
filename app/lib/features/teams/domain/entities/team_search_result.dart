import 'package:equatable/equatable.dart';

import 'team.dart';

class TeamSearchResult extends Equatable {
  const TeamSearchResult({
    required this.teamId,
    required this.name,
    required this.score,
    this.logoUrl,
    this.logoMonogram,
    this.primaryColor,
    this.secondaryColor,
    this.isVerified = false,
    this.distanceKm,
    this.foundedYear,
    this.teamType,
  });

  final TeamId teamId;
  final String name;
  final double score;
  final String? logoUrl;
  final String? logoMonogram;
  final String? primaryColor;
  final String? secondaryColor;
  final bool isVerified;
  final double? distanceKm;
  final int? foundedYear;
  final String? teamType;

  String get metaLine {
    final parts = <String>[
      if (foundedYear != null) 'FD $foundedYear',
      if (teamType != null && teamType!.isNotEmpty)
        teamType!.replaceAll('_', '-'),
    ];
    return parts.join(' · ');
  }

  @override
  List<Object?> get props => [
        teamId,
        name,
        score,
        logoUrl,
        logoMonogram,
        primaryColor,
        secondaryColor,
        isVerified,
        distanceKm,
        foundedYear,
        teamType,
      ];
}
