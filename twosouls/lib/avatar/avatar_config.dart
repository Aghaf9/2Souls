// ---------------------------------------------------------------------------
// AvatarConfig
//
// Holds the user's selected option (a string id) for each customizable
// avatar category. This is intentionally just plain strings, not enums,
// so new options can be added to AvatarOptions below without touching
// this model or any save/load code.
//
// Persisting this is a single JSON-encodable map - see toJson/fromJson.
// ---------------------------------------------------------------------------

class AvatarConfig {
  final String skinTone;
  final String face;
  final String hairStyle;
  final String hairColor;
  final String outfit;
  final String accessory; // 'none' is a valid value -> no accessory layer

  const AvatarConfig({
    this.skinTone = 'tone_1',
    this.face = 'face_1',
    this.hairStyle = 'hair_1',
    this.hairColor = 'color_brown',
    this.outfit = 'outfit_1',
    this.accessory = 'none',
  });

  AvatarConfig copyWith({
    String? skinTone,
    String? face,
    String? hairStyle,
    String? hairColor,
    String? outfit,
    String? accessory,
  }) {
    return AvatarConfig(
      skinTone: skinTone ?? this.skinTone,
      face: face ?? this.face,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      accessory: accessory ?? this.accessory,
    );
  }

  Map<String, String> toJson() => {
        'skinTone': skinTone,
        'face': face,
        'hairStyle': hairStyle,
        'hairColor': hairColor,
        'outfit': outfit,
        'accessory': accessory,
      };

  factory AvatarConfig.fromJson(Map<String, dynamic> json) => AvatarConfig(
        skinTone: json['skinTone'] ?? 'tone_1',
        face: json['face'] ?? 'face_1',
        hairStyle: json['hairStyle'] ?? 'hair_1',
        hairColor: json['hairColor'] ?? 'color_brown',
        outfit: json['outfit'] ?? 'outfit_1',
        accessory: json['accessory'] ?? 'none',
      );
}

// ---------------------------------------------------------------------------
// AvatarCategory
//
// Defines the customization categories shown as tabs in the creator screen,
// and the list of selectable option ids within each. Asset file paths are
// derived from these ids - see AvatarAssets below.
//
// TO ADD A NEW OPTION: just add its id string to the relevant list here,
// then drop a matching image into the assets folder using the same id as
// the filename (see AvatarAssets.layerPath for the exact naming pattern).
// No other code needs to change.
// ---------------------------------------------------------------------------

enum AvatarCategoryType { skinTone, face, hairStyle, hairColor, outfit, accessory }

class AvatarCategory {
  final AvatarCategoryType type;
  final String label;
  final List<String> optionIds;

  const AvatarCategory({
    required this.type,
    required this.label,
    required this.optionIds,
  });
}

const avatarCategories = [
  AvatarCategory(
    type: AvatarCategoryType.skinTone,
    label: 'Skin tone',
    optionIds: ['tone_1', 'tone_2', 'tone_3', 'tone_4', 'tone_5'],
  ),
  AvatarCategory(
    type: AvatarCategoryType.face,
    label: 'Face',
    optionIds: ['face_1', 'face_2', 'face_3', 'face_4'],
  ),
  AvatarCategory(
    type: AvatarCategoryType.hairStyle,
    label: 'Hair style',
    optionIds: ['hair_1', 'hair_2', 'hair_3', 'hair_4', 'hair_5'],
  ),
  AvatarCategory(
    type: AvatarCategoryType.hairColor,
    label: 'Hair color',
    optionIds: ['color_brown', 'color_black', 'color_blonde', 'color_red', 'color_blue', 'color_purple'],
  ),
  AvatarCategory(
    type: AvatarCategoryType.outfit,
    label: 'Outfit',
    optionIds: ['outfit_1', 'outfit_2', 'outfit_3', 'outfit_4', 'outfit_5'],
  ),
  AvatarCategory(
    type: AvatarCategoryType.accessory,
    label: 'Accessories',
    optionIds: ['none', 'accessory_glasses', 'accessory_hat', 'accessory_earrings', 'accessory_necklace'],
  ),
];