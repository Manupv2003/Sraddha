import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// ✅ Format Supabase timestamp into readable string
String formatTimestamp(String? isoTime) {
  if (isoTime == null) return 'സമയം ലഭ്യമല്ല';
  try {
    final date = DateTime.parse(isoTime);
    return DateFormat('MMM d, h:mm a').format(date);
  } catch (_) {
    return 'Invalid';
  }
}

/// ✅ Government news UI theme
Map<String, dynamic> govtStyle() {
  return {
    'icon': Icons.gavel_sharp,
    'color': const Color(0xFFF97316), // Warm orange accent
  };
}

class GovernmentNewsScreen extends StatefulWidget {
  const GovernmentNewsScreen({super.key});

  @override
  State<GovernmentNewsScreen> createState() => _GovernmentNewsScreenState();
}

class _GovernmentNewsScreenState extends State<GovernmentNewsScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchGovernmentNews() async {
    try {
      final response = await supabase
          .from('government_news')
          .select()
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching government news: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = govtStyle();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'സർക്കാർ അറിയിപ്പുകൾ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: style['color'],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGovernmentNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('പിശക്: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(style['icon'], size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'ഒന്നും ലഭ്യമല്ല',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index];
              final timestamp = formatTimestamp(data['timestamp']);
              final title = data['title'] ?? 'സർക്കാർ അറിയിപ്പ്';
              final details = data['details'] ?? 'വിവരങ്ങൾ ലഭ്യമല്ല';
              final source = data['official_source'] ?? 'സർക്കാർ വകുപ്പ്';
              final photoUrl = data['photo_url'] as String?;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(style['icon'], color: style['color']),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: style['color'],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            timestamp,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),

                      const Divider(),

                      // --- PHOTO ---
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photoUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 150,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                        ),

                      // --- DETAILS ---
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // --- SOURCE ---
                      Row(
                        children: [
                          const Icon(
                            Icons.source,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Source: $source',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
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
