import 'lexicon.dart';
import 'wheel.dart';

/// Watches a running profile of the person's speech and finds the axis
/// that is missing from one account although it is usually present.
class AxisWatch {
  AxisWatch();

  /// Cumulative hits per approach across everything the person has said.
  final Map<String, int> profile = {for (final a in Wheel.order) a: 0};
  int passages = 0;

  void learn(Score s) {
    passages++;
    s.byApproach().forEach((a, sc) {
      profile[a] = (profile[a] ?? 0) + sc.total;
    });
  }

  /// Which approaches the person habitually uses (top three by hits).
  List<String> habitual() {
    final sorted = Wheel.order.toList()
      ..sort((x, y) => profile[y]!.compareTo(profile[x]!));
    return sorted.take(3).toList();
  }

  /// Approaches never or rarely present in the profile.
  List<String> neverSeen() =>
      Wheel.order.where((a) => (profile[a] ?? 0) == 0).toList();

  /// For one account: the approach whose weapon is loudest, and the
  /// axes absent from the account. The missing axis to ask about is the
  /// first absent one that is not a habitual approach going quiet by chance:
  /// prefer an axis the person never uses, then one across the wheel from
  /// the loudest weapon (the tool that would answer it).
  AxisReading read(Score s, Wheel wheel) {
    final by = s.byApproach();
    String? loudestWeapon;
    var max = 0;
    by.forEach((a, sc) {
      if (sc.weaponHits > max) {
        max = sc.weaponHits;
        loudestWeapon = a;
      }
    });
    final absent = s.absent(Wheel.order);
    String? missing;
    final never = neverSeen();
    for (final a in absent) {
      if (never.contains(a)) {
        missing = a;
        break;
      }
    }
    if (missing == null && loudestWeapon != null) {
      for (final o in wheel.opposites(loudestWeapon!)) {
        if (absent.contains(o)) {
          missing = o;
          break;
        }
      }
    }
    missing ??= absent.isEmpty ? null : absent.first;
    return AxisReading(
      loudest: s.loudest(),
      loudestWeapon: loudestWeapon,
      absent: absent,
      missing: missing,
    );
  }
}

class AxisReading {
  AxisReading({
    required this.loudest,
    required this.loudestWeapon,
    required this.absent,
    required this.missing,
  });
  final String? loudest;
  final String? loudestWeapon;
  final List<String> absent;
  final String? missing;
}
