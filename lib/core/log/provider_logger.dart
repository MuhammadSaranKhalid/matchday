import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ck_log.dart';

/// Logs provider lifecycle so state transitions are visible without a
/// debugger attached.
///
/// Riverpod is where the match-start flow's truth lives — a phase change is a
/// provider update, and a reconnect is a provider rebuild — so watching the
/// container is the cheapest way to see the whole machine move.
///
/// Unfiltered this is far too noisy to read, so by default only providers
/// whose name matches [nameFilter] are reported. The default set is the
/// match-start graph.
final class CkProviderLogger extends ProviderObserver {
  CkProviderLogger({this.nameFilter = defaultFilter});

  /// Substrings of provider names worth reporting.
  final List<String> nameFilter;

  static const defaultFilter = <String>[
    'matchStart',
    'liveMatch',
    'liveInningsState',
    'matchPlayers',
    'appResumeCount',
  ];

  bool _wanted(ProviderObserverContext context) {
    final name = context.provider.name;
    if (name == null) return false;
    return nameFilter.any(name.contains);
  }

  /// Providers are keyed by family argument, so include it — otherwise three
  /// concurrent matches produce indistinguishable lines.
  String _label(ProviderObserverContext context) {
    final name = context.provider.name ?? context.provider.runtimeType.toString();
    final arg = context.provider.argument;
    return arg == null ? name : '$name(${CkLog.short(arg)})';
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!_wanted(context)) return;
    CkLog.write(
      CkLogChannel.providers,
      'created',
      data: {'provider': _label(context), 'value': _summarise(value)},
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!_wanted(context)) return;
    final before = _summarise(previousValue);
    final after = _summarise(newValue);
    if (before == after) return; // identical renders add nothing
    CkLog.write(
      CkLogChannel.providers,
      'updated',
      data: {'provider': _label(context), 'from': before, 'to': after},
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!_wanted(context)) return;
    CkLog.warn(
      CkLogChannel.providers,
      'failed',
      data: {'provider': _label(context)},
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (!_wanted(context)) return;
    CkLog.write(
      CkLogChannel.providers,
      'disposed',
      data: {'provider': _label(context)},
    );
  }

  /// Values are arbitrary objects; print something short and comparable
  /// rather than a wall of `toString`.
  static String _summarise(Object? value) => switch (value) {
        null => 'null',
        AsyncLoading() => 'loading',
        AsyncError(:final error) => 'error(${error.runtimeType})',
        AsyncData(:final value) => _summarise(value),
        List<Object?>(:final length) => 'list[$length]',
        _ => _clip(value.toString()),
      };

  static String _clip(String s) => s.length <= 80 ? s : '${s.substring(0, 77)}…';
}
