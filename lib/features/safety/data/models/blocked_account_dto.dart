import '../../domain/entities/blocked_account.dart';
class BlockedAccountDto {
  const BlockedAccountDto(this.id, this.name);
  factory BlockedAccountDto.fromJson(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>?;
    return BlockedAccountDto(row['blocked_id'] as String, profile?['display_name'] as String? ?? 'Player');
  }
  final String id;
  final String name;
  BlockedAccount toEntity() => BlockedAccount(id: id, name: name);
}
