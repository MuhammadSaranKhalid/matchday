import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/draw/draw_plan.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/ground.dart';
import '../../domain/entities/match_official.dart';
import '../../domain/entities/scorer_candidate.dart';
import '../../domain/entities/tournament_awards.dart';
import '../../domain/entities/tournament_fee_entry.dart';
import '../../domain/entities/tournament_leader.dart';
import '../../domain/entities/tournament_organizer.dart';
import '../../domain/ops/revised_target.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../models/match_official_dto.dart';
import '../models/ground_dto.dart';
import '../models/tournament_dto.dart';
import '../models/tournament_fee_entry_dto.dart';
import '../models/tournament_leader_dto.dart';
import '../models/tournament_fixture_dto.dart';
import '../models/tournament_live_match_dto.dart';
import '../models/tournament_registration_dto.dart';
import '../models/tournament_standing_dto.dart';

/// Direct PostgREST + Realtime client for Tournaments tables.
class TournamentsRemoteDataSource {
  TournamentsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _tournamentsTable = 'tournaments';
  static const _registrationsTable = 'tournament_teams';
  static const _standingsTable = 'tournament_standings';
  static const _cricketMatchesView = 'cricket_match_details';
  static const _followsTable = 'follows';
  static const _groundsTable = 'grounds';
  static const _bannerBucket = 'tournament-banners';
  static const _logoBucket = 'tournament-logos';
  static const _tournamentGroundsTable = 'tournament_grounds';

