---

## 🧠 Architecture Notes

- 🟢 UI reads from Firestore via streams
- 🟡 Game logic (resource ticks, upgrades) handled by Cloud Functions
- 🔴 Client no longer applies local state updates (except UI display)

---




### 📄 main_content_controller.dart

✅ What it does:
- Holds a reference to the currently shown content widget (`_currentContent`)
- Lets you call:
    - `showVillageCenter(...)` → shows `VillageCenterScreen`
    - `setCustomContent(...)` → set any custom content
    - `reset()` → clears the content


---

### 📄 village_service.dart

✅ What it does:
- Handles all Firestore CRUD for villages
- Sends building upgrade requests
- Handles all Firestore CRUD for villages
- Sends building upgrade requests
- Removed local timer/resource sync logic (now handled via Cloud Functions)
- Still includes createTestVillage() and saveVillage() for manual village creation (used for dev/testing only)

⚠️ These will later be replaced by a server-side createVillage() Cloud Function, once village creation rules (e.g. tile placement, spawn zones) are finalized.