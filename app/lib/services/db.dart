import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/folders.dart';
import '../core/store.dart';

/// SQLite store: one table for entries (folder column), one for the profile.
class DbStore implements Store {
  DbStore._(this._db);
  final Database _db;

  static Future<DbStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final db = await openDatabase(
      p.join(dir.path, 'anatomy.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folder TEXT NOT NULL,
            text TEXT NOT NULL,
            created TEXT NOT NULL,
            person TEXT, animal TEXT, approach TEXT, note TEXT)''');
        await db.execute('CREATE INDEX entries_folder ON entries(folder)');
        await db.execute('CREATE TABLE kv(k TEXT PRIMARY KEY, v TEXT NOT NULL)');
      },
    );
    return DbStore._(db);
  }

  @override
  Future<int> add(Entry e) => _db.insert('entries', e.toMap()..remove('id'));

  @override
  Future<List<Entry>> list(Folder f, {int limit = 50}) async {
    final rows = await _db.query('entries',
        where: 'folder = ?', whereArgs: [f.name], orderBy: 'id DESC', limit: limit);
    return rows.map(Entry.fromMap).toList();
  }

  @override
  Future<List<Entry>> recent({int limit = 20}) async {
    final rows = await _db.query('entries', orderBy: 'id DESC', limit: limit);
    return rows.map(Entry.fromMap).toList();
  }

  @override
  Future<List<Entry>> byPerson(String person) async {
    final rows = await _db.query('entries',
        where: 'lower(person) = ?', whereArgs: [person.toLowerCase()], orderBy: 'id DESC');
    return rows.map(Entry.fromMap).toList();
  }

  @override
  Future<void> move(int id, Folder to) =>
      _db.update('entries', {'folder': to.name}, where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> delete(int id) => _db.delete('entries', where: 'id = ?', whereArgs: [id]);

  @override
  Future<Profile> profile() async {
    final rows = await _db.query('kv');
    final kv = {for (final r in rows) r['k'] as String: r['v'] as String};
    List<String> lst(String k) =>
        (kv[k] ?? '').split('|').where((s) => s.isNotEmpty).toList();
    Map<String, String> map(String k) => {
          for (final pair in lst(k))
            if (pair.contains('=')) pair.split('=')[0]: pair.split('=').sublist(1).join('=')
        };
    final lex = map('lexicon').map((k, v) => MapEntry(k, int.tryParse(v) ?? 0));
    return Profile(
      favourites: lst('favourites'),
      dislikedWeapons: lst('disliked'),
      reframers: map('reframers'),
      lexiconProfile: lex,
      passages: int.tryParse(kv['passages'] ?? '0') ?? 0,
    );
  }

  @override
  Future<void> saveProfile(Profile pr) async {
    Future<void> put(String k, String v) =>
        _db.insert('kv', {'k': k, 'v': v}, conflictAlgorithm: ConflictAlgorithm.replace);
    await put('favourites', pr.favourites.join('|'));
    await put('disliked', pr.dislikedWeapons.join('|'));
    await put('reframers', pr.reframers.entries.map((e) => '${e.key}=${e.value}').join('|'));
    await put('lexicon', pr.lexiconProfile.entries.map((e) => '${e.key}=${e.value}').join('|'));
    await put('passages', '${pr.passages}');
  }
}
