import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'viewmodels/juego_viewmodel.dart';
import 'vistas/inicio_screen.dart';
import 'vistas/puntuaciones_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JuegoViewModel()),
      ],
      child: const ComeSoloApp(),
    ),
  );
}

class ComeSoloApp extends StatelessWidget {
  const ComeSoloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Come Solo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const InicioScreen(),
      routes: {
        '/puntuaciones': (_) => const PuntuacionesScreen(),
      },
    );
  }
}
