import 'package:flutter/material.dart';
import '../modelo/celda.dart';
import '../modelo/tablero.dart';
import '../modelo/juego_state.dart';

// VIEWMODEL: JuegoViewModel
// Contiene toda la lógica del juego Come Solo.
// La View solo lee estado y llama funciones, nunca decide lógica.
class JuegoViewModel extends ChangeNotifier {

  // El tablero del juego
  Tablero _tablero = Tablero();

  // Celda actualmente seleccionada por el jugador (null si ninguna)
  Celda? celdaSeleccionada;

  // Estado actual del juego
  EstadoJuego estado = EstadoJuego.jugando;

  // Historial de estados para deshacer (patrón Memento)
  // Cada entrada es una copia del tablero antes de un movimiento
  final List<List<List<Celda?>>> _historial = [];
  final int maxHistorial = 5; // máximo de movimientos a deshacer

  // Contador de movimientos realizados
  int contadorMovimientos = 0;

  // Sugerencia activa (coordenadas origen y destino)
  List<int>? sugerencia;

  // Getter para acceder al tablero desde la View
  Tablero get tablero => _tablero;

  // Constructor: inicializa el tablero
  JuegoViewModel() {
    _tablero.inicializar();
  }

  // RF02: El jugador elige dónde empieza el hueco
  void inicializarHueco(int f, int c) {
    _tablero.inicializarHueco(f, c);
    notifyListeners(); // avisa a la View que cambiaron los datos
  }

  // RF03: Reinicia el juego completamente
  void reiniciar() {
    _tablero = Tablero();
    celdaSeleccionada = null;
    estado = EstadoJuego.jugando;
    _historial.clear();
    contadorMovimientos = 0;
    sugerencia = null;
    notifyListeners();
  }

  // Maneja el toque del usuario sobre una celda
  // Si no hay celda seleccionada, selecciona la tocada
  // Si ya hay una seleccionada, intenta mover
  void onCeldaTocada(int f, int c) {
    final celda = _tablero.matriz[f][c];
    if (celda == null) return; // celda fuera del tablero

    if (celdaSeleccionada == null) {
      // Primera selección: solo puede seleccionar celdas con pieza
      if (celda.ocupada) {
        celdaSeleccionada = celda;
        sugerencia = null; // quita sugerencia al tocar
        notifyListeners();
      }
    } else {
      // Segunda selección: intenta mover
      final origen = celdaSeleccionada!;
      if (origen.fila == f && origen.col == c) {
        // Tocó la misma celda: deselecciona
        celdaSeleccionada = null;
        notifyListeners();
        return;
      }

      if (_tablero.validarMovimiento(origen.fila, origen.col, f, c)) {
        // Guarda el estado actual en el historial ANTES de mover
        _guardarEnHistorial();
        // Ejecuta el movimiento
        _tablero.mover(origen.fila, origen.col, f, c);
        contadorMovimientos++;
        celdaSeleccionada = null;
        sugerencia = null;
        // Verifica si el juego terminó
        _verificarEstado();
        notifyListeners();
      } else {
        // Movimiento inválido: si tocó otra pieza, la selecciona
        if (celda.ocupada) {
          celdaSeleccionada = celda;
          notifyListeners();
        }
      }
    }
  }

  // Guarda copia del tablero en el historial (patrón Memento)
  void _guardarEnHistorial() {
    _historial.add(_tablero.copiarMatriz());
    // Mantiene solo el máximo permitido
    if (_historial.length > maxHistorial) {
      _historial.removeAt(0);
    }
  }

  // RF04: Deshace el último movimiento
  // También se activa cuando el usuario agita el celular
  bool deshacer() {
    if (_historial.isEmpty) return false;
    _tablero.matriz = _historial.removeLast();
    contadorMovimientos--;
    celdaSeleccionada = null;
    estado = EstadoJuego.jugando;
    sugerencia = null;
    notifyListeners();
    return true;
  }

  // RF08: Verifica si quedan movimientos disponibles
  void _verificarEstado() {
    if (!hayMovimientos()) {
      estado = EstadoJuego.terminado;
    } else {
      estado = EstadoJuego.jugando;
    }
  }

  // Revisa todas las celdas para ver si alguna tiene movimiento válido
  bool hayMovimientos() {
    List<List<int>> dirs = [
      [2,0],[-2,0],[0,2],[0,-2],[2,2],[-2,-2]
    ];
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_tablero.matriz[i][j] != null && _tablero.matriz[i][j]!.ocupada) {
          for (var d in dirs) {
            int ni = i + d[0];
            int nj = j + d[1];
            if (ni >= 0 && nj >= 0 && ni < 5 && nj < 5) {
              if (_tablero.validarMovimiento(i, j, ni, nj)) return true;
            }
          }
        }
      }
    }
    return false;
  }

  // Sugiere un movimiento válido al jugador
  void sugerirMovimiento() {
    List<List<int>> dirs = [
      [2,0],[-2,0],[0,2],[0,-2],[2,2],[-2,-2]
    ];
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_tablero.matriz[i][j] != null && _tablero.matriz[i][j]!.ocupada) {
          for (var d in dirs) {
            int ni = i + d[0];
            int nj = j + d[1];
            if (ni >= 0 && nj >= 0 && ni < 5 && nj < 5) {
              if (_tablero.validarMovimiento(i, j, ni, nj)) {
                sugerencia = [i, j, ni, nj];
                notifyListeners();
                return;
              }
            }
          }
        }
      }
    }
  }

  // Cuenta las piezas restantes (para la puntuación)
  // Menos piezas = mejor puntuación
  int contarPiezas() {
    int cuenta = 0;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j <= i; j++) {
        if (_tablero.matriz[i][j] != null && _tablero.matriz[i][j]!.ocupada) {
          cuenta++;
        }
      }
    }
    return cuenta;
  }

  // Indica si hay movimientos en el historial para deshacer
  bool get puedeDeshacer => _historial.isNotEmpty;
}
