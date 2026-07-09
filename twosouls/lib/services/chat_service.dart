import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// ChatService
//
// Realtime chat, one thread per match. Firestore structure:
//   /users/{uid}/chatThreads/{matchEntryId}/messages/{messageId}
//
// Threads live under the logged-in user's own subtree rather than a
// shared /chats/{chatId} collection, because a MatchCandidate isn't a
// real second account yet (see match_pool.dart) — there's no other uid
// to key a shared thread against yet. senderId is still stored on every
// message so the data model itself doesn't need to change once real
// two-way matching exists; only the storage location would migrate, to
// a thread shared between both real uids.
//
// Every method requires a signed-in user and no-ops (or returns an empty
// stream) when currentUid is null, matching the pattern already used by
// CollectionService/UserService.
// ---------------------------------------------------------------------------

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _messagesRef(
    String matchEntryId,
  ) {
    final uid = AuthService.instance.currentUid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('chatThreads')
        .doc(matchEntryId)
        .collection('messages');
  }

  /// Realtime stream of every message in this thread, oldest first.
  /// Rebuilds automatically whenever a message is added — this is what
  /// makes the chat "realtime": no manual refresh or polling needed.
  Stream<List<ChatMessage>> watchMessages(String matchEntryId) {
    final ref = _messagesRef(matchEntryId);
    if (ref == null) return const Stream.empty();
    return ref
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// Sends a message from the logged-in user into this thread. Silently
  /// ignores empty/whitespace-only input and no-ops if signed out.
  Future<void> sendMessage(String matchEntryId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final ref = _messagesRef(matchEntryId);
    final uid = AuthService.instance.currentUid;
    if (ref == null || uid == null) return;

    await ref.add(
      ChatMessage(
        id: '', // ignored — Firestore assigns the real doc id on add()
        senderId: uid,
        text: trimmed,
        createdAt: null, // resolved server-side via FieldValue.serverTimestamp()
      ).toFirestore(),
    );
  }

  /// Most recent message in a thread — for a future chat-list preview row
  /// (e.g. "last message" under each of the 3 chat slots). Returns null
  /// if the thread has no messages yet.
  Future<ChatMessage?> latestMessage(String matchEntryId) async {
    final ref = _messagesRef(matchEntryId);
    if (ref == null) return null;
    final snap = await ref
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ChatMessage.fromFirestore(snap.docs.first);
  }
}
