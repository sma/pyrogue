import 'dart:async';

import 'package:flutter/services.dart';

void beep() {
  unawaited(SystemSound.play(SystemSoundType.alert));
}
