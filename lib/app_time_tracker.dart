import 'dart:async';

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/repositories/repository.dart';
import 'package:flutter/material.dart';

class AppTimeTracker with WidgetsBindingObserver {
  AppTimeTracker._();
  static final AppTimeTracker instance = AppTimeTracker._()..init();
  factory AppTimeTracker() => instance;

  static const _interval = Duration(minutes: 1);

  late DateTime _startTime;
  late Timer _timer;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(_interval, (_) => _flush());
  }

  Future<void> _flush() async {
    final now = DateTime.now();
    final elapsed = now.difference(_startTime);
    final db = await AppDb.instance.database;
    await Repository(db: db).updateTimeSpentStats(now, elapsed);
    _startTime = now;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startTimer();
        break;
      case AppLifecycleState.paused: // backgrounded
        _flush();
        _timer.cancel();
        break;
      default:
        break;
    }
  }
}
