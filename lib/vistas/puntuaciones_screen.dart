import 'package:flutter/material.dart';
import '../servicios/firebase_servicio.dart';

// VISTA: PuntuacionesScreen
// Muestra la tabla de puntuaciones obtenida de Firebase en tiempo real.
class PuntuacionesScreen extends StatelessWidget {
  const PuntuacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servicio = FirebaseServicio();

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Puntuaciones'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Stream en tiempo real desde Firebase
        stream: servicio.getPuntuaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay puntuaciones aún',
                  style: TextStyle(color: Colors.white54)),
            );
          }

          final puntuaciones = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: puntuaciones.length,
            itemBuilder: (context, index) {
              final p = puntuaciones[index];
              // Medalla para los primeros tres lugares
              String medalla = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}.';

              return Card(
                color: const Color(0xFF283593),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(medalla, style: const TextStyle(fontSize: 24)),
                  title: Text(p['nombre'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${p['movimientos']} movimientos',
                      style: const TextStyle(color: Colors.white54)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${p['piezas']}',
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text('piezas',
                          style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
