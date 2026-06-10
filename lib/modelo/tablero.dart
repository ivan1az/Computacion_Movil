import 'celda.dart';

class Tablero {
  List<List<Celda?>> matriz = List.generate(5, (_) => List.filled(5, null));

  Tablero() {
    _inicializar();
  }

  void _inicializar() {
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j <= i; j++) {
        matriz[i][j] = Celda(fila: i, col: j, ocupada: true);
      }
    }
    // El hueco predeterminado (centro del triángulo) se sobreescribe en inicializarHueco
    matriz[2][1]!.ocupada = false;
  }

  void inicializarHueco(int fila, int col) {
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j <= i; j++) {
        matriz[i][j]!.ocupada = true;
      }
    }
    matriz[fila][col]!.ocupada = false;
  }

  bool validarMovimiento(int f1, int c1, int f2, int c2) {
    if (matriz[f1][c1] == null || matriz[f2][c2] == null) return false;
    if (!matriz[f1][c1]!.ocupada || matriz[f2][c2]!.ocupada) return false;

    final df = f2 - f1;
    final dc = c2 - c1;

    const direccionesValidas = [
      [2, 0], [-2, 0],
      [0, 2], [0, -2],
      [2, 2], [-2, -2],
    ];

    final dirValida = direccionesValidas.any((d) => d[0] == df && d[1] == dc);
    if (!dirValida) return false;

    final midF = (f1 + f2) ~/ 2;
    final midC = (c1 + c2) ~/ 2;

    return matriz[midF][midC]?.ocupada == true;
  }

  void mover(int f1, int c1, int f2, int c2) {
    final midF = (f1 + f2) ~/ 2;
    final midC = (c1 + c2) ~/ 2;

    matriz[f1][c1]!.ocupada = false;
    matriz[midF][midC]!.ocupada = false;
    matriz[f2][c2]!.ocupada = true;
  }

  List<List<Celda?>> copiarMatriz() {
    return List.generate(
      5,
      (i) => List.generate(
        5,
        (j) => matriz[i][j]?.copia(),
      ),
    );
  }
}
