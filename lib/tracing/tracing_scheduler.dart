import 'package:flutter/material.dart';

enum TracingMode { central, peripheral }

class TracingScheduler {
  /*
  15 minute tracing (peripheral/central) period, each cycle is 1 minute long.
  Recommendation of 20% of the duty cycle to be central (as in BlueTrace).

  true  : central (scanning/client)
  false : peripheral (advertising/server)
  */
  late List<TracingMode> _schedule;

  TracingScheduler() {
    newSchedule();
  }

  void newSchedule() {
    // Reset schedule
    _schedule = List.generate(15, (index) => TracingMode.peripheral);

    // Set 20% of the schedule to central
    _schedule.fillRange(0, 3, TracingMode.central);

    // Randomise the schedule
    _schedule.shuffle();

    debugPrint(_schedule.toString());
  }

  TracingMode getNext() {
    if (_schedule.isEmpty) {
      newSchedule();
    }

    // Get the next value in the schedule
    return _schedule.removeAt(0);
  }
}
