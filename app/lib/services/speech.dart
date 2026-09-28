import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Speech in and speech out. Stage one uses the phone's own recogniser and
/// voice (no download, on-device on most Android phones). The interfaces
/// stay the same when sherpa-onnx replaces them.
abstract class Listener {
  Future<bool> init();
  Future<void> start(void Function(String text, bool isFinal) onResult);
  Future<void> stop();
  bool get isListening;
}

abstract class Speaker {
  Future<void> say(String text);
  Future<void> stop();
}

class PhoneListener implements Listener {
  final _stt = stt.SpeechToText();
  bool _ready = false;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<bool> init() async {
    _ready = await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    return _ready;
  }

  @override
  Future<void> start(void Function(String text, bool isFinal) onResult) async {
    if (!_ready && !await init()) return;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        onDevice: false,
        cancelOnError: false,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 3),
      ),
    );
  }

  @override
  Future<void> stop() => _stt.stop();
}

class PhoneSpeaker implements Speaker {
  PhoneSpeaker() {
    _tts.setSpeechRate(0.45);
    _tts.awaitSpeakCompletion(true);
  }
  final _tts = FlutterTts();

  @override
  Future<void> say(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
