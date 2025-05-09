import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';

class CreateCompanionScreen extends StatefulWidget {
  const CreateCompanionScreen({super.key});

  @override
  State<CreateCompanionScreen> createState() => _CreateCompanionScreenState();
}

class _CreateCompanionScreenState extends State<CreateCompanionScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedVillageId;
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadVillages();
  }

  Future<void> _loadVillages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .get();

    final villages = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      _villages = villages;
      _selectedVillageId = villages.isNotEmpty ? villages.first['id'] : null;
      _isLoading = false;
    });
  }

  Future<void> _createCompanion() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller =
        Provider.of<MainContentController>(context, listen: false);

    if (_selectedVillageId == null || _nameController.text.trim().length < 3) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid name and select a village.")),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final village =
          _villages.firstWhere((v) => v['id'] == _selectedVillageId);
      final callable =
          FirebaseFunctions.instance.httpsCallable('createCompanion');
      final result = await callable.call({
        'tileX': village['tileX'],
        'tileY': village['tileY'],
        'name': _nameController.text.trim(),
      });

      final heroId = result.data['heroId'];
      final heroDoc = await FirebaseFirestore.instance
          .collection('heroes')
          .doc(heroId)
          .get();

      if (!mounted) return;

      if (heroDoc.exists) {
        final hero = HeroModel.fromFirestore(heroDoc.id, heroDoc.data()!);
        controller.setCustomContent(HeroDetailsScreen(hero: hero));
        messenger.showSnackBar(
            const SnackBar(content: Text("Companion created successfully!")));
      } else {
        messenger.showSnackBar(
            const SnackBar(content: Text("Companion created, but not found.")));
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      messenger.showSnackBar(
          SnackBar(content: Text("Failed to create companion: $e")));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Companion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _villages.isEmpty
            ? const Center(child: Text('No villages available.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Companion name:", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter companion name",
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Select spawn village:",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedVillageId,
                    items: _villages.map((village) {
                      return DropdownMenuItem<String>(
                        value: village['id'],
                        child: Text(
                            "${village['name']} (${village['tileX']}, ${village['tileY']})"),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedVillageId = value),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text("Create Companion"),
                    onPressed: _isCreating ? null : _createCompanion,
                  ),
                ],
              ),
      ),
    );
  }
}
