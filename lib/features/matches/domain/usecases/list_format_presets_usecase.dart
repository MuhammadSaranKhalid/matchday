import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/format_preset.dart';
import '../repositories/matches_repository.dart';

class ListFormatPresetsUseCase {
  const ListFormatPresetsUseCase(this._repository);

  final MatchesRepository _repository;

  Future<Either<Failure, List<FormatPreset>>> call() {
    return _repository.listFormatPresets();
  }
}
