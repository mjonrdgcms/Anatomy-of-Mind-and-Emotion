import 'lexicon.dart';

/// Black-and-white thinking: an absolute or a hyperbole means the
/// definition is being missed (docs/context-and-definitions.md, section 5).
class Absolute {
  Absolute({required this.sentence, required this.words, required this.about});
  final String sentence;
  final List<String> words;

  /// Tools and weapons referenced in the same sentence.
  final List<LexEntry> about;
}

class AbsoluteDetector {
  AbsoluteDetector(this.lexicon);
  final Lexicon lexicon;

  static final _re = RegExp(
      r"\b(always|never|everyone|everybody|no ?one|nobody|everything|nothing|every (single )?time|all the time|"
      r"completely|totally|absolutely|entirely|impossible|the only|the worst|the best|ruined|disaster|perfect(ly)?|"
      r"literally|a hundred percent|100 ?%|forever|can't ever|cannot ever|no way|not once|without exception|"
      r"every ?one of them|none of them|all of them|hopeless|useless|pointless)\b",
      caseSensitive: false);

  static final _sentence = RegExp(r'(?<=[.!?])\s+');

  List<Absolute> detect(String text) {
    final out = <Absolute>[];
    for (final s in text.split(_sentence)) {
      final ms = _re.allMatches(s).map((m) => m.group(0)!.toLowerCase()).toList();
      if (ms.isEmpty) continue;
      final about = lexicon.score(s).hits.keys.toList();
      out.add(Absolute(sentence: s.trim(), words: ms, about: about));
    }
    return out;
  }
}
