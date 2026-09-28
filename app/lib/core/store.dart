import 'definitions.dart';
import 'folders.dart';

/// One filed passage.
class Entry {
  Entry({
    this.id,
    required this.folder,
    required this.text,
    required this.created,
    this.person,
    this.animal,
    this.approach,
    this.note,
  });
  final int? id;
  final Folder folder;
  final String text;
  final DateTime created;
  final String? person;
  final String? animal;
  final String? approach;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'folder': folder.name,
        'text': text,
        'created': created.toIso8601String(),
        'person': person,
        'animal': animal,
        'approach': approach,
        'note': note,
      };

  static Entry fromMap(Map<String, Object?> m) => Entry(
        id: m['id'] as int?,
        folder: Folder.values.byName(m['folder'] as String),
        text: m['text'] as String,
        created: DateTime.parse(m['created'] as String),
        person: m['person'] as String?,
        animal: m['animal'] as String?,
        approach: m['approach'] as String?,
        note: m['note'] as String?,
      );
}

/// What the app keeps about the person (docs/conversation-method.md, section 6).
class Profile {
  Profile({
    this.favourites = const [],
    this.dislikedWeapons = const [],
    Map<String, String>? reframers,
    Map<String, int>? lexiconProfile,
    this.passages = 0,
  })  : reframers = reframers ?? {},
        lexiconProfile = lexiconProfile ?? {};

  List<String> favourites;
  List<String> dislikedWeapons;

  /// approach -> the person named as good at it.
  final Map<String, String> reframers;

  /// approach -> cumulative lexicon hits.
  final Map<String, int> lexiconProfile;
  int passages;
}

abstract class Store {
  Future<int> add(Entry e);

  /// The whole transcript, as spoken. Never loaded into context.
  Future<int> archive(String transcript, DateTime when);

  /// Search the archive for something specific.
  Future<List<Entry>> search(String query, {int limit = 20});

  Future<void> addPhrases(List<Phrase> phrases);
  Future<List<Phrase>> phrasesFor(String term);
  Future<Map<String, List<Phrase>>> allPhrases();
  Future<List<Entry>> list(Folder f, {int limit = 50});
  Future<List<Entry>> recent({int limit = 20});
  Future<List<Entry>> byPerson(String person);
  Future<void> move(int id, Folder to);
  Future<void> delete(int id);
  Future<Profile> profile();
  Future<void> saveProfile(Profile p);
}

/// In-memory store, used by tests and as a fallback.
class MemoryStore implements Store {
  final List<Entry> _entries = [];
  final List<Phrase> _phrases = [];
  Profile _profile = Profile();
  int _next = 1;

  @override
  Future<int> archive(String transcript, DateTime when) =>
      add(Entry(folder: Folder.archive, text: transcript, created: when));

  @override
  Future<List<Entry>> search(String query, {int limit = 20}) async {
    final q = query.toLowerCase();
    return _entries
        .where((e) => e.folder == Folder.archive && e.text.toLowerCase().contains(q))
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  @override
  Future<void> addPhrases(List<Phrase> phrases) async => _phrases.addAll(phrases);

  @override
  Future<List<Phrase>> phrasesFor(String term) async =>
      _phrases.where((p) => p.term == term).toList();

  @override
  Future<Map<String, List<Phrase>>> allPhrases() async {
    final out = <String, List<Phrase>>{};
    for (final p in _phrases) {
      out.putIfAbsent(p.term, () => []).add(p);
    }
    return out;
  }

  @override
  Future<int> add(Entry e) async {
    final id = _next++;
    _entries.add(Entry(
      id: id,
      folder: e.folder,
      text: e.text,
      created: e.created,
      person: e.person,
      animal: e.animal,
      approach: e.approach,
      note: e.note,
    ));
    return id;
  }

  @override
  Future<List<Entry>> list(Folder f, {int limit = 50}) async =>
      _entries.where((e) => e.folder == f).toList().reversed.take(limit).toList();

  @override
  Future<List<Entry>> recent({int limit = 20}) async =>
      _entries.where((e) => e.folder != Folder.archive).toList().reversed.take(limit).toList();

  @override
  Future<List<Entry>> byPerson(String person) async => _entries
      .where((e) => e.person?.toLowerCase() == person.toLowerCase())
      .toList();

  @override
  Future<void> move(int id, Folder to) async {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final e = _entries[i];
    _entries[i] = Entry(
      id: e.id,
      folder: to,
      text: e.text,
      created: e.created,
      person: e.person,
      animal: e.animal,
      approach: e.approach,
      note: e.note,
    );
  }

  @override
  Future<void> delete(int id) async => _entries.removeWhere((e) => e.id == id);

  @override
  Future<Profile> profile() async => _profile;

  @override
  Future<void> saveProfile(Profile p) async => _profile = p;
}
