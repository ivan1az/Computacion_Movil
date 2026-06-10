import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseServicio {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> guardarPuntuacion(
    String nombre,
    int piezas,
    int movimientos,
  ) async {
    await _db.ref('puntuaciones').push().set({
      'nombre': nombre,
      'piezas': piezas,
      'movimientos': movimientos,
      'fecha': DateTime.now().toIso8601String(),
    });

    await _analytics.logEvent(
      name: 'partida_terminada',
      parameters: {
        'nombre': nombre,
        'piezas_restantes': piezas,
        'movimientos': movimientos,
      },
    );
  }

  Stream<List<Map<String, dynamic>>> getPuntuaciones() {
    return _db.ref('puntuaciones').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final lista = data.entries.map((e) {
        final val = e.value as Map<dynamic, dynamic>;
        return <String, dynamic>{
          'nombre': val['nombre'] ?? '',
          'piezas': val['piezas'] ?? 0,
          'movimientos': val['movimientos'] ?? 0,
          'fecha': val['fecha'] ?? '',
        };
      }).toList();

      lista.sort((a, b) => (a['piezas'] as int).compareTo(b['piezas'] as int));
      return lista;
    });
  }

  Future<void> logInicioPartida(String nombre) async {
    await _analytics.logEvent(
      name: 'partida_iniciada',
      parameters: {'nombre': nombre},
    );
  }

  Future<void> logDeshacer() async {
    await _analytics.logEvent(name: 'deshacer_movimiento');
  }

  Future<void> logSugerencia() async {
    await _analytics.logEvent(name: 'sugerencia_pedida');
  }
}
