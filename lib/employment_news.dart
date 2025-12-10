import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// ✅ Helper: Format ISO timestamp into readable text
String _formatTimestamp(String? isoTime) {
  if (isoTime == null) return 'Time N/A';
  try {
    final date = DateTime.parse(isoTime);
    return DateFormat('MMM d, h:mm a').format(date);
  } catch (_) {
    return 'Invalid';
  }
}

/// ✅ Consistent Icon & Color theme
Map<String, dynamic> _getEmploymentStyle() {
  return {
    'icon': Icons.work_history_rounded,
    'color': const Color(0xFF10B981), // Emerald green
  };
}

/// ============================================================
/// 🔹 Citizen-side Employment News Feed
/// ============================================================
class EmploymentNewsViewScreen extends StatefulWidget {
  const EmploymentNewsViewScreen({super.key});

  @override
  State<EmploymentNewsViewScreen> createState() =>
      _EmploymentNewsViewScreenState();
}

class _EmploymentNewsViewScreenState extends State<EmploymentNewsViewScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    try {
      final response = await supabase
          .from('employment_news')
          .select()
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getEmploymentStyle();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'തൊഴിൽ / ജോബ് പോസ്റ്റിംഗുകൾ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: style['color'],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('ഡാറ്റ ലോഡുചെയ്യൽ പിശക്: ${snapshot.error}'),
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 50, color: Colors.grey.shade500),
                  const SizedBox(height: 10),
                  const Text(
                    'തൊഴിൽ സംബന്ധമായ പോസ്റ്റുകളൊന്നുമില്ല',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index];
              final formattedTime = _formatTimestamp(data['timestamp']);
              final mediaUrl = data['logo_url'] as String?;
              final title = data['title'] ?? 'Employment Opportunity';
              final description = data['description'] ?? 'വിവരണം ലഭ്യമല്ല';
              final company = data['company_name'] ?? 'Unspecified Company';
              final location = data['location'] ?? 'Location N/A';
              final type = data['type'] ?? 'Job Vacancy';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                style['icon'],
                                color: style['color'],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: style['color'],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 16, thickness: 0.5),

                      // --- TITLE ---
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // --- LOGO + DESCRIPTION ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mediaUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                mediaUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.business,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              description,
                              maxLines: mediaUrl != null ? 4 : 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20, thickness: 0.5),

                      // --- FOOTER ---
                      Row(
                        children: [
                          const Icon(
                            Icons.apartment,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.teal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

/// ============================================================
/// 🔹 Admin-side Employment Post Uploader
/// ============================================================
class EmploymentSettingsManager extends StatefulWidget {
  const EmploymentSettingsManager({super.key});

  @override
  State<EmploymentSettingsManager> createState() =>
      _EmploymentSettingsManagerState();
}

class _EmploymentSettingsManagerState extends State<EmploymentSettingsManager> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  final _logoController = TextEditingController();
  bool _isLoading = false;

  bool get _isAdmin {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    return email.endsWith('@admin.com') || email == 'admin@gmail.com';
  }

  Future<void> _addEmploymentPost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await supabase.from('employment_news').insert({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'company_name': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _typeController.text.trim(),
        'logo_url': _logoController.text.trim().isEmpty
            ? null
            : _logoController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job Posting Added Successfully!')),
      );
      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding post: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied: Admins Only',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employment Manager'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (v) => v!.isEmpty ? 'Enter job title' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company / Organization',
                ),
                validator: (v) => v!.isEmpty ? 'Enter company name' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v!.isEmpty ? 'Enter location' : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Job Type'),
              ),
              TextFormField(
                controller: _logoController,
                decoration: const InputDecoration(
                  labelText: 'Logo Image URL (optional)',
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _addEmploymentPost,
                      icon: const Icon(Icons.upload),
                      label: const Text('Add Job Posting'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
