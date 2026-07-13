import 'dart:async';

import 'package:flutter/material.dart';

import 'app_bootstrap_status.dart';

typedef BootstrapInitializer<T> = Future<T> Function(BuildContext context);
typedef BootstrapReadyBuilder<T> = Widget Function(
    BuildContext context, T data);
typedef BootstrapErrorBuilder = Widget Function(
    BuildContext context, Object error, StackTrace stackTrace);

class AsyncBootstrapGate<T> extends StatefulWidget {
  const AsyncBootstrapGate({
    super.key,
    required this.initializer,
    required this.initializingBuilder,
    required this.readyBuilder,
    required this.failedBuilder,
    this.minimumInitializationDuration = Duration.zero,
  });

  final BootstrapInitializer<T> initializer;
  final WidgetBuilder initializingBuilder;
  final BootstrapReadyBuilder<T> readyBuilder;
  final BootstrapErrorBuilder failedBuilder;
  final Duration minimumInitializationDuration;

  @override
  State<AsyncBootstrapGate<T>> createState() => _AsyncBootstrapGateState<T>();
}

class _AsyncBootstrapGateState<T> extends State<AsyncBootstrapGate<T>> {
  AppBootstrapStatus _status = AppBootstrapStatus.initializing;
  T? _data;
  Object? _error;
  StackTrace? _stackTrace;
  bool _didStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStart) return;
    _didStart = true;
    unawaited(_runBootstrap());
  }

  Future<void> _runBootstrap() async {
    final minimumDurationFuture =
        widget.minimumInitializationDuration > Duration.zero
            ? Future<void>.delayed(widget.minimumInitializationDuration)
            : Future<void>.value();
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        widget.initializer(context),
        minimumDurationFuture,
      ]);
      final data = results.first as T;
      if (!mounted) return;
      setState(() {
        _data = data;
        _status = AppBootstrapStatus.ready;
      });
    } catch (error, stackTrace) {
      await minimumDurationFuture;
      if (!mounted) return;
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
        _status = AppBootstrapStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AppBootstrapStatus.initializing:
        return widget.initializingBuilder(context);
      case AppBootstrapStatus.ready:
        return widget.readyBuilder(context, _data as T);
      case AppBootstrapStatus.failed:
        return widget.failedBuilder(
          context,
          _error!,
          _stackTrace ?? StackTrace.empty,
        );
    }
  }
}
