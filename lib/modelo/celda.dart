class Celda {
  final int fila;
  final int col;
  bool ocupada;

  Celda({required this.fila, required this.col, required this.ocupada});

  Celda copia() => Celda(fila: fila, col: col, ocupada: ocupada);
}
