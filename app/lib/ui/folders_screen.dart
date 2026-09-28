import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/folders.dart';
import '../core/store.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key, required this.state});
  final AppState state;

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  Folder? _open;

  @override
  Widget build(BuildContext context) {
    if (_open == null) {
      return ListView(
        children: [
          for (final f in Folder.values)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(f.label),
              onTap: () => setState(() => _open = f),
            ),
        ],
      );
    }
    final f = _open!;
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _open = null),
          ),
          title: Text(f.label),
        ),
        Expanded(
          child: FutureBuilder<List<Entry>>(
            future: widget.state.store.list(f),
            builder: (context, snap) {
              final items = snap.data ?? const [];
              if (snap.hasData && items.isEmpty) {
                return const Center(child: Text('Nothing filed here yet.'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final e = items[i];
                  return ListTile(
                    title: Text(e.text),
                    subtitle: Text([
                      e.created.toLocal().toString().substring(0, 16),
                      if (e.person != null) e.person!,
                      if (e.animal != null) e.animal!,
                      if (e.note != null) e.note!,
                    ].join(' · ')),
                    trailing: PopupMenuButton<Folder>(
                      tooltip: 'Move',
                      icon: const Icon(Icons.drive_file_move_outline),
                      onSelected: (to) async {
                        await widget.state.store.move(e.id!, to);
                        setState(() {});
                      },
                      itemBuilder: (_) => [
                        for (final t in Folder.values)
                          if (t != f) PopupMenuItem(value: t, child: Text(t.label)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
