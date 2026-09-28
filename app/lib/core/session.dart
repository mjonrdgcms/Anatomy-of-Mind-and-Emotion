import 'axis.dart';
import 'context.dart';
import 'definitions.dart';
import 'fallacies.dart';
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
    required this.context,
    this.fallacies = const [],
    this.addedSomethingNew = false,
  });
  final List<Entry> filed;
  final Score score;
  final AxisReading axis;
  final Question question;
  final WorkingContext context;

  /// Recorded this turn, not raised.
  final List<FallacyHit> fallacies;
  final bool addedSomethingNew;
}

/// The conversation engine (docs/conversation-method.md, section 5;
/// docs/context-and-definitions.md, section 6).
class Session {
  Session({
    required this.wheel,
    required this.lexicon,
    required this.router,
    required this.store,
    required this.catalogue,
  })  : questions = QuestionBank(wheel),
        taboo = Taboo(wheel),
        detector = FallacyDetector(catalogue, lexicon),
        collector = DefinitionCollector(lexicon, wheel),
        analysis = DefinitionAnalysis(wheel);

  final Wheel wheel;
  final Lexicon lexicon;
  final Router router;
  final Store store;
  final FallacyCatalogue catalogue;
  final QuestionBank questions;
  final Taboo taboo;
  final FallacyDetector detector;
  final DefinitionCollector collector;
  final DefinitionAnalysis analysis;
  final AxisWatch watch = AxisWatch();
  final Focus focus = Focus();

  Question? _lastQuestion;

  /// Fallacies recorded and not yet worked, oldest first.
  final List<FallacyHit> pending = [];

  /// The chain being walked, if any.
  FallacyHit? _active;
  int _step = 0;
  final Set<String> _saidSoFar = {};
  final Set<String> _askedDefinition = {};
  final Set<String> _askedBoundary = {};

  Future<void> load() async {
    final p = await store.profile();
    p.lexiconProfile.forEach((a, n) => watch.profile[a] = n);
    watch.passages = p.passages;
    // Fallacies recorded in earlier sessions and never worked.
    for (final e in await store.list(Folder.fallacies, limit: 200)) {
      final note = e.note ?? '';
      if (!note.endsWith('pending')) continue;
      final name = note.split(' · ').first;
      final f = catalogue.fallacies.where((x) => x.name == name).firstOrNull;
      if (f == null) continue;
      final cue = RegExp(r'"(.*)"').firstMatch(note)?.group(1) ?? '';
      pending.add(FallacyHit(
        fallacy: f, sentence: e.text, cue: cue, context: e.text,
        about: const [], when: e.created, entryId: e.id,
      ));
    }
  }

  TabooReading? _reading(Profile p) => p.dislikedWeapons.isEmpty && p.favourites.isEmpty
      ? null
      : taboo.read(dislikedWeapons: p.dislikedWeapons, favourites: p.favourites);

