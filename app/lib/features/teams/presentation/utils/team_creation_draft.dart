bool hasTeamCreationDraft(Map<String, dynamic>? draft) =>
    (draft?['name'] as String? ?? '').trim().isNotEmpty ||
    (draft?['city'] as String? ?? '').trim().isNotEmpty;
