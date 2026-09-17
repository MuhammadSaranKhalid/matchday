import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/place_facet.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_claim_request.dart';
import '../../domain/entities/team_invite.dart';
import '../../domain/entities/team_join_request.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/entities/team_search_result.dart';
import '../../domain/entities/user_team_affiliation.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/value_objects/jersey_number.dart';
import '../../domain/value_objects/player_display_name.dart';
import '../../domain/value_objects/team_name.dart';
import '../datasources/teams_remote_datasource.dart';
import '../models/team_member_dto.dart';

/// Online-only teams repository. Reads stream directly from Supabase realtime;
/// writes go straight to the server. The only place remote exceptions become
/// [Failure]s.
class TeamsRepositoryImpl implements TeamsRepository {
  TeamsRepositoryImpl({
    required TeamsRemoteDataSource remote,
    Uuid? uuid,
  })  : _remote = remote,
        _uuid = uuid ?? const Uuid();

  final TeamsRemoteDataSource _remote;
  final Uuid _uuid;

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Team>> watchMyTeams(String userId) => Rx.combineLatest2(
        _remote.watchTeams(),
        _remote.watchMembers(),
        (teams, members) {
          final myMemberTeamIds = members
              .where((m) => m.userId == userId)
              .map((m) => m.teamId)
              .toSet();

          // Staff hold a roster row now (the owner's is created by a trigger),
          // so membership alone is the whole test — the owner/manager clauses
          // that used to sit here were dropped 2026-09-10.
          final mine = teams
              .map((d) => d.toEntity())
              .where((t) => myMemberTeamIds.contains(t.id.value))
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return mine;
        },
      );

  @override
  Stream<Map<String, MemberRole>> watchMyTeamRoles(String userId) =>
      Rx.combineLatest2(
        _remote.watchMembers(),
        _remote.watchMemberRoles(),
        (members, rolesByMembership) {
          // A realtime stream cannot join, so roles arrive separately and are
          // stitched here. Their absence means "no roles loaded yet", never
          // "holds nothing" — so an empty set yields no entry at all rather
          // than a member who looks demoted.
          final out = <String, MemberRole>{};
          for (final m in members) {
            if (m.userId != userId) continue;
            final keys = rolesByMembership[m.membershipId];
            if (keys == null || keys.isEmpty) continue;
            out[m.teamId] = m.toEntity(roles: keys).topRole;
          }
          return out;
        },
      );

  @override
  Stream<List<Team>> watchAllTeams() => _remote.watchTeams().map((dtos) {
        final all = dtos.map((d) => d.toEntity()).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return all;
      });

  @override
  Stream<Team?> watchTeam(TeamId id) => _remote.watchTeams().map((dtos) {
        for (final d in dtos) {
          if (d.teamId == id.value) return d.toEntity();
        }
        return null;
      });