  /// Handle a spoken transcript: archive it, file the passages, collect the
  /// person's phrases, note absolutes, update the focus, ask one question.
  Future<Turn> hear(String transcript) async {
    final now = DateTime.now();
    final profile = await store.profile();
    final last = _lastQuestion;

    await store.archive(transcript, now);
    await _recordAnswer(last, transcript, now, profile);

    // File the passages and collect phrases.
    final filed = <Entry>[];
    final phrases = <Phrase>[];
    String? named;
    for (final p in splitPassages(transcript)) {
      final r = await router.route(p);
      final e = Entry(folder: r.folder, text: p, created: now, person: r.person, animal: r.animal);
      await store.add(e);
      filed.add(e);
      if (r.folder == Folder.people && r.person != null) named ??= r.person;
      phrases.addAll(collector.extract(p, lexicon.score(p), r.folder, now));
    }
    if (last != null && (last.kind == QuestionKind.boundary || last.kind == QuestionKind.definition) && last.about != null) {
      // The answer is about the term asked, even if its words are absent.
      phrases.add(Phrase(
        term: last.about!,
        kind: wheel.find(last.about!)?.weapon == last.about ? 'weapon' : 'tool',
        approach: wheel.approachOf(last.about!) ?? '',
        text: transcript,
        created: now,
        folder: Folder.profile,
        coApproaches: lexicon.score(transcript).byApproach().keys.toList(),
        isBoundary: last.kind == QuestionKind.boundary,
      ));
    }
    await store.addPhrases(phrases);

    // Fallacies: record with context, say nothing now. A question to the
    // app, or an answer inside a chain, is not an account and is not scanned.
    final hits = _active == null && !asksTheApp(transcript)
        ? detector.detect(transcript, now)
        : <FallacyHit>[];
    for (final h in hits) {
      h.entryId = await store.add(Entry(
        folder: Folder.fallacies,
        text: h.context,
        created: now,
        approach: h.fallacy.approach ?? (h.about.isEmpty ? null : h.about.first.approach),
        note: '${h.fallacy.name} · "${h.cue}" · pending',
      ));
      pending.add(h);
    }

    // Score, watch, focus.
    final score = lexicon.score(transcript);
    watch.learn(score);
    focus.learn(score);
    profile.passages = watch.passages;
    watch.profile.forEach((a, n) => profile.lexiconProfile[a] = n);
    await store.saveProfile(profile);
    final axis = watch.read(score, wheel);
    final reading = _reading(profile);
    final unseen = reading == null ? axis.absent : taboo.unseen(reading);

    // Did the answer add anything new?
    final words = transcript.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    final addedNew = words.difference(_saidSoFar).length >= 3;
    _saidSoFar.addAll(words);

    // Build the working context: top three, each with its definition summary.
    final items = <FocusItem>[];
    for (final f in focus.top()) {
      final ph = await store.phrasesFor(f.key.name);
      final sum = analysis.summarise(f.key.name, ph, reading: reading, unseen: unseen);
      items.add(FocusItem(
        entry: f.key,
        weight: f.value,
        summary: sum,
        openQuestion: _openQuestion(sum),
      ));
    }
    final ordered = pending.toList()
      ..sort((a, b) {
        final c = fallacyPriority(a).compareTo(fallacyPriority(b));
        return c != 0 ? c : b.when.compareTo(a.when);
      });
    final ctx = WorkingContext(items, pendingFallacies: ordered.map((h) => h.fallacy.name).toList());

    // Choose one question by precedence. A person just named for an axis
    // always gets the follow-up first.
    Question q;
    final follow = _pendingWhatWouldTheyDo;
    final chain = await _chainStep(transcript, ordered, now);
    if (chain != null) {
      q = chain;
    } else if (follow != null) {
      _pendingWhatWouldTheyDo = null;
      q = questions.whatWouldTheyDo(follow.$1, follow.$2);
    } else {
      q = _choose(items, axis, profile, named);
    }
    if (last != null && q.text == last.text) {
      q = addedNew ? questions.whenDidThatLastHappen() : questions.open();
    }
    _lastQuestion = q;
    return Turn(
      filed: filed,
      score: score,
      axis: axis,
      question: q,
      context: ctx,
      fallacies: hits,
      addedSomethingNew: addedNew,
    );
  }

  String _openQuestion(DefinitionSummary s) {
    if (s.phrases.isEmpty) return 'what it means in their words, and the last time';
    if (s.isPanacea) {
      return 'where it does not apply; what belongs to ${s.spaceTaken ?? "the unseen approach"} instead';
    }
    if (!s.hasBoundary) return 'where it does not apply';
    if (s.isBlindSpot) return 'who they know who does this well';
    return 'whether the definition still holds in the newest case';
  }

  /// Walk the active fallacy chain, or start one when the person asks the
  /// app something and a fallacy is pending. Never in the moment: the
  /// context of why it was used is data, and interrupting loses it.
  Future<Question?> _chainStep(String transcript, List<FallacyHit> ordered, DateTime now) async {
    if (_active != null) {
      final f = _active!.fallacy;
      _step++;
      if (_step < f.chain.length) return questions.chainStep(f.chain[_step], f.id);
      // Chain finished: the answer to the last step closes the record.
      final h = _active!;
      _active = null;
      _step = 0;
      pending.remove(h);
      if (h.entryId != null) {
        await store.annotate(h.entryId!, '${f.name} · "${h.cue}" · worked ${now.toIso8601String().substring(0, 10)}');
      }
      await store.add(Entry(
        folder: Folder.fallacies,
        text: transcript,
        created: now,
        approach: f.approach,
        note: 'answer to ${f.name}',
      ));
      return null;
    }
    if (ordered.isEmpty || !asksTheApp(transcript)) return null;
    _active = ordered.first;
    _step = 0;
    return questions.chainStep(_active!.fallacy.chain.first, _active!.fallacy.id);
  }

