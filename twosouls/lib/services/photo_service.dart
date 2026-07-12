import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// PhotoService
//
// Background removal for the Face Rank FIFA-style card, calling remove.bg
// DIRECTLY from the client.
//
// ⚠️  PRE-LAUNCH / DEV ONLY (remove.bg call) — this embeds an API key in
// the compiled app. It MUST move server-side (a Cloud Function proxy, or
// a free alternative like a Cloudflare Worker) before any public
// release. See the note further down for the exact spot that changes.
//
// ⚠️  STORAGE UPLOAD DISABLED UNTIL LAUNCH — Firebase Storage now
// requires the Blaze (pay-as-you-go) plan to provision a bucket at all,
// which means putting a card on file. Deferred deliberately until
// launch. generateCardCutout() is stubbed below — search "RE-ENABLE AT
// LAUNCH" for the exact spot to restore (see user_service.dart for the
// same pattern on profile photo upload).
//
// The remove.bg key is never hardcoded here — it's passed in at
// build/run time via --dart-define so it doesn't sit in source control.
// Run with:
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

  /// Sends [photoBytes] to remove.bg and returns the cutout PNG bytes
  /// (transparent background). Throws on failure — callers should catch
  /// and show a friendly error, since this depends on an external API
  /// that can fail, rate-limit, or run out of free-tier credits.
  ///
  /// This part still works pre-launch — it's a plain HTTP call, no
  /// Firebase Storage involved. Only the upload step below is stubbed.
  Future<Uint8List> removeBackground(Uint8List photoBytes) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'REMOVE_BG_API_KEY was not provided. Run with '
        '--dart-define=REMOVE_BG_API_KEY=your_key_here',
      );
    }

    // PRE-LAUNCH: this direct call is the piece that moves into a Cloud
    // Function (or equivalent proxy) before public launch — everything
    // else in this class stays the same either way.
    final response = await http.post(
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
      headers: {'X-Api-Key': _apiKey, 'Content-Type': 'application/json'},
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

  /// PRE-LAUNCH STUB — always returns null and uploads nothing.
  ///
  /// RE-ENABLE AT LAUNCH: once Firebase Storage is provisioned (Blaze
  /// plan active), restore the upload to
  /// `card_cutouts/{uid}/{filename}` via FirebaseStorage.instance and
  /// return the download URL, same as before. The removeBackground()
  /// call above already works fine pre-launch — only the final upload
  /// step needs restoring.
  Future<String?> generateCardCutout(
    Uint8List photoBytes,
    String filename,
  ) async {
    final uid = AuthService.instance.currentUid;
    if (uid == null) return null;

    // ignore: avoid_print
    print(
      'generateCardCutout: skipped — Firebase Storage not provisioned '
      'yet (deferred until launch, see PhotoService header comment).',
    );
    return null;
  }
}
