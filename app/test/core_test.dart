import 'dart:io';

import 'package:anatomy_app/core/axis.dart';
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
      final s = Session(wheel: wheel, lexicon: lexicon, router: RuleRouter(lexicon), store: store);
      await s.load();
      final t1 = await s.hear(
          'At work today he just steamrolled the plan, he had already done it, total overreach and so stubborn.');
      expect(t1.question.kind, QuestionKind.whoIsGoodAt);
      final t2 = await s.hear('Probably my sister Anna, she is good at that.');
      expect(t2.question.kind, QuestionKind.whatWouldTheyDo);
      expect(t2.question.about, isNotNull);
      final p = await store.profile();
      expect(p.reframers.values, contains(t2.question.about));
      final people = await store.list(Folder.people);
      expect(people, isNotEmpty);
    });

    test('never asks the identical question twice running', () async {
      final store = MemoryStore();
      final s = Session(wheel: wheel, lexicon: lexicon, router: RuleRouter(lexicon), store: store);
      final a = await s.hear('Nothing much happened, it was quiet.');
      final b = await s.hear('Nothing much happened, it was quiet.');
      expect(a.question.text == b.question.text, isFalse);
    });

    test('survey stores favourites and dislikes', () async {
      final store = MemoryStore();
      final s = Session(wheel: wheel, lexicon: lexicon, router: RuleRouter(lexicon), store: store);
      final r = await s.survey(dislikedWeapons: ['Greed', 'Cowardice', 'Pessimism'], favourites: ['Unification']);
      expect(r.taboo, 'Preservation');
      expect(r.loadBearing, ['Unification', 'Implementation']);
      expect((await store.profile()).dislikedWeapons.length, 3);
    });
  });
}