  @override
  Future<Either<Failure, Team?>> getTeam(TeamId id) async {
    try {
      final dtos = await _remote.listTeams();
      for (final d in dtos) {
        if (d.teamId == id.value) return Right(d.toEntity());
      }
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<RosterMember>> watchRoster(TeamId teamId) {
    return Rx.combineLatest2(
      _remote.watchMembers(),
      _remote.watchMemberRoles(),
      (List<TeamMemberDto> m, Map<String, Set<String>> r) => (m, r),
    ).asyncMap((pair) async {
      final (memberDtos, rolesByMembership) = pair;
      final teamMembers =
          memberDtos.where((m) => m.teamId == teamId.value).toList();

      final userIds = teamMembers
          .map((m) => m.userId)
          .whereType<String>()
          .toSet()
          .toList();
      final unclaimedIds = teamMembers
          .map((m) => m.unclaimedId)
          .whereType<String>()
          .toSet()
          .toList();

      final profilesById = await _remote.getProfilesByIds(userIds);
      final unclaimedById = await _remote.getUnclaimedByIds(unclaimedIds);

      final roster = teamMembers
          .map((m) {
            String displayName = 'Unknown player';
            String? username;
            String? profilePhotoUrl;
            String? phoneNumber;
            if (m.userId != null) {
              final p = profilesById[m.userId];
              displayName = p?['display_name'] as String? ??
                  p?['username'] as String? ??
                  'Verified Member';
              username = p?['username'] as String?;
              profilePhotoUrl = p?['profile_photo_url'] as String?;
            } else if (m.unclaimedId != null) {
              final u = unclaimedById[m.unclaimedId];
              displayName = u?.displayName ?? 'Offline Player';
              phoneNumber = u?.phoneNumber;
            }
            return RosterMember(
              member: m.toEntity(
                roles: rolesByMembership[m.membershipId] ?? const <String>{},
              ),
              displayName: displayName,
              username: username,
              profilePhotoUrl: profilePhotoUrl,
              phoneNumber: phoneNumber,
            );
          })
          .toList()
        ..sort((a, b) => a.member.joinedAt.compareTo(b.member.joinedAt));
      return roster;
    });
  }

  @override
  Stream<List<UserTeamAffiliation>> watchUserAffiliatedTeams(String userId) {
    return Rx.combineLatest3(
      _remote.watchTeams(),
      _remote.watchMembers(),
      _remote.watchMemberRoles(),
      (teams, members, rolesByMembership) {
        final List<UserTeamAffiliation> result = [];
        final myMemberships = members.where((m) => m.userId == userId).toList();
        final memberByTeamId = {for (final m in myMemberships) m.teamId: m};

        for (final t in teams) {
          final member = memberByTeamId[t.teamId];

          if (member != null) {
            // 2026-09-10: this used to compare raw strings and derive the role
            // from two sources, which is why an OWNER and a roster captain both
            // rendered "CAPTAIN". One enum, one label.
            final role = member
                .toEntity(roles: rolesByMembership[member.membershipId] ?? const {})
                .topRole;
            final isCaptain = role.hasMatchAuthority;
            final roleStr = role.label;

            result.add(
              UserTeamAffiliation(
                teamId: t.teamId,
                teamName: t.teamName,
                logoMonogram: t.logoMonogram ??
                    (t.teamName.isNotEmpty ? t.teamName[0].toUpperCase() : 'T'),
                logoUrl: t.logoUrl,
                primaryColor: t.teamColors?['primary'] as String?,
                role: roleStr,
                isCaptain: isCaptain,
              ),
            );
          }
        }
        return result;
      },
    );
  }

  @override
  Future<Either<Failure, List<TeamInvite>>> getTeamPendingInvites(
      String teamId) async {
    try {
      final rows = await _remote.getTeamInvites(teamId);
      final invites = rows.map((row) {
        final invitee = row['invitee'] as Map<String, dynamic>?;
        return TeamInvite(
          inviteId: row['invite_id'] as String,
          teamId: row['team_id'] as String,
          inviteeId: row['invitee_id'] as String,
          invitedBy: row['invited_by'] as String,
          role: MemberRole.fromWire(row['role'] as String?),
          status: row['status'] as String? ?? 'pending',
          createdAt: DateTime.parse(row['created_at'] as String),
          message: row['message'] as String?,
          jerseyNumber: row['jersey_number'] as int?,
          inviteeName:
              invitee?['display_name'] as String? ?? invitee?['username'] as String?,
          inviteeUsername: invitee?['username'] as String?,
          inviteePhotoUrl: invitee?['profile_photo_url'] as String?,
        );
      }).toList();
      return Right(invites);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TeamInvite?>> getMyPendingInviteForTeam(
      String teamId) async {
    try {
      final row = await _remote.getMyPendingInviteForTeam(teamId);
      if (row == null) return const Right(null);
      final inviter = row['inviter'] as Map<String, dynamic>?;
      return Right(TeamInvite(
        inviteId: row['invite_id'] as String,
        teamId: row['team_id'] as String,
        inviteeId: row['invitee_id'] as String,
        invitedBy: row['invited_by'] as String,
        role: MemberRole.fromWire(row['role'] as String?),
        status: row['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(row['created_at'] as String),
        message: row['message'] as String?,
        jerseyNumber: row['jersey_number'] as int?,
        inviterName: inviter?['display_name'] as String? ??
            inviter?['username'] as String?,
        inviterUsername: inviter?['username'] as String?,
      ));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptTeamInvite(String inviteId) async {
    try {
      await _remote.acceptTeamInvite(inviteId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> declineTeamInvite(String inviteId) async {
    try {
      await _remote.declineTeamInvite(inviteId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TeamClaimRequest>>> getTeamPendingClaimRequests(
      String teamId) async {
    try {
      final rows = await _remote.getClaimRequests(teamId);
      final requests = rows.map((row) {
        final unclaimed = row['unclaimed'] as Map<String, dynamic>?;
        final requester = row['requester'] as Map<String, dynamic>?;
        return TeamClaimRequest(
          requestId: row['request_id'] as String,
          unclaimedId: row['unclaimed_id'] as String,
          requesterId: row['requester_id'] as String,
          status: row['status'] as String? ?? 'pending',
          createdAt: DateTime.parse(row['created_at'] as String),
          message: row['message'] as String?,
          unclaimedPlayerName: unclaimed?['display_name'] as String?,
          unclaimedJerseyNumber: unclaimed?['jersey_number'] as int?,
          requesterName:
              requester?['display_name'] as String? ?? requester?['username'] as String?,
          requesterUsername: requester?['username'] as String?,
          requesterPhotoUrl: requester?['profile_photo_url'] as String?,
        );
      }).toList();
      return Right(requests);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TeamJoinRequest>>> getTeamPendingJoinRequests(
      String teamId) async {
    try {
      final rows = await _remote.getTeamJoinRequests(teamId);
      final requests = rows.map((row) {
        final applicant = row['applicant'] as Map<String, dynamic>?;
        return TeamJoinRequest(
          requestId: row['request_id'] as String,
          teamId: row['team_id'] as String,
          applicantId: row['applicant_id'] as String,
          role: MemberRole.fromWire(row['role'] as String?),
          status: row['status'] as String? ?? 'pending',
          createdAt: DateTime.parse(row['created_at'] as String),
          message: row['message'] as String?,
          applicantName:
              applicant?['display_name'] as String? ?? applicant?['username'] as String?,
          applicantUsername: applicant?['username'] as String?,
          applicantPhotoUrl: applicant?['profile_photo_url'] as String?,
        );
      }).toList();
      return Right(requests);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Team>> createTeam({
    required TeamName name,
    required TeamType type,
    TeamPrivacy privacy = TeamPrivacy.public,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    CrestKind crestKind = CrestKind.monogram,
    String? label,
    String? district,
    String? province,
    String? postcode,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
  }) async {
    try {
      final dto = await _remote.createTeam({
        'id': _uuid.v4(),
        'team_name': name.value,
        'team_type': type.wire,
        'privacy': privacy.wire,
        'description': description,
        'home_ground': homeGround,
        'city': city,
        'founded_year': foundedYear,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'tagline': tagline,
        'logo_monogram': logoMonogram,
        'crest_kind': crestKind.name,
        'label': label,
        'district': district,
        'province': province,
        'postcode': postcode,
        'place_id': placeId,
        'lat': latitude,
        'lng': longitude,
        'country_code': countryCode,
      });
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Team>> updateTeam({
    required TeamId teamId,
    TeamName? name,
    TeamType? type,
    TeamPrivacy? privacy,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    String? district,
    String? province,
    String? postcode,
    String? countryCode,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['team_name'] = name.value;
      if (type != null) payload['team_type'] = type.wire;
      if (privacy != null) payload['privacy'] = privacy.wire;
      if (description != null) payload['description'] = description;
      if (homeGround != null) payload['home_ground'] = homeGround;
      if (city != null) payload['city'] = city;
      if (foundedYear != null) payload['founded_year'] = foundedYear;
      if (primaryColor != null) payload['primary_color'] = primaryColor;
      if (secondaryColor != null) payload['secondary_color'] = secondaryColor;
      if (tagline != null) payload['tagline'] = tagline;
      if (logoMonogram != null) payload['logo_monogram'] = logoMonogram;
      if (district != null) payload['district'] = district;
      if (province != null) payload['province'] = province;
      if (postcode != null) payload['postcode'] = postcode;
      if (countryCode != null) payload['country_code'] = countryCode;

      final dto = await _remote.updateTeam(teamId.value, payload);
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Team>> setTeamStatus({
    required TeamId teamId,
    required TeamStatus status,
  }) async {
    try {
      final dto = await _remote.updateTeam(teamId.value, {
        'status': status.wire,
      });
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> leaveTeam(MembershipId membershipId) async {
    try {
      await _remote.leaveTeam(membershipId.value);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadTeamLogo({
    required TeamId teamId,
    required List<int> bytes,
    required String extension,
  }) async {
    try {
      final url = await _remote.uploadTeamLogo(
        teamId: teamId.value,
        bytes: bytes,
        extension: extension,
      );
      return Right(url);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addUnclaimedPlayer({
    required TeamId teamId,
    required PlayerDisplayName displayName,
    String? phoneNumber,
    JerseyNumber? jerseyNumber,
    PlayingRole? playingRole,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
  }) async {
    try {
      final profile = <String, dynamic>{
        if (playingRole != null) 'playing_role': playingRole.wire,
        if (battingStyle != null) 'batting_style': battingStyle.wire,
        if (bowlingStyle != null) 'bowling_style': bowlingStyle.wire,
      };
      await _remote.addUnclaimedTeamMember(
        teamId: teamId.value,
        displayName: displayName.value,
        phoneNumber: phoneNumber?.trim(),
        jerseyNumber: jerseyNumber?.value,
        playerProfile: profile,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addRegisteredPlayer({
    required TeamId teamId,
    required String userId,
    JerseyNumber? jerseyNumber,
    MemberRole role = MemberRole.player,
  }) async {
    try {
      await _remote.createMember({
        'id': _uuid.v4(),
        'team_id': teamId.value,
        'player_id': userId,
        'player_type': PlayerType.claimed.wire,
        'role': role.wire,
        'jersey_number': jerseyNumber?.value,
      });
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers(
      String query) async {
    try {
      final results = await _remote.searchUsers(query);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember(MembershipId id) async {
    try {
      await _remote.deleteMember(id.value);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setJerseyNumber(
    MembershipId id,
    JerseyNumber? jersey,
  ) async {
    try {
      // Server's partial-unique index is the authoritative check; the remote
      // translates code 23505 to "That jersey number is already taken".
      await _remote.updateMember(id.value, {
        'jersey_number': jersey?.value,
      });
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setMemberRole(
    MembershipId id,
    MemberRole role,
  ) async {
    try {
      // 2026-09-10: this used to read the whole roster, demote the incumbent
      // captain, then promote — three round trips, no transaction, and a race
      // where two concurrent promotions both "won". `set_team_member_role`
      // does the swap in one statement, and enforces the rule the client
      // cannot ("never grant a rung at or above your own"), so a 42501 here is
      // a real authorization answer rather than a guess.
      await _remote.setMemberRole(id.value, role.wire);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> transferOwnership(
    TeamId teamId,
    String newOwnerId,
  ) async {
    try {
      await _remote.transferOwnership(teamId.value, newOwnerId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendTeamInvite({
    required String teamId,
    required String inviteeId,
    String? message,
    MemberRole role = MemberRole.player,
    int? jerseyNumber,
  }) async {
    try {
      await _remote.sendTeamInvite(
        teamId: teamId,
        inviteeId: inviteeId,
        message: message,
        role: role.wire,
        jerseyNumber: jerseyNumber,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelTeamInvite(String inviteId) async {
    try {
      await _remote.cancelTeamInvite(inviteId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptClaimRequest(String requestId) async {
    try {
      await _remote.approveClaimRequest(requestId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> declineClaimRequest(String requestId) async {
    try {
      await _remote.rejectClaimRequest(requestId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestToJoinTeam({
    required String teamId,
    MemberRole role = MemberRole.player,
    String? message,
  }) async {
    try {
      await _remote.requestToJoinTeam(
        teamId,
        role: role.wire,
        message: message,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptJoinRequest(String requestId) async {
    try {
      await _remote.acceptTeamJoinRequest(requestId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> declineJoinRequest(String requestId) async {
    try {
      await _remote.declineTeamJoinRequest(requestId);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Search & discovery ────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TeamSearchResult>>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    double? scaleKm,
    String? countryCode,
    int? limit,
  }) async {
    try {
      final dtos = await _remote.searchTeams(
        query: query,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        scaleKm: scaleKm,
        countryCode: countryCode,
        limit: limit,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlaceFacet>>> teamPlaceFacets({
    String? countryCode,
  }) async {
    try {
      final dtos = await _remote.teamPlaceFacets(countryCode: countryCode);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
