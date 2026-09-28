import 'lexicon.dart';

/// The folders (docs/app-plan.md, section 2).
enum Folder {
  dreams,
  people,
  animals,
  places,
  waking,
  alarms,
  profile,
  loose;

  String get label => switch (this) {
        Folder.dreams => 'Dreams',
        Folder.people => 'People',
        Folder.animals => 'Animals and relationships',
        Folder.places => 'Places and objects',
        Folder.waking => 'Waking life',
        Folder.alarms => 'Alarms',
        Folder.profile => 'Approach profile',
        Folder.loose => 'Loose',
      };
}

/// A rule-based router. A small language model can replace [route] later;
/// the interface is the same: a passage in, a folder out.
abstract class Router {
  Future<Routing> route(String passage);
}

class Routing {
  Routing(this.folder, {this.person, this.animal, this.confidence = 1.0});
  final Folder folder;
  final String? person;
  final String? animal;
  final double confidence;
}

class RuleRouter implements Router {
  RuleRouter(this.lexicon);
  final Lexicon lexicon;

  static final _dream = RegExp(
      r'\b(dream(t|ed|ing|s)?|nightmare|last night|i was asleep|woke up)\b',
      caseSensitive: false);
  static final _alarm = RegExp(
      r"\b(panic|alarm|anxious|anxiety|scared|terrified|can't stop (checking|thinking)|on edge|braced)\b",
      caseSensitive: false);
  static final _animal = RegExp(
      r'\b(dog|cat|horse|cow|sheep|bear|wolf|lion|snake|serpent|bird|fish|bee|bees|spider|ant|ants|insect|bug|bugs|mouse|rat|tiger|deer|fox|pig|goat)\b',
      caseSensitive: false);
  static final _place = RegExp(
      r'\b(house|home|kitchen|bathroom|bedroom|basement|attic|car|bus|train|road|bridge|river|sea|ocean|lake|water|mountain|desert|forest|school|church|office|library)\b',
      caseSensitive: false);
  static final _person = RegExp(
      r'\b(my|his|her|their) (mother|mom|father|dad|brother|sister|wife|husband|partner|boss|friend|son|daughter|ex|coworker|colleague|neighbour|neighbor)\b',
      caseSensitive: false);
  static final _named = RegExp(r'\b([A-Z][a-z]{2,})\b');

  @override
  Future<Routing> route(String passage) async {
    final person = _person.firstMatch(passage)?.group(0) ??
        _named
            .allMatches(passage)
            .map((m) => m.group(1)!)
            .where((n) => !_stop.contains(n))
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);
    final animal = _animal.firstMatch(passage)?.group(0)?.toLowerCase();

    if (_dream.hasMatch(passage)) {
      return Routing(Folder.dreams, person: person, animal: animal);
    }
    if (_alarm.hasMatch(passage)) {
      return Routing(Folder.alarms, person: person, confidence: 0.8);
    }
    if (animal != null && person != null) {
      return Routing(Folder.animals, person: person, animal: animal, confidence: 0.7);
    }
    if (person != null && _describes.hasMatch(passage)) {
      return Routing(Folder.people, person: person, confidence: 0.7);
    }
    if (_place.hasMatch(passage) && _means.hasMatch(passage)) {
      return Routing(Folder.places, confidence: 0.6);
    }
    final score = lexicon.score(passage);
    if (score.hits.isNotEmpty || _time.hasMatch(passage)) {
      return Routing(Folder.waking, person: person, confidence: 0.6);
    }
    return Routing(Folder.loose, person: person, confidence: 0.3);
  }

  static final _describes = RegExp(
      r"\b(is|was|always|never|so|such a|kind of|type of|he's|she's|they're)\b",
      caseSensitive: false);
  static final _means =
      RegExp(r'\b(means|reminds|feels like|always|to me)\b', caseSensitive: false);
  static final _time = RegExp(
      r'\b(today|yesterday|this morning|tonight|this week|at work|meeting|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      caseSensitive: false);
  static const _stop = {
    'The', 'And', 'But', 'Then', 'When', 'She', 'They', 'This', 'That', 'There',
    'What', 'Who', 'Why', 'How', 'Yes', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday', 'January', 'February', 'March',
    'April', 'June', 'July', 'August', 'September', 'October', 'November',
    'December', 'Also', 'Well', 'Okay', 'Just', 'Like', 'Something', 'Anyway',
  };
}

/// Split a transcript into passages at sentence-ish boundaries and topic
/// shifts ("and then", "another thing", "also").
List<String> splitPassages(String transcript) {
  final t = transcript.trim();
  if (t.isEmpty) return [];
  final parts = t
      .split(RegExp(
          r'(?<=[.!?])\s+|\s+(?=(and then|another thing|also,|the other thing|separately)\b)',
          caseSensitive: false))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  // Merge very short fragments into their neighbour.
  final out = <String>[];
  for (final p in parts) {
    if (out.isNotEmpty && p.split(' ').length < 4) {
      out[out.length - 1] = '${out.last} $p';
    } else {
      out.add(p);
    }
  }
  return out;
}
