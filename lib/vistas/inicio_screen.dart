import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/juego_viewmodel.dart';
import 'juego_screen.dart';

// VISTA: InicioScreen
// Pantalla de bienvenida donde el jugador ingresa su nombre
// y elige dónde empieza el hueco del tablero.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _nombreController = TextEditingController();
  // Hueco seleccionado (fila, col) — por defecto el centro
  int _huecoFila = 2;
  int _huecoCol = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título
              const Text(
                'COME\nSOLO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Flutter Edition',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Campo de nombre
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tu nombre',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.person, color: Colors.amber),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selector de hueco inicial
              const Text(
                'Elige el hueco inicial:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _construirSelectorHueco(),
              const SizedBox(height: 32),

              // Botón jugar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final nombre = _nombreController.text.trim();
                    if (nombre.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa tu nombre')),
                      );
                      return;
                    }
                    // Inicializa el hueco en el ViewModel
                    context.read<JuegoViewModel>()
                        .inicializarHueco(_huecoFila, _huecoCol);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JuegoScreen(nombreJugador: nombre),
                      ),
                    );
                  },
                  child: const Text('INICIAR JUEGO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // Botón ver puntuaciones
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/puntuaciones'),
                child: const Text('Ver puntuaciones',
                    style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mini tablero triangular para seleccionar el hueco inicial
  Widget _construirSelectorHueco() {
    return Column(
      children: List.generate(5, (fila) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(fila + 1, (col) {
            final seleccionado = _huecoFila == fila && _huecoCol == col;
            return GestureDetector(
              onTap: () => setState(() {
                _huecoFila = fila;
                _huecoCol = col;
              }),
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: seleccionado ? Colors.red : Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seleccionado ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
