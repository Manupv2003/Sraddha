import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'citizen_reporting.dart';
import 'employment_news.dart';
import 'govt_news.dart';
import 'news_feed_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://yylqokuyjuczkpcchree.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5bHFva3V5anVjemtwY2NocmVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM4MTAsImV4cCI6MjA3NzkwOTgxMH0.B8XDK3CuLw3GzOyAJs6lsX7fpHH9gTDUQDKS5hlKJP0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ഗ്രാമം ആപ്പ്',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16)),
      ),
      home: const MyHomePage(title: 'വെള്ളാഞ്ചേരി ഗ്രാമം'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Optional: Supabase sign-out (not needed now but safe)
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('സൈൻ ഔട്ട് ചെയ്തു')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 4,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDCF5F2), Color(0xFFF6FDFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "ഗ്രാമ സേവനങ്ങൾ",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 4
                      : 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  children: [
                    _buildHomeOption(
                      icon: Icons.report_problem,
                      label: 'പൗര റിപ്പോർട്ടിംഗ്',
                      color1: Colors.blueAccent,
                      color2: Colors.lightBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CitizenReportingScreen(),
                          ),
                        );
                      },
                    ),
                    _buildHomeOption(
                      icon: Icons.newspaper,
                      label: 'വാർത്തകൾ',
                      color1: Colors.green,
                      color2: Colors.lightGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewsFeedScreen(),
                          ),
                        );
                      },
                    ),
                    _buildHomeOption(
                      icon: Icons.campaign,
                      label: 'സർക്കാർ അറിയിപ്പുകൾ',
                      color1: Colors.orange,
                      color2: Colors.deepOrangeAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GovernmentNewsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildHomeOption(
                      icon: Icons.work_outline,
                      label: 'തൊഴിൽ വാർത്തകൾ',
                      color1: Colors.purple,
                      color2: Colors.deepPurpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmploymentNewsViewScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: const [
                        Text(
                          "📍 വെള്ളാഞ്ചേരി പഞ്ചായത്ത് പോർട്ടൽ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "പൗര സേവനങ്ങൾ | സർക്കാർ വാർത്തകൾ | തൊഴിൽ അവസരങ്ങൾ | ഗ്രാമ വികസനങ്ങൾ",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable Home Option Tile
  Widget _buildHomeOption({
    required IconData icon,
    required String label,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
