import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../models/content_models.dart';

/// Embedded story creator with text/photo modes, color palettes,
/// fonts, and background images — mirrors web StoryCreatorPanel.
class StoryCreatorPanel extends StatefulWidget {
  /// Callback fired whenever story metadata changes (text mode auto-sync).
  final ValueChanged<StoryMeta?> onStoryMetaChanged;

  /// Callback fired when a photo story is captured (screenshot file).
  final ValueChanged<XFile?> onStoryFileChanged;

  /// Callback fired when story text changes.
  final ValueChanged<String> onTextChanged;

  const StoryCreatorPanel({
    super.key,
    required this.onStoryMetaChanged,
    required this.onStoryFileChanged,
    required this.onTextChanged,
  });

  @override
  State<StoryCreatorPanel> createState() => StoryCreatorPanelState();
}

class StoryCreatorPanelState extends State<StoryCreatorPanel> {
  // select | text | photo
  String _mode = 'select';
  final _textController = TextEditingController();

  // Text story state
  int _selectedColorIndex = 0;
  int? _selectedBgImageIndex;
  int _selectedFontIndex = 0;
  double _fontSize = 22;

  // Photo story state
  XFile? _photoFile;
  Uint8List? _photoBytes; // For web preview
  final _overlayTextController = TextEditingController();
  final GlobalKey _captureKey = GlobalKey();
  bool _isCaptured = false;

  static const List<Color> _bgColors = [
    Color(0xFF3498db), // Blue
    Color(0xFFe74c3c), // Red
    Color(0xFF2ecc71), // Green
    Color(0xFF1abc9c), // Teal
    Color(0xFFf1c40f), // Yellow
    Color(0xFF2c3e50), // Dark
    Color(0xFF27ae60), // Green dark
    Color(0xFF95a5a6), // Gray
    Color(0xFFe91e90), // Pink
  ];

  static const List<_FontOption> _fonts = [
    _FontOption('Simple', 'Arial, sans-serif'),
    _FontOption('Clean', 'Open Sans, sans-serif'),
    _FontOption('Casual', 'Courier New, monospace'),
    _FontOption('Poppins', 'Poppins, sans-serif'),
    _FontOption('Fancy', 'cursive'),
    _FontOption('Headline', 'Times New Roman, serif'),
  ];

  String get _activeBgColor {
    if (_selectedBgImageIndex != null) return '';
    return '#${_bgColors[_selectedColorIndex].value.toRadixString(16).substring(2)}';
  }

  Color get _activeColor {
    if (_selectedBgImageIndex != null) return Colors.transparent;
    return _bgColors[_selectedColorIndex];
  }

  /// Auto-compute text color based on background luminance
  String get _textColor {
    if (_selectedBgImageIndex != null) return '#ffffff';
    final c = _bgColors[_selectedColorIndex];
    return c.computeLuminance() > 0.5 ? '#000000' : '#ffffff';
  }

