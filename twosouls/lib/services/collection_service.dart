import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_rarity_model.dart';
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// CollectionService
//
// Persists the user's card collection (won matches) and chat slots to
// Firestore so they survive app restarts.
//
// Firestore structure:
//   /users/{uid}/collection/{entryId}  — each won card
//   /users/{uid}/chats/{slotIndex}     — the 3 chat slots (docs 0, 1, 2)
//
// CollectionStore (messages_screen.dart) remains the in-memory source of
// truth for the UI — CollectionService reads from Firestore on startup to
// hydrate it, and writes back whenever something changes.
// ---------------------------------------------------------------------------

class CollectionService {
  CollectionService._();
  static final CollectionService instance = CollectionService._();

  final _db = FirebaseFirestore.instance;

  CollectionRef get _collection {
    final uid = AuthService.instance.currentUid!;
    return _db.collection('users').doc(uid).collection('collection');
  }

  CollectionRef get _chats {
    final uid = AuthService.instance.currentUid!;
    return _db.collection('users').doc(uid).collection('chats');
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadCollection() async {
    if (AuthService.instance.currentUid == null) return [];
    final snap = await _collection.get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>?>> loadChats() async {
    if (AuthService.instance.currentUid == null) return [null, null, null];
    final slots = <Map<String, dynamic>?>[null, null, null];
    final snap = await _chats.get();
    for (final doc in snap.docs) {
      final slot = int.tryParse(doc.id);
      if (slot != null && slot >= 0 && slot < 3) {
        slots[slot] = doc.data() as Map<String, dynamic>?;
      }
    }
    return slots;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> saveEntry(Map<String, dynamic> entry) async {
    if (AuthService.instance.currentUid == null) return;
    await _collection.doc(entry['id'] as String).set(entry);
  }

  Future<void> deleteEntry(String entryId) async {
    if (AuthService.instance.currentUid == null) return;
    await _collection.doc(entryId).delete();
  }

  Future<void> saveChatSlot(int slot, Map<String, dynamic>? entry) async {
    if (AuthService.instance.currentUid == null) return;
    final doc = _chats.doc('$slot');
    if (entry == null) {
      await doc.delete().catchError((_) {});
    } else {
      await doc.set(entry);
    }
  }

  Future<void> clearChatSlot(int slot) => saveChatSlot(slot, null);
}

typedef CollectionRef = CollectionReference<Map<String, dynamic>>;
