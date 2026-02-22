import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';

class PresentationSettingsBody extends StatefulWidget {
  const PresentationSettingsBody({super.key});

  @override
  State<PresentationSettingsBody> createState() => _PresentationSettingsBodyState();
}

class _PresentationSettingsBodyState extends State<PresentationSettingsBody> {
  List<Display> _displays = [];

  @override
  void initState() {
    super.initState();
    _loadDisplays();
  }

  Future<void> _loadDisplays() async {
    final displays = await screenRetriever.getAllDisplays();
    if (mounted) {
      setState(() {
        _displays = displays;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nastavení prezentace',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Screen selection
              _buildSectionTitle('Výběr obrazovky'),
              const SizedBox(height: 8),
              _buildScreenSelector(state),
              const SizedBox(height: 20),
              // Lines per page
              _buildSectionTitle('Počet řádků na stránku'),
              const SizedBox(height: 8),
              _buildLinesPerPageSelector(state),
              const SizedBox(height: 20),
              // Font size
              _buildSectionTitle('Velikost písma'),
              const SizedBox(height: 8),
              _buildFontSizeSelector(state),
              const SizedBox(height: 8),
              Text(
                'Maximální velikost písma v prezentaci. Pokud se řádek nevejde na obrazovku, bude zalomen.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              // Font color
              _buildSectionTitle('Barva písma'),
              const SizedBox(height: 8),
              _buildFontColorSelector(state),
              const SizedBox(height: 20),
              // Show chords
              _buildSectionTitle('Zobrazení akordů'),
              const SizedBox(height: 8),
              _buildShowChordsToggle(state),
              const SizedBox(height: 20),
              // Black screen settings
              _buildSectionTitle('Černá obrazovka'),
              const SizedBox(height: 8),
              _buildBlackScreenSettings(state),
              const SizedBox(height: 20),
              // Display options
              _buildSectionTitle('Zobrazení informací'),
              const SizedBox(height: 8),
              _buildDisplayOptions(state),
              const SizedBox(height: 20),
              // Preview
              _buildSectionTitle('Náhled'),
              const SizedBox(height: 8),
              _buildPreview(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColor.primaryColor,
      ),
    );
  }

  Widget _buildScreenSelector(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dostupné obrazovky: ${_displays.length}',
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Obnovit seznam obrazovek',
                onPressed: _loadDisplays,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_displays.isEmpty)
            const Text(
              'Načítání...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            ..._displays.asMap().entries.map((entry) {
              final index = entry.key;
              final display = entry.value;
              final isSelected = state.presentationScreenIndex == index;
              return InkWell(
                onTap: () {
                  debugPrint('[ScreenSelector] User tapped screen index=$index (${display.size.width.toInt()}x${display.size.height.toInt()})');
                  context.read<SettingsBloc>().add(
                        ChangeSettingsValue('presentationScreenIndex', index),
                      );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : null,
                    border: Border.all(
                      color: isSelected ? AppColor.primaryColor : AppColor.grey3Color,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: isSelected ? AppColor.primaryColor : AppColor.grey1Color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Obrazovka ${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${display.size.width.toInt()} x ${display.size.height.toInt()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      if (index == 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Hlavní',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLinesPerPageSelector(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_list_numbered, size: 20),
          const SizedBox(width: 8),
          Text(
            'Řádků: ${state.presentationLinesPerPage}',
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: state.presentationLinesPerPage > 2
                ? () {
                    context.read<SettingsBloc>().add(
                          ChangeSettingsValue('presentationLinesPerPage', state.presentationLinesPerPage - 1),
                        );
                  }
                : null,
          ),
          SizedBox(
            width: 120,
            child: Slider(
              value: state.presentationLinesPerPage.toDouble(),
              min: 2,
              max: 20,
              divisions: 18,
              label: '${state.presentationLinesPerPage}',
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      ChangeSettingsValue('presentationLinesPerPage', value.toInt()),
                    );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: state.presentationLinesPerPage < 20
                ? () {
                    context.read<SettingsBloc>().add(
                          ChangeSettingsValue('presentationLinesPerPage', state.presentationLinesPerPage + 1),
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSelector(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_size, size: 20),
          const SizedBox(width: 8),
          Text(
            'Velikost: ${state.presentationFontSize.toInt()} px',
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: state.presentationFontSize > 12
                ? () {
                    context.read<SettingsBloc>().add(
                          ChangeSettingsValue('presentationFontSize', state.presentationFontSize - 2.0),
                        );
                  }
                : null,
          ),
          SizedBox(
            width: 120,
            child: Slider(
              value: state.presentationFontSize,
              min: 12,
              max: 120,
              divisions: 54,
              label: '${state.presentationFontSize.toInt()}',
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      ChangeSettingsValue('presentationFontSize', value.roundToDouble()),
                    );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: state.presentationFontSize < 120
                ? () {
                    context.read<SettingsBloc>().add(
                          ChangeSettingsValue('presentationFontSize', state.presentationFontSize + 2.0),
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFontColorSelector(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.color_lens, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Barva písma:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              _showColorPicker(state);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: state.presentationFontColor,
                border: Border.all(color: AppColor.grey1Color),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quick color presets
          ...([Colors.white, Colors.yellow, Colors.cyan, Colors.green]).map((color) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: InkWell(
                  onTap: () {
                    context.read<SettingsBloc>().add(
                          ChangeSettingsValue('presentationFontColor', color),
                        );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: state.presentationFontColor == color ? AppColor.primaryColor : AppColor.grey3Color,
                        width: state.presentationFontColor == color ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showColorPicker(SettingsState state) {
    Color pickerColor = state.presentationFontColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vyberte barvu písma'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              enableAlpha: false,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<SettingsBloc>().add(
                      ChangeSettingsValue('presentationFontColor', pickerColor),
                    );
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShowChordsToggle(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Zobrazit akordy v prezentaci',
            style: TextStyle(fontSize: 13),
          ),
          const Spacer(),
          Switch(
            value: state.presentationShowChords,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                    ChangeSettingsValue('presentationShowChords', value),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlackScreenSettings(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_1, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Černá stránka na začátku písně',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: state.presentationBlackFirstPage,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                        ChangeSettingsValue('presentationBlackFirstPage', value),
                      );
                },
              ),
            ],
          ),
          const Divider(height: 1),
          Row(
            children: [
              const Icon(Icons.brightness_1, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Černá stránka na konci písně / mezi písněmi',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: state.presentationBlackLastPage,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                        ChangeSettingsValue('presentationBlackLastPage', value),
                      );
                },
              ),
            ],
          ),
          if (state.presentationBlackLastPage)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                'Mezi písněmi se zobrazí pouze jedna černá stránka',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisplayOptions(SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.title, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Zobrazit název písně',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: state.presentationShowTitle,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                        ChangeSettingsValue('presentationShowTitle', value),
                      );
                },
              ),
            ],
          ),
          const Divider(height: 1),
          Row(
            children: [
              const Icon(Icons.numbers, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Zobrazit číslo stránky',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: state.presentationShowPageNumber,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                        ChangeSettingsValue('presentationShowPageNumber', value),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(SettingsState state) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.grey3Color),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ukázkový text písně',
            style: TextStyle(
              color: state.presentationFontColor,
              fontSize: (state.presentationFontSize * 0.6).clamp(12.0, 36.0),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          if (state.presentationShowChords)
            Text(
              '  Am        C         G',
              style: TextStyle(
                color: state.presentationFontColor.withValues(alpha: 0.7),
                fontSize: (state.presentationFontSize * 0.4).clamp(10.0, 28.0),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          Text(
            'Toto je ukázkový řádek textu',
            style: TextStyle(
              color: state.presentationFontColor,
              fontSize: (state.presentationFontSize * 0.5).clamp(10.0, 30.0),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (state.presentationShowChords)
            Text(
              '  Dm        F         E',
              style: TextStyle(
                color: state.presentationFontColor.withValues(alpha: 0.7),
                fontSize: (state.presentationFontSize * 0.4).clamp(10.0, 28.0),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          Text(
            'Druhý řádek textu písně',
            style: TextStyle(
              color: state.presentationFontColor,
              fontSize: (state.presentationFontSize * 0.5).clamp(10.0, 30.0),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const Spacer(),
          Text(
            'Řádků na stránku: ${state.presentationLinesPerPage} | Velikost písma: ${state.presentationFontSize.toInt()} px',
            style: TextStyle(
              color: state.presentationFontColor.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
