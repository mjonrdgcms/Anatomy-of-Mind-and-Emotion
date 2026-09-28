import 'package:flutter/material.dart';

import 'app_state.dart';
import 'ui/folders_screen.dart';
import 'ui/profile_screen.dart';
import 'ui/survey_screen.dart';
import 'ui/talk_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnatomyApp());
}

class AnatomyApp extends StatelessWidget {
  const AnatomyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anatomy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF438088)),
        useMaterial3: true,
      ),
      home: FutureBuilder<AppState>(
        future: AppState.boot(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(body: Center(child: Text('Could not start: ${snap.error}')));
          }
          if (!snap.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Home(state: snap.data!);
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.state});
  final AppState state;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TalkScreen(state: widget.state),
      FoldersScreen(state: widget.state),
      ProfileScreen(state: widget.state),
      SurveyScreen(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mic), label: 'Talk'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Folders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Wheel'),
        ],
      ),
    );
  }
}