  Question _choose(List<FocusItem> items, AxisReading axis, Profile profile, String? named) {
    // 1. (Fallacies are handled before this, and only when asked.)
    // 2. The top focus item has no definition yet. One definition question
    // at a time, never two in a row, so the conversation is not a quiz.
    if (items.isNotEmpty && _lastQuestion?.kind != QuestionKind.definition) {
      final f = items.first;
      if (f.summary.phrases.length <= 1 && !_askedDefinition.contains(f.entry.name)) {
        _askedDefinition.add(f.entry.name);
        return questions.definition(f.entry.name);
      }
    }
    // 3. A panacea in focus: the boundary, then the person across the wheel.
    for (final f in items) {
      if (f.summary.isPanacea) {
        if (!_askedBoundary.contains(f.entry.name)) {
          _askedBoundary.add(f.entry.name);
          return questions.boundary(f.entry.name);
        }
        final space = f.summary.spaceTaken;
        if (space != null) {
          final person = profile.reframers[space];
          return person != null ? questions.whatWouldTheyDo(person, space) : questions.whoIsGoodAt(space);
        }
      }
    }
    // 4. A missing axis. 5. A person by one mechanism. 6. What happened before.
    final base = questions.choose(score: Score({}, 0), axis: axis, reframers: profile.reframers, named: named);
    if (base.kind == QuestionKind.whatHappenedBefore) {
      // Nothing louder: ask for a boundary on the top focus item if it has none.
      for (final f in items) {
        if (!f.summary.hasBoundary && !_askedBoundary.contains(f.entry.name) && f.summary.phrases.length > 1) {
          _askedBoundary.add(f.entry.name);
          return questions.boundary(f.entry.name);
        }
      }
    }
    return base;
  }

  Future<void> _recordAnswer(Question? last, String transcript, DateTime now, Profile profile) async {
    if (last == null) return;
    switch (last.kind) {
      case QuestionKind.whoIsGoodAt:
        final person = _extractPerson(transcript);
        if (person != null && last.approach != null) {
          profile.reframers[last.approach!] = person;
          await store.add(Entry(
            folder: Folder.people,
            text: transcript,
            created: now,
            person: person,
            approach: last.approach,
            note: 'good at ${last.approach}',
          ));
          await store.saveProfile(profile);
          _pendingWhatWouldTheyDo = (person, last.approach!);
        }
      case QuestionKind.whatWouldTheyDo:
        await store.add(Entry(
          folder: Folder.people,
          text: transcript,
          created: now,
          person: last.about,
          approach: last.approach,
          note: 'what ${last.about} would do',
        ));
      case QuestionKind.criterion:
        await store.add(Entry(folder: Folder.alarms, text: transcript, created: now, note: 'criterion'));
      case QuestionKind.chain:
        await store.add(Entry(
          folder: Folder.fallacies,
          text: transcript,
          created: now,
          note: 'answer in ${catalogue.byId(last.about ?? "")?.name ?? "chain"}',
        ));
      default:
        break;
    }
  }

  (String, String)? _pendingWhatWouldTheyDo;

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

  /// Summaries of every term the person has spoken about, for the profile screen.
  Future<List<DefinitionSummary>> definitions() async {
    final profile = await store.profile();
    final reading = _reading(profile);
    final unseen = reading == null ? <String>[] : taboo.unseen(reading);
    final all = await store.allPhrases();
    final out = all.entries
        .map((e) => analysis.summarise(e.key, e.value, reading: reading, unseen: unseen))
        .toList()
      ..sort((a, b) => b.breadth.compareTo(a.breadth));
    return out;
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
