import 'dart:async';
import 'dart:developer' as developer;

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:flutter/material.dart';

class AppTimeTracker with WidgetsBindingObserver {
  AppTimeTracker._();
  static final AppTimeTracker instance = AppTimeTracker._();
  factory AppTimeTracker() => instance;

  static const _interval = Duration(minutes: 1);

  late DateTime _startTime;
  late Timer _timer;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
  }

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(_interval, (_) => _flush());
  }

  Future<void> _flush() async {
    if (!_timer.isActive) return;

    final now = DateTime.now();
    if (now.isBefore(_startTime)) {
      _startTime = now;
      return;
    }

    final elapsed = now.difference(_startTime);
    _startTime = now;

    try {
      final db = await AppDb.instance.database;
      await Repository(db: db).updateTimeSpentStats(now, elapsed);
    } catch (e) {
      developer.log("Erreur sauvegarde temps: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startTimer();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _flush();
        _timer.cancel();
        break;
    }
  }
}
