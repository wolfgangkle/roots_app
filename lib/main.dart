import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialized successfully');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roots',
      routes: {
        '/village': (_) => const MainHomeScreen(),
      },
      home: const MainHomeScreen(), // Skip auth and go directly to Home Screen
    );
  }
}

class FirestoreTestPage extends StatefulWidget {
  const FirestoreTestPage({super.key});

  @override
  State<FirestoreTestPage> createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  String _loadedValue = "Loading...";

  Future<void> _saveData() async {
    try {
      await FirebaseFirestore.instance.collection('test').doc('demo').set({
        'message': 'Hello from Wolfgang’s WebApp!',
        'timestamp': DateTime.now().toIso8601String(),
      });
      print("✅ Data saved");
    } catch (e, stack) {
      print("❌ Error saving data: $e");
      print(stack);
    }
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('test').doc('demo').get();
      final data = doc.data();
      print("📦 Loaded data: $data");
      setState(() {
        _loadedValue = data?['message'] ?? 'No data found';
      });
    } catch (e, stack) {
      print("❌ Error loading data: $e");
      print(stack);
      setState(() {
        _loadedValue = "❌ Error loading";
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _saveData().then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Test")),
      body: Center(child: Text(_loadedValue)),
    );
  }
}
