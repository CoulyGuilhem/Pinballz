import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'pinballz_game.dart';

void main() {
  runApp(const PinballzApp());
}

class PinballzApp extends StatelessWidget {
  const PinballzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF101020),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // ⬅️ UI gauche : 1/4
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0x3322AAFF),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'DEBUG LEFT UI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Largeur totale: ${constraints.maxWidth.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const Text(
                          'Zone prévue pour les mécaniques de jeu',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🎮 Jeu Flame au centre : 1/2
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0x3300FF00),
                    child: GameWidget(
                      game: PinballzGame(),
                      loadingBuilder: (context) {
                        return const Center(
                          child: SizedBox(
                            width: 220,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chargement de Pinballz...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 16),
                                LinearProgressIndicator(),
                                SizedBox(height: 8),
                                Text(
                                  'DEBUG: loadingBuilder actif',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ➡️ UI droite : 1/4
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0x33FFAA00),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'DEBUG RIGHT UI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Zone prévue pour le score, infos, etc.',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
