import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// PhotoService
//
// Background removal for the Face Rank FIFA-style card, calling remove.bg
// DIRECTLY from the client.
//
// ⚠️  PRE-LAUNCH / DEV ONLY — this embeds an API key in the compiled app.
// Anyone who inspects a shipped build (web bundle or mobile APK/IPA) can
// extract the key and use your remove.bg credits. This is an accepted
// tradeoff to avoid a paid Firebase Blaze upgrade before launch — it MUST
// move server-side (a Cloud Function proxy, or a free alternative like a
// Cloudflare Worker) before any public release. Search "PRE-LAUNCH" in
// this file for the exact spot that changes when that happens.
//
// The key is never hardcoded here — it's passed in at build/run time via
// --dart-define so it doesn't sit in source control. Run with:
//
//   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080 \
//     --dart-define=REMOVE_BG_API_KEY=your_key_here
//
// (swap `run` for `build` the same way for release builds)
// ---------------------------------------------------------------------------

class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  static const String _apiKey = String.fromEnvironment('REMOVE_BG_API_KEY');

  final _storage = FirebaseStorage.instance;

  /// Sends [photoBytes] to remove.bg and returns the cutout PNG bytes
  /// (transparent background). Throws on failure — callers should catch
  /// and show a friendly error, since this depends on an external API
  /// that can fail, rate-limit, or run out of free-tier credits.
  Future<Uint8List> removeBackground(Uint8List photoBytes) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'REMOVE_BG_API_KEY was not provided. Run with '
        '--dart-define=REMOVE_BG_API_KEY=your_key_here',
      );
    }

    // PRE-LAUNCH: this direct call is the piece that moves into a Cloud
    // Function (or equivalent proxy) before public launch — everything
    // else in this class (Storage upload, the public methods) stays the
    // same either way.
    final response = await http.post(
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
      headers: {
        'X-Api-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image_file_b64': base64Encode(photoBytes),
        'size': 'auto',
        // Focuses the cutout on the person rather than guessing between
        // product/animal/car/etc.
        'type': 'person',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'remove.bg request failed (${response.statusCode}): ${response.body}',
      );
    }

    return response.bodyBytes;
  }

  /// Runs background removal, then uploads the cutout to
  /// `card_cutouts/{uid}/{filename}` and returns the download URL.
  /// This is a separate image from the regular profile photo
  /// (`profile_photos/{uid}/...`, see UserService) — the cutout is only
  /// ever used on the Face Rank card, so the original full photo (with
  /// background) is preserved for everywhere else in the app.
  Future<String?> generateCardCutout(
    Uint8List photoBytes,
    String filename,
  ) async {
    final uid = AuthService.instance.currentUid;
    if (uid == null) return null;

    final cutoutBytes = await removeBackground(photoBytes);

    final ref = _storage.ref('card_cutouts/$uid/$filename');
    final task = await ref.putData(
      cutoutBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    return task.ref.getDownloadURL();
  }
}