  Color get _textColorValue {
    if (_selectedBgImageIndex != null) return Colors.white;
    final c = _bgColors[_selectedColorIndex];
    return c.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  void _syncMetaToParent() {
    final text = _textController.text.trim();
    widget.onTextChanged(text);
    if (text.isEmpty) {
      widget.onStoryMetaChanged(null);
      return;
    }
    widget.onStoryMetaChanged(StoryMeta(
      color: _activeBgColor.isNotEmpty ? _activeBgColor : null,
      textColor: _textColor,
      fontFamily: _fonts[_selectedFontIndex].fontFamily,
      fontSize: _fontSize,
      textAlignment: 'center',
      bgImageId: _selectedBgImageIndex != null
          ? '${_selectedBgImageIndex! + 1}'
          : null,
    ));
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoFile = picked;
        _photoBytes = bytes;
        _isCaptured = false;
      });
      widget.onStoryFileChanged(null); // Reset until captured
    }
  }

  Future<void> _captureStory() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // On web, dart:io File is unavailable — pass bytes directly
        if (mounted) {
          setState(() => _isCaptured = true);
          widget.onStoryFileChanged(
            XFile('story_capture.png', bytes: bytes, mimeType: 'image/png'),
          );
          widget.onTextChanged(_overlayTextController.text.trim());
        }
      } else {
        final tempDir = Directory.systemTemp;
        final file = File(
            '${tempDir.path}/story_capture_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes);
        if (mounted) {
          setState(() => _isCaptured = true);
          widget.onStoryFileChanged(XFile(file.path));
          widget.onTextChanged(_overlayTextController.text.trim());
        }
      }
    } catch (_) {
      // Capture failed
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _overlayTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case 'text':
        return _buildTextMode();
      case 'photo':
        return _buildPhotoMode();
      default:
        return _buildSelectMode();
    }
  }

  // ─── SELECT MODE ─────────────────────────────────
  Widget _buildSelectMode() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF307777).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF307777)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Create a text or photo story. Stories disappear after 24 hours.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF307777)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                icon: Icons.text_fields,
                label: 'Text\nStory',
                gradient: const LinearGradient(
                  colors: [Color(0xFF06b6d4), Color(0xFF0891b2)],
                ),
                onTap: () => setState(() => _mode = 'text'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeCard(
                icon: Icons.photo_camera,
                label: 'Photo\nStory',
                gradient: const LinearGradient(
                  colors: [Color(0xFFec4899), Color(0xFFdb2777)],
                ),
                onTap: () => setState(() => _mode = 'photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── TEXT MODE ───────────────────────────────────
  Widget _buildTextMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            setState(() {
              _mode = 'select';
              _textController.clear();
              _selectedColorIndex = 0;
              _selectedBgImageIndex = null;
              _selectedFontIndex = 0;
              _fontSize = 22;
            });
            widget.onStoryMetaChanged(null);
            widget.onTextChanged('');
          },
          child: Row(
            children: [
              const Icon(Icons.arrow_back, size: 18),
              const SizedBox(width: 4),
              const Text('Back', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preview canvas (9:16 aspect ratio)
        AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedBgImageIndex == null ? _activeColor : null,
              borderRadius: BorderRadius.circular(12),
              image: _selectedBgImageIndex != null
                  ? DecorationImage(
                      image: NetworkImage(
                        '${_serverOrigin}/assets/stories/${_selectedBgImageIndex! + 1}.png',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              _textController.text.isEmpty
                  ? 'Start typing...'
                  : _textController.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: _textColorValue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Text input
        TextField(
          controller: _textController,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'Start typing...',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            setState(() {});
            _syncMetaToParent();
          },
        ),
        const SizedBox(height: 12),

        // Font family dropdown
        DropdownButtonFormField<int>(
          value: _selectedFontIndex,
          decoration: const InputDecoration(
            labelText: 'Font Style',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _fonts.asMap().entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedFontIndex = val);
              _syncMetaToParent();
            }
          },
        ),
        const SizedBox(height: 16),

        // Color palette
        const Text('Select Color',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_bgColors.length, (i) {
            final isSelected = _selectedColorIndex == i && _selectedBgImageIndex == null;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColorIndex = i;
                  _selectedBgImageIndex = null;
                });
                _syncMetaToParent();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _bgColors[i],
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _bgColors[i].withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Background images
        const Text('Background Images',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(18, (i) {
            final isSelected = _selectedBgImageIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedBgImageIndex = i);
                _syncMetaToParent();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF307777), width: 2)
                      : Border.all(color: Colors.grey[300]!),
                  image: DecorationImage(
                    image: NetworkImage(
                      '$_serverOrigin/assets/stories/${i + 1}.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Font size slider
        Row(
          children: [
            const Text('Text Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_fontSize.round()}px',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        Slider(
          value: _fontSize,
          min: 12,
          max: 48,
          activeColor: const Color(0xFF307777),
          onChanged: (val) {
            setState(() => _fontSize = val);
            _syncMetaToParent();
          },
        ),

        // Status indicator
        if (_textController.text.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Story ready — set schedule below',
                  style: TextStyle(fontSize: 13, color: Colors.green[700]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── PHOTO MODE ──────────────────────────────────
  Widget _buildPhotoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            setState(() {
              _mode = 'select';
              _photoFile = null;
              _overlayTextController.clear();
              _isCaptured = false;
            });
            widget.onStoryFileChanged(null);
            widget.onTextChanged('');
          },
          child: Row(
            children: [
              const Icon(Icons.arrow_back, size: 18),
              const SizedBox(width: 4),
              const Text('Back', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preview canvas (9:16)
        RepaintBoundary(
          key: _captureKey,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: _photoFile != null
                    ? DecorationImage(
                        image: _photoBytes != null
                            ? MemoryImage(_photoBytes!)
                            : (kIsWeb
                                ? NetworkImage(_photoFile!.path)
                                : FileImage(File(_photoFile!.path)))
                                as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: _photoFile == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Upload Image',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    )
                  : _overlayTextController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _overlayTextController.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ],
                            ),
                          ),
                        )
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Choose photo button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose Photo'),
          ),
        ),
        const SizedBox(height: 12),

        // Text overlay input
        const Text('Text Overlay',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _overlayTextController,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'Add text to your photo...',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),

        // Capture button
        if (_photoFile != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _captureStory,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Capture Story Preview'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF307777),
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // Status
        if (_isCaptured) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Story captured',
                  style: TextStyle(fontSize: 13, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Server origin for story background images
  static String get _serverOrigin {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://217.73.238.134:9006/api',
    );
    return baseUrl.replaceAll('/api', '');
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontOption {
  final String label;
  final String fontFamily;
  const _FontOption(this.label, this.fontFamily);
}
