import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';


class OnboardSummaryScreen extends StatelessWidget {
  final String heroName;
  final String race;
  final String villageName;
  final String startZone;
  final VoidCallback onConfirm; // ✅ Keep this
  final VoidCallback onEdit;

  const OnboardSummaryScreen({
    Key? key,
    required this.heroName,
    required this.race,
    required this.villageName,
    required this.startZone,
    required this.onConfirm,
    required this.onEdit,
  }) : super(key: key);

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _handleConfirm(BuildContext context) {
    // 🧠 Step 1: Finalize onboarding (e.g. Firestore write)
    onConfirm();

    // 🧠 Step 2: Create and provide the profile model
    final userProfile = UserProfileModel(heroName: heroName);

    // 🧠 Step 3: Navigate to main screen with provider in scope
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<UserProfileModel>.value(
          value: userProfile,
          child: const MainHomeScreen(), // replace if needed
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review Your Choices")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Please review your choices before finalizing:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow("Hero Name", heroName),
            _buildSummaryRow("Race", race),
            _buildSummaryRow("Village Name", villageName),
            _buildSummaryRow("Starting Zone", startZone),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEdit,
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleConfirm(context),
                    child: const Text("Confirm"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
