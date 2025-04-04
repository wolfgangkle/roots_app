class _VillagePanelState extends State<VillagePanel> {
  final VillageService service = VillageService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VillageModel>>(
      future: service.getVillagesOnce(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final villages = snapshot.data ?? [];

        if (villages.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You don’t have any villages yet."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await service.createTestVillage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test village created!')),
                  );
                  setState(() {}); // Refresh UI
                },
                child: const Text("Create Test Village"),
              ),
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await service.createTestVillage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test village created!')),
                  );
                  setState(() {}); // Refresh UI
                },
                icon: const Icon(Icons.add),
                label: const Text("Create Test Village"),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const Divider(),
                itemCount: villages.length,
                itemBuilder: (context, index) {
                  final village = villages[index];
                  return VillageCard(
                    village: village,
                    onTap: () => onVillageTap?.call(village),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
