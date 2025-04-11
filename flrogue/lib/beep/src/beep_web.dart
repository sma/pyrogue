import 'package:web/web.dart';

void beep() {
  var context = AudioContext();
  var oscillator =
      context.createOscillator()
        ..type = "square"
        ..frequency.value = 440
        ..connect(context.destination)
        ..start();
  Future.delayed(Duration(milliseconds: 50), () => oscillator.stop());
}
