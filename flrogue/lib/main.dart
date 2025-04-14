import 'dart:async';
import 'package:flutter/material.dart';
import 'rogue/globals.dart' show exc;
import 'rogue/main.dart' as rogue;
import 'rogue/ui.dart';
import 'terminal_widget.dart';

void main() {
  runApp(const RogueApp());
}

class RogueApp extends StatelessWidget {
  const RogueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rogue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'monospace',
      ),
      home: const RogueGame(),
    );
  }
}

class RogueGame extends StatefulWidget {
  const RogueGame({super.key});

  @override
  State<RogueGame> createState() => _RogueGameState();
}

class _RogueGameState extends State<RogueGame> {
  bool _isGameRunning = false;

  @override
  void initState() {
    super.initState();
    // Start the game after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startGame());
    });
  }

  Future<void> _startGame() async {
    setState(() {
      _isGameRunning = true;
    });
    try {
      ui = TerminalUI(80, 25);
      await rogue.main();
    } catch (e, st) {
      exc = (e, st);
    } finally {
      setState(() {
        _isGameRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(child: TerminalWidget(ui: ui as TerminalUI)),
          if (!_isGameRunning)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red,
              width: double.infinity,
              child: Text(
                'Game ended${exc != null ? ': ${exc.toString()}' : ''}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
