import 'wheel.dart';

/// The disliked-weapon survey and the favourite three
/// (docs/conversation-method.md, section 2).
class TabooReading {
  TabooReading({
    required this.dislikedWeapons,
    required this.tabooApproaches,
    required this.loadBearing,
    required this.favourites,
    required this.agreements,
    required this.disagreements,
  });

  /// The three (or more) weapon names the person dislikes most.
  final List<String> dislikedWeapons;

  /// Approaches the dislikes cluster in, most disliked first.
  final List<String> tabooApproaches;

  /// Approaches across the wheel from the taboos: where the person lives.
  final List<String> loadBearing;

  /// The favourite three approaches the person chose by description.
  final List<String> favourites;

  /// Favourites that sit across the wheel from a taboo (as the theory predicts).
  final List<String> agreements;

  /// Favourites that do not, which is itself a question.
  final List<String> disagreements;

  /// The single strongest taboo, if any.
  String? get taboo => tabooApproaches.isEmpty ? null : tabooApproaches.first;
}

class Taboo {
  Taboo(this.wheel);
  final Wheel wheel;

  TabooReading read({
    required List<String> dislikedWeapons,
    List<String> favourites = const [],
  }) {
    final counts = <String, int>{};
    for (final w in dislikedWeapons) {
      final a = wheel.approachOf(w);
      if (a != null) counts.update(a, (v) => v + 1, ifAbsent: () => 1);
    }
    final taboos = counts.keys.toList()
      ..sort((x, y) {
        final c = counts[y]!.compareTo(counts[x]!);
        return c != 0 ? c : Wheel.order.indexOf(x).compareTo(Wheel.order.indexOf(y));
      });

    final load = <String>[];
    for (final t in taboos) {
      for (final o in wheel.opposites(t)) {
        if (!load.contains(o) && !taboos.contains(o)) load.add(o);
      }
    }

    final agree = <String>[];
    final disagree = <String>[];
    for (final f in favourites) {
      if (load.contains(f)) {
        agree.add(f);
      } else {
        disagree.add(f);
      }
    }
    return TabooReading(
      dislikedWeapons: dislikedWeapons,
      tabooApproaches: taboos,
      loadBearing: load,
      favourites: favourites,
      agreements: agree,
      disagreements: disagree,
    );
  }

  /// The approaches the person is not seeing, given favourites and taboos.
  /// These are the axes the missing-axis question is for.
  List<String> unseen(TabooReading r) {
    return Wheel.order
        .where((a) => !r.favourites.contains(a) && !r.loadBearing.contains(a))
        .toList();
  }
}
