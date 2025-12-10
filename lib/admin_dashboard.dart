import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsManager extends StatefulWidget {
  const SettingsManager({super.key});

  @override
  State<SettingsManager> createState() => _SettingsManagerState();
}

class _SettingsManagerState extends State<SettingsManager> {
  final supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // ---------------------- Load Admin Data ----------------------
  Future<void> _loadAdminData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      _emailController.text = user.email ?? '';

      final response = await supabase
          .from('admin_settings')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _nameController.text = response['name'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
  }

  // ---------------------- Save Admin Profile ----------------------
  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await supabase.from('admin_settings').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('പ്രൊഫൈൽ വിജയകരമായി സേവ് ചെയ്തു')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('സേവ് ചെയ്യാനായില്ല: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  // ---------------------- Clear Old Reports ----------------------
  Future<void> _clearOldReports() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));

      final oldReports = await supabase
          .from('citizen_reporting')
          .select()
          .lt('timestamp', cutoff.toIso8601String());

      if (oldReports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('പഴയ റിപ്പോർട്ടുകൾ ഒന്നുമില്ല')),
        );
        return;
      }

      for (var report in oldReports) {
        await supabase
            .from('citizen_reporting')
            .delete()
            .eq('id', report['id']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${oldReports.length} പഴയ റിപ്പോർട്ടുകൾ നീക്കം ചെയ്തു'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('പിശക്: $e')));
    }
  }

  // ---------------------- Sign Out ----------------------
  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ലോഗ് ഔട്ട് ചെയ്തു')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('No admin logged in.'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.settings, color: Colors.redAccent, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Admin Settings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Admin Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email (read-only)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _clearOldReports,
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Clear Reports Older Than 30 Days'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
