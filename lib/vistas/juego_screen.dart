import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../viewmodels/juego_viewmodel.dart';
import '../modelo/juego_state.dart';
import '../servicios/firebase_servicio.dart';

// VISTA: JuegoScreen
// Muestra el tablero y los controles del juego.
// No tiene lógica: solo lee del ViewModel y llama sus funciones.
class JuegoScreen extends StatefulWidget {
  final String nombreJugador;
  const JuegoScreen({super.key, required this.nombreJugador});

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  final FirebaseServicio _servicio = FirebaseServicio();
  StreamSubscription? _acelerometroSub;
  bool _gameOverMostrado = false;

  // Umbral de sacudida para activar el deshacer
  // Si la aceleración supera este valor, considera que se agitó
  static const double _umbralSacudida = 20.0;
  DateTime _ultimaSacudida = DateTime.now();

  @override
  void initState() {
    super.initState();
    _iniciarSensor();
    // Registra en Analytics que inició la partida
    _servicio.logInicioPartida(widget.nombreJugador);
  }

  // Inicializa el sensor acelerómetro
  void _iniciarSensor() {
    _acelerometroSub = accelerometerEventStream().listen((event) {
      // Calcula la magnitud total del movimiento
      double magnitud = (event.x.abs() + event.y.abs() + event.z.abs());

      // Solo reacciona si pasó al menos 1 segundo desde la última sacudida
      // para evitar múltiples deshaceres seguidos
      final ahora = DateTime.now();
      if (magnitud > _umbralSacudida &&
          ahora.difference(_ultimaSacudida).inMilliseconds > 1000) {
        _ultimaSacudida = ahora;

        final vm = context.read<JuegoViewModel>();
        if (vm.puedeDeshacer) {
          vm.deshacer();
          _servicio.logDeshacer(); // registra en Analytics
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('↩ Movimiento deshecho (sacudida detectada)'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    // Cancela la escucha del sensor al salir de la pantalla
    _acelerometroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JuegoViewModel>();

    // Detecta cuando el juego termina y muestra el diálogo
    if (vm.estado == EstadoJuego.terminado && !_gameOverMostrado) {
      _gameOverMostrado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarGameOver(vm);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // fondo azul oscuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text('Come Solo - ${widget.nombreJugador}'),
        actions: [
          // Botón de sugerir movimiento
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Sugerir movimiento',
            onPressed: () {
              vm.sugerirMovimiento();
              _servicio.logSugerencia();
            },
          ),
          // Botón de deshacer
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer (o agita el celular)',
            onPressed: vm.puedeDeshacer ? () {
              vm.deshacer();
              _servicio.logDeshacer();
            } : null,
          ),
          // Botón de reiniciar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar',
            onPressed: () {
              setState(() => _gameOverMostrado = false);
              vm.reiniciar();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del juego
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCard('Piezas', '${vm.contarPiezas()}'),
                _infoCard('Movimientos', '${vm.contadorMovimientos}'),
                _infoCard('Deshacer', '${vm.puedeDeshacer ? "✓" : "✗"}'),
              ],
            ),
          ),

          // Tablero triangular
          Expanded(
            child: Center(
              child: _construirTablero(vm),
            ),
          ),

          // Indicador del sensor
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              '📳 Agita el celular para deshacer',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el tablero triangular fila por fila
  Widget _construirTablero(JuegoViewModel vm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (fila) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(fila + 1, (col) {
            return _construirCelda(vm, fila, col);
          }),
        );
      }),
    );
  }

  // Construye una celda individual del tablero
  Widget _construirCelda(JuegoViewModel vm, int fila, int col) {
    final celda = vm.tablero.matriz[fila][col];
    if (celda == null) return const SizedBox();

    // Determina si esta celda está seleccionada
    final estaSeleccionada = vm.celdaSeleccionada?.fila == fila &&
        vm.celdaSeleccionada?.col == col;

    // Determina si esta celda es parte de la sugerencia
    final esSugerenciaOrigen = vm.sugerencia != null &&
        vm.sugerencia![0] == fila && vm.sugerencia![1] == col;
    final esSugerenciaDestino = vm.sugerencia != null &&
        vm.sugerencia![2] == fila && vm.sugerencia![3] == col;

    // Color según el estado de la celda
    Color color;
    if (estaSeleccionada) {
      color = Colors.yellow;           // seleccionada
    } else if (esSugerenciaOrigen) {
      color = Colors.greenAccent;      // sugerencia origen
    } else if (esSugerenciaDestino) {
      color = Colors.green;            // sugerencia destino
    } else if (celda.ocupada) {
      color = const Color(0xFFFFB300); // pieza normal (amarillo)
    } else {
      color = Colors.white24;          // hueco vacío
    }

    return GestureDetector(
      onTap: () => vm.onCeldaTocada(fila, col),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: estaSeleccionada ? Colors.orange : Colors.white24,
            width: estaSeleccionada ? 3 : 1,
          ),
          boxShadow: celda.ocupada ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(2, 2),
            )
          ] : null,
        ),
      ),
    );
  }

  // Tarjeta de información (piezas, movimientos)
  Widget _infoCard(String label, String valor) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  // Diálogo de Game Over
  void _mostrarGameOver(JuegoViewModel vm) {
    final piezas = vm.contarPiezas();
    // Guarda la puntuación en Firebase
    _servicio.guardarPuntuacion(widget.nombreJugador, piezas, vm.contadorMovimientos);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¡Juego Terminado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Piezas restantes: $piezas',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Movimientos: ${vm.contadorMovimientos}'),
            const SizedBox(height: 8),
            Text(
              piezas == 1 ? '🏆 ¡Perfecto!' :
              piezas <= 3 ? '⭐ ¡Muy bien!' : '¡Sigue practicando!',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/puntuaciones');
            },
            child: const Text('Ver puntuaciones'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _gameOverMostrado = false);
              vm.reiniciar();
            },
            child: const Text('Jugar de nuevo'),
          ),
        ],
      ),
    );
  }
}
