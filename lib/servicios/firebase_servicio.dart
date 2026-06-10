import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// SERVICIO: FirebaseServicio
// Maneja toda la comunicación con Firebase.
// El ViewModel usa este servicio; nunca habla directo con Firebase.
class FirebaseServicio {

  // Referencia a la base de datos en tiempo real
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Analytics para registrar eventos del juego
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Guarda la puntuación del jugador en Firebase
  // La puntuación es el número de piezas restantes (menos = mejor)
  Future<void> guardarPuntuacion(String nombre, int piezas, int movimientos) async {
    final ref = _db.ref('puntuaciones').push();
    await ref.set({
      'nombre': nombre,
      'piezas': piezas,
      'movimientos': movimientos,
      'fecha': DateTime.now().toIso8601String(),
    });

    // Registra el evento en Analytics
    await _analytics.logEvent(
      name: 'partida_terminada',
      parameters: {
        'nombre': nombre,
        'piezas_restantes': piezas,
        'movimientos': movimientos,
      },
    );
  }

  // Obtiene todas las puntuaciones ordenadas por piezas (menor primero)
  Stream<List<Map<String, dynamic>>> getPuntuaciones() {
    return _db.ref('puntuaciones').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      List<Map<String, dynamic>> lista = data.entries.map((e) {
        final val = e.value as Map<dynamic, dynamic>;
        return {
          'nombre': val['nombre'] ?? '',
          'piezas': val['piezas'] ?? 0,
          'movimientos': val['movimientos'] ?? 0,
          'fecha': val['fecha'] ?? '',
        };
      }).toList();

      // Ordena por piezas restantes (menor = mejor)
      lista.sort((a, b) => (a['piezas'] as int).compareTo(b['piezas'] as int));
      return lista;
    });
  }

  // Registra cuando el jugador inicia una partida
  Future<void> logInicioPartida(String nombre) async {
    await _analytics.logEvent(
      name: 'partida_iniciada',
      parameters: {'nombre': nombre},
    );
  }

  // Registra cuando el jugador deshace un movimiento (con el sensor)
  Future<void> logDeshacer() async {
    await _analytics.logEvent(name: 'deshacer_movimiento');
  }

  // Registra cuando el jugador pide una sugerencia
  Future<void> logSugerencia() async {
    await _analytics.logEvent(name: 'sugerencia_pedida');
  }
}
