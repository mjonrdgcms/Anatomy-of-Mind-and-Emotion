import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/definitions.dart';
import '../core/store.dart';
import '../core/wheel.dart';

/// The personality profile: the person's own phrases about each term,
/// with panaceas and blind spots flagged, and the reframing library.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<(Profile, List<DefinitionSummary>)> _load() async {
    final p = await widget.state.store.profile();
    final d = await widget.state.session.definitions();
    return (p, d);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Profile, List<DefinitionSummary>)>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final (p, defs) = snap.data!;
        final panaceas = defs.where((d) => d.isPanacea).toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (panaceas.isNotEmpty) ...[
              Text('Definitions that have become the answer to everything',
                  style: Theme.of(context).textTheme.titleMedium),
              for (final d in panaceas)
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    title: Text('${d.term} (${d.approach})'),
                    subtitle: Text(
                        'Used in ${d.breadth} kinds of situation, no boundary named yet.'
                        '${d.spaceTaken == null ? "" : " Taking the place of ${d.spaceTaken}."}'),
                    onTap: () => _showTerm(context, d),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            Text('In your words', style: Theme.of(context).textTheme.titleMedium),
            if (defs.isEmpty) const Text('Nothing yet. Talk, and the phrases you use about each tool collect here.'),
            for (final d in defs.where((d) => !d.isPanacea))
              ListTile(
                dense: true,
                title: Text('${d.term} (${d.kind}, ${d.approach})'),
                subtitle: Text(d.recent(1).firstOrNull ?? ''),
                trailing: Text('${d.phrases.length}·${d.breadth}${d.hasBoundary ? "·b" : ""}',
                    style: Theme.of(context).textTheme.labelSmall),
                onTap: () => _showTerm(context, d),
              ),
            const SizedBox(height: 16),
            Text('People who are good at what you are not',
                style: Theme.of(context).textTheme.titleMedium),
            for (final a in Wheel.order)
              ListTile(
                dense: true,
                title: Text(a),
                subtitle: Text(widget.state.wheel[a].description),
                trailing: Text(p.reframers[a] ?? '—'),
                onTap: p.reframers[a] == null ? null : () => _showPerson(context, p.reframers[a]!),
              ),
          ],
        );
      },
    );
  }

  void _showTerm(BuildContext context, DefinitionSummary d) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(d.term, style: Theme.of(context).textTheme.titleLarge),
          Text('${d.kind} of ${d.approach} · breadth ${d.breadth}'
              '${d.hasBoundary ? " · boundary named" : " · no boundary yet"}'),
          const SizedBox(height: 8),
          for (final ph in d.phrases.reversed)
            ListTile(
              dense: true,
              title: Text(ph.text),
              subtitle: Text('${ph.created.toLocal().toString().substring(0, 16)} · ${ph.folder.label}'
                  '${ph.isBoundary ? " · boundary" : ""}'),
            ),
        ],
      ),
    );
  }

  void _showPerson(BuildContext context, String person) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => FutureBuilder<List<Entry>>(
        future: widget.state.store.byPerson(person),
        builder: (context, snap) {
          final items = snap.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(person, style: Theme.of(context).textTheme.titleLarge),
              for (final e in items) ListTile(title: Text(e.text), subtitle: Text(e.note ?? '')),
            ],
          );
        },
      ),
    );
  }
}
