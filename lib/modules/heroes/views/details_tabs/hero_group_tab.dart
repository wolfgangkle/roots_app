import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';

class HeroGroupsTab extends StatefulWidget {
  final HeroModel hero;

  const HeroGroupsTab({super.key, required this.hero});

  @override
  State<HeroGroupsTab> createState() => _HeroGroupsTabState();
}

class _HeroGroupsTabState extends State<HeroGroupsTab> {
  bool _isProcessing = false;

  Future<void> connectToHero(String targetHeroId) async {
    setState(() => _isProcessing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('connectHeroToGroup');
      final result = await callable.call({
        'heroId': widget.hero.id,
        'targetHeroId': targetHeroId,
      });

      debugPrint("✅ Connected: ${result.data}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to hero.')),
      );
    } catch (e) {
      debugPrint("❌ Error connecting to hero: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> leaveGroup() async {
    setState(() => _isProcessing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('disconnectHeroFromGroup');
      final result = await callable.call({'heroId': widget.hero.id});
      debugPrint("✅ Disconnected from group: ${result.data}");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left group.')),
      );
    } catch (e) {
      debugPrint("❌ Error disconnecting from group: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave group: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> kickHero(String targetHeroId) async {
    setState(() => _isProcessing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('kickHeroFromGroup');
      final result = await callable.call({
        'heroId': widget.hero.id,
        'targetHeroId': targetHeroId,
      });

      debugPrint("✅ Kicked: ${result.data}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hero kicked from group.')),
      );
    } catch (e) {
      debugPrint("❌ Error kicking hero: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to kick hero: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroRef = FirebaseFirestore.instance.collection('heroes');
    final groupRef = FirebaseFirestore.instance.collection('heroGroups').doc(widget.hero.groupId);

    return FutureBuilder<DocumentSnapshot>(
      future: groupRef.get(),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) return const CircularProgressIndicator();

        final groupData = groupSnapshot.data!.data() as Map<String, dynamic>?;
        if (groupData == null) {
          return const Text("⚠️ Group data not found.");
        }

        final tileX = groupData['tileX'] ?? -9999;
        final tileY = groupData['tileY'] ?? -9999;

        final groupQuery = heroRef.where('groupId', isEqualTo: widget.hero.groupId).snapshots();
        final isRootLeader = widget.hero.groupId == widget.hero.id;
        final isInGroup = widget.hero.groupId != null;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🧑‍🤝‍🧑 Group Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Hero: ${widget.hero.heroName}"),
              const SizedBox(height: 8),
              Text("Current Group: ${isRootLeader ? "Solo (you)" : widget.hero.groupId}"),
              Text("Group Leader: ${widget.hero.groupLeaderId ?? "You (leader)"}"),
              const SizedBox(height: 16),

              if (isInGroup)
                StreamBuilder<QuerySnapshot>(
                  stream: groupQuery,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final heroes = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return HeroModel.fromFirestore(doc.id, data);
                    }).toList();

                    final leader = heroes.firstWhere(
                          (h) => h.id == widget.hero.groupId,
                      orElse: () => widget.hero,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📊 Group Structure:"),
                        const SizedBox(height: 8),
                        if (heroes.length <= 1)
                          const Text("You are currently not connected to any other heroes."),
                        if (heroes.length > 1)
                          HeroTreeNode(
                            hero: leader,
                            allHeroes: heroes,
                            currentHeroId: widget.hero.id,
                            currentHeroGroupId: widget.hero.groupId!,
                            isRootLeader: isRootLeader,
                            onKick: kickHero,
                            isProcessing: _isProcessing,
                          ),
                        const SizedBox(height: 8),
                        if (!isRootLeader)
                          _isProcessing
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                            onPressed: widget.hero.state == 'idle' ? leaveGroup : null,
                            icon: const Icon(Icons.logout),
                            label: const Text("Leave Group"),
                          ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 24),
              const Text("Nearby Heroes (same tile):"),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: heroRef.where('state', isEqualTo: 'idle').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final docs = snapshot.data!.docs.where((doc) => doc.id != widget.hero.id).toList();
                  if (docs.isEmpty) return const Text("• No heroes nearby.");

                  final isCurrentHeroLeader = widget.hero.groupLeaderId == null;

                  return FutureBuilder<List<MapEntry<HeroModel, Map<String, dynamic>>>>(
                    future: Future.wait(docs.map((doc) async {
                      final data = doc.data() as Map<String, dynamic>;
                      final hero = HeroModel.fromFirestore(doc.id, data);
                      final groupSnap = await FirebaseFirestore.instance.collection('heroGroups').doc(hero.groupId).get();
                      final groupData = groupSnap.data();

                      return MapEntry(hero, groupData ?? {});
                    })),
                    builder: (context, groupSnapshot) {
                      if (!groupSnapshot.hasData) return const CircularProgressIndicator();

                      final sameTileHeroes = groupSnapshot.data!
                          .where((entry) =>
                      entry.value['tileX'] == tileX &&
                          entry.value['tileY'] == tileY)
                          .toList();

                      if (sameTileHeroes.isEmpty) return const Text("• No heroes nearby.");

                      return Column(
                        children: sameTileHeroes.map((entry) {
                          final otherHero = entry.key;
                          final isGroupLeader = otherHero.groupLeaderId == null || otherHero.groupLeaderId == otherHero.id;
                          final isSameGroup = otherHero.groupId == widget.hero.groupId;
                          final canConnect = isGroupLeader && !isSameGroup;

                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(otherHero.heroName),
                            subtitle: Text("Group: ${isSameGroup ? "Same group" : otherHero.groupId}"),
                            trailing: canConnect && isCurrentHeroLeader
                                ? _isProcessing
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : ElevatedButton(
                              onPressed: widget.hero.state == 'idle'
                                  ? () => connectToHero(otherHero.id)
                                  : null,
                              child: const Text("Connect"),
                            )
                                : Text(
                              isSameGroup
                                  ? "In your group"
                                  : !isGroupLeader
                                  ? "Not a leader"
                                  : "Not the leader (you)",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              Text(
                "⚠️ Only the group leader can move the party. Others must leave or be kicked to act independently.",
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HeroTreeNode extends StatelessWidget {
  final HeroModel hero;
  final List<HeroModel> allHeroes;
  final String currentHeroId;
  final String currentHeroGroupId;
  final bool isRootLeader;
  final void Function(String heroId) onKick;
  final bool isProcessing;

  const HeroTreeNode({
    super.key,
    required this.hero,
    required this.allHeroes,
    required this.currentHeroId,
    required this.currentHeroGroupId,
    required this.isRootLeader,
    required this.onKick,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final children = allHeroes.where((h) => h.groupLeaderId == hero.id).toList();
    final canKick = isRootLeader && hero.id != currentHeroId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: (hero.id == currentHeroId ? 0 : 16.0)),
              child: Text(
                "${hero.heroName}${hero.id == currentHeroGroupId ? " (leader)" : ""}",
                style: TextStyle(fontWeight: hero.id == currentHeroId ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            if (canKick)
              isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                tooltip: "Kick from group",
                onPressed: () => onKick(hero.id),
              ),
          ],
        ),
        ...children.map((child) => HeroTreeNode(
          hero: child,
          allHeroes: allHeroes,
          currentHeroId: currentHeroId,
          currentHeroGroupId: currentHeroGroupId,
          isRootLeader: isRootLeader,
          onKick: onKick,
          isProcessing: isProcessing,
        )),
      ],
    );
  }
}
