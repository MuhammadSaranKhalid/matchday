import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/repositories/tournament_artwork_picker.dart';
import 'tournament_artwork_processor.dart';
import 'tournaments_remote_datasource.dart';

part 'tournaments_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
TournamentsRemoteDataSource tournamentsRemoteDataSource(Ref ref) =>
    TournamentsRemoteDataSource(ref.watch(supabaseClientProvider));

/// Returns the abstract type: the wizard and settings screen depend on the
/// contract, not on the image_picker/cropper stack behind it.
@Riverpod(keepAlive: true)
TournamentArtworkPicker tournamentArtworkPicker(Ref ref) =>
    const TournamentArtworkProcessor();
