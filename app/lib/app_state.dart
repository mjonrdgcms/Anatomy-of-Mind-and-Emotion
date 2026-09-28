import 'package:flutter/services.dart' show rootBundle;

import 'core/fallacies.dart';
import 'core/folders.dart';
import 'core/lexicon.dart';
import 'core/session.dart';
import 'core/store.dart';
import 'core/wheel.dart';
import 'services/db.dart';
import 'services/speech.dart';

/// Everything the screens share.
class AppState {
  AppState._({
    required this.wheel,
    required this.lexicon,
    required this.store,
    required this.session,
    required this.listener,
    required this.speaker,
  });

  final Wheel wheel;
  final Lexicon lexicon;
  final Store store;
  final Session session;
  final Listener listener;
  final Speaker speaker;

  static Future<AppState> boot() async {
    final wheel = Wheel.fromJson(await rootBundle.loadString('assets/grammar/approaches.json'));
    final lexicon = Lexicon.fromJson(await rootBundle.loadString('assets/grammar/lexicon.json'));
    final catalogue = FallacyCatalogue.fromJson(await rootBundle.loadString('assets/grammar/fallacies.json'));
    Store store;
    try {
      store = await DbStore.open();
    } catch (_) {
      store = MemoryStore();
    }
    final session = Session(
      wheel: wheel,
      lexicon: lexicon,
      router: RuleRouter(lexicon),
      store: store,
      catalogue: catalogue,
    );
    await session.load();
    return AppState._(
      wheel: wheel,
      lexicon: lexicon,
      store: store,
      session: session,
      listener: PhoneListener(),
      speaker: PhoneSpeaker(),
    );
  }
}
