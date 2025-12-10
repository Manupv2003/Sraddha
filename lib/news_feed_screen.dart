import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final supabase = Supabase.instance.client;

  int _tapCount = 0;
  final int _requiredTaps = 7;
  DateTime? _lastTapTime;

  final String _adminUsername = 'admin';
  final String _adminPassword = '12345';
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();

  final Map<String, String> _incidentLabels = {
    'road_issue': 'റോഡ് തടസ്സം / ഇൻഫ്രാസ്ട്രക്ചർ പ്രശ്നം',
    'power_water': 'വൈദ്യുതി / ജല പ്രശ്നം',
    'health_emergency': 'ആരോഗ്യ / മെഡിക്കൽ അടിയന്തിരാവസ്ഥ',
    'death_info': 'മരണം / ശവസംസ്കാര വിവരം',
    'law_order': 'നിയമ-സമാധാന / സുരക്ഷാ വിഷയം',
    'village_news': 'മറ്റു ഗ്രാമ വാർത്തകൾ',
  };

  // -------------------- Fetch Citizen Reports --------------------
  Future<List<Map<String, dynamic>>> _fetchCitizenReports() async {
    try {
      final response = await supabase
          .from('citizen_reporting')
          .select()
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  // -------------------- Hidden Admin Login --------------------
  void _handleHiddenTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds > 1) {
      _tapCount = 0;
    }
    _tapCount++;
    _lastTapTime = now;

    if (_tapCount == _requiredTaps) {
      _tapCount = 0;
      _showLoginDialog(context);
    }
  }

  void _showLoginDialog(BuildContext context) {
    _usernameController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Admin Login Required'),
          content: Form(
            key: _loginFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    icon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter username' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    icon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter password' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_loginFormKey.currentState!.validate()) {
                  if (_usernameController.text == _adminUsername &&
                      _passwordController.text == _adminPassword) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Access Granted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const SettingsManager(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid Credentials'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  // -------------------- Helper Functions --------------------
  String _formatTimestamp(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (_) {
      return 'Invalid Date';
    }
  }

  Map<String, dynamic> _getItemStyle(String? typeKey) {
    IconData icon;
    Color color;
    String label = _incidentLabels[typeKey] ?? 'ഗ്രാമ വാർത്ത';

    switch (typeKey) {
      case 'road_issue':
        icon = Icons.traffic_sharp;
        color = const Color(0xFF6D28D9);
        break;
      case 'power_water':
        icon = Icons.electrical_services_sharp;
        color = const Color(0xFFD97706);
        break;
      case 'health_emergency':
        icon = Icons.medical_services_sharp;
        color = const Color(0xFFE53935);
        break;
      case 'death_info':
        icon = Icons.church_sharp;
        color = const Color(0xFF1F2937);
        break;
      case 'law_order':
        icon = Icons.security_sharp;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.campaign_sharp;
        color = const Color(0xFF3B82F6);
        break;
    }

    return {'icon': icon, 'color': color, 'label': label};
  }

  // -------------------- Build UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _handleHiddenTap(context),
          child: const Text(
            'ഗ്രാമ വാർത്തകൾ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCitizenReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('ഒന്നും കണ്ടെത്തിയില്ല.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final style = _getItemStyle(report['incidentType']);
              final timestamp = _formatTimestamp(report['timestamp']);
              final reporter = report['reporterName'] ?? 'അജ്ഞാതൻ';
              final place = report['placeOfIncident'] ?? '—';
              final desc = report['description'] ?? 'വിവരണം ലഭ്യമല്ല';
              final photoUrl = report['photoUrl'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Icon(style['icon'], color: style['color'], size: 36),
                  title: Text(
                    style['label'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(desc),
                      const SizedBox(height: 4),
                      Text('സ്ഥലം: $place'),
                      Text('റിപ്പോർട്ട് ചെയ്തത്: $reporter'),
                      Text('സമയം: $timestamp'),
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photoUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text('ചിത്രം ലോഡ് ചെയ്യാനായില്ല'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
