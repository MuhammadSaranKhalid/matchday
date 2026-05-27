import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team.dart';
import '../repositories/teams_repository.dart';

/// Uploads a team's logo to Supabase Storage and patches the team row's
/// `logo_url`. Returns the public URL.
class UploadTeamLogo implements UseCase<String, UploadTeamLogoParams> {
  const UploadTeamLogo(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, String>> call(UploadTeamLogoParams p) =>
      _repo.uploadTeamLogo(
        teamId: p.teamId,
        bytes: p.bytes,
        extension: p.extension,
      );
}

class UploadTeamLogoParams {
  const UploadTeamLogoParams({
    required this.teamId,
    required this.bytes,
    required this.extension,
  });
  final TeamId teamId;
  final List<int> bytes;
  final String extension;
}
