import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/context.dart';
import '../core/session.dart';

/// Listen, file, ask one question, wait.
class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key, required this.state});
  final AppState state;

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  final _log = <_Line>[];
  final _typed = TextEditingController();
  String _partial = '';
  bool _listening = false;
  bool _busy = false;
  WorkingContext? _ctx;
  bool _showCtx = false;

  Future<void> _toggle() async {
    if (_listening) {
      await widget.state.listener.stop();
      setState(() => _listening = false);
      return;
    }
    await widget.state.speaker.stop();
    final ok = await widget.state.listener.init();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone or speech recognition is not available.')),
        );
      }
      return;
    }
    setState(() {
      _listening = true;
      _partial = '';
    });
    await widget.state.listener.start((text, isFinal) async {
      if (!mounted) return;
      if (!isFinal) {
        setState(() => _partial = text);
        return;
      }
      setState(() {
        _listening = false;
        _partial = '';
      });
      if (text.trim().isNotEmpty) await _handle(text.trim());
    });
  }

  Future<void> _handle(String text) async {
    setState(() {
      _busy = true;
      _log.add(_Line(text, fromUser: true));
    });
    final Turn turn = await widget.state.session.hear(text);
    final filedNote = turn.filed.isEmpty
        ? null
        : turn.filed.map((e) => e.folder.label).toSet().join(', ');
    setState(() {
      _busy = false;
      _ctx = turn.context;
      _log.add(_Line(turn.question.text, fromUser: false, note: filedNote));
    });
    await widget.state.speaker.say(turn.question.text);
  }

  Future<void> _end() async {
    final q = widget.state.session.end();
    setState(() => _log.add(_Line(q.text, fromUser: false)));
    await widget.state.speaker.say(q.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_ctx != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.center_focus_strong, size: 18),
            title: Text(
              _ctx!.items.isEmpty
                  ? 'Focus: nothing yet'
                  : 'Focus: ${_ctx!.items.map((f) => f.entry.name).join(', ')}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            trailing: Icon(_showCtx ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showCtx = !_showCtx),
          ),
        if (_ctx != null && _showCtx)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(_ctx!.toPrompt(), style: Theme.of(context).textTheme.bodySmall),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _log.length + (_partial.isEmpty ? 0 : 1),
            itemBuilder: (context, i) {
              if (i == _log.length) {
                return _bubble(_Line(_partial, fromUser: true), faded: true);
              }
              return _bubble(_log[i]);
            },
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typed,
                  decoration: const InputDecoration(hintText: 'Or type it', isDense: true),
                  onSubmitted: (t) {
                    _typed.clear();
                    if (t.trim().isNotEmpty) _handle(t.trim());
                  },
                ),
              ),
              IconButton(
                tooltip: 'End with a criterion',
                onPressed: _end,
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FloatingActionButton.large(
            onPressed: _toggle,
            backgroundColor: _listening ? Colors.red.shade400 : null,
            child: Icon(_listening ? Icons.stop : Icons.mic),
          ),
        ),
      ],
    );
  }

  Widget _bubble(_Line l, {bool faded = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: l.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: l.fromUser
              ? scheme.primaryContainer.withValues(alpha: faded ? 0.4 : 1)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.text),
            if (l.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Filed under: ${l.note}',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _Line {
  _Line(this.text, {required this.fromUser, this.note});
  final String text;
  final bool fromUser;
  final String? note;
}
