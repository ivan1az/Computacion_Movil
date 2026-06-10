import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../viewmodels/juego_viewmodel.dart';
import '../modelo/juego_state.dart';

class JuegoScreen extends StatefulWidget {
  const JuegoScreen({super.key, required this.nombreJugador});

  final String nombreJugador;

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  StreamSubscription? _acelerometroSub;
  bool _gameOverMostrado = false;

  // Umbral empírico: valores < 15 generan falsos positivos en uso normal
  static const double _umbralSacudida = 20.0;
  DateTime _ultimaSacudida = DateTime.now();

  @override
  void initState() {
    super.initState();
    _iniciarSensor();
  }

  void _iniciarSensor() {
    _acelerometroSub = accelerometerEventStream().listen((event) {
      final magnitud = event.x.abs() + event.y.abs() + event.z.abs();
      final ahora = DateTime.now();
      final cooldownOk = ahora.difference(_ultimaSacudida).inMilliseconds > 1000;

      if (magnitud > _umbralSacudida && cooldownOk) {
        _ultimaSacudida = ahora;
        if (!mounted) return;
        final vm = context.read<JuegoViewModel>();
        if (vm.deshacer()) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('↩ Movimiento deshecho'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _acelerometroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JuegoViewModel>();

    if (vm.estado == EstadoJuego.terminado && !_gameOverMostrado) {
      _gameOverMostrado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarGameOver(vm));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text('Come Solo — ${widget.nombreJugador}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Sugerir movimiento',
            onPressed: vm.sugerirMovimiento,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer (o agita el celular)',
            onPressed: vm.puedeDeshacer ? vm.deshacer : null,
          ),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoCard(label: 'Piezas', valor: '${vm.contarPiezas()}'),
                _InfoCard(label: 'Movimientos', valor: '${vm.contadorMovimientos}'),
                _InfoCard(label: 'Deshacer', valor: vm.puedeDeshacer ? '✓' : '✗'),
              ],
            ),
          ),
          Expanded(
            child: Center(child: _Tablero(vm: vm)),
          ),
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

  void _mostrarGameOver(JuegoViewModel vm) {
    final piezas = vm.contarPiezas();
    final mensaje = piezas == 1
        ? '🏆 ¡Perfecto!'
        : piezas <= 3
            ? '⭐ ¡Muy bien!'
            : '¡Sigue practicando!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¡Juego Terminado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Piezas restantes: $piezas',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Movimientos: ${vm.contadorMovimientos}'),
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(fontSize: 16)),
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

class _Tablero extends StatelessWidget {
  const _Tablero({required this.vm});

  final JuegoViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (fila) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(fila + 1, (col) => _Celda(vm: vm, fila: fila, col: col)),
        );
      }),
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({required this.vm, required this.fila, required this.col});

  final JuegoViewModel vm;
  final int fila;
  final int col;

  @override
  Widget build(BuildContext context) {
    final celda = vm.tablero.matriz[fila][col];
    if (celda == null) return const SizedBox();

    final estaSeleccionada =
        vm.celdaSeleccionada?.fila == fila && vm.celdaSeleccionada?.col == col;
    final esSugerenciaOrigen =
        vm.sugerencia != null && vm.sugerencia![0] == fila && vm.sugerencia![1] == col;
    final esSugerenciaDestino =
        vm.sugerencia != null && vm.sugerencia![2] == fila && vm.sugerencia![3] == col;

    final Color color;
    if (estaSeleccionada) {
      color = Colors.yellow;
    } else if (esSugerenciaOrigen) {
      color = Colors.greenAccent;
    } else if (esSugerenciaDestino) {
      color = Colors.green;
    } else if (celda.ocupada) {
      color = const Color(0xFFFFB300);
    } else {
      color = Colors.white24;
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
          boxShadow: celda.ocupada
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
