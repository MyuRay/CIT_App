import 'dart:async';

import 'package:flutter/material.dart';

/// Paint the native launch artwork while platform services initialize.
class AppStartupHost extends StatefulWidget {
  const AppStartupHost({super.key, required this.initialize});
  final Future<Widget> Function() initialize;

  @override
  State<AppStartupHost> createState() => _AppStartupHostState();
}

class _AppStartupHostState extends State<AppStartupHost> {
  late Future<Widget> _initialization;
  Timer? _loadingHintTimer;
  bool _showLoadingHint = false;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<Widget> _initialize() {
    _loadingHintTimer?.cancel();
    _showLoadingHint = false;
    _loadingHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showLoadingHint = true);
    });
    return Future<Widget>.sync(widget.initialize).whenComplete(() {
      _loadingHintTimer?.cancel();
    });
  }

  void _retry() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  void dispose() {
    _loadingHintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _initialization,
    builder: (context, snapshot) {
      final reduceMotion =
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations;
      return AnimatedSwitcher(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child:
            snapshot.hasData
                ? KeyedSubtree(
                  key: const ValueKey('initialized-app'),
                  child: snapshot.requireData,
                )
                : MaterialApp(
                  key: const ValueKey('startup-splash'),
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    brightness: Brightness.dark,
                    scaffoldBackgroundColor: const Color(0xFF16856B),
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: const Color(0xFF16856B),
                      brightness: Brightness.dark,
                    ),
                  ),
                  home: Scaffold(
                    body: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/icons/app_splash_icon.png',
                            width: 112,
                            height: 112,
                            fit: BoxFit.contain,
                            semanticLabel: 'CIT App',
                          ),
                        ),
                        if (snapshot.hasError || _showLoadingHint)
                          Positioned.fill(
                            child: SafeArea(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 320,
                                    ),
                                    child:
                                        snapshot.hasError
                                            ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '起動できませんでした。\n通信環境を確認して再試行してください。',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                FilledButton(
                                                  onPressed: _retry,
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        const Color(0xFF16856B),
                                                  ),
                                                  child: const Text('再試行'),
                                                ),
                                              ],
                                            )
                                            : Semantics(
                                              label: 'アプリを起動しています',
                                              child: const SizedBox.square(
                                                dimension: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white70,
                                                    ),
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      );
    },
  );
}
