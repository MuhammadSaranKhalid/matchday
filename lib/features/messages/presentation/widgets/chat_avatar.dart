import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// One avatar renderer for people, DMs, teams and groups.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.size = 40,
    this.online = false,
    this.backgroundColor = ChatTheme.softSandFill,
    this.foregroundColor = ChatTheme.charcoalInk,
  });

  final String label;
  final String? imageUrl;
  final double size;
  final bool online;
  final Color backgroundColor;
  final Color foregroundColor;

  String get _monogram {
    final pieces = label
        .trim()
        .split(RegExp(r'\s+'))
        .where((piece) => piece.isNotEmpty)
        .take(2)
        .toList();
    if (pieces.isEmpty) return '?';
    return pieces.map((piece) => piece[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: ChatTheme.hairlineSand),
      ),
      child: Text(
        _monogram,
        style: ChatTheme.badge(color: foregroundColor).copyWith(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final cleanUrl = imageUrl?.trim();
    final avatar = cleanUrl == null || cleanUrl.isEmpty
        ? fallback
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: cleanUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
          );

    if (!online) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.26,
            height: size * 0.26,
            decoration: BoxDecoration(
              color: ChatTheme.successMintText,
              shape: BoxShape.circle,
              border: Border.all(color: ChatTheme.pureSurface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
