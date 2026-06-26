// ---------------------------------------------------------------------------
// AvatarAssets
//
// Single source of truth for turning an AvatarConfig into the list of
// image layers to stack, bottom to top.
//
// PLACEHOLDER MODE: until real artwork exists, every layer renders as a
// flat colored shape via _PlaceholderLayer so the whole picker/preview
// flow is testable today.
//
// SWITCHING TO REAL ART: once you have real PNGs/SVGs, drop them at
// assets/avatar/<category>/<id>.png using the exact ids from
// avatar_config.dart (e.g. assets/avatar/hair/hair_3.png), add the
// assets/avatar/ folder to pubspec.yaml, then change
// AvatarRenderer.usePlaceholders to false. No other code changes needed -
// layerPath() below already builds the right file path from the config.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'avatar_config.dart';

class AvatarAssets {
  static String layerPath(AvatarCategoryType type, String optionId) {
    final folder = switch (type) {
      AvatarCategoryType.skinTone => 'base',
      AvatarCategoryType.face => 'face',
      AvatarCategoryType.hairStyle => 'hair',
      AvatarCategoryType.hairColor => 'hair', // color is applied as a tint, see note below
      AvatarCategoryType.outfit => 'outfit',
      AvatarCategoryType.accessory => 'accessory',
    };
    return 'assets/avatar/$folder/$optionId.png';
  }

  // Ordered bottom-to-top. hairColor is not its own image layer - it's
  // applied as a color tint over the hairStyle layer (see ColorFiltered
  // in AvatarRenderer), since most 2D avatar art ships as a single
  // greyscale/white hair shape that gets recolored rather than redrawn
  // per color.
  static List<AvatarCategoryType> get layerOrder => const [
        AvatarCategoryType.skinTone,
        AvatarCategoryType.face,
        AvatarCategoryType.outfit,
        AvatarCategoryType.hairStyle,
        AvatarCategoryType.accessory,
      ];
}

// Maps hair color option ids to an actual Color used to tint the hair layer.
const Map<String, Color> hairColorSwatch = {
  'color_brown': Color(0xFF6B4226),
  'color_black': Color(0xFF1A1A1A),
  'color_blonde': Color(0xFFE3C16F),
  'color_red': Color(0xFFB5482E),
  'color_blue': Color(0xFF3D74FF),
  'color_purple': Color(0xFFB44CFF),
};

// Placeholder visual per category+option, used until real art is added.
// Deterministic per id so the same option always looks the same.
class PlaceholderLayer extends StatelessWidget {
  final AvatarCategoryType type;
  final String optionId;
  final Color? tint;

  const PlaceholderLayer({
    super.key,
    required this.type,
    required this.optionId,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    if (optionId == 'none') return const SizedBox.shrink();

    final baseColor = tint ?? _colorForId(optionId);

    return switch (type) {
      AvatarCategoryType.skinTone => Center(
          child: Container(
            width: 150,
            height: 190,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(70),
            ),
          ),
        ),
      AvatarCategoryType.face => Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Eye(color: baseColor),
                const SizedBox(width: 24),
                _Eye(color: baseColor),
              ],
            ),
          ),
        ),
      AvatarCategoryType.outfit => Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 170,
            height: 120,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
          ),
        ),
      AvatarCategoryType.hairStyle => Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 165,
            height: 90,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(80)),
            ),
          ),
        ),
      AvatarCategoryType.hairColor => const SizedBox.shrink(),
      AvatarCategoryType.accessory => Center(
          child: Icon(
            _iconForAccessory(optionId),
            size: 56,
            color: baseColor,
          ),
        ),
    };
  }

  IconData _iconForAccessory(String id) {
    return switch (id) {
      'accessory_glasses' => Icons.center_focus_strong_outlined,
      'accessory_hat' => Icons.checkroom_outlined,
      'accessory_earrings' => Icons.circle_outlined,
      'accessory_necklace' => Icons.diamond_outlined,
      _ => Icons.star_outline,
    };
  }

  Color _colorForId(String id) {
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = [
      Color(0xFF9EC5FF),
      Color(0xFFD4AF6A),
      Color(0xFFB44CFF),
      Color(0xFF6FCF97),
      Color(0xFFE085FF),
      Color(0xFF3D74FF),
    ];
    return palette[hash % palette.length];
  }
}

class _Eye extends StatelessWidget {
  final Color color;
  const _Eye({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}
