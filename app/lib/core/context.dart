import 'definitions.dart';
import 'lexicon.dart';

/// The working context: the three tools or weapons currently referenced,
/// each with a summary of the question about it
/// (docs/context-and-definitions.md, section 3).
class FocusItem {
  FocusItem({required this.entry, required this.weight, required this.summary, required this.openQuestion});
  final LexEntry entry;
  final double weight;
  final DefinitionSummary summary;
  final String openQuestion;
}

class WorkingContext {
  WorkingContext(this.items, {this.lastAbsolute});
  final List<FocusItem> items;
  final String? lastAbsolute;

  /// The compact form handed to a model, or shown on screen.
  String toPrompt() {
    final b = StringBuffer();
    for (final f in items) {
      final e = f.entry;
      b.writeln('${e.name} (${e.isWeapon ? "weapon" : "tool"} of ${e.approach}):');
      final r = f.summary.recent();
      if (r.isEmpty) {
        b.writeln('  no definition in their words yet');
      } else {
        for (final s in r) {
          b.writeln('  they said: "$s"');
        }
      }
      b.writeln('  breadth ${f.summary.breadth}'
          '${f.summary.hasBoundary ? ", has a boundary" : ", no boundary yet"}'
          '${f.summary.isPanacea ? ", panacea taking the place of ${f.summary.spaceTaken ?? "an unseen approach"}" : ""}'
          '${f.summary.isBlindSpot ? ", blind spot" : ""}');
      b.writeln('  open question: ${f.openQuestion}');
    }
    if (lastAbsolute != null) b.writeln('last absolute: "$lastAbsolute"');
    return b.toString().trimRight();
  }
}

/// Recency-weighted focus over lexicon entries.
class Focus {
  final Map<LexEntry, double> _w = {};
  static const decay = 0.6;

  void learn(Score s) {
    for (final k in _w.keys.toList()) {
      _w[k] = _w[k]! * decay;
      if (_w[k]! < 0.05) _w.remove(k);
    }
    s.hits.forEach((e, ws) {
      _w.update(e, (v) => v + ws.length, ifAbsent: () => ws.length.toDouble());
    });
  }

  List<MapEntry<LexEntry, double>> top([int n = 3]) {
    final l = _w.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return l.take(n).toList();
  }
}
