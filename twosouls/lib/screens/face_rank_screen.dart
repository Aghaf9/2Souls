import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// FaceRankScreen
//
// Lets the user upload 1–6 photos of themselves to receive an
// attractiveness rating (0-10, one decimal place) for each photo, plus
// an overall "looks score" averaged across all submitted photos. This
// score feeds into MatchCandidate.looksMatchScore for compatibility
// matching — people are matched with others of similar attractiveness.
//
// Scoring right now is a PLACEHOLDER: the score is derived from a simple
// byte-hash of the image data, producing a number that looks meaningful
// and is deterministic (same photo always gives the same score) but has
// no real relationship to actual attractiveness. Replace
// _scoreBytesPlaceholder() with a real ML inference call when one exists
// — the API surface stays identical.
//
// TODO: wire the final overallLooksScore into UserProfile.looksScore once
// that field exists — for now, onScored(score) hands it back to the caller.
// ---------------------------------------------------------------------------

class FaceRankScreen extends StatefulWidget {
  /// Called with the overall looks score (0-100) once the user taps
  /// "Save". Caller (e.g. Profile's edit sheet) stores it.
  final void Function(int overallScore) onScored;

  const FaceRankScreen({super.key, required this.onScored});

  @override
  State<FaceRankScreen> createState() => _FaceRankScreenState();
}

class _FaceRankScreenState extends State<FaceRankScreen> {
  static const int kMaxPhotos = 6;

  final List<Uint8List> _photos = [];
  final List<double?> _scores = []; // null = not yet scored
  bool _scoring = false;

  Future<void> _pickPhoto() async {
    if (_photos.length >= kMaxPhotos) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photos.add(bytes);
      _scores.add(null); // not scored yet
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _scores.removeAt(index);
    });
  }

  Future<void> _scoreAll() async {
    if (_photos.isEmpty) return;
    setState(() => _scoring = true);

    // Score each photo in sequence. The artificial delay makes it feel
    // like real inference is happening; remove when wiring real ML.
    for (int i = 0; i < _photos.length; i++) {
      if (_scores[i] != null) continue; // already scored, skip
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _scores[i] = _scoreBytesPlaceholder(_photos[i]));
    }

    setState(() => _scoring = false);
  }

  /// PLACEHOLDER SCORER — returns a 0-10 score derived from the hash of
  /// the image bytes. Deterministic (same bytes = same score), but has
  /// no real relationship to attractiveness.
  ///
  /// Replace with:
  ///   final response = await http.post(Uri.parse('YOUR_ML_ENDPOINT'),
  ///     body: bytes, headers: {'Content-Type': 'image/jpeg'});
  ///   return (jsonDecode(response.body)['score'] as num).toDouble();
  double _scoreBytesPlaceholder(Uint8List bytes) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < bytes.length && i < 512; i++) {
      hash ^= bytes[i];
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    // Map hash to 4.0 – 9.5 (realistic attractiveness range)
    final normalised = (hash & 0xFFFF) / 0xFFFF;
    return 4.0 + normalised * 5.5;
  }

  double? get _overallScore {
    final scored = _scores.whereType<double>().toList();
    if (scored.isEmpty) return null;
    return scored.reduce((a, b) => a + b) / scored.length;
  }

  Color _scoreColor(double score) {
    if (score >= 8.0) return AppColors.gold;
    if (score >= 6.5) return AppColors.emerald;
    if (score >= 5.0) return AppColors.textSecondary;
    return AppColors.bronze;
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallScore;
    final allScored = _photos.isNotEmpty && _scores.every((s) => s != null);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x22B44CFF))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.panelBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33B44CFF)),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'FACE RANKING',
                    style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Explanation
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.panelBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.panelBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How it works', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            'Upload 1\u20136 photos of yourself. Each is scored 0\u201310 for attractiveness. Your overall looks score helps us match you with people at a similar level \u2014 so you\u2019re not competing against everyone at once.',
                            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.85), fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Overall score pill
                    if (overall != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _scoreColor(overall).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: _scoreColor(overall).withOpacity(0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: _scoreColor(overall), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Overall: ${overall.toStringAsFixed(1)} / 10',
                                style: TextStyle(color: _scoreColor(overall), fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (overall != null) const SizedBox(height: 20),

                    // Photo grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _photos.length + (_photos.length < kMaxPhotos ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _photos.length) {
                          return _AddPhotoTile(onTap: _pickPhoto);
                        }
                        return _PhotoScoreTile(
                          bytes: _photos[index],
                          score: _scores[index],
                          scoreColor: _scores[index] != null ? _scoreColor(_scores[index]!) : AppColors.textSecondary,
                          onRemove: () => _removePhoto(index),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Score / Save buttons
                    if (_photos.isNotEmpty && !allScored)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _scoring ? null : _scoreAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _scoring
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Rate My Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    if (allScored && overall != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onScored((overall * 10).round().clamp(0, 100));
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Save Score', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile widgets ─────────────────────────────────────────────────────────────

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.gold.withOpacity(0.8), size: 22),
            const SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppColors.gold.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PhotoScoreTile extends StatelessWidget {
  final Uint8List bytes;
  final double? score;
  final Color scoreColor;
  final VoidCallback onRemove;

  const _PhotoScoreTile({required this.bytes, required this.score, required this.scoreColor, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        // Score overlay at bottom
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
              ),
            ),
            child: score == null
                ? const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: scoreColor, size: 11),
                      const SizedBox(width: 3),
                      Text(score!.toStringAsFixed(1), style: TextStyle(color: scoreColor, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}
