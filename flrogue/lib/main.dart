// rogue/main.dart

import 'dart:async';
import 'dart:io';
import 'package:flrogue/rogue/room.dart';
import 'package:flutter/material.dart';
import 'rogue/globals.dart';
import 'rogue/init.dart';
import 'rogue/level.dart';
import 'rogue/monster.dart';
import 'rogue/object.dart';
import 'rogue/play.dart';
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

    // Run game in separate isolate to prevent UI freezes
    try {
      await init();

      while (true) {
        try {
          clearLevel();
          makeLevel();
          putObjects();
          putStairs();
          putMonsters();
          putPlayer();
          lightUpRoom();
          printStats();
          await playLevel();
          levelObjects.nextObject = null;
          levelMonsters.nextObject = null;
          ui.clearScreen();
        } catch (e) {
          print("Level error: $e");
          exc = e as Exception;
          break;
        }
      }
    } catch (e) {
      print("Game error: $e");
      exc = e as Exception;
      cleanUp("Game error occurred");
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
          Expanded(child: TerminalWidget()),
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

// Simplified version for testing
void cleanUp(String msg) {
  print("Game cleanup: $msg");
  if (exc != null) {
    print("Exception: ${exc.toString()}");
  }
  exit(0);
}
