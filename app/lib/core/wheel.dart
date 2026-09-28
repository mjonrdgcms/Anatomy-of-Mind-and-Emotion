import 'dart:convert';

/// The seven approaches, their poles, halves, tools and weapons,
/// loaded from grammar/approaches.json (see docs/approach-wheel.md).
class Wheel {
  Wheel._(this.approaches);

  final Map<String, Approach> approaches;

  static const order = [
    'Initiation',
    'Deconstruction',
    'Expansion',
    'Unification',
    'Implementation',
    'Preservation',
    'Transformation',
  ];

  /// What each approach does, for asking without naming it.
  static const described = {
    'Initiation': 'recognise a situation and make contact with it',
    'Deconstruction': 'take a thing apart and test what is really there',
    'Expansion': 'see the bigger category a case belongs to and try something new',
    'Unification': 'bring people and parts together so the present works',
    'Implementation': 'commit to one course and carry it through',
    'Preservation': 'prepare, insulate and keep things safe for later',
    'Transformation': 'step back, compare the process with the result, and let go of what no longer fits',
  };

  static const axis = {
    'Initiation': 'functionality',
    'Deconstruction': 'reproducibility',
    'Expansion': 'perspective',
    'Unification': 'harmony',
    'Implementation': 'stability',
    'Preservation': 'certainty',
    'Transformation': 'excellence',
  };

  static const emotion = {
    'Initiation': 'contempt',
    'Deconstruction': 'sadness',
    'Expansion': 'surprise',
    'Unification': 'happiness',
    'Implementation': 'anger',
    'Preservation': 'fear',
    'Transformation': 'disgust',
  };

  factory Wheel.fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final raw = data['approaches'] as Map<String, dynamic>;
    final map = <String, Approach>{};
    raw.forEach((name, v) {
      map[name] = Approach.fromJson(name, v as Map<String, dynamic>);
    });
    return Wheel._(map);
  }

  Approach operator [](String name) => approaches[name]!;

  Iterable<Tool> get allTools => approaches.values.expand((a) => a.tools);

  /// Every weapon name on the wheel, with the approach it belongs to.
  Iterable<Tool> get allWeapons => allTools;

  /// Find the tool whose tool name or weapon name matches.
  Tool? find(String name) {
    final n = name.toLowerCase();
    for (final t in allTools) {
      if (t.tool.toLowerCase() == n || t.weapon.toLowerCase() == n) return t;
    }
    for (final a in approaches.values) {
      for (final q in a.quadrants) {
        if (q.pairTool.toLowerCase() == n || q.pairWeapon.toLowerCase() == n) {
          return q.sub.first;
        }
      }
    }
    return null;
  }

  /// The approach a tool or weapon name belongs to.
  String? approachOf(String toolOrWeapon) => find(toolOrWeapon)?.approach;

  /// The two approaches across the wheel from [name].
  List<String> opposites(String name) => this[name].oppositeApproaches;
}

class Approach {
  Approach({
    required this.name,
    required this.number,
    required this.colour,
    required this.polesWhole,
    required this.bridge,
    required this.oppositeApproaches,
    required this.quadrants,
  });

  final String name;
  final int number;
  final String colour;
  final List<String> polesWhole;
  final List<String> bridge;
  final List<String> oppositeApproaches;
  final List<Quadrant> quadrants;

  List<Tool> get tools => quadrants.expand((q) => q.sub).toList();
  String get assetPole => bridge[0];
  String get riskPole => bridge[1];
  String get description => Wheel.described[name]!;
  String get axis => Wheel.axis[name]!;
  String get emotion => Wheel.emotion[name]!;

  factory Approach.fromJson(String name, Map<String, dynamic> j) {
    return Approach(
      name: name,
      number: j['number'] as int,
      colour: j['colour'] as String,
      polesWhole: List<String>.from(j['poles_whole'] as List),
      bridge: List<String>.from(j['bridge'] as List),
      oppositeApproaches: List<String>.from(j['opposite_approaches'] as List),
      quadrants: (j['tools'] as List)
          .map((q) => Quadrant.fromJson(name, q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Quadrant {
  Quadrant({
    required this.pairTool,
    required this.pairWeapon,
    required this.domain,
    required this.side,
    required this.halfPole,
    required this.sub,
  });

  final String pairTool;
  final String pairWeapon;
  final String domain; // concrete | abstract
  final String side; // asset | risk
  final String halfPole;
  final List<Tool> sub;

  factory Quadrant.fromJson(String approach, Map<String, dynamic> j) {
    return Quadrant(
      pairTool: j['pair_tool'] as String,
      pairWeapon: j['pair_weapon'] as String,
      domain: j['domain'] as String,
      side: j['side'] as String,
      halfPole: j['half_pole'] as String,
      sub: (j['sub'] as List)
          .map((s) => Tool.fromJson(approach, j, s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Tool {
  Tool({
    required this.approach,
    required this.pairTool,
    required this.pairWeapon,
    required this.tool,
    required this.weapon,
    required this.domain,
    required this.side,
    required this.kind,
    required this.symbol,
    required this.definedBy,
  });

  final String approach;
  final String pairTool;
  final String pairWeapon;
  final String tool;
  final String weapon;
  final String domain;
  final String side;
  final String kind; // raw | interpreted
  final String symbol;
  final List<String> definedBy;

  factory Tool.fromJson(
      String approach, Map<String, dynamic> q, Map<String, dynamic> s) {
    return Tool(
      approach: approach,
      pairTool: q['pair_tool'] as String,
      pairWeapon: q['pair_weapon'] as String,
      tool: s['tool'] as String,
      weapon: s['weapon'] as String,
      domain: q['domain'] as String,
      side: q['side'] as String,
      kind: s['kind'] as String,
      symbol: s['symbol'] as String,
      definedBy: List<String>.from(s['defined_by'] as List),
    );
  }

  @override
  String toString() => '$tool/$weapon ($approach, $side $domain $kind)';
}
