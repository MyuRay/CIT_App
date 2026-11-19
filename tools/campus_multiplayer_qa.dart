import 'package:cit_app/screens/classroom_map/campus_3d_screen.dart';
import 'package:cit_app/widgets/campus_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// QA only: intercept campusGame to the emulator before opening this build.
const qaFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-campus-game-api-key',
  appId: '1:1234567890:web:campus-game-qa',
  messagingSenderId: '1234567890',
  projectId: 'demo-campus-game',
  authDomain: 'demo-campus-game.firebaseapp.com',
  storageBucket: 'demo-campus-game.appspot.com',
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: qaFirebaseOptions);
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator('127.0.0.1', 9198);
    await auth.signInAnonymously();
    runApp(
      MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: const Color(0xff1976d2),
          useMaterial3: true,
        ),
        home: Builder(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Campus multiplayer emulator QA'),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const Campus3dScreen(),
                                ),
                              ),
                          child: const Text('3Dマップを開く'),
                        ),
                        const SizedBox(height: 12),
                        const CampusBusGameButton(),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('QA認証エミュレーターに接続できません。ローカル設定を確認してください。')),
        ),
      ),
    );
  }
}
