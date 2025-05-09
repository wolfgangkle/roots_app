import 'package:flutter/material.dart';

class VillageNameScreen extends StatefulWidget {
  final void Function(String villageName) onNext;

  const VillageNameScreen({super.key, required this.onNext});

  @override
  State<VillageNameScreen> createState() => _VillageNameScreenState();
}

class _VillageNameScreenState extends State<VillageNameScreen> {
  final _controller = TextEditingController();
  String? _errorText;

  void _validateAndContinue() {
    final input = _controller.text.trim();

    final isValid = RegExp(r'^[A-Za-z ]+$').hasMatch(input);
    if (!isValid || input.length < 3 || input.length > 24) {
      setState(() => _errorText = 'Name must be 3–24 letters/spaces only.');
      return;
    }

    widget.onNext(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Name Your Village')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your village name can be anything you like.\n'
              'Other players can see it, but it doesn’t have to be unique.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Village Name',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateAndContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
