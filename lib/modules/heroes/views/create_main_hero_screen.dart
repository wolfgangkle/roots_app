import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/functions/create_hero.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';

class CreateMainHeroScreen extends StatefulWidget {
  const CreateMainHeroScreen({Key? key}) : super(key: key);

  @override
  State<CreateMainHeroScreen> createState() => _CreateMainHeroScreenState();
}

class _CreateMainHeroScreenState extends State<CreateMainHeroScreen> {
  String? _selectedVillageId;
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;
  bool _isCreatingHero = false;

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

  Future<void> _createHero() async {
    if (_selectedVillageId == null || _isCreatingHero) return;

    setState(() => _isCreatingHero = true);

    final village = _villages.firstWhere((v) => v['id'] == _selectedVillageId);
    final tileX = village['tileX'];
    final tileY = village['tileY'];

    final heroId = await createHero(
      heroName: 'Main Hero',
      race: 'Human',
      tileX: tileX,
      tileY: tileY,
    );

    setState(() => _isCreatingHero = false);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final controller = Provider.of<MainContentController>(context, listen: false);

    if (heroId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('heroes').doc(heroId).get();
        final data = doc.data();

        if (data != null) {
          final hero = HeroModel.fromFirestore(doc.id, data);

          // Show hero detail screen
          controller.setCustomContent(HeroDetailsScreen(hero: hero));

          messenger.showSnackBar(
            const SnackBar(content: Text('Main hero created!')),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Hero created, but data not found.')),
          );
        }
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error loading hero: $e')),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to create hero.')),
      );
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
      appBar: AppBar(title: const Text('Create Main Hero')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _villages.isEmpty
            ? const Center(child: Text('No villages found.'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select spawn village:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedVillageId,
              items: _villages.map<DropdownMenuItem<String>>((village) {
                return DropdownMenuItem<String>(
                  value: village['id'] as String,
                  child: Text(
                      '${village['name']} (${village['tileX']}, ${village['tileY']})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedVillageId = value),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create Main Hero'),
              onPressed: _isCreatingHero ? null : _createHero,
            ),
          ],
        ),
      ),
    );
  }
}
