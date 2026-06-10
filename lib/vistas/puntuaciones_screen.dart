import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/juego_viewmodel.dart';

class PuntuacionesScreen extends StatelessWidget {
  const PuntuacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final puntuaciones = context.watch<JuegoViewModel>().puntuaciones;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Puntuaciones'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: puntuaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay puntuaciones aún',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _EntradaPuntuacion(
                entrada: snapshot.data![index],
                posicion: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _EntradaPuntuacion extends StatelessWidget {
  const _EntradaPuntuacion({required this.entrada, required this.posicion});

  final Map<String, dynamic> entrada;
  final int posicion;

  String get _medalla {
    const medallas = ['🥇', '🥈', '🥉'];
    return posicion < medallas.length ? medallas[posicion] : '${posicion + 1}.';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF283593),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(_medalla, style: const TextStyle(fontSize: 24)),
        title: Text(
          entrada['nombre'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${entrada['movimientos']} movimientos',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${entrada['piezas']}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'piezas',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
