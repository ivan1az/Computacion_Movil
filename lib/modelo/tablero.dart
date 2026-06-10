// MODELO: Tablero
// Contiene la matriz 5x5 del juego Come Solo.
// El tablero es triangular: fila 0 tiene 1 celda, fila 4 tiene 5 celdas.
import 'celda.dart';

class Tablero {
  // Matriz 5x5, algunas posiciones son null (fuera del triángulo)
  List<List<Celda?>> matriz = List.generate(5, (_) => List.filled(5, null));

  Tablero() {
    inicializar();
  }

  // Inicializa el tablero con todas las celdas ocupadas
  // Solo existen celdas donde col <= fila (forma triangular)
  void inicializar() {
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j <= i; j++) {
        matriz[i][j] = Celda(fila: i, col: j, ocupada: true);
      }
    }
    // Hueco inicial por defecto en el centro
    matriz[2][1]!.ocupada = false;
  }

  // RF02: Permite elegir dónde empieza el hueco vacío
  void inicializarHueco(int f, int c) {
    // Primero ocupa todas las celdas
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j <= i; j++) {
        matriz[i][j]!.ocupada = true;
      }
    }
    // Deja vacía la celda seleccionada
    matriz[f][c]!.ocupada = false;
  }

  // RF05: Valida si un movimiento es legal
  // Un movimiento es válido si:
  // - La celda origen existe y tiene pieza
  // - La celda destino existe y está vacía
  // - La celda del medio existe y tiene pieza
  // - La dirección es válida (salto de 2 posiciones)
  bool validarMovimiento(int f1, int c1, int f2, int c2) {
    if (matriz[f1][c1] == null || matriz[f2][c2] == null) return false;
    if (!matriz[f1][c1]!.ocupada) return false;
    if (matriz[f2][c2]!.ocupada) return false;

    int df = f2 - f1;
    int dc = c2 - c1;

    // Direcciones válidas: vertical, horizontal y diagonal
    List<List<int>> dirs = [
      [2, 0], [-2, 0],   // vertical
      [0, 2], [0, -2],   // horizontal
      [2, 2], [-2, -2],  // diagonal principal
    ];

    bool dirValida = dirs.any((d) => d[0] == df && d[1] == dc);
    if (!dirValida) return false;

    // La celda del medio (la que se elimina)
    int midF = (f1 + f2) ~/ 2;
    int midC = (c1 + c2) ~/ 2;

    if (matriz[midF][midC] == null) return false;
    return matriz[midF][midC]!.ocupada;
  }

  // Ejecuta el movimiento: mueve la pieza y elimina la del medio
  void mover(int f1, int c1, int f2, int c2) {
    int midF = (f1 + f2) ~/ 2;
    int midC = (c1 + c2) ~/ 2;

    matriz[f1][c1]!.ocupada = false;   // origen queda vacío
    matriz[midF][midC]!.ocupada = false; // pieza del medio se elimina
    matriz[f2][c2]!.ocupada = true;    // destino queda ocupado
  }

  // Crea una copia profunda del tablero (para guardar en historial)
  List<List<Celda?>> copiarMatriz() {
    return List.generate(5, (i) =>
      List.generate(5, (j) =>
        matriz[i][j] != null
          ? matriz[i][j]!.copia()
          : null
      )
    );
  }
}
