import 'folders.dart';
import 'lexicon.dart';
import 'taboo.dart';
import 'wheel.dart';

/// One phrase the person used about a term (approach, pole, tool or weapon).
class Phrase {
  Phrase({
    this.id,
    required this.term,
    required this.kind, // approach | pole | tool | weapon
    required this.approach,
    required this.text,
    required this.created,
    required this.folder,
    required this.coApproaches,
    this.isBoundary = false,
  });
  final int? id;
  final String term;
  final String kind;
  final String approach;
  final String text;
  final DateTime created;
  final Folder folder;

  /// Other approaches present in the same passage.
  final List<String> coApproaches;

  /// The person said where the term does not apply.
  final bool isBoundary;

  Map<String, Object?> toMap() => {
        'id': id,
        'term': term,
        'kind': kind,
        'approach': approach,
        'text': text,
        'created': created.toIso8601String(),
        'folder': folder.name,
        'co': coApproaches.join('|'),
        'boundary': isBoundary ? 1 : 0,
      };

  static Phrase fromMap(Map<String, Object?> m) => Phrase(
        id: m['id'] as int?,
        term: m['term'] as String,
        kind: m['kind'] as String,
        approach: m['approach'] as String,
        text: m['text'] as String,
        created: DateTime.parse(m['created'] as String),
        folder: Folder.values.byName(m['folder'] as String),
        coApproaches: (m['co'] as String? ?? '').split('|').where((s) => s.isNotEmpty).toList(),
        isBoundary: (m['boundary'] as int? ?? 0) == 1,
      );
}

/// Pulls the person's phrases about each term out of a passage.
class DefinitionCollector {
  DefinitionCollector(this.lexicon, this.wheel);
  final Lexicon lexicon;
  final Wheel wheel;

  static final _sentence = RegExp(r'(?<=[.!?])\s+');
  static final _boundary = RegExp(
      r"\b(doesn't apply|does not apply|not (always|every)|except|unless|only when|but not|sometimes|depends|"
      r"not (in|for|with) (this|that|every|all)|there are times)\b",
      caseSensitive: false);

  /// Poles, by the words people use for them.
  static const poleWords = {
    'Direct': ['direct', 'directly', 'head on', 'straight to'],
    'Indirect': ['indirect', 'indirectly', 'roundabout', 'around it'],
    'Specific': ['specific', 'specifically', 'in particular', 'this case'],
    'General': ['general', 'generally', 'in general', 'overall', 'big picture'],
    'Future': ['future', 'later', 'long term', 'someday', 'eventually'],
    'Present': ['present', 'right now', 'today', 'at the moment', 'currently'],
    'Interactive': ['together', 'with them', 'back and forth', 'discuss it'],
    'Speculative': ['speculate', 'in theory', 'hypothetically', 'what if', 'imagine if'],
    'Simple': ['simple', 'simply', 'straightforward', 'step by step', 'linear'],
    'Complex': ['complex', 'complicated', 'nonlinear', 'tangled', 'many moving parts'],
    'Process': ['process', 'bottom up', 'as we go', 'one thing at a time', 'how it is done'],
    'Result': ['result', 'results', 'top down', 'outcome', 'the end goal', 'bottom line'],
    'Flexible': ['flexible', 'impartial', 'open to', 'either way', 'adapt'],
    'Rigid': ['rigid', 'strict', 'partial', 'no matter what', 'stick to'],
  };

  List<Phrase> extract(String passage, Score score, Folder folder, DateTime when) {
    final out = <Phrase>[];
    final co = score.byApproach().keys.toList()..sort();
    for (final s in passage.split(_sentence)) {
      final sent = s.trim();
      if (sent.isEmpty) continue;
      final lower = sent.toLowerCase();
      final isBoundary = _boundary.hasMatch(sent);
      final ss = lexicon.score(sent);
      for (final e in ss.hits.keys) {
        out.add(Phrase(
          term: e.name,
          kind: e.isWeapon ? 'weapon' : 'tool',
          approach: e.approach,
          text: sent,
          created: when,
          folder: folder,
          coApproaches: co.where((a) => a != e.approach).toList(),
          isBoundary: isBoundary,
        ));
      }
      for (final a in Wheel.order) {
        if (lower.contains(a.toLowerCase())) {
          out.add(Phrase(
            term: a,
            kind: 'approach',
            approach: a,
            text: sent,
            created: when,
            folder: folder,
            coApproaches: co.where((x) => x != a).toList(),
            isBoundary: isBoundary,
          ));
        }
      }
      poleWords.forEach((pole, words) {
        if (words.any((w) => RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(lower))) {
          out.add(Phrase(
            term: pole,
            kind: 'pole',
            approach: _bridging(pole),
            text: sent,
            created: when,
            folder: folder,
            coApproaches: co,
            isBoundary: isBoundary,
          ));
        }
      });
    }
    return out;
  }

