import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'lore_intro_screen.dart';
import 'race_picker_screen.dart';
import 'name_picker_screen.dart';
import 'village_name_screen.dart';
import 'zone_picker_screen.dart';
import 'onboard_summary.dart';

class OnboardingEntry extends StatefulWidget {
  const OnboardingEntry({Key? key}) : super(key: key);

  @override
  State<OnboardingEntry> createState() => _OnboardingEntryState();
}

class _OnboardingEntryState extends State<OnboardingEntry> {
  String? selectedRace = 'Human';
  String? heroName;
  String? villageName;
  String? startZone;
  int currentStep = 0;
  bool _isSubmitting = false; // ✅ Lock for confirm button

  void _nextStep() {
    setState(() => currentStep++);
  }

  void _setRace(String race) {
    selectedRace = race;
    _nextStep();
  }

  void _setHeroName(String name) {
    heroName = name;
    _nextStep();
  }

  void _setVillageName(String name) {
    villageName = name;
    _nextStep();
  }

  void _setZone(String zone) {
    startZone = zone;
    _nextStep();
  }

  /// Finalizes onboarding by calling the Cloud Function.
  Future<void> _finalizeOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('finalizeOnboarding');
      await callable.call({
        'heroName': heroName!,
        'villageName': villageName!,
        'startZone': startZone!,
        'race': selectedRace!,
      });
    } catch (e) {
      debugPrint("❌ Onboarding error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error finalizing onboarding: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Allows the user to edit their choices. Here we simply restart the flow.
  void _editOnboarding() {
    setState(() {
      currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 0:
        return LoreIntroScreen(onNext: _nextStep);
      case 1:
        return RacePickerScreen(onNext: _setRace);
      case 2:
        return NamePickerScreen(onNext: _setHeroName);
      case 3:
        return VillageNameScreen(onNext: _setVillageName);
      case 4:
        return ZonePickerScreen(onNext: _setZone);
      case 5:
      default:
        return OnboardSummaryScreen(
          heroName: heroName!,
          race: selectedRace!,
          villageName: villageName!,
          startZone: startZone!,
          onConfirm: _finalizeOnboarding,
          onEdit: _editOnboarding,
          isLoading: _isSubmitting, // ✅ Pass loading state
        );
    }
  }
}
