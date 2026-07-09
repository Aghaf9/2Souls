import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// ChatMessage
//
// A single message within a chat thread with a match. Threads currently
// live under the logged-in user's own Firestore subtree (see ChatService)
// since matches aren't backed by real second accounts yet — see the note
// at the top of match_pool.dart. senderId is still recorded per-message so
// that once real two-way matching exists, rendering "theirs vs mine" and
// migrating to a shared thread needs no changes to this model.
// ---------------------------------------------------------------------------

class ChatMessage {
  final String id;
  final String senderId;
  final String text;

  /// Null very briefly right after sending, until the server timestamp
  /// resolves and a fresh snapshot comes back with it filled in.
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