  String _bridging(String pole) {
    for (final a in wheel.approaches.values) {
      if (a.bridge.contains(pole)) return a.name;
    }
    return '';
  }
}

/// How broad a term's definition has become, and whether it is a panacea
/// or a blind spot (docs/context-and-definitions.md, section 4).
class DefinitionSummary {
  DefinitionSummary({
    required this.term,
    required this.kind,
    required this.approach,
    required this.phrases,
    required this.breadth,
    required this.hasBoundary,
    required this.isPanacea,
    required this.isBlindSpot,
    required this.spaceTaken,
  });
  final String term;
  final String kind;
  final String approach;
  final List<Phrase> phrases;

  /// Distinct situations: folders + co-occurring approaches + weeks.
  final int breadth;
  final bool hasBoundary;
  final bool isPanacea;
  final bool isBlindSpot;

  /// For a panacea: the unseen approach whose place it is taking.
  final String? spaceTaken;

  /// The last few things the person said about it, for the working context.
  List<String> recent([int n = 3]) {
    final sorted = phrases.toList()..sort((a, b) => b.created.compareTo(a.created));
    return sorted.take(n).map((p) => p.text).toList();
  }
}

class DefinitionAnalysis {
  DefinitionAnalysis(this.wheel);
  final Wheel wheel;

  /// Breadth at or above this, with no boundary, on a favourite or
  /// load-bearing approach, is a panacea.
  static const panaceaBreadth = 4;

  /// And at least this many phrases, so two sentences cannot make one.
  static const panaceaPhrases = 4;

  DefinitionSummary summarise(
    String term,
    List<Phrase> phrases, {
    required TabooReading? reading,
    required List<String> unseen,
  }) {
    if (phrases.isEmpty) {
      final t = wheel.find(term);
      final approach = t?.approach ?? term;
      return DefinitionSummary(
        term: term,
        kind: t == null ? 'approach' : (t.weapon == term ? 'weapon' : 'tool'),
        approach: approach,
        phrases: const [],
        breadth: 0,
        hasBoundary: false,
        isPanacea: false,
        isBlindSpot: unseen.contains(approach),
        spaceTaken: null,
      );
    }
    final p0 = phrases.first;
    final situations = <String>{};
    for (final p in phrases) {
      situations.add('f:${p.folder.name}');
      for (final c in p.coApproaches) {
        situations.add('a:$c');
      }
      final w = p.created.difference(DateTime(2020)).inDays ~/ 7;
      situations.add('w:$w');
    }
    final hasBoundary = phrases.any((p) => p.isBoundary);
    final lived = reading == null
        ? <String>[]
        : [...reading.favourites, ...reading.loadBearing];
    final isPanacea = phrases.length >= panaceaPhrases &&
        situations.length >= panaceaBreadth &&
        !hasBoundary &&
        (lived.isEmpty || lived.contains(p0.approach));

    String? space;
    if (isPanacea) {
      final absentCounts = <String, int>{};
      for (final p in phrases) {
        for (final u in unseen) {
          if (!p.coApproaches.contains(u) && u != p.approach) {
            absentCounts.update(u, (v) => v + 1, ifAbsent: () => 1);
          }
        }
      }
      if (absentCounts.isNotEmpty) {
        final opp = wheel.opposites(p0.approach);
        final ranked = absentCounts.keys.toList()
          ..sort((x, y) {
            final c = absentCounts[y]!.compareTo(absentCounts[x]!);
            if (c != 0) return c;
            return (opp.contains(x) ? 0 : 1).compareTo(opp.contains(y) ? 0 : 1);
          });
        space = ranked.first;
      }
    }
    return DefinitionSummary(
      term: term,
      kind: p0.kind,
      approach: p0.approach,
      phrases: phrases,
      breadth: situations.length,
      hasBoundary: hasBoundary,
      isPanacea: isPanacea,
      isBlindSpot: phrases.isEmpty && unseen.contains(p0.approach),
      spaceTaken: space,
    );
  }
}
