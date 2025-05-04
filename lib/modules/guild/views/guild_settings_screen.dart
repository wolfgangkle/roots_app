import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';


class GuildSettingsScreen extends StatefulWidget {
  const GuildSettingsScreen({super.key});

  @override
  State<GuildSettingsScreen> createState() => _GuildSettingsScreenState();
}

class _GuildSettingsScreenState extends State<GuildSettingsScreen> {
  final _descController = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;
  String _currentDescription = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentDescription();
  }

  Future<void> _loadCurrentDescription() async {
    final profile = FirebaseAuth.instance.currentUser;
    if (profile == null) return;

    final userDoc = await FirebaseFirestore.instance
        .doc('users/${profile.uid}/profile/main')
        .get();

    final guildId = userDoc.data()?['guildId'];
    if (guildId == null) return;

    final guildDoc = await FirebaseFirestore.instance
        .doc('guilds/$guildId')
        .get();

    final description = guildDoc.data()?['description'] ?? '';
    setState(() {
      _currentDescription = description;
      _descController.text = description;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final isLeader = profile.guildRole == 'leader';
    final guildId = profile.guildId;

    return Scaffold(
      appBar: AppBar(title: const Text("Guild Settings")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "⚙️ Manage Guild Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text("📝 Guild Description"),
            const SizedBox(height: 8),

            if (!_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(_currentDescription.isEmpty
                        ? "(No description set)"
                        : _currentDescription),
                  ),
                  const SizedBox(height: 12),
                  if (isLeader)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Description"),
                      onPressed: () {
                        setState(() => _isEditing = true);
                      },
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a new guild description...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? "Saving..." : "Save"),
                        onPressed: _isSaving
                            ? null
                            : () async {
                          final newDescription = _descController.text.trim();
                          if (newDescription.length > 500) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Max 500 characters.")),
                            );
                            return;
                          }

                          setState(() => _isSaving = true);
                          try {
                            await FirebaseFunctions.instance
                                .httpsCallable('updateGuildDescription')
                                .call({
                              'guildId': guildId,
                              'description': newDescription,
                            });

                            if (context.mounted) {
                              setState(() {
                                _currentDescription = newDescription;
                                _isEditing = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Description updated!")),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          _descController.text = _currentDescription;
                          setState(() => _isEditing = false);
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ],
              ),

            const Divider(height: 40),

            if (isLeader)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.warning),
                label: const Text("Disband Guild"),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Disband Guild?"),
                      content: const Text("This will permanently delete your guild. Cannot be undone."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Disband")),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    await FirebaseFunctions.instance.httpsCallable('disbandGuild').call();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Guild disbanded.")),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
