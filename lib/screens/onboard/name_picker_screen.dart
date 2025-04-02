

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NamePickerScreen extends StatefulWidget {
  final void Function(String heroName) onNext;

  const NamePickerScreen({super.key, required this.onNext});

  @override
  State<NamePickerScreen> createState() => _NamePickerScreenState();
}

class _NamePickerScreenState extends State<NamePickerScreen> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isChecking = false;

  Future<void> _checkAndContinue() async {
    final input = _controller.text.trim();

    // Validation: letters + spaces only
    final isValid = RegExp(r'^[A-Za-z ]+$').hasMatch(input);
    if (!isValid || input.length < 3 || input.length > 24) {
      setState(() => _errorText = 'Name must be 3–24 letters/spaces only.');
      return;
    }

    setState(() {
      _errorText = null;
      _isChecking = true;
    });

    // Check Firestore for existing hero name
    final query = await FirebaseFirestore.instance
        .collection('heroes')
        .where('name', isEqualTo: input)
        .limit(1)
        .get();

    setState(() => _isChecking = false);

    if (query.docs.isNotEmpty) {
      setState(() => _errorText = 'That name is already taken.');
    } else {
      widget.onNext(input); // pass the validated name to the next screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Name')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose your hero name',
              style: TextStyle(fontSize: 20),
            ),

            // WARNING for account and hero name
            const SizedBox(height: 12),
            const Text(
              'This name will represent your account and your main hero.\n'
                  'It cannot be changed later. Choose wisely!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
                        
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Hero Name',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkAndContinue,
              child: _isChecking
                  ? const CircularProgressIndicator()
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
