import 'dart:io';

import 'package:anatomy_app/core/axis.dart';
import 'package:anatomy_app/core/definitions.dart';
import 'package:anatomy_app/core/fallacies.dart';
import 'package:anatomy_app/core/folders.dart';
import 'package:anatomy_app/core/lexicon.dart';
import 'package:anatomy_app/core/questions.dart';
import 'package:anatomy_app/core/session.dart';
import 'package:anatomy_app/core/store.dart';
import 'package:anatomy_app/core/taboo.dart';
import 'package:anatomy_app/core/wheel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wheel = Wheel.fromJson(File('assets/grammar/approaches.json').readAsStringSync());
  final lexicon = Lexicon.fromJson(File('assets/grammar/lexicon.json').readAsStringSync());
  final catalogue = FallacyCatalogue.fromJson(File('assets/grammar/fallacies.json').readAsStringSync());
  Session newSession(MemoryStore store) => Session(
      wheel: wheel, lexicon: lexicon, router: RuleRouter(lexicon), store: store, catalogue: catalogue);

  group('wheel', () {
    test('loads seven approaches with eight tools each', () {
      expect(wheel.approaches.length, 7);
      for (final a in wheel.approaches.values) {
        expect(a.tools.length, 8, reason: a.name);
        expect(a.polesWhole.length, 6);
        expect(a.bridge.length, 2);
      }
      expect(wheel.allTools.length, 56);
    });

    test('opposites are across the wheel', () {
      expect(wheel.opposites('Implementation'), ['Preservation', 'Expansion']);
      expect(wheel.opposites('Initiation'), ['Expansion', 'Transformation']);
    });

    test('finds tools and weapons by name', () {
      expect(wheel.approachOf('Hope'), 'Unification');
      expect(wheel.approachOf('Scapegoating'), 'Initiation');
      expect(wheel.approachOf('tyranny'), 'Unification');
      expect(wheel.find('Optimism')!.side, 'asset');
      expect(wheel.find('Optimism')!.symbol, '●');
    });

    test('asset half sits in the first bridge pole', () {
      final u = wheel['Unification'];
      final hope = u.quadrants.firstWhere((q) => q.pairTool == 'Hope');
      expect(hope.halfPole, 'Future');
      expect(hope.sub.first.definedBy, contains('Future'));
    });
  });

  group('lexicon', () {
    test('has 168 entries and scores words and phrases', () {
      expect(lexicon.entries.length, 168);
      final s = lexicon.score('I kept procrastinating and then I had to follow up with him.');
      final names = s.hits.keys.map((e) => e.name).toSet();
      expect(names, contains('Procrastination'));
      expect(names, contains('Follow-up'));
    });

    test('weapon share and loudest approach', () {
      final s = lexicon.score(
          'He is such a tyrant, always dominating, controlling and micromanaging everyone.');
      final by = s.byApproach();
      expect(s.loudest(), 'Unification');
      expect(by['Unification']!.weaponShare, greaterThan(0.5));
    });
  });

  group('taboo', () {
    test('three disliked weapons give a taboo and a load-bearing pair', () {
      final r = Taboo(wheel).read(
        dislikedWeapons: ['Tyranny', 'Nosey', 'Enmeshment'],
        favourites: ['Deconstruction', 'Preservation', 'Initiation'],
      );
      expect(r.taboo, 'Unification');
      expect(r.loadBearing, ['Deconstruction', 'Preservation']);
      expect(r.agreements, ['Deconstruction', 'Preservation']);
      expect(r.disagreements, ['Initiation']);
    });

    test('unseen axes exclude favourites and load-bearing', () {
      final t = Taboo(wheel);
      final r = t.read(dislikedWeapons: ['Mania'], favourites: ['Preservation']);
      expect(r.taboo, 'Implementation');
      expect(t.unseen(r), isNot(contains('Preservation')));
      expect(t.unseen(r), isNot(contains('Expansion')));
    });
  });

  group('axis', () {
    test('finds the missing axis across from the loud weapon', () {
      final w = AxisWatch();
      final s = lexicon.score(
          'She just steamrolls everyone, she already did it, overreach, stubborn as always.');
      w.learn(s);
      final r = w.read(s, wheel);
      expect(r.loudestWeapon, 'Implementation');
      expect(r.missing, isNotNull);
      expect(r.absent, contains(r.missing));
    });
  });

  group('router', () {
    final router = RuleRouter(lexicon);
    test('routes dreams, alarms, people, waking and loose', () async {
      expect((await router.route('Last night I dreamt I was in my old kitchen.')).folder, Folder.dreams);
      expect((await router.route("I can't stop checking my phone, I am on edge.")).folder, Folder.alarms);
      expect((await router.route('My brother is always so controlling.')).folder, Folder.people);
      expect((await router.route('At work today the meeting ran long.')).folder, Folder.waking);
      expect((await router.route('Hmm.')).folder, Folder.loose);
    });

    test('splits passages at topic shifts', () {
      final p = splitPassages('I dreamt of a dog. And then at work my boss yelled. Also, I called my mother.');
      expect(p.length, 3);
    });
  });

  group('session', () {
    test('asks who is good at the missing axis, then what they would do', () async {
      final store = MemoryStore();
      final s = newSession(store);
      await s.load();
      final t1 = await s.hear(
          'At work today he just steamrolled the plan, he had already done it, total overreach and so stubborn.');
      // A term new to the profile is defined first, in the person's words.
      expect(t1.question.kind, QuestionKind.definition);
      final t2 = await s.hear('It is when someone pushes a decision through without asking, like he did with the rota.');
      expect(t2.question.kind, QuestionKind.whoIsGoodAt);
      final t3 = await s.hear('Probably my sister Anna, she is good at that.');
      expect(t3.question.kind, QuestionKind.whatWouldTheyDo);
      expect(t3.question.about, isNotNull);
      final p = await store.profile();
      expect(p.reframers.values, contains(t3.question.about));
      final people = await store.list(Folder.people);
      expect(people, isNotEmpty);
    });

    test('never asks the identical question twice running', () async {
      final store = MemoryStore();
      final s = newSession(store);
      final a = await s.hear('Nothing much happened, it was quiet.');
      final b = await s.hear('Nothing much happened, it was quiet.');
      expect(a.question.text == b.question.text, isFalse);
    });

    test('survey stores favourites and dislikes', () async {
      final store = MemoryStore();
      final s = newSession(store);
      final r = await s.survey(dislikedWeapons: ['Greed', 'Cowardice', 'Pessimism'], favourites: ['Unification']);
      expect(r.taboo, 'Preservation');
      expect(r.loadBearing, ['Unification', 'Implementation']);
      expect((await store.profile()).dislikedWeapons.length, 3);
    });
  });

  group('fallacies', () {
    final d = FallacyDetector(catalogue, lexicon);
    test('detects an overgeneralisation and what it is about', () {
      final hits = d.detect('He never follows up. We had lunch.', DateTime(2026));
      expect(hits.length, 1);
      expect(hits.first.fallacy.id, 'overgeneralization');
      expect(hits.first.about.map((e) => e.name), contains('Follow-up'));
    });
    test('detects the double standard and keeps the context', () {
      final text = 'I was late because the traffic was terrible. When I am late it is different, but when she is late she just does not care.';
      final hits = d.detect(text, DateTime(2026));
      expect(hits.map((h) => h.fallacy.id), contains('double_standard'));
      expect(hits.first.context, text);
    });
    test('a double standard comes before a logical fallacy', () {
      final hits = d.detect('Everyone knows that. It is different when I do it.', DateTime(2026));
      hits.sort((a, b) => fallacyPriority(a).compareTo(fallacyPriority(b)));
      expect(hits.first.fallacy.id, 'double_standard');
    });
    test('knows when the person asks the app', () {
      expect(asksTheApp('What do you think I should do?'), isTrue);
      expect(asksTheApp('Am I wrong here'), isTrue);
      expect(asksTheApp('Then we went home.'), isFalse);
    });
  });

  group('definitions', () {
    test('collects phrases per term with co-occurring approaches', () {
      final c = DefinitionCollector(lexicon, wheel);
      final text = 'I try to be honest about it. In general the structure matters more than the hope.';
      final ph = c.extract(text, lexicon.score(text), Folder.waking, DateTime(2026, 9, 1));
      final terms = ph.map((p) => p.term).toSet();
      expect(terms, contains('Honesty'));
      expect(terms, contains('General'));
      final honesty = ph.firstWhere((p) => p.term == 'Honesty');
      expect(honesty.approach, 'Implementation');
    });

    test('a broad definition with no boundary on a lived approach is a panacea', () {
      final a = DefinitionAnalysis(wheel);
      final reading = Taboo(wheel).read(
          dislikedWeapons: ['Tyranny', 'Nosey', 'Enmeshment'],
          favourites: ['Deconstruction', 'Preservation', 'Implementation']);
      final unseen = Taboo(wheel).unseen(reading);
      final phrases = [
        for (var i = 0; i < 5; i++)
          Phrase(
            term: 'Honesty',
            kind: 'tool',
            approach: 'Implementation',
            text: 'honesty is what matters here',
            created: DateTime(2026, 1, 1).add(Duration(days: 7 * i)),
            folder: Folder.values[i % 4],
            coApproaches: const ['Preservation'],
          ),
      ];
      final s = a.summarise('Honesty', phrases, reading: reading, unseen: unseen);
      expect(s.isPanacea, isTrue);
      expect(s.breadth, greaterThanOrEqualTo(4));
      expect(unseen, contains(s.spaceTaken));
      final bounded = [
        ...phrases,
        Phrase(
          term: 'Honesty',
          kind: 'tool',
          approach: 'Implementation',
          text: 'honesty does not apply when someone is grieving',
          created: DateTime(2026, 3, 1),
          folder: Folder.waking,
          coApproaches: const [],
          isBoundary: true,
        ),
      ];
      expect(a.summarise('Honesty', bounded, reading: reading, unseen: unseen).isPanacea, isFalse);
    });
  });

  group('context', () {
    test('archives the transcript outside the folders and keeps three focus items', () async {
      final store = MemoryStore();
      final s = newSession(store);
      final t = await s.hear(
          'At work I stay honest and keep the structure, and I am diligent about it, whatever the pessimism around me.');
      expect((await store.list(Folder.archive)).length, 1);
      expect((await store.recent()).any((e) => e.folder == Folder.archive), isFalse);
      expect(t.context.items.length, lessThanOrEqualTo(3));
      expect(t.context.items, isNotEmpty);
      expect(t.context.toPrompt(), contains('open question'));
      expect((await store.search('diligent')).length, 1);
      expect((await store.search('unicorn')), isEmpty);
    });

    test('a fallacy is recorded silently and worked only when the person asks', () async {
      final store = MemoryStore();
      final s = newSession(store);
      final t1 = await s.hear(
          'She was late again and I was furious. When I am late it is different, but when she is late she just does not care.');
      expect(t1.fallacies.map((h) => h.fallacy.id), contains('double_standard'));
      expect(t1.question.kind, isNot(QuestionKind.chain));
      expect((await store.list(Folder.fallacies)).first.note, endsWith('pending'));
      expect(t1.context.toPrompt(), contains('pending, not yet raised: Double standard'));

      final t2 = await s.hear('What do you think I should do about it?');
      expect(t2.question.kind, QuestionKind.chain);
      expect(t2.question.text, startsWith('What would it look like if we reversed the roles?'));

      final t3 = await s.hear('I suppose I would want a bit of slack, I would explain.');
      expect(t3.question.kind, QuestionKind.chain);
      expect(t3.question.text, startsWith('And what are all the reasons'));

      final t4 = await s.hear('She has the kids to drop off, her car is old, and she probably thinks I am strict.');
      expect(t4.question.kind, QuestionKind.chain);
      final t5 = await s.hear('It looks smaller, honestly.');
      expect(t5.question.kind, isNot(QuestionKind.chain));
      expect(s.pending, isEmpty);
      final notes = (await store.list(Folder.fallacies)).map((e) => e.note ?? '').toList();
      expect(notes.any((n) => n.contains('worked')), isTrue);
    });

    test('pending fallacies survive a restart', () async {
      final store = MemoryStore();
      final s1 = newSession(store);
      await s1.hear('Everyone knows he is impossible to work with.');
      final s2 = newSession(store);
      await s2.load();
      expect(s2.pending.map((h) => h.fallacy.id), contains('overgeneralization'));
    });

    test('a new focus term gets the definition question', () async {
      final store = MemoryStore();
      final s = newSession(store);
      final t = await s.hear('I did some budgeting for the trip and it went fine.');
      expect(t.question.kind, QuestionKind.definition);
      final t2 = await s.hear('It means I set the amount first and stick to it, last week for the car.');
      expect((await store.phrasesFor(t.question.about!)).length, greaterThanOrEqualTo(2));
      expect(t2.question.kind, isNot(QuestionKind.definition));
    });
  });
}
