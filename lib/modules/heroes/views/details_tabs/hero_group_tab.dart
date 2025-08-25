import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';

// 🔷 Tokens
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

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
    // 🔁 Tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    final heroRef = FirebaseFirestore.instance.collection('heroes');
    final groupRef =
    FirebaseFirestore.instance.collection('heroGroups').doc(widget.hero.groupId);

    return FutureBuilder<DocumentSnapshot>(
      future: groupRef.get(),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupData = groupSnapshot.data!.data() as Map<String, dynamic>?;
        if (groupData == null) {
          return Padding(
            padding: EdgeInsets.all(pad.horizontal / 2),
            child: TokenPanel(
              glass: glass, text: text, padding: EdgeInsets.all(14),
              child: Text("⚠️ Group data not found.", style: TextStyle(color: text.primary)),
            ),
          );
        }

        final tileX = groupData['tileX'] ?? -9999;
        final tileY = groupData['tileY'] ?? -9999;

        final groupQuery =
        heroRef.where('groupId', isEqualTo: widget.hero.groupId).snapshots();

        final isInGroup = widget.hero.groupId != null;
        final isRootLeader = widget.hero.groupId == widget.hero.id;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, pad.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🧑‍🤝‍🧑 Overview
              TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🧑‍🤝‍🧑 Group Info",
                      style: TextStyle(
                        color: text.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _kv(text, "Hero", widget.hero.heroName),
                    const SizedBox(height: 6),
                    _kv(
                      text,
                      "Current Group",
                      isRootLeader ? "Solo (you)" : (widget.hero.groupId ?? "—"),
                    ),
                    _kv(
                      text,
                      "Group Leader",
                      widget.hero.groupLeaderId ?? "You (leader)",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 📊 Group structure + leave button
              if (isInGroup)
                StreamBuilder<QuerySnapshot>(
                  stream: groupQuery,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final heroes = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return HeroModel.fromFirestore(doc.id, data);
                    }).toList();

                    final leader = heroes.firstWhere(
                          (h) => h.id == widget.hero.groupId,
                      orElse: () => widget.hero,
                    );

                    return TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📊 Group Structure",
                            style: TextStyle(
                              color: text.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (heroes.length <= 1)
                            Text(
                              "You are currently not connected to any other heroes.",
                              style: TextStyle(color: text.secondary),
                            )
                          else
                            HeroTreeNode(
                              hero: leader,
                              allHeroes: heroes,
                              currentHeroId: widget.hero.id,
                              currentHeroGroupId: widget.hero.groupId!,
                              isRootLeader: isRootLeader,
                              onKick: kickHero,
                              isProcessing: _isProcessing,
                              glass: glass,
                              text: text,
                              buttons: buttons,
                            ),
                          const SizedBox(height: 12),
                          if (!isRootLeader)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _isProcessing
                                  ? const SizedBox(
                                  width: 22, height: 22, child: CircularProgressIndicator())
                                  : TokenIconButton(
                                glass: glass,
                                text: text,
                                buttons: buttons,
                                variant: TokenButtonVariant.danger,
                                icon: const Icon(Icons.logout),
                                label: const Text("Leave Group"),
                                onPressed:
                                widget.hero.state == 'idle' ? leaveGroup : null,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 12),

              // 🧭 Nearby heroes
              TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nearby Heroes (same tile)",
                      style: TextStyle(
                        color: text.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: heroRef.where('state', isEqualTo: 'idle').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs
                            .where((doc) => doc.id != widget.hero.id)
                            .toList();

                        if (docs.isEmpty) {
                          return Text("• No heroes nearby.",
                              style: TextStyle(color: text.secondary));
                        }

                        final isCurrentHeroLeader = widget.hero.groupLeaderId == null;

                        return FutureBuilder<
                            List<MapEntry<HeroModel, Map<String, dynamic>>>>(
                          future: Future.wait(docs.map((doc) async {
                            final data = doc.data() as Map<String, dynamic>;
                            final hero = HeroModel.fromFirestore(doc.id, data);
                            final groupSnap = await FirebaseFirestore.instance
                                .collection('heroGroups')
                                .doc(hero.groupId)
                                .get();
                            final groupData = groupSnap.data();
                            return MapEntry(hero, groupData ?? {});
                          })),
                          builder: (context, groupSnapshot2) {
                            if (!groupSnapshot2.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final sameTileHeroes = groupSnapshot2.data!
                                .where((entry) =>
                            entry.value['tileX'] == tileX &&
                                entry.value['tileY'] == tileY &&
                                (entry.value['insideVillage'] ?? false) ==
                                    (groupData['insideVillage'] ?? false))
                                .toList();

                            if (sameTileHeroes.isEmpty) {
                              return Text("• No heroes nearby.",
                                  style: TextStyle(color: text.secondary));
                            }

                            return Column(
                              children: sameTileHeroes.map((entry) {
                                final otherHero = entry.key;
                                final isGroupLeader =
                                    otherHero.groupLeaderId == null ||
                                        otherHero.groupLeaderId == otherHero.id;
                                final isSameGroup =
                                    otherHero.groupId == widget.hero.groupId;
                                final canConnect = isGroupLeader && !isSameGroup;

                                return Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(otherHero.heroName,
                                                style: TextStyle(
                                                    color: text.primary,
                                                    fontWeight:
                                                    FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Group: ${isSameGroup ? "Same group" : (otherHero.groupId ?? "—")}",
                                              style: TextStyle(
                                                  color: text.secondary,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (canConnect && isCurrentHeroLeader)
                                        (_isProcessing)
                                            ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                            : TokenTextButton(
                                          glass: glass,
                                          text: text,
                                          buttons: buttons,
                                          variant:
                                          TokenButtonVariant.primary,
                                          onPressed:
                                          widget.hero.state == 'idle'
                                              ? () => connectToHero(
                                              otherHero.id)
                                              : null,
                                          child: const Text("Connect"),
                                        )
                                      else
                                        Text(
                                          isSameGroup
                                              ? "In your group"
                                              : !isGroupLeader
                                              ? "Not a leader"
                                              : "Not the leader (you)",
                                          style: TextStyle(
                                              color: text.subtle, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ⚠️ Leader warning
              TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Only the group leader can move the party. Others must leave or be kicked to act independently.",
                        style: TextStyle(color: text.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(TextOnGlassTokens text, String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(color: text.secondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            v,
            style: TextStyle(color: text.primary),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  // 🔷 tokens from parent
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final ButtonTokens? buttons;

  const HeroTreeNode({
    super.key,
    required this.hero,
    required this.allHeroes,
    required this.currentHeroId,
    required this.currentHeroGroupId,
    required this.isRootLeader,
    required this.onKick,
    required this.isProcessing,
    required this.glass,
    required this.text,
    this.buttons,
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
                style: TextStyle(
                  color: text.primary,
                  fontWeight: hero.id == currentHeroId
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (canKick) ...[
              const SizedBox(width: 8),
              isProcessing
                  ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TokenTextButton(
                glass: glass,
                text: text,
                buttons: buttons,
                variant: TokenButtonVariant.danger,
                onPressed: () => onKick(hero.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.remove_circle, size: 16),
                    SizedBox(width: 4),
                    Text("Kick"),
                  ],
                ),
              ),
            ],
          ],
        ),
        ...children.map(
              (child) => Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 6),
            child: HeroTreeNode(
              hero: child,
              allHeroes: allHeroes,
              currentHeroId: currentHeroId,
              currentHeroGroupId: currentHeroGroupId,
              isRootLeader: isRootLeader,
              onKick: onKick,
              isProcessing: isProcessing,
              glass: glass,
              text: text,
              buttons: buttons,
            ),
          ),
        ),
      ],
    );
  }
}
