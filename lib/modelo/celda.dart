// MODELO: Celda
// Representa una celda del tablero triangular.
// Cada celda sabe su posición y si tiene una pieza o no.
class Celda {
  final int fila;
  final int col;
  bool ocupada;

  Celda({required this.fila, required this.col, required this.ocupada});

  // Crea una copia de la celda (para el historial de deshacer)
  Celda copia() => Celda(fila: fila, col: col, ocupada: ocupada);
}
