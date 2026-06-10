import 'package:flutter/foundation.dart';
import '../modelo/celda.dart';
import '../modelo/tablero.dart';
import '../modelo/juego_state.dart';
import '../servicios/firebase_servicio.dart';

class JuegoViewModel extends ChangeNotifier {
  static const int _maxHistorial = 5;

  static const List<List<int>> _direcciones = [
    [2, 0], [-2, 0],
    [0, 2], [0, -2],
    [2, 2], [-2, -2],
  ];

  final FirebaseServicio _servicio;

  Tablero _tablero = Tablero();
  Celda? celdaSeleccionada;
  EstadoJuego estado = EstadoJuego.jugando;
  List<int>? sugerencia;
  int contadorMovimientos = 0;
  String _nombreJugador = '';

  final List<List<List<Celda?>>> _historial = [];

  // Permite inyectar un servicio falso en tests
  JuegoViewModel({FirebaseServicio? servicio})
      : _servicio = servicio ?? FirebaseServicio();

  Tablero get tablero => _tablero;
  bool get puedeDeshacer => _historial.isNotEmpty;
  Stream<List<Map<String, dynamic>>> get puntuaciones => _servicio.getPuntuaciones();

  void iniciarPartida(String nombre, int huecoFila, int huecoCol) {
    _nombreJugador = nombre;
    _tablero.inicializarHueco(huecoFila, huecoCol);
    _servicio.logInicioPartida(nombre);
    notifyListeners();
  }

  void reiniciar() {
    _tablero = Tablero();
    celdaSeleccionada = null;
    estado = EstadoJuego.jugando;
    contadorMovimientos = 0;
    sugerencia = null;
    _historial.clear();
    notifyListeners();
  }

  void onCeldaTocada(int fila, int col) {
    final celda = _tablero.matriz[fila][col];
    if (celda == null) return;

    if (celdaSeleccionada == null) {
      if (celda.ocupada) {
        celdaSeleccionada = celda;
        sugerencia = null;
        notifyListeners();
      }
      return;
    }

    final origen = celdaSeleccionada!;

    if (origen.fila == fila && origen.col == col) {
      celdaSeleccionada = null;
      notifyListeners();
      return;
    }

    if (_tablero.validarMovimiento(origen.fila, origen.col, fila, col)) {
      _guardarEnHistorial();
      _tablero.mover(origen.fila, origen.col, fila, col);
      contadorMovimientos++;
      celdaSeleccionada = null;
      sugerencia = null;
      _actualizarEstado();
      notifyListeners();
    } else if (celda.ocupada) {
      celdaSeleccionada = celda;
      notifyListeners();
    }
  }

  bool deshacer() {
    if (_historial.isEmpty) return false;
    _tablero.matriz = _historial.removeLast();
    contadorMovimientos--;
    celdaSeleccionada = null;
    estado = EstadoJuego.jugando;
    sugerencia = null;
    _servicio.logDeshacer();
    notifyListeners();
    return true;
  }

  void sugerirMovimiento() {
    final movimiento = _buscarPrimerMovimiento();
    sugerencia = movimiento;
    if (movimiento != null) _servicio.logSugerencia();
    notifyListeners();
  }

  int contarPiezas() {
    int total = 0;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j <= i; j++) {
        if (_tablero.matriz[i][j]?.ocupada == true) total++;
      }
    }
    return total;
  }

  // --- Privados ---

  void _guardarEnHistorial() {
    _historial.add(_tablero.copiarMatriz());
    if (_historial.length > _maxHistorial) _historial.removeAt(0);
  }

  void _actualizarEstado() {
    final siguienteMovimiento = _buscarPrimerMovimiento();
    estado = siguienteMovimiento != null
        ? EstadoJuego.jugando
        : EstadoJuego.terminado;

    if (estado == EstadoJuego.terminado) {
      // fire-and-forget: no bloqueamos la UI esperando a Firebase
      _servicio.guardarPuntuacion(_nombreJugador, contarPiezas(), contadorMovimientos);
    }
  }

  // Único método que itera el tablero buscando movimientos válidos.
  // Reemplaza la antigua duplicación entre hayMovimientos() y sugerirMovimiento().
  List<int>? _buscarPrimerMovimiento() {
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_tablero.matriz[i][j]?.ocupada != true) continue;
        for (final d in _direcciones) {
          final ni = i + d[0];
          final nj = j + d[1];
          if (ni >= 0 && nj >= 0 && ni < 5 && nj < 5) {
            if (_tablero.validarMovimiento(i, j, ni, nj)) return [i, j, ni, nj];
          }
        }
      }
    }
    return null;
  }
}
