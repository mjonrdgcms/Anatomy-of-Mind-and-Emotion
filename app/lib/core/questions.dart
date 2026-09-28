import 'axis.dart';
import 'lexicon.dart';
import 'wheel.dart';

/// A question the app will ask by voice. [kind] says what it is for, so the
/// session can tell whether the answer added something new.
class Question {
  Question(this.kind, this.text, {this.approach, this.about});
  final QuestionKind kind;
  final String text;
  final String? approach;
  final String? about;

  @override
  String toString() => '[$kind] $text';
}

enum QuestionKind {
  whoIsGoodAt, // who do you know who is good at X
  whatWouldTheyDo, // what would that person likely do here
  threeWords, // three words for a person
  whatHappenedBefore, // situation before the emotion
  whenDidThatLastHappen, // a case, not resonance
  contraryElement, // the element that pushes the other way
  competentUse, // what the competent use of the tool would look like
  whoseEyes, // whose eyes are you seeing this through
  criterion, // the one thing to watch for and when to re-check
  chain, // a step in a fallacy's question chain
  exception, // when was a time it went differently
  proportion, // out of the last ten times, how many
  definition, // what does X mean when you use it; the last time
  boundary, // where does X not apply
  dislikedWeapons, // the survey
  favourites, // the favourite three
  open, // say more
}

/// Chooses one non-leading question at a time
/// (docs/conversation-method.md, section 3).
class QuestionBank {
  QuestionBank(this.wheel);
  final Wheel wheel;

  Question whoIsGoodAt(String approach) => Question(
        QuestionKind.whoIsGoodAt,
        'Who do you know who is good at this: someone who can ${wheel[approach].description}?',
        approach: approach,
      );

  Question whatWouldTheyDo(String person, String approach) => Question(
        QuestionKind.whatWouldTheyDo,
        'What would $person likely do here?',
        approach: approach,
        about: person,
      );

  Question threeWords(String person) => Question(
        QuestionKind.threeWords,
        'What three words come to mind for $person?',
        about: person,
      );

  Question whatHappenedBefore() => Question(
        QuestionKind.whatHappenedBefore,
        'What happened just before that?',
      );

  Question whenDidThatLastHappen() => Question(
        QuestionKind.whenDidThatLastHappen,
        'When did that last happen? Tell me the actual time.',
      );

  Question contrary(String element) => Question(
        QuestionKind.contraryElement,
        'One thing in what you said points the other way: $element. What do you make of that?',
        about: element,
      );

  Question competentUse(String toolName, String approach) => Question(
        QuestionKind.competentUse,
        'If someone used $toolName well here, rather than too much or not at all, what would that look like?',
        approach: approach,
        about: toolName,
      );

  Question whoseEyes() => Question(
        QuestionKind.whoseEyes,
        'Whose eyes are you seeing this through?',
      );

  Question criterion() => Question(
        QuestionKind.criterion,
        'What is the one thing to watch for, and when will you check again?',
      );

  Question dislikedWeapons() => Question(
        QuestionKind.dislikedWeapons,
        'Which three of these do you like least in other people?',
      );

  Question favourites() => Question(
        QuestionKind.favourites,
        'Which three of these ways of working do you enjoy most?',
      );

  Question open() => Question(QuestionKind.open, 'Say more about that.');

  Question chainStep(String text, String fallacyId) => Question(
        QuestionKind.chain,
        text,
        about: fallacyId,
      );

  Question exception(String? term) => Question(
        QuestionKind.exception,
        'When was a time it went differently?',
        about: term,
      );

  Question proportion(String? term) => Question(
        QuestionKind.proportion,
        'Out of the last ten times, how many went that way?',
        about: term,
      );

  Question definition(String term) => Question(
        QuestionKind.definition,
        'When you say $term, what does it mean for you? Tell me the last time it came up.',
        about: term,
      );

  Question boundary(String term) => Question(
        QuestionKind.boundary,
        'Where does $term not apply?',
        about: term,
      );

  /// Pick the next question for one passage. [named] is a person mentioned
  /// in the passage, if the router found one. [reframers] maps approaches to
  /// people the person has already named as good at them.
  Question choose({
    required Score score,
    required AxisReading axis,
    required Map<String, String> reframers,
    String? named,
    bool endOfSession = false,
  }) {
    if (endOfSession) return criterion();

    // A person described by one mechanism: ask for three words, not one.
    if (named != null) return threeWords(named);

    // A weapon is loud: ask what the competent use would look like,
    // through a person the dreamer already respects if one is on file.
    final loud = axis.loudestWeapon;
    if (loud != null) {
      final missing = axis.missing;
      if (missing != null) {
        final person = reframers[missing];
        if (person != null) return whatWouldTheyDo(person, missing);
        return whoIsGoodAt(missing);
      }
      final by = score.byApproach()[loud]!;
      final weapon = by.weapons.keys.first;
      final tool = wheel.find(weapon)?.tool ?? weapon;
      return competentUse(tool, loud);
    }

    // No weapon loud but an axis missing: the two questions.
    final missing = axis.missing;
    if (missing != null) {
      final person = reframers[missing];
      if (person != null) return whatWouldTheyDo(person, missing);
      return whoIsGoodAt(missing);
    }

    return whatHappenedBefore();
  }
}
