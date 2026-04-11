import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../models/content_models.dart';

// ══════════════════════════════════════════════════════════════
// Data passed back from full-screen editors
// ══════════════════════════════════════════════════════════════

class _StoryResult {
  final StoryMeta? meta;
  final XFile? file;
  final String text;
  final _StoryPreview preview;
  const _StoryResult({
    this.meta,
    this.file,
    this.text = '',
    required this.preview,
  });
}

class _StoryPreview {
  final Color? bgColor;
  final int? bgImageIndex;
  final String? displayText;
  final Uint8List? photoBytes;
  final bool isPhoto;
  const _StoryPreview({
    this.bgColor,
    this.bgImageIndex,
    this.displayText,
    this.photoBytes,
    this.isPhoto = false,
  });
}

// ══════════════════════════════════════════════════════════════
// PUBLIC WIDGET — select mode + completed preview
// Embeds in SchedulePostModal. Opens full-screen editors.
// ══════════════════════════════════════════════════════════════

class StoryCreatorPanel extends StatefulWidget {
  final ValueChanged<StoryMeta?> onStoryMetaChanged;
  final ValueChanged<XFile?> onStoryFileChanged;
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
  _StoryResult? _result;

  Future<void> _openTextEditor() async {
    final result = await Navigator.of(context).push<_StoryResult>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const _TextStoryEditor(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
    if (result != null && mounted) {
      setState(() => _result = result);
      widget.onStoryMetaChanged(result.meta);
      widget.onStoryFileChanged(result.file);
      widget.onTextChanged(result.text);
    }
  }

  Future<void> _openPhotoEditor() async {
    final result = await Navigator.of(context).push<_StoryResult>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const _PhotoStoryEditor(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
    if (result != null && mounted) {
      setState(() => _result = result);
      widget.onStoryMetaChanged(result.meta);
      widget.onStoryFileChanged(result.file);
      widget.onTextChanged(result.text);
    }
  }

  void _clearResult() {
    setState(() => _result = null);
    widget.onStoryMetaChanged(null);
    widget.onStoryFileChanged(null);
    widget.onTextChanged('');
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildPreview();
    return _buildSelectMode();
  }

  // ── Two-card selector ──
  Widget _buildSelectMode() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF307777).withValues(alpha: 0.08),
              const Color(0xFF307777).withValues(alpha: 0.03),
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF307777).withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: Color(0xFF307777)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Create a text or photo story. Stories disappear after 24 hours.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF307777)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _modeCard(
                icon: Icons.text_fields_rounded,
                label: 'Text Story',
                subtitle: 'Colors, fonts & backgrounds',
                colors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                onTap: _openTextEditor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _modeCard(
                icon: Icons.photo_camera_rounded,
                label: 'Photo Story',
                subtitle: 'Upload, crop & add text',
                colors: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                onTap: _openPhotoEditor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Preview after story is created ──
  Widget _buildPreview() {
    final p = _result!.preview;
    return Column(
      children: [
        // Match story aspect ratio (9:16) so preview matches editor exactly
        AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: BoxDecoration(
              color: p.isPhoto
                  ? Colors.black
                  : (p.bgColor ?? Colors.grey[900]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Text story background image
                  if (!p.isPhoto && p.bgImageIndex != null)
                    Image.network(
                      '${ApiConstants.serverOrigin}/assets/stories/${p.bgImageIndex! + 1}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: p.bgColor ?? Colors.grey[900]),
                    ),
                  // Photo story — captured composite or raw photo
                  // Use BoxFit.contain so framing matches the editor exactly
                  if (p.photoBytes != null)
                    Image.memory(p.photoBytes!,
                        fit: p.isPhoto
                            ? BoxFit.contain
                            : BoxFit.cover),
                  // Only overlay text for text stories (photo stories
                  // have text baked into the captured image)
                  if (!p.isPhoto &&
                      p.displayText != null &&
                      p.displayText!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          p.displayText!,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: p.bgImageIndex != null
                                ? const [
                                    Shadow(
                                        blurRadius: 8,
                                        color: Colors.black87),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  // Status badge
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green[300]),
                          const SizedBox(width: 6),
                          Text(
                            p.isPhoto
                                ? 'Photo story ready'
                                : 'Text story ready',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final wasPhoto = _result?.preview.isPhoto ?? false;
                  _clearResult();
                  if (wasPhoto) {
                    _openPhotoEditor();
                  } else {
                    _openTextEditor();
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearResult,
                icon: const Icon(Icons.close,
                    size: 16, color: Colors.redAccent),
                label: const Text('Discard',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TEXT STORY EDITOR — Full-screen immersive (Facebook-style)
// ══════════════════════════════════════════════════════════════

class _TextStoryEditor extends StatefulWidget {
  const _TextStoryEditor();

  @override
  State<_TextStoryEditor> createState() => _TextStoryEditorState();
}

class _TextStoryEditorState extends State<_TextStoryEditor> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  int _colorIndex = 0;
  int? _bgImageIndex;
  int _fontIndex = 0;
  double _fontSize = 24;
  int _activeTool = -1; // -1=none, 0=backgrounds, 1=size

  static const List<Color> _colors = [
    Color(0xFF1877F2),
    Color(0xFF7C3AED),
    Color(0xFFE11D48),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF0D9488),
    Color(0xFF475569),
    Color(0xFF1E293B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
  ];

  static const List<_FontOption> _fonts = [
    _FontOption('Simple', 'Arial, sans-serif', null),
    _FontOption('Clean', 'Open Sans, sans-serif', null),
    _FontOption('Casual', 'Courier New, monospace', 'Courier New'),
    _FontOption('Poppins', 'Poppins, sans-serif', 'Poppins'),
    _FontOption('Fancy', 'cursive', null),
    _FontOption('Headline', 'Times New Roman, serif', 'Times New Roman'),
    _FontOption('Modern', 'Georgia, serif', 'Georgia'),
  ];

  Color get _bgColor =>
      _bgImageIndex != null ? Colors.black : _colors[_colorIndex];

  Color get _textColor {
    if (_bgImageIndex != null) return Colors.white;
    return _colors[_colorIndex].computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  String get _textColorHex {
    if (_bgImageIndex != null) return '#ffffff';
    return _colors[_colorIndex].computeLuminance() > 0.5
        ? '#000000'
        : '#ffffff';
  }

  String get _bgColorHex {
    if (_bgImageIndex != null) return '';
    return '#${_colors[_colorIndex].value.toRadixString(16).substring(2)}';
  }

  void _done() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(_StoryResult(
      meta: StoryMeta(
        color: _bgColorHex.isNotEmpty ? _bgColorHex : null,
        textColor: _textColorHex,
        fontFamily: _fonts[_fontIndex].fontFamily,
        fontSize: _fontSize,
        textAlignment: 'center',
        bgImageId:
            _bgImageIndex != null ? '${_bgImageIndex! + 1}' : null,
      ),
      text: text,
      preview: _StoryPreview(
        bgColor: _bgColor,
        bgImageIndex: _bgImageIndex,
        displayText: text,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCanvas(),
          _buildTopBar(),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  // ── Full-screen colored/image background with centered text ──
  Widget _buildCanvas() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          if (_activeTool >= 0) {
            setState(() => _activeTool = -1);
          }
          _focusNode.requestFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _bgImageIndex == null ? _bgColor : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_bgImageIndex != null)
                Image.network(
                  '${ApiConstants.serverOrigin}/assets/stories/${_bgImageIndex! + 1}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: _colors[_colorIndex]),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: EditableText(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      fontFamily: _fonts[_fontIndex].flutterFamily,
                      height: 1.4,
                      shadows: _bgImageIndex != null
                          ? const [
                              Shadow(
                                  blurRadius: 8,
                                  color: Colors.black54),
                              Shadow(
                                  blurRadius: 16,
                                  color: Colors.black26),
                            ]
                          : null,
                    ),
                    cursorColor: _textColor,
                    backgroundCursorColor: Colors.transparent,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              if (_textController.text.isEmpty)
                Center(
                  child: IgnorePointer(
                    child: Text(
                      'Tap to type...',
                      style: TextStyle(
                        fontSize: _fontSize,
                        color: _textColor.withValues(alpha: 0.35),
                        fontFamily: _fonts[_fontIndex].flutterFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Floating top bar: close, font cycle, done ──
  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _floatingButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // Font cycle button
          _floatingButton(
            icon: Icons.text_fields,
            label: _fonts[_fontIndex].label,
            onTap: () {
              setState(() {
                _fontIndex = (_fontIndex + 1) % _fonts.length;
              });
            },
          ),
          const SizedBox(width: 8),
          // Done button
          if (_textController.text.trim().isNotEmpty)
            GestureDetector(
              onTap: _done,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom toolbar with gradient overlay ──
  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.25),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expandable tool panel
                if (_activeTool >= 0) _buildToolPanel(),
                const SizedBox(height: 8),
                // Tool buttons (Backgrounds, Size)
                _buildToolButtons(),
                const SizedBox(height: 10),
                // Color strip (always visible)
                _buildColorStrip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolChip(Icons.image_outlined, 'Backgrounds', 0),
          _toolChip(Icons.format_size_rounded, 'Size', 1),
        ],
      ),
    );
  }

  Widget _toolChip(IconData icon, String label, int index) {
    final isActive = _activeTool == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = isActive ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolPanel() {
    Widget content;
    switch (_activeTool) {
      case 0:
        content = _buildBackgroundGrid();
        break;
      case 1:
        content = _buildSizeControl();
        break;
      default:
        content = const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: content,
    );
  }

  Widget _buildColorStrip() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final isSelected =
              _colorIndex == i && _bgImageIndex == null;
          return GestureDetector(
            onTap: () {
              setState(() {
                _colorIndex = i;
                _bgImageIndex = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isSelected ? 40 : 32,
              height: isSelected ? 40 : 32,
              decoration: BoxDecoration(
                color: _colors[i],
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(
                        color:
                            Colors.white.withValues(alpha: 0.3),
                        width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              _colors[i].withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 16, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "None" — use color
        GestureDetector(
          onTap: () => setState(() => _bgImageIndex = null),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _bgImageIndex == null
                  ? _bgColor
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: _bgImageIndex == null
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text('Aa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _bgImageIndex == null
                        ? _textColor
                        : Colors.white60,
                  )),
            ),
          ),
        ),
        // 18 background images
        ...List.generate(18, (i) {
          final isSelected = _bgImageIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _bgImageIndex = i),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Colors.white, width: 2.5)
                    : Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.15)),
                image: DecorationImage(
                  image: NetworkImage(
                      '${ApiConstants.serverOrigin}/assets/stories/${i + 1}.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: isSelected
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.4),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check,
                          size: 20, color: Colors.white),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSizeControl() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Text Size',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${_fontSize.round()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor:
                Colors.white.withValues(alpha: 0.2),
            thumbColor: Colors.white,
            overlayColor:
                Colors.white.withValues(alpha: 0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: _fontSize,
            min: 16,
            max: 48,
            onChanged: (val) =>
                setState(() => _fontSize = val),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _sizePreset('S', 18),
            _sizePreset('M', 24),
            _sizePreset('L', 32),
            _sizePreset('XL', 44),
          ],
        ),
      ],
    );
  }

  Widget _sizePreset(String label, double size) {
    final isActive = (_fontSize - size).abs() < 2;
    return GestureDetector(
      onTap: () => setState(() => _fontSize = size),
      child: Container(
        width: 48,
        height: 34,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.black : Colors.white70,
              )),
        ),
      ),
    );
  }

  Widget _floatingButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: label != null
            ? const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: label != null
              ? BorderRadius.circular(20)
              : BorderRadius.circular(24),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PHOTO STORY EDITOR — Full-screen immersive
// ══════════════════════════════════════════════════════════════

class _PhotoStoryEditor extends StatefulWidget {
  const _PhotoStoryEditor();

  @override
  State<_PhotoStoryEditor> createState() => _PhotoStoryEditorState();
}

class _PhotoStoryEditorState extends State<_PhotoStoryEditor> {
  XFile? _photo;
  Uint8List? _photoBytes;
  final _overlayController = TextEditingController();
  final _overlayFocus = FocusNode();
  final GlobalKey _captureKey = GlobalKey();
  final _transformController = TransformationController();
  bool _showTextInput = false;
  bool _isCapturing = false;
  Offset _textOffset = const Offset(0.5, 0.45);

  // Text styling state
  int _textColorIndex = 0;
  int _fontIndex = 0;

  // Background gradient state (0 = plain black)
  int _bgGradientIndex = 0;

  // ── Text color palette ──
  static const List<Color> _textColors = [
    Colors.white,
    Color(0xFF000000),
    Color(0xFFFF3040),
    Color(0xFFFF6B00),
    Color(0xFFFFD700),
    Color(0xFF00E676),
    Color(0xFF00B0FF),
    Color(0xFF7C3AED),
    Color(0xFFE91E63),
    Color(0xFF1877F2),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
  ];

  // ── Font options (matches text story editor) ──
  static const List<_FontOption> _fonts = [
    _FontOption('Simple', 'Arial, sans-serif', null),
    _FontOption('Clean', 'Open Sans, sans-serif', null),
    _FontOption('Casual', 'Courier New, monospace', 'Courier New'),
    _FontOption('Poppins', 'Poppins, sans-serif', 'Poppins'),
    _FontOption('Fancy', 'cursive', null),
    _FontOption('Headline', 'Times New Roman, serif', 'Times New Roman'),
    _FontOption('Modern', 'Georgia, serif', 'Georgia'),
  ];

  // ── Gradient presets (Facebook-style background fills) ──
  static const List<List<Color>> _gradients = [
    [Color(0xFF000000), Color(0xFF000000)],
    [Color(0xFF833AB4), Color(0xFFE1306C)],
    [Color(0xFF1877F2), Color(0xFF00C6FF)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFF512F), Color(0xFFDD2476)],
    [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF373B44), Color(0xFF4286F4)],
    [Color(0xFFE44D26), Color(0xFFF16529)],
    [Color(0xFF7F00FF), Color(0xFFE100FF)],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhoto());
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _overlayFocus.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _photo = picked;
          _photoBytes = bytes;
        });
      }
    } else if (_photo == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _zoomIn() {
    final current = _transformController.value.getMaxScaleOnAxis();
    final next = (current * 1.3).clamp(0.5, 4.0);
    _transformController.value = Matrix4.identity()..scale(next, next);
  }

  void _zoomOut() {
    final current = _transformController.value.getMaxScaleOnAxis();
    final next = (current / 1.3).clamp(0.5, 4.0);
    if (next <= 1.05) {
      _transformController.value = Matrix4.identity();
    } else {
      _transformController.value = Matrix4.identity()..scale(next, next);
    }
  }

  bool get _hasModifications {
    final hasOverlay = _overlayController.text.trim().isNotEmpty;
    final hasGradient = _bgGradientIndex != 0;
    final hasZoom =
        _transformController.value.getMaxScaleOnAxis() > 1.05;
    return hasOverlay || hasGradient || hasZoom;
  }

  Future<void> _captureAndReturn() async {
    if (_photo == null || _isCapturing) return;
    setState(() => _isCapturing = true);

    // No modifications — return the raw photo file
    if (!_hasModifications) {
      Navigator.of(context).pop(_StoryResult(
        file: _photo,
        text: '',
        preview:
            _StoryPreview(photoBytes: _photoBytes, isPhoto: true),
      ));
      return;
    }

    // Capture composed canvas (gradient + zoom + text overlay)
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      XFile capturedFile;
      if (kIsWeb) {
        // name: must be explicit on web — XFile ignores the path for .name
        capturedFile = XFile('story_capture.png',
            name: 'story_capture.png',
            bytes: bytes, mimeType: 'image/png');
      } else {
        final tempDir = Directory.systemTemp;
        final file = File(
            '${tempDir.path}/story_cap_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes);
        capturedFile = XFile(file.path);
      }

      if (mounted) {
        // Captured bytes already contain gradient + photo + text baked in
        // Don't pass displayText — it would render double
        Navigator.of(context).pop(_StoryResult(
          file: capturedFile,
          text: _overlayController.text.trim(),
          preview: _StoryPreview(
            photoBytes: bytes,
            isPhoto: true,
          ),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCapturing = false);
        Navigator.of(context).pop(_StoryResult(
          file: _photo,
          text: _overlayController.text.trim(),
          preview: _StoryPreview(
              photoBytes: _photoBytes, isPhoto: true),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: _photo == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white))
          : Stack(
              fit: StackFit.expand,
              children: [
                _buildCanvas(),
                // Hint overlay — outside RepaintBoundary so it won't
                // be baked into the captured image
                if (_overlayController.text.isEmpty &&
                    !_showTextInput)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.4),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Text(
                            'Tap Aa to add text  \u2022  Pinch to zoom',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12)),
                      ),
                    ),
                  ),
                _buildTopBar(),
                if (!_showTextInput) _buildBottomBar(),
                if (_showTextInput) _buildTextInputOverlay(),
              ],
            ),
    );
  }

  // ── Full-screen photo with gradient bg, zoom, draggable styled text ──
  Widget _buildCanvas() {
    final textColor = _textColors[_textColorIndex];
    // Adaptive shadow: dark shadow for light text, light shadow for dark text
    final shadowColor = textColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white70;
    final shadowColor2 = textColor.computeLuminance() > 0.5
        ? Colors.black54
        : Colors.white38;

    return Positioned.fill(
      child: RepaintBoundary(
        key: _captureKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradients[_bgGradientIndex],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable photo via InteractiveViewer
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: true,
                child: _photoBytes != null
                    ? Image.memory(_photoBytes!,
                        fit: BoxFit.contain)
                    : kIsWeb
                        ? Image.network(_photo!.path,
                            fit: BoxFit.contain)
                        : Image.file(File(_photo!.path),
                            fit: BoxFit.contain),
              ),

              // Draggable styled text overlay
              if (_overlayController.text.isNotEmpty)
                Positioned.fill(
                  child: LayoutBuilder(
                      builder: (context, constraints) {
                    return Stack(children: [
                      Positioned(
                        left: _textOffset.dx *
                                constraints.maxWidth -
                            constraints.maxWidth * 0.4,
                        top: _textOffset.dy *
                                constraints.maxHeight -
                            20,
                        width: constraints.maxWidth * 0.8,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final box = _captureKey
                                    .currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                            if (box == null) return;
                            setState(() {
                              _textOffset = Offset(
                                (_textOffset.dx +
                                        details.delta.dx /
                                            box.size.width)
                                    .clamp(0.0, 1.0),
                                (_textOffset.dy +
                                        details.delta.dy /
                                            box.size.height)
                                    .clamp(0.0, 1.0),
                              );
                            });
                          },
                          child: Text(
                            _overlayController.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              fontFamily: _fonts[_fontIndex]
                                  .flutterFamily,
                              shadows: [
                                Shadow(
                                    blurRadius: 8,
                                    color: shadowColor),
                                Shadow(
                                    blurRadius: 20,
                                    color: shadowColor2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),

              // Tap hint removed — now rendered outside RepaintBoundary
              // so it won't be baked into captured images
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: close + zoom controls + add text ──
  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          // Close
          _topBarButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // Zoom out
          _topBarButton(
            icon: Icons.remove_rounded,
            onTap: _zoomOut,
          ),
          const SizedBox(width: 6),
          // Zoom in
          _topBarButton(
            icon: Icons.add_rounded,
            onTap: _zoomIn,
          ),
          const SizedBox(width: 10),
          // Add text button
          GestureDetector(
            onTap: () {
              setState(() => _showTextInput = true);
              _overlayFocus.requestFocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color:
                        Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.text_fields,
                      size: 20, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Aa',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBarButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  // ── Bottom bar: gradient palette + change/done buttons ──
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient palette strip ──
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  itemCount: _gradients.length,
                  itemBuilder: (context, i) {
                    final sel = i == _bgGradientIndex;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _bgGradientIndex = i),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _gradients[i],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel
                                ? Colors.white
                                : Colors.white30,
                            width: sel ? 2.5 : 1,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: Colors.white
                                        .withValues(
                                            alpha: 0.3),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: i == 0
                            ? const Center(
                                child: Icon(Icons.block,
                                    size: 16,
                                    color: Colors.white38))
                            : null,
                      ),
                    );
                  },
                ),
              ),
              // ── Change photo + Done buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 8, 16, 12),
                child: Row(
                  children: [
                    // Change photo
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white
                                    .withValues(
                                        alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons
                                      .photo_library_rounded,
                                  size: 18,
                                  color: Colors.white),
                              SizedBox(width: 8),
                              Text('Change',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Done
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isCapturing ? null : _captureAndReturn,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          decoration: BoxDecoration(
                            color: _isCapturing
                                ? Colors.grey[300]
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white
                                    .withValues(
                                        alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: _isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                        Icons
                                            .check_rounded,
                                        size: 20,
                                        color:
                                            Colors.black),
                                    SizedBox(width: 6),
                                    Text('Done',
                                        style: TextStyle(
                                            color: Colors
                                                .black,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            fontSize:
                                                16)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text input with color strip + font selector ──
  Widget _buildTextInputOverlay() {
    final selectedColor = _textColors[_textColorIndex];
    // Adaptive fill: light fill for dark text, dark fill for light text
    final isLightText = selectedColor.computeLuminance() > 0.4;
    final fillColor = isLightText
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isLightText
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.15);

    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // ── Text color dots ──
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: _textColors.length,
                itemBuilder: (context, i) {
                  final sel = i == _textColorIndex;
                  final dotColor = _textColors[i];
                  // Adaptive check: dark icon for light dots, light for dark
                  final checkColor =
                      dotColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _textColorIndex = i),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4),
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel
                              ? Colors.white
                              : Colors.white24,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                      child: sel
                          ? Icon(Icons.check,
                              size: 14, color: checkColor)
                          : null,
                    ),
                  );
                },
              ),
            ),
            // ── Font button + text field + done ──
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(10, 4, 8, 14),
              child: Row(
                children: [
                  // Font cycle button
                  GestureDetector(
                    onTap: () => setState(() => _fontIndex =
                        (_fontIndex + 1) % _fonts.length),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      margin:
                          const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _fonts[_fontIndex].label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: _fonts[_fontIndex]
                              .flutterFamily,
                        ),
                      ),
                    ),
                  ),
                  // Text field with adaptive fill
                  Expanded(
                    child: TextField(
                      controller: _overlayController,
                      focusNode: _overlayFocus,
                      maxLength: 200,
                      style: TextStyle(
                        color: selectedColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily:
                            _fonts[_fontIndex].flutterFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add text to your story...',
                        hintStyle: TextStyle(
                            color: isLightText
                                ? Colors.white38
                                : Colors.black38),
                        counterText: '',
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: selectedColor
                                  .withValues(alpha: 0.7),
                              width: 1.5),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12),
                        // Clear button when text is present
                        suffixIcon:
                            _overlayController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _overlayController.clear();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.close,
                                        size: 18,
                                        color: isLightText
                                            ? Colors.white38
                                            : Colors.black38),
                                  )
                                : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Done
                  GestureDetector(
                    onTap: () {
                      _overlayFocus.unfocus();
                      setState(
                          () => _showTextInput = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check,
                          size: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Font option
// ══════════════════════════════════════════════════════════════

class _FontOption {
  final String label;
  final String fontFamily; // CSS family for web story rendering
  final String? flutterFamily; // Flutter fontFamily
  const _FontOption(this.label, this.fontFamily, this.flutterFamily);
}
