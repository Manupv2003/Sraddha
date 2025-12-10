import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CitizenReportingScreen extends StatefulWidget {
  const CitizenReportingScreen({super.key});

  @override
  State<CitizenReportingScreen> createState() => _CitizenReportingScreenState();
}

class _CitizenReportingScreenState extends State<CitizenReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _panchayatController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  XFile? _pickedImage;
  String? _selectedIncidentType;

  final Map<String, String> _incidentTypes = {
    'road_issue': 'റോഡ് തടസ്സം / ഇൻഫ്രാസ്ട്രക്ചർ പ്രശ്നം',
    'power_water': 'വൈദ്യുതി / ജല പ്രശ്നം',
    'health_emergency': 'ആരോഗ്യ / മെഡിക്കൽ അടിയന്തിരാവസ്ഥ',
    'death_info': 'മരണം / ശവസംസ്കാര വിവരം',
    'law_order': 'നിയമ-സമാധാന / സുരക്ഷാ വിഷയം',
    'village_news': 'മറ്റു ഗ്രാമ വാർത്തകൾ',
  };

  // ---------------- Google Login ----------------
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _isLoggedIn = false;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'sraddha://login-callback',
      );

      // When the Future completes, Supabase should have a session
      final user = supabase.auth.currentUser;

      if (!mounted) return;

      if (user != null) {
        setState(() => _isLoggedIn = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google ലോഗിൻ വിജയകരം ✅')));
      } else {
        // Something went wrong – no session
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ലോഗിൻ പൂർത്തിയാകില്ല. വീണ്ടും ശ്രമിക്കൂ.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ലോഗിൻ പരാജയപ്പെട്ടു: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------- Image Picker ----------------
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _pickedImage = picked);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ചിത്രം തിരഞ്ഞെടുക്കൽ പരാജയപ്പെട്ടു: $e')),
      );
    }
  }

  // ---------------- Upload to Supabase ----------------
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('citizen_reporting')
          .upload(fileName, imageFile);

      return Supabase.instance.client.storage
          .from('citizen_reporting')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  // ---------------- Submit Report ----------------
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(File(_pickedImage!.path));
      }

      final user = Supabase.instance.client.auth.currentUser;

      await Supabase.instance.client.from('citizen_reporting').insert({
        'reporter_name': _nameController.text.trim(),
        'email': user?.email ?? 'anonymous',
        'panchayat': _panchayatController.text.trim(),
        'place_of_incident': _placeController.text.trim(),
        'incident_type': _selectedIncidentType,
        'description': _descriptionController.text.trim(),
        'photo_url': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('റിപ്പോർട്ട് വിജയകരമായി സമർപ്പിച്ചു ✅'),
          backgroundColor: Colors.teal,
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _pickedImage = null;
        _selectedIncidentType = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('സമർപ്പണം പരാജയപ്പെട്ടു: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('പൗര റിപ്പോർട്ടിംഗ്'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoggedIn ? _buildReportForm() : _buildLoginCard(),
      ),
    );
  }

  // ---------------- Google Login UI ----------------
  Widget _buildLoginCard() {
    return Center(
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 70, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                "Google ഉപയോഗിച്ച് ലോഗിൻ ചെയ്യുക",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.teal)
                  : ElevatedButton.icon(
                      onPressed: _loginWithGoogle,
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text(
                        'Google Sign-In',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, color: Color(0xFFDB4437), size: 14),
                  Icon(Icons.circle, color: Color(0xFFF4B400), size: 14),
                  Icon(Icons.circle, color: Color(0xFF0F9D58), size: 14),
                  Icon(Icons.circle, color: Color(0xFF4285F4), size: 14),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Powered by Supabase + Google",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Report Form UI ----------------
  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "സംഭവ റിപ്പോർട്ട് സമർപ്പിക്കുക",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'പേര്'),
                _buildTextField(
                  _panchayatController,
                  'ഗ്രാമപഞ്ചായത്ത് / വാർഡ്',
                ),
                _buildTextField(_placeController, 'സംഭവസ്ഥലം'),
                DropdownButtonFormField<String>(
                  value: _selectedIncidentType,
                  items: _incidentTypes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'സംഭവത്തിന്റെ തരം തിരഞ്ഞെടുക്കുക',
                  ),
                  onChanged: (v) => setState(() => _selectedIncidentType = v),
                  validator: (v) =>
                      v == null ? 'ഒരു വിഭാഗം തിരഞ്ഞെടുക്കുക' : null,
                ),
                _buildTextField(_descriptionController, 'വിവരണം', maxLines: 4),
                const SizedBox(height: 10),
                _pickedImage == null
                    ? OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.teal),
                        label: const Text('ചിത്രം ചേർക്കുക'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.teal),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_pickedImage!.path),
                              height: 160,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text('മാറ്റുക'),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.teal)
                    : ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          'സമർപ്പിക്കുക',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => v!.isEmpty ? '$label നൽകുക' : null,
      ),
    );
  }
}
