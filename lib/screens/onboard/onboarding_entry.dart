import 'package:flutter/material.dart';

import 'lore_intro_screen.dart';
import 'race_picker_screen.dart';
import 'name_picker_screen.dart';
import 'village_name_screen.dart';
import 'zone_picker_screen.dart';
import '../../services/firestore_service.dart';

class OnboardingEntry extends StatefulWidget {
  const OnboardingEntry({super.key});

  @override
  State<OnboardingEntry> createState() => _OnboardingEntryState();
}

class _OnboardingEntryState extends State<OnboardingEntry> {
  String? selectedRace = 'Human';
  String? heroName;
  String? villageName;
  String? startZone;

  int currentStep = 0;

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

  void _setZone(String zone) async {
    startZone = zone;

    await FirestoreService().createNewPlayer(
      heroName: heroName!,
      villageName: villageName!,
      startZone: startZone!,
      race: selectedRace!,
    );

    Navigator.of(context).pushReplacementNamed('/village');
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
      default:
        return ZonePickerScreen(onNext: _setZone);
    }
  }
}
