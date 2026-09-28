import 'axis.dart';
import 'folders.dart';
import 'lexicon.dart';
import 'questions.dart';
import 'store.dart';
import 'taboo.dart';
import 'wheel.dart';

/// One turn of the conversation: what was filed and what the app asks next.
class Turn {
  Turn({
    required this.filed,
    required this.score,
    required this.axis,
    required this.question,
    this.addedSomethingNew = false,
  });
  final List<Entry> filed;
  final Score score;
  final AxisReading axis;
  final Question question;
  final bool addedSomethingNew;
}

/// The conversation engine (docs/conversation-method.md, section 5).
/// Listen, score, check, choose one question, ask, wait.
class Session {
  Session({
    required this.wheel,
    required this.lexicon,
    required this.router,
    required this.store,
  })  : questions = QuestionBank(wheel),
        taboo = Taboo(wheel);

  final Wheel wheel;
  final Lexicon lexicon;
  final Router router;
  final Store store;
  final QuestionBank questions;
  final Taboo taboo;
  final AxisWatch watch = AxisWatch();

  Question? _lastQuestion;
  final Set<String> _saidSoFar = {};

  Future<void> load() async {
    final p = await store.profile();
    p.lexiconProfile.forEach((a, n) => watch.profile[a] = n);
    watch.passages = p.passages;
  }

  /// Handle a spoken transcript. Files it, scores it, and returns the next
  /// question. If the previous question asked for a person, the answer is
  /// recorded as that person for that approach.
  Future<Turn> hear(String transcript) async {
    final profile = await store.profile();
    final last = _lastQuestion;

    // Answers to the two reframing questions go into the person's library.
    if (last != null && last.kind == QuestionKind.whoIsGoodAt) {
      final person = _extractPerson(transcript);
      if (person != null && last.approach != null) {
        profile.reframers[last.approach!] = person;
        await store.add(Entry(
          folder: Folder.people,
          text: transcript,
          created: DateTime.now(),
          person: person,
          approach: last.approach,
          note: 'good at ${last.approach}',
        ));
        await store.saveProfile(profile);
        final q = questions.whatWouldTheyDo(person, last.approach!);
        _lastQuestion = q;
        final s = lexicon.score(transcript);
        return Turn(
          filed: const [],
          score: s,
          axis: AxisReading(loudest: null, loudestWeapon: null, absent: const [], missing: null),
          question: q,
          addedSomethingNew: true,
        );
      }
    }
    if (last != null && last.kind == QuestionKind.whatWouldTheyDo) {
      await store.add(Entry(
        folder: Folder.people,
        text: transcript,
        created: DateTime.now(),
        person: last.about,
        approach: last.approach,
        note: 'what ${last.about} would do',
      ));
    }
    if (last != null && last.kind == QuestionKind.criterion) {
      await store.add(Entry(
        folder: Folder.alarms,
        text: transcript,
        created: DateTime.now(),
        note: 'criterion',
      ));
    }

    // File the passages.
    final filed = <Entry>[];
    String? named;
    for (final p in splitPassages(transcript)) {
      final r = await router.route(p);
      final e = Entry(
        folder: r.folder,
        text: p,
        created: DateTime.now(),
        person: r.person,
        animal: r.animal,
      );
      await store.add(e);
      filed.add(e);
      if (r.folder == Folder.people && r.person != null) named ??= r.person;
    }

    // Score and watch.
    final score = lexicon.score(transcript);
    watch.learn(score);
    profile.passages = watch.passages;
    watch.profile.forEach((a, n) => profile.lexiconProfile[a] = n);
    await store.saveProfile(profile);
    final axis = watch.read(score, wheel);

    // Did the answer add anything new?
    final words = transcript.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    final fresh = words.difference(_saidSoFar);
    final addedNew = fresh.length >= 3;
    _saidSoFar.addAll(words);

    // Choose one question, and never the same one twice running.
    var q = questions.choose(
      score: score,
      axis: axis,
      reframers: profile.reframers,
      named: named,
    );
    if (last != null && q.kind == last.kind && q.text == last.text) {
      q = addedNew ? questions.whenDidThatLastHappen() : questions.open();
    }
    _lastQuestion = q;
    return Turn(
      filed: filed,
      score: score,
      axis: axis,
      question: q,
      addedSomethingNew: addedNew,
    );
  }

  /// Record the survey and favourites; returns the reading.
  Future<TabooReading> survey({
    required List<String> dislikedWeapons,
    required List<String> favourites,
  }) async {
    final p = await store.profile();
    p.dislikedWeapons = dislikedWeapons;
    p.favourites = favourites;
    await store.saveProfile(p);
    return taboo.read(dislikedWeapons: dislikedWeapons, favourites: favourites);
  }

  Question end() {
    final q = questions.criterion();
    _lastQuestion = q;
    return q;
  }

  static final _personRe = RegExp(
      r"\b(my |our )?(mother|mom|father|dad|brother|sister|wife|husband|partner|boss|friend|son|daughter|uncle|aunt|grandmother|grandfather|coworker|colleague|neighbour|neighbor|teacher|coach|pastor)\b( [A-Z][a-z]+)?",
      caseSensitive: false);
  static final _nameRe = RegExp(r'\b([A-Z][a-z]{2,})\b');

  String? _extractPerson(String answer) {
    final m = _personRe.firstMatch(answer);
    if (m != null) return m.group(0)!.trim();
    for (final n in _nameRe.allMatches(answer)) {
      final s = n.group(1)!;
      if (!RuleRouterStop.words.contains(s)) return s;
    }
    return null;
  }
}

class RuleRouterStop {
  static const words = {
    'The', 'And', 'But', 'Then', 'When', 'She', 'They', 'This', 'That', 'There',
    'What', 'Who', 'Why', 'How', 'Yes', 'Probably', 'Maybe', 'Well', 'Okay',
    'Just', 'Like', 'Something', 'Anyway', 'Someone', 'Nobody', 'Honestly',
  };
}
