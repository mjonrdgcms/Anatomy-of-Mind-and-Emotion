import 'dart:convert';

import 'lexicon.dart';

/// A fallacy from grammar/fallacies.json: logical (the mind bypassed) or
/// meaningful (the heart bypassed), with the cues that detect it and the
/// chain of questions that lets the person see it for themselves.
class Fallacy {
  Fallacy({
    required this.id,
    required this.name,
    required this.side,
    required this.description,
    required this.cues,
    required this.chain,
    this.source,
    this.approach,
    this.category,
  });
  final String id;
  final String name;
  final String side; // logic | meaning
  final String description;
  final List<RegExp> cues;
  final List<String> chain;
  final String? source;
  final String? approach;

  /// 'cost' for hostility and vindictiveness: the uncounted cost.
  final String? category;

  bool get isMeaningful => side == 'meaning';
}

/// One occurrence, kept with its context and never raised in the moment.
class FallacyHit {
  FallacyHit({
    required this.fallacy,
    required this.sentence,
    required this.cue,
    required this.context,
    required this.about,
    required this.when,
    this.entryId,
  });
  final Fallacy fallacy;
  final String sentence;
  final String cue;

  /// The passage around the sentence, so the reason it was used is kept.
  final String context;

  /// Tools and weapons referenced in the same sentence.
  final List<LexEntry> about;
  final DateTime when;
  int? entryId;
}

class FallacyCatalogue {
  FallacyCatalogue._(this.fallacies);
  final List<Fallacy> fallacies;

  factory FallacyCatalogue.fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final list = (data['fallacies'] as List).map((raw) {
      final m = raw as Map<String, dynamic>;
      return Fallacy(
        id: m['id'] as String,
        name: m['name'] as String,
        side: m['side'] as String,
        description: m['description'] as String,
        cues: (m['cues'] as List).map((c) => RegExp(c as String, caseSensitive: false)).toList(),
        chain: List<String>.from(m['chain'] as List),
        source: m['source'] as String?,
        approach: m['approach'] as String?,
        category: m['category'] as String?,
      );
    }).toList();
    return FallacyCatalogue._(list);
  }

  Fallacy? byId(String id) {
    for (final f in fallacies) {
      if (f.id == id) return f;
    }
    return null;
  }
}

class FallacyDetector {
  FallacyDetector(this.catalogue, this.lexicon);
  final FallacyCatalogue catalogue;
  final Lexicon lexicon;

  static final _sentence = RegExp(r'(?<=[.!?])\s+');

  /// Every fallacy in the passage, at most one hit per fallacy per sentence.
  List<FallacyHit> detect(String passage, DateTime when) {
    final out = <FallacyHit>[];
    for (final s in passage.split(_sentence)) {
      final sent = s.trim();
      if (sent.isEmpty) continue;
      List<LexEntry>? about;
      for (final f in catalogue.fallacies) {
        for (final cue in f.cues) {
          final m = cue.firstMatch(sent);
          if (m != null) {
            about ??= lexicon.score(sent).hits.keys.toList();
            out.add(FallacyHit(
              fallacy: f,
              sentence: sent,
              cue: m.group(0)!,
              context: passage,
              about: about,
              when: when,
            ));
            break;
          }
        }
      }
    }
    return out;
  }
}

/// Which pending fallacy to work first: the double standard, then
/// hostility and vindictiveness (the uncounted cost), then other
/// meaningful ones, then logical ones; most recent first within each.
int fallacyPriority(FallacyHit h) {
  if (h.fallacy.id == 'double_standard') return 0;
  if (h.fallacy.category == 'cost') return 1;
  if (h.fallacy.isMeaningful) return 2;
  return 3;
}

/// Did the person ask the app something? That is when a chain may start.
final _askRe = RegExp(
    r"^\s*(what|why|how|should|do you|is it|is that|am i|are they|can you|could you|would you|any (idea|thoughts)|what do you (think|make)|help me)\b",
    caseSensitive: false);

bool asksTheApp(String transcript) {
  final t = transcript.trim();
  if (t.endsWith('?')) return true;
  if (_askRe.hasMatch(t)) return true;
  return RegExp(r"\b(what do you think|what should i do|what would you do|am i (wrong|right|crazy)|does that make sense)\b",
          caseSensitive: false)
      .hasMatch(t);
}
