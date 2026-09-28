import 'dart:convert';

/// The author's text-analysis word lists (grammar/lexicon.json) and a
/// scorer that counts hits per tool and weapon in a passage.
class Lexicon {
  Lexicon._(this.entries) {
    for (final e in entries) {
      for (final w in e.words) {
        final toks = _tokens(w);
        if (toks.isEmpty) continue;
        _index.putIfAbsent(toks.first, () => []).add(_Phrase(toks, e));
        if (toks.length > _maxLen) _maxLen = toks.length;
      }
    }
  }

  final List<LexEntry> entries;
  final Map<String, List<_Phrase>> _index = {};
  int _maxLen = 1;

  factory Lexicon.fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final raw = data['approaches'] as Map<String, dynamic>;
    final list = <LexEntry>[];
    raw.forEach((approach, v) {
      for (final e in v as List) {
        final m = e as Map<String, dynamic>;
        list.add(LexEntry(
          approach: approach,
          name: m['name'] as String,
          isWeapon: m['polarity'] == 'weapon',
          isPair: m['pair'] as bool,
          words: List<String>.from(m['words'] as List),
        ));
      }
    });
    return Lexicon._(list);
  }

  static final _wordRe = RegExp(r"[a-z0-9]+(?:['\-][a-z0-9]+)*");

  static List<String> _tokens(String s) =>
      _wordRe.allMatches(s.toLowerCase()).map((m) => m.group(0)!).toList();

  /// Score a passage. Longest phrase match wins at each position.
  Score score(String text) {
    final toks = _tokens(text);
    final hits = <LexEntry, List<String>>{};
    var i = 0;
    while (i < toks.length) {
      final cands = _index[toks[i]];
      _Phrase? best;
      if (cands != null) {
        for (final p in cands) {
          if (i + p.toks.length > toks.length) continue;
          var ok = true;
          for (var k = 1; k < p.toks.length; k++) {
            if (toks[i + k] != p.toks[k]) {
              ok = false;
              break;
            }
          }
          if (ok && (best == null || p.toks.length > best.toks.length)) {
            best = p;
          }
        }
      }
      if (best != null) {
        hits.putIfAbsent(best.entry, () => []).add(best.toks.join(' '));
        i += best.toks.length;
      } else {
        i++;
      }
    }
    return Score(hits, toks.length);
  }
}

class LexEntry {
  LexEntry({
    required this.approach,
    required this.name,
    required this.isWeapon,
    required this.isPair,
    required this.words,
  });
  final String approach;
  final String name;
  final bool isWeapon;
  final bool isPair;
  final List<String> words;

  @override
  String toString() => '$name (${isWeapon ? "weapon" : "tool"}, $approach)';
}

class _Phrase {
  _Phrase(this.toks, this.entry);
  final List<String> toks;
  final LexEntry entry;
}

class Score {
  Score(this.hits, this.tokenCount);

  /// Matched words per entry.
  final Map<LexEntry, List<String>> hits;
  final int tokenCount;

  int count(LexEntry e) => hits[e]?.length ?? 0;

  /// Hits per approach, split into tools and weapons.
  Map<String, ApproachScore> byApproach() {
    final out = <String, ApproachScore>{};
    hits.forEach((e, ws) {
      final s = out.putIfAbsent(e.approach, () => ApproachScore(e.approach));
      if (e.isWeapon) {
        s.weaponHits += ws.length;
        s.weapons.update(e.name, (v) => v + ws.length, ifAbsent: () => ws.length);
      } else {
        s.toolHits += ws.length;
        s.tools.update(e.name, (v) => v + ws.length, ifAbsent: () => ws.length);
      }
    });
    return out;
  }

  /// Approaches with no hits at all in this passage.
  List<String> absent(List<String> all) =>
      all.where((a) => !hits.keys.any((e) => e.approach == a)).toList();

  /// The approach with the most hits, or null if none.
  String? loudest() {
    final b = byApproach();
    if (b.isEmpty) return null;
    final sorted = b.values.toList()..sort((x, y) => y.total.compareTo(x.total));
    return sorted.first.approach;
  }
}

class ApproachScore {
  ApproachScore(this.approach);
  final String approach;
  int toolHits = 0;
  int weaponHits = 0;
  final Map<String, int> tools = {};
  final Map<String, int> weapons = {};
  int get total => toolHits + weaponHits;
  double get weaponShare => total == 0 ? 0 : weaponHits / total;
}
