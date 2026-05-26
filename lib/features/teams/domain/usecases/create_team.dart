import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';
import '../value_objects/team_name.dart';

/// Validate the team-create inputs and persist a new team.
class CreateTeam implements UseCase<Team, CreateTeamParams> {
  const CreateTeam(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Team>> call(CreateTeamParams p) {
    return TeamName.create(p.name).fold(
      (f) async => Left(f),
      (name) => _repo.createTeam(
        name: name,
        type: p.type,
        privacy: p.privacy,
        description: _blankToNull(p.description),
        homeGround: _blankToNull(p.homeGround),
        city: _blankToNull(p.city),
        foundedYear: p.foundedYear,
        primaryColor: p.primaryColor,
        secondaryColor: p.secondaryColor,
        tagline: _blankToNull(p.tagline),
        logoMonogram: _blankToNull(p.logoMonogram),
      ),
    );
  }

  String? _blankToNull(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}

class CreateTeamParams {
  const CreateTeamParams({
    required this.name,
    required this.type,
    this.privacy = TeamPrivacy.public,
    this.description,
    this.homeGround,
    this.city,
    this.foundedYear,
    this.primaryColor,
    this.secondaryColor,
    this.tagline,
    this.logoMonogram,
  });

  final String name;
  final TeamType type;
  final TeamPrivacy privacy;
  final String? description;
  final String? homeGround;
  final String? city;
  final int? foundedYear;
  final String? primaryColor;
  final String? secondaryColor;

  /// Optional short tagline (≤60 chars).
  final String? tagline;

  /// Optional 1–3 letter monogram override. Null = server-side / UI
  /// auto-derive from the team name.
  final String? logoMonogram;
}
