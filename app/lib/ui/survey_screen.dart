import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/store.dart';
import '../core/taboo.dart';
import '../core/wheel.dart';

/// The two instruments: three disliked weapons, three favourite approaches.
/// Weapons are offered as names; approaches as descriptions, never as names.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.state});
  final AppState state;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _disliked = <String>{};
  final _fav = <String>{};
  TabooReading? _reading;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.state.store.profile().then((Profile p) {
      setState(() {
        _disliked.addAll(p.dislikedWeapons);
        _fav.addAll(p.favourites);
        _loaded = true;
        if (_disliked.isNotEmpty) {
          _reading = widget.state.session.taboo
              .read(dislikedWeapons: _disliked.toList(), favourites: _fav.toList());
        }
      });
    });
  }

  Future<void> _save() async {
    final r = await widget.state.session.survey(
      dislikedWeapons: _disliked.toList(),
      favourites: _fav.toList(),
    );
    setState(() => _reading = r);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final wheel = widget.state.wheel;
    final weapons = wheel.allTools.map((t) => t.weapon).toList()..sort();
    final shuffled = List<String>.from(Wheel.order)..shuffle();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Which three of these do you like least in other people?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in weapons)
              FilterChip(
                label: Text(w),
                selected: _disliked.contains(w),
                onSelected: (on) => setState(() {
                  if (on && _disliked.length < 3) _disliked.add(w);
                  if (!on) _disliked.remove(w);
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Which three of these ways of working do you enjoy most?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final a in _fav.isEmpty ? shuffled : Wheel.order)
          CheckboxListTile(
            value: _fav.contains(a),
            title: Text(wheel[a].description),
            onChanged: (on) => setState(() {
              if (on == true && _fav.length < 3) _fav.add(a);
              if (on == false) _fav.remove(a);
            }),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _disliked.length == 3 && _fav.length == 3 ? _save : null,
          child: const Text('Read the wheel'),
        ),
        if (_reading != null) ...[
          const SizedBox(height: 16),
          _ReadingCard(reading: _reading!, wheel: wheel, taboo: widget.state.session.taboo),
        ],
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, required this.wheel, required this.taboo});
  final TabooReading reading;
  final Wheel wheel;
  final Taboo taboo;

  @override
  Widget build(BuildContext context) {
    final t = reading.taboo;
    final unseen = taboo.unseen(reading);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t != null) ...[
              Text('The weapons you dislike cluster in one way of working:',
                  style: Theme.of(context).textTheme.labelLarge),
              Text('${wheel[t].description} ($t)'),
              const SizedBox(height: 8),
              Text('Across the wheel from it, where you likely spend your time:',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(reading.loadBearing.join(', ')),
              const SizedBox(height: 8),
            ],
            if (reading.disagreements.isNotEmpty) ...[
              Text('A favourite that is not across from a dislike, which is worth a question:',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(reading.disagreements.join(', ')),
              const SizedBox(height: 8),
            ],
            if (unseen.isNotEmpty) ...[
              Text('Ways of working you may not be seeing. For each, who do you know who is good at it?',
                  style: Theme.of(context).textTheme.labelLarge),
              for (final a in unseen) Text('• ${wheel[a].description}'),
            ],
          ],
        ),
      ),
    );
  }
}
