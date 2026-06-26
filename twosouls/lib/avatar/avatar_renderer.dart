// ---------------------------------------------------------------------------
// AvatarRenderer
//
// Stacks the layers for a given AvatarConfig, bottom to top, and renders
// them. This is the ONE widget used everywhere an avatar needs to be shown
// - the creator preview, the profile card, the discover stack, etc - so
// switching from placeholders to real art happens in exactly one place.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'avatar_config.dart';
import 'avatar_assets.dart';

class AvatarRenderer extends StatelessWidget {
  final AvatarConfig config;

  // Flip to false once real PNG/SVG assets exist at the paths produced by
  // AvatarAssets.layerPath and are declared in pubspec.yaml.
  static const bool usePlaceholders = true;

  const AvatarRenderer({super.key, required this.config});

  String _optionFor(AvatarCategoryType type) {
    return switch (type) {
      AvatarCategoryType.skinTone => config.skinTone,
      AvatarCategoryType.face => config.face,
      AvatarCategoryType.hairStyle => config.hairStyle,
      AvatarCategoryType.hairColor => config.hairColor,
      AvatarCategoryType.outfit => config.outfit,
      AvatarCategoryType.accessory => config.accessory,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: AvatarAssets.layerOrder.map((type) {
        final optionId = _optionFor(type);

        if (usePlaceholders) {
          final tint = type == AvatarCategoryType.hairStyle
              ? hairColorSwatch[config.hairColor]
              : null;
          return PlaceholderLayer(type: type, optionId: optionId, tint: tint);
        }

        if (optionId == 'none') return const SizedBox.shrink();

        final path = AvatarAssets.layerPath(type, optionId);
        final image = Image.asset(path, fit: BoxFit.contain);

        if (type == AvatarCategoryType.hairStyle) {
          final tint = hairColorSwatch[config.hairColor];
          if (tint != null) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
              child: image,
            );
          }
        }
        return image;
      }).toList(),
    );
  }
}