import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/store.dart';
import '../core/wheel.dart';

/// The person's own reframing library: who is good at each axis,
/// and what that person would do.
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: state.store.profile(),
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('People who are good at what you are not',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final a in Wheel.order)
              Card(
                child: ListTile(
                  title: Text(a),
                  subtitle: Text(state.wheel[a].description),
                  trailing: Text(p.reframers[a] ?? '—',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: p.reframers[a] == null
                      ? null
                      : () => _showPerson(context, p.reframers[a]!),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPerson(BuildContext context, String person) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => FutureBuilder<List<Entry>>(
        future: state.store.byPerson(person),
        builder: (context, snap) {
          final items = snap.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(person, style: Theme.of(context).textTheme.titleLarge),
              for (final e in items)
                ListTile(title: Text(e.text), subtitle: Text(e.note ?? '')),
            ],
          );
        },
      ),
    );
  }
}