  String _requireUid() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw const UnauthorizedException('Must be signed in');
    return uid;
  }

  Future<Map<String, dynamic>> _matchAction(
    String action,
    Map<String, dynamic> params,
  ) async {
    try {
      final res = await _supabase.functions.invoke(
        'cricket-match-action',
        body: {
          'action': action,
          ...params,
        },
      );

      final data = res.data;
      if (data is Map && data['ok'] == true) {
        return Map<String, dynamic>.from(data);
      }

      throw ServerException(
        data is Map
            ? (data['error']?['message']?.toString() ??
                'Tournament match action failed')
            : 'Tournament match action failed',
      );
    } on FunctionException catch (e) {
      String? message;
      final details = e.details;

      if (details is Map && details['error'] is Map) {
        message = (details['error'] as Map)['message']?.toString();
      }

      if (e is FunctionsFetchException) {
        throw NetworkException(
          e.reasonPhrase ?? 'No connection to tournament match service',
        );
      }

      if (e.status == 401 || e.status == 403) {
        throw UnauthorizedException(
          message ?? 'Not allowed to perform this action',
        );
      }

      throw ServerException(
        message ?? 'Tournament match action failed',
        statusCode: e.status,
      );
    }
  }

  // ─── Tournaments ──────────────────────────────────────────────────────────

  Future<TournamentDto> getTournament(String tournamentId) async {
    try {
      final response = await _supabase
          .from(_tournamentsTable)
          .select()
          .eq('tournament_id', tournamentId)
          .single();

      // Counted in its own round-trip rather than as an embedded aggregate.
      // The embed counted every registration regardless of status, so a cup
      // with two teams in and four declined advertised itself as 6/8 full —
      // and disagreed with `search-all`, which has always filtered on
      // `approved`. An embedded filter would have fixed the number but a
      // `!inner` join drops the tournament row entirely when nobody is
      // approved yet, which is every cup on its first day.
      final countRes = await _supabase
          .from(_registrationsTable)
          .select('registration_id')
          .eq('tournament_id', tournamentId)
          .eq('status', 'approved')
          .count(CountOption.exact);

      final copy = Map<String, dynamic>.from(response);
      copy['approved_teams_count'] = countRes.count;

      return TournamentDto.fromJson(copy);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<TournamentDto>> getMyTournaments() async {
    final uid = _requireUid();
    try {
      // 1. Tournaments organized by user
      final organizedRows = await _supabase
          .from(_tournamentsTable)
          .select()
          .or('created_by.eq.$uid,organizers.cs.{$uid}')
          .order('updated_at', ascending: false);

      // 2. Tournaments followed by user
      final followedRows = await _supabase
          .from(_followsTable)
          .select('target_id')
          .eq('follower_id', uid)
          .eq('target_type', 'tournament');

      final followedIds = followedRows
          .map((r) => r['target_id'] as String?)
          .whereType<String>()
          .toList();

      List<Map<String, dynamic>> followedTournaments = [];
      if (followedIds.isNotEmpty) {
        followedTournaments = await _supabase
            .from(_tournamentsTable)
            .select()
            .inFilter('tournament_id', followedIds);
      }

      // Combine and deduplicate
      final seen = <String>{};
      final combined = <TournamentDto>[];

      for (final r in organizedRows) {
        final id = r['tournament_id'] as String;
        if (seen.add(id)) {
          combined.add(TournamentDto.fromJson(r));
        }
      }

      for (final r in followedTournaments) {
        final id = r['tournament_id'] as String;
        if (seen.add(id)) {
          combined.add(TournamentDto.fromJson(r));
        }
      }

      return combined;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<TournamentDto>> getDiscoverTournaments({
    double? latitude,
    double? longitude,
    double? radiusKm,
    TournamentType? type,
    TournamentStatus? status,
    String? city,
  }) async {
    try {
      var query = _supabase
          .from(_tournamentsTable)
          .select()
          .eq('privacy', 'public')
          .neq('status', 'draft');

      if (type != null) {
        query = query.eq('tournament_type', type.wire);
      }

      if (status != null) {
        query = query.eq('status', status.wire);
      }

      final rows = await query.order('start_date', ascending: false).limit(30);
      return rows.map(TournamentDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TournamentDto> createTournament(CreateTournamentParams params) async {
    final uid = _requireUid();
    try {
      final insertData = <String, dynamic>{
        'tournament_name': params.name,
        'tournament_type': params.type.wire,
        'privacy': params.privacy.wire,
        'created_by': uid,
        'organizers': [uid],
        'status': 'draft',
        'format': params.format,
        'rules': params.rules,
        'venues': params.venues.map((v) => v.toJson()).toList(),
        if (params.description != null) 'description': params.description,
        if (params.startDate != null)
          'start_date': params.startDate!.toIso8601String().split('T').first,
        if (params.endDate != null)
          'end_date': params.endDate!.toIso8601String().split('T').first,
        if (params.registrationDeadline != null)
          'registration_deadline':
              params.registrationDeadline!.toIso8601String().split('T').first,
        if (params.prizeDetails != null) 'prize_details': params.prizeDetails,
        if (params.entryFee != null) 'entry_fee': params.entryFee,
        if (params.minTeams != null) 'min_teams': params.minTeams,
        if (params.maxTeams != null) 'max_teams': params.maxTeams,
        if (params.bannerImageUrl != null)
          'banner_image_url': params.bannerImageUrl,
        if (params.logoUrl != null) 'logo_url': params.logoUrl,
      };

      final response = await _supabase
          .from(_tournamentsTable)
          .insert(insertData)
          .select()
          .single();

      final dto = TournamentDto.fromJson(response);

      if (params.groundIds.isNotEmpty) {
        await setTournamentGrounds(
          tournamentId: dto.tournamentId,
          groundIds: params.groundIds,
        );
      }

      return dto;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> updateTournament(
      String tournamentId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from(_tournamentsTable)
          .update(updates)
          .eq('tournament_id', tournamentId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> publishTournament(String tournamentId) async {
    try {
      await _supabase
          .from(_tournamentsTable)
          .update({'status': 'registration'})
          .eq('tournament_id', tournamentId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Cancelling is destructive (artboard 27g): it voids unplayed fixtures,
  /// keeps completed scorecards, and notifies everyone. That is more than a
  /// column write, so it goes through the RPC — which also stores the reason
  /// on `rules` rather than clobbering the tournament's description.
  Future<void> cancelTournament(String tournamentId, String reason) async {
    try {
      await _supabase.rpc<void>(
        'tournament_cancel',
        params: {'p_tournament_id': tournamentId, 'p_reason': reason},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Registrations ────────────────────────────────────────────────────────

  Future<List<TournamentRegistrationDto>> getTournamentRegistrations(
      String tournamentId) async {
    try {
      final rows = await _supabase
          .from(_registrationsTable)
          .select('''
            *,
            teams (
              team_name,
              logo_url,
              logo_monogram,
              team_colors
            ),
            profiles:registered_by (
              display_name
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: true);

      return rows.map(TournamentRegistrationDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TournamentRegistrationDto> registerTeam({
    required String tournamentId,
    required String teamId,
    required List<String> squadPlayerIds,
    String? message,
  }) async {
    final uid = _requireUid();
    try {
      final insertData = {
        'tournament_id': tournamentId,
        'team_id': teamId,
        'registered_by': uid,
        'squad': squadPlayerIds,
        'status': 'pending',
        if (message != null) 'message': message,
      };

      final response = await _supabase
          .from(_registrationsTable)
          .insert(insertData)
          .select('''
            *,
            teams (
              team_name,
              logo_url,
              logo_monogram,
              team_colors
            )
          ''')
          .single();

      return TournamentRegistrationDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> approveRegistration(String registrationId) async {
    try {
      await _supabase.rpc<void>(
        'approve_tournament_registration',
        params: {'p_registration_id': registrationId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> rejectRegistration(
      String registrationId, String reason) async {
    try {
      await _supabase.rpc<void>(
        'reject_tournament_registration',
        params: {
          'p_registration_id': registrationId,
          'p_reason': reason,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> withdrawRegistration(String registrationId) async {
    try {
      await _supabase
          .from(_registrationsTable)
          .update({'status': 'withdrawn'})
          .eq('registration_id', registrationId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> updatePaymentStatus(
      String registrationId, String paymentStatus) async {
    try {
      await _supabase
          .from(_registrationsTable)
          .update({'payment_status': paymentStatus})
          .eq('registration_id', registrationId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> assignTeamGroup(String registrationId, String? groupId) async {
    try {
      await _supabase
          .from(_registrationsTable)
          .update({'group_id': groupId})
          .eq('registration_id', registrationId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> assignMultipleTeamsGroup(
      List<String> registrationIds, String? groupId) async {
    if (registrationIds.isEmpty) return;
    try {
      await _supabase
          .from(_registrationsTable)
          .update({'group_id': groupId})
          .inFilter('registration_id', registrationIds);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> autoDistributeGroups(
      String tournamentId, List<String> groupNames) async {
    if (groupNames.isEmpty) return;
    try {
      final rows = await _supabase
          .from(_registrationsTable)
          .select('registration_id')
          .eq('tournament_id', tournamentId)
          .eq('status', 'approved')
          .order('registered_at', ascending: true);

      for (int i = 0; i < rows.length; i++) {
        final regId = rows[i]['registration_id'] as String;
        final assignedGroup = groupNames[i % groupNames.length];
        await _supabase
            .from(_registrationsTable)
            .update({'group_id': assignedGroup})
            .eq('registration_id', regId);
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Fixtures & Standings ──────────────────────────────────────────────────

  Future<List<Match>> getTournamentFixtures(String tournamentId) async {
    try {
      final rows = await _supabase
          .from(_cricketMatchesView)
          .select()
          .eq('tournament_id', tournamentId)
          .order('bracket_round_number', ascending: true)
          .order('bracket_match_number', ascending: true)
          .order('scheduled_start_time', ascending: true);

      return rows
          .map((r) => TournamentFixtureDto.fromJson(r).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<TournamentStandingDto>> getStandings(String tournamentId) async {
    try {
      final rows = await _supabase
          .from(_standingsTable)
          .select('''
            *,
            teams (
              team_name,
              logo_url,
              logo_monogram,
              team_colors
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('points', ascending: false)
          .order('net_run_rate', ascending: false);

      return rows.map(TournamentStandingDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Stream<List<TournamentStandingDto>> watchStandings(String tournamentId) {
    return _supabase
        .from(_standingsTable)
        .stream(primaryKey: ['tournament_id', 'team_id'])
        .eq('tournament_id', tournamentId)
        .order('points', ascending: false)
        .order('net_run_rate', ascending: false)
        .map((rows) => rows.map(TournamentStandingDto.fromJson).toList());
  }

  /// Publishes the draw.
  ///
  /// Goes through an RPC rather than inserting: `matches` has RLS enabled with
  /// only a SELECT policy, so a client-side insert is rejected — silently, as
  /// far as the organiser could tell. Returns the number of fixtures created.
  ///
  /// The whole plan goes over, unresolved rounds included. Feeder links travel
  /// as the plan's own `slot_id` strings because no match id exists yet; the
  /// RPC mints the ids and resolves them.
  Future<int> generateAndPublishFixtures({
    required String tournamentId,
    required DrawPlan plan,
    List<String> seedOrder = const [],
  }) async {
    try {
      final count = await _supabase.rpc<int>(
        'tournament_generate_fixtures',
        params: {
          'p_tournament_id': tournamentId,
          'p_slots': [
            for (final f in plan.fixtures)
              {
                'slot_id': f.slotId,
                'team_a_id': f.teamAId,
                'team_b_id': f.teamBId,
                'prev_slot_a': f.prevSlotAId,
                'prev_slot_b': f.prevSlotBId,
                'scheduled_start_time':
                    f.scheduledStartTime.toUtc().toIso8601String(),
                'venue': f.venue,
                'round': f.roundLabel,
                'bracket_round_number': f.roundNumber,
                'bracket_match_number': f.matchNumber,
              },
          ],
          'p_seed_order': seedOrder,
        },
      );
      return count;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<TournamentAwards> getSuggestedAwards(String tournamentId) async {
    try {
      final tournament = await getTournament(tournamentId);
      if (tournament.awards.isNotEmpty) {
        return TournamentAwards.fromJson(tournament.awards);
      }
      return const TournamentAwards();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> confirmAwards(
      String tournamentId, TournamentAwards awards) async {
    try {
      await _supabase.rpc<void>(
        'confirm_tournament_awards',
        params: {
          'p_tournament_id': tournamentId,
          'p_awards': awards.toJson(),
        },
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Registrations belonging to teams the caller manages, newest first, with
  /// the tournament embedded.
  ///
  /// This is what makes the hub's "Playing" bucket real: a tournament is one
  /// you play in when a team you manage has a registration in it. Deriving it
  /// from the team side keeps it to a single query and needs no new RPC.
  Future<List<({TournamentDto tournament, TournamentRegistrationDto registration})>>
      getMyRegistrations(List<String> teamIds) async {
    if (teamIds.isEmpty) return [];
    try {
      final rows = await _supabase
          .from(_registrationsTable)
          .select('''
            *,
            teams (
              team_name,
              logo_url,
              logo_monogram,
              team_colors
            ),
            tournaments (*)
          ''')
          .inFilter('team_id', teamIds)
          .order('registered_at', ascending: false);

      final out =
          <({TournamentDto tournament, TournamentRegistrationDto registration})>[];
      for (final row in rows) {
        final embedded = row['tournaments'];
        if (embedded is! Map<String, dynamic>) continue;
        out.add((
          tournament: TournamentDto.fromJson(embedded),
          registration: TournamentRegistrationDto.fromJson(row),
        ));
      }
      return out;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Artwork ──────────────────────────────────────────────────────────────

  /// Uploads whichever files are supplied and patches the tournament row with
  /// their public URLs.
  ///
  /// Must run AFTER the tournament row exists: the storage policy authorises
  /// on `is_tournament_organizer(<first path segment>::uuid)`, so the folder
  /// name has to be a tournament the caller already organises. Same ordering
  /// the posts feature uses for `post-media`.
  Future<({String? bannerUrl, String? logoUrl})> uploadArtwork({
    required String tournamentId,
    File? banner,
    File? logo,
  }) async {
    try {
      String? bannerUrl;
      String? logoUrl;

      if (banner != null) {
        bannerUrl = await _uploadOne(
          bucket: _bannerBucket,
          tournamentId: tournamentId,
          file: banner,
          name: 'banner.jpg',
        );
      }
      if (logo != null) {
        logoUrl = await _uploadOne(
          bucket: _logoBucket,
          tournamentId: tournamentId,
          file: logo,
          name: 'logo.jpg',
        );
      }

      if (bannerUrl != null || logoUrl != null) {
        await _supabase.from(_tournamentsTable).update({
          if (bannerUrl != null) 'banner_image_url': bannerUrl,
          if (logoUrl != null) 'logo_url': logoUrl,
        }).eq('tournament_id', tournamentId);
      }

      return (bannerUrl: bannerUrl, logoUrl: logoUrl);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<String> _uploadOne({
    required String bucket,
    required String tournamentId,
    required File file,
    required String name,
  }) async {
    final path = '$tournamentId/$name';
    await _supabase.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    // Bucket is public, so the URL is deterministic. Cache-bust on the
    // timestamp: re-uploading to the same path would otherwise keep serving
    // the previous image from CDN and device caches.
    final base = _supabase.storage.from(bucket).getPublicUrl(path);
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ─── Grounds ──────────────────────────────────────────────────────────────

  /// Ranked by name similarity, then proximity. An empty query lists the
  /// nearest grounds, which is what the picker shows before the user types.
  Future<List<Ground>> searchGrounds({
    String? query,
    double? latitude,
    double? longitude,
    int limit = 12,
  }) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'search_grounds',
        params: {
          'p_query': query,
          'p_lat': latitude,
          'p_lng': longitude,
          'p_limit': limit,
        },
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map((r) => GroundDto.fromJson(r).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<Ground> createGround({
    required String name,
    String? city,
    double? latitude,
    double? longitude,
    GroundSurface? surface,
    bool hasFloodlights = false,
    String? notes,
  }) async {
    final uid = _requireUid();
    try {
      final row = await _supabase
          .from(_groundsTable)
          .insert({
            'name': name,
            'created_by': uid,
            'has_floodlights': hasFloodlights,
            if (surface != null) 'surface': surface.wire,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            'location': {
              if (city != null && city.isNotEmpty) 'city': city,
              if (latitude != null) 'lat': latitude,
              if (longitude != null) 'lng': longitude,
            },
          })
          .select()
          .single();
      return GroundDto.fromJson(row).toEntity();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<Ground>> getTournamentGrounds(String tournamentId) async {
    try {
      final rows = await _supabase
          .from(_tournamentGroundsTable)
          .select('sort_order, grounds(*)')
          .eq('tournament_id', tournamentId)
          .order('sort_order');

      return rows
          .map((r) => r['grounds'])
          .whereType<Map<String, dynamic>>()
          .map((g) => GroundDto.fromJson(g).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Replaces the tournament's ground list, preserving the given order — the
  /// order is what the G1/G2 labels are derived from.
  Future<void> setTournamentGrounds({
    required String tournamentId,
    required List<String> groundIds,
  }) async {
    try {
      await _supabase
          .from(_tournamentGroundsTable)
          .delete()
          .eq('tournament_id', tournamentId);

      if (groundIds.isEmpty) return;

      await _supabase.from(_tournamentGroundsTable).insert([
        for (var i = 0; i < groundIds.length; i++)
          {
            'tournament_id': tournamentId,
            'ground_id': groundIds[i],
            'sort_order': i,
          },
      ]);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Live Ops ─────────────────────────────────────────────────────────────

  Future<List<TournamentLiveMatchDto>> getLiveBoard(String tournamentId) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'tournament_live_board',
        params: {'p_tournament_id': tournamentId},
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(TournamentLiveMatchDto.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> assignScorer({
    required String matchId,
    required String userId,
  }) async {
    try {
      await _supabase.rpc<void>(
        'tournament_assign_scorer',
        params: {'p_match_id': matchId, 'p_user_id': userId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> rescheduleMatch({
    required String matchId,
    required DateTime startTime,
    String? venue,
  }) async {
    await _matchAction('tournament_reschedule_match', {
      'p_match_id': matchId,
      'p_start': startTime.toUtc().toIso8601String(),
      if (venue != null) 'p_venue': venue,
    });
  }

  Future<void> abandonMatch({
    required String matchId,
    required String mode,
    DateTime? rescheduleTo,
    String? reason,
  }) async {
    await _matchAction('tournament_abandon_match', {
      'p_match_id': matchId,
      'p_mode': mode,
      if (rescheduleTo != null)
        'p_reschedule_to': rescheduleTo.toUtc().toIso8601String(),
      if (reason != null) 'p_reason': reason,
    });
  }

  Future<void> declareWalkover({
    required String matchId,
    required String winnerTeamId,
    String? reason,
  }) async {
    await _matchAction('tournament_declare_walkover', {
      'p_match_id': matchId,
      'p_winner_team_id': winnerTeamId,
      if (reason != null) 'p_reason': reason,
    });
  }

  Future<void> overrideResult({
    required String matchId,
    required String winnerTeamId,
    required String reason,
  }) async {
    await _matchAction('tournament_override_result', {
      'p_match_id': matchId,
      'p_winner_team_id': winnerTeamId,
      'p_reason': reason,
    });
  }

  Future<void> setCoOrganizer({
    required String tournamentId,
    required String userId,
    required bool add,
  }) async {
    try {
      await _supabase.rpc<void>(
        'tournament_set_coorganizer',
        params: {
          'p_tournament_id': tournamentId,
          'p_user_id': userId,
          'p_add': add,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<ScorerCandidate>> getScorerCandidates(String tournamentId) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'tournament_scorer_candidates',
        params: {'p_tournament_id': tournamentId},
      );
      return rows.cast<Map<String, dynamic>>().map((r) {
        return ScorerCandidate(
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String? ?? 'Unknown',
          username: r['username'] as String?,
          roleLabel: r['role_label'] as String? ?? 'Team manager',
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<int> sendAnnouncement({
    required String tournamentId,
    required String message,
  }) async {
    try {
      final count = await _supabase.rpc<int>(
        'tournament_announce',
        params: {'p_tournament_id': tournamentId, 'p_message': message},
      );
      return count;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Fee ledger (artboard 24c) ──────────────────────────────────────────────

  Future<List<TournamentFeeEntryDto>> getFeeLedger(String tournamentId) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'tournament_fee_ledger',
        params: {'p_tournament_id': tournamentId},
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(TournamentFeeEntryDto.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> recordPayment({
    required String registrationId,
    required double amountPaid,
    PaymentChannel? channel,
    String? reference,
  }) async {
    try {
      await _supabase.rpc<void>(
        'tournament_record_payment',
        params: {
          'p_registration_id': registrationId,
          'p_amount_paid': amountPaid,
          'p_channel': channel?.wire,
          'p_reference': reference,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Match officials (artboard 27j) ─────────────────────────────────────────

  Future<List<MatchOfficialDto>> getMatchOfficials(String matchId) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'tournament_match_officials',
        params: {'p_match_id': matchId},
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(MatchOfficialDto.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<OfficialCandidateDto>> getOfficialCandidates({
    required String tournamentId,
    required String matchId,
  }) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'tournament_official_candidates',
        params: {'p_tournament_id': tournamentId, 'p_match_id': matchId},
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(OfficialCandidateDto.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> assignOfficial({
    required String matchId,
    required String userId,
    required OfficialRole role,
  }) async {
    try {
      await _supabase.rpc<void>(
        'tournament_assign_official',
        params: {
          'p_match_id': matchId,
          'p_user_id': userId,
          'p_role': role.wire,
        },
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> removeOfficial({
    required String matchId,
    required OfficialRole role,
  }) async {
    try {
      await _supabase.rpc<void>(
        'tournament_remove_official',
        params: {'p_match_id': matchId, 'p_role': role.wire},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Matchday-morning ops (artboards 27k, 27m, 28b, 28c) ────────────────────

  Future<int> autoAssignScorers(String tournamentId) async {
    try {
      return await _supabase.rpc<int>(
        'tournament_auto_assign_scorers',
        params: {'p_tournament_id': tournamentId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Writes down the revision the organiser read back to the captains. Every
  /// number here was computed by [RevisedTargetCalculator]; the RPC stores it.
  Future<void> reviseMatchConditions({
    required String matchId,
    required int revisedOvers,
    required int bowlerQuota,
    int? revisedTarget,
    TargetMethod method = TargetMethod.runRate,
    String? reason,
  }) async {
    await _matchAction(
      'tournament_revise_match_conditions',
      {
        'p_match_id': matchId,
        'p_revised_overs': revisedOvers,
        'p_bowler_quota': bowlerQuota,
        if (revisedTarget != null) 'p_revised_target': revisedTarget,
        'p_method': method.wire,
        if (reason != null) 'p_reason': reason,
      },
    );
  }

  Future<void> triggerSuperOver({
    required String matchId,
    required String batsFirstTeamId,
  }) async {
    await _matchAction('tournament_trigger_super_over', {
      'p_match_id': matchId,
      'p_bats_first_id': batsFirstTeamId,
    });
  }

  // ─── Leaderboards (artboards 10, 11, 15) ────────────────────────────────────

  /// Both boards in one round trip — "Leading the cup" needs the pair, and
  /// two sequential RPCs would make the Overview tab pop in twice.
  Future<TournamentLeaderboards> getLeaderboards(
    String tournamentId, {
    int limit = 5,
  }) async {
    try {
      final results = await Future.wait([
        _supabase.rpc<List<dynamic>>(
          'tournament_batting_leaderboard',
          params: {'p_tournament_id': tournamentId, 'p_limit': limit},
        ),
        _supabase.rpc<List<dynamic>>(
          'tournament_bowling_leaderboard',
          params: {'p_tournament_id': tournamentId, 'p_limit': limit},
        ),
      ]);
      return TournamentLeaderboards(
        batting: results[0]
            .cast<Map<String, dynamic>>()
            .map((r) => TournamentLeaderDto(r, batting: true).toEntity())
            .toList(),
        bowling: results[1]
            .cast<Map<String, dynamic>>()
            .map((r) => TournamentLeaderDto(r, batting: false).toEntity())
            .toList(),
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// The organiser's track record (artboard 09). Null when the cup has no
  /// creator on record — an import, or a deleted account.
  Future<TournamentOrganizer?> getOrganizer(String tournamentId) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'tournament_organizer_profile',
        params: {'p_tournament_id': tournamentId},
      );
      if (rows.isEmpty) return null;
      final r = rows.first as Map<String, dynamic>;
      int asInt(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
      return TournamentOrganizer(
        userId: r['user_id'] as String,
        displayName: r['display_name'] as String? ?? 'Organiser',
        username: r['username'] as String?,
        avatarUrl: r['avatar_url'] as String?,
        city: r['city'] as String?,
        cupsRun: asInt(r['cups_run']),
        firstCupYear:
            r['first_cup_year'] == null ? null : asInt(r['first_cup_year']),
        completedCups: asInt(r['completed_cups']),
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
