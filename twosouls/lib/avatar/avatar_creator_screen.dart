// ---------------------------------------------------------------------------
// AvatarCreatorScreen
//
// Lets the user build their fantasy avatar: pick a category tab, pick an
// option from the swatch row, see the result instantly in the live
// preview above (since rendering is just swapping which layer image
// shows - no network, no rendering delay).
//
// On "Save avatar", calls onSave with the finished AvatarConfig. Wire
// this to your real persistence (backend call, local storage, etc) -
// for now it just pops back with the result.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'avatar_config.dart';
import 'avatar_assets.dart';
import 'avatar_renderer.dart';

class AvatarCreatorScreen extends StatefulWidget {
  final AvatarConfig initialConfig;
  final ValueChanged<AvatarConfig>? onSave;

  const AvatarCreatorScreen({
    super.key,
    this.initialConfig = const AvatarConfig(),
    this.onSave,
  });

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late AvatarConfig _config;
  int _selectedCategoryIndex = 0;

  static const glow = Color(0xFFB44CFF);
  static const gold = Color(0xFFD4AF6A);

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  String _currentOptionId(AvatarCategory category) {
    return switch (category.type) {
      AvatarCategoryType.skinTone => _config.skinTone,
      AvatarCategoryType.face => _config.face,
      AvatarCategoryType.hairStyle => _config.hairStyle,
      AvatarCategoryType.hairColor => _config.hairColor,
      AvatarCategoryType.outfit => _config.outfit,
      AvatarCategoryType.accessory => _config.accessory,
    };
  }

  void _selectOption(AvatarCategory category, String optionId) {
    setState(() {
      _config = switch (category.type) {
        AvatarCategoryType.skinTone => _config.copyWith(skinTone: optionId),
        AvatarCategoryType.face => _config.copyWith(face: optionId),
        AvatarCategoryType.hairStyle => _config.copyWith(hairStyle: optionId),
        AvatarCategoryType.hairColor => _config.copyWith(hairColor: optionId),
        AvatarCategoryType.outfit => _config.copyWith(outfit: optionId),
        AvatarCategoryType.accessory => _config.copyWith(accessory: optionId),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = avatarCategories[_selectedCategoryIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F1F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Create your avatar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _PreviewStage(config: _config),
            const SizedBox(height: 16),
            _CategoryTabs(
              selectedIndex: _selectedCategoryIndex,
              onSelect: (i) => setState(() => _selectedCategoryIndex = i),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: category.type == AvatarCategoryType.hairColor
                  ? _ColorSwatchGrid(
                      category: category,
                      selectedId: _currentOptionId(category),
                      onSelect: (id) => _selectOption(category, id),
                    )
                  : _OptionSwatchGrid(
                      category: category,
                      selectedId: _currentOptionId(category),
                      onSelect: (id) => _selectOption(category, id),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave?.call(_config);
                    Navigator.pop(context, _config);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Save avatar',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStage extends StatelessWidget {
  final AvatarConfig config;
  const _PreviewStage({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101C3F), Color(0xFF0A1330)],
        ),
        border: Border.all(color: const Color(0xFFD4AF6A), width: 1.2),
        boxShadow: [
          BoxShadow(color: const Color(0xFFB44CFF).withAlpha(50), blurRadius: 30),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AvatarRenderer(config: config),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _CategoryTabs({required this.selectedIndex, required this.onSelect});

  static const glow = Color(0xFFB44CFF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: avatarCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final label = avatarCategories[index].label;

          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? glow.withAlpha(40) : const Color(0xFF101830),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? glow : const Color(0x33B44CFF),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withAlpha(160),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OptionSwatchGrid extends StatelessWidget {
  final AvatarCategory category;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _OptionSwatchGrid({
    required this.category,
    required this.selectedId,
    required this.onSelect,
  });

  static const glow = Color(0xFFB44CFF);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: category.optionIds.length,
      itemBuilder: (context, index) {
        final optionId = category.optionIds[index];
        final isSelected = optionId == selectedId;
        final isNone = optionId == 'none';

        return GestureDetector(
          onTap: () => onSelect(optionId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: const Color(0xFF101830),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? glow : const Color(0x33B44CFF),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: glow.withAlpha(110), blurRadius: 14)]
                  : null,
            ),
            child: isNone
                ? const Center(
                    child: Icon(Icons.close, color: Colors.white54, size: 20),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: PlaceholderLayer(type: category.type, optionId: optionId),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _ColorSwatchGrid extends StatelessWidget {
  final AvatarCategory category;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ColorSwatchGrid({
    required this.category,
    required this.selectedId,
    required this.onSelect,
  });

  static const glow = Color(0xFFB44CFF);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: category.optionIds.length,
      itemBuilder: (context, index) {
        final optionId = category.optionIds[index];
        final isSelected = optionId == selectedId;
        final color = hairColorSwatch[optionId] ?? Colors.grey;

        return GestureDetector(
          onTap: () => onSelect(optionId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? glow : Colors.white24,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: glow.withAlpha(110), blurRadius: 14)]
                  : null,
            ),
          ),
        );
      },
    );
  }
}