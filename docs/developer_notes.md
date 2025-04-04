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
- Removed local timer sync logic (moved to cloud functions)
