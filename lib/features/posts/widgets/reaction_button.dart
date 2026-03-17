// Ported from quantum_possibilities_flutter/lib/reactions.dart
// Standalone ReactionButton — no external packages needed.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Reaction {
  final String key;
  final String label;
  final Color accent;
  final String? emoji;
  final String? asset;

  const Reaction({
    required this.key,
    required this.label,
    required this.accent,
    this.emoji,
    this.asset,
  }) : assert(emoji != null || asset != null,
            'Provide either emoji or asset for the reaction icon.');
}

const kDefaultReactions = <Reaction>[
  Reaction(
      key: 'like', label: 'Like', emoji: '👍', accent: Color(0xFF1877F2)),
  Reaction(
      key: 'love', label: 'Love', emoji: '❤️', accent: Color(0xFFE53935)),
  Reaction(
      key: 'care', label: 'Care', emoji: '🥰', accent: Color(0xFFFF6D00)),
  Reaction(
      key: 'haha', label: 'Haha', emoji: '😆', accent: Color(0xFFFFC107)),
  Reaction(
      key: 'wow', label: 'Wow', emoji: '😮', accent: Color(0xFFFFD54F)),
  Reaction(
      key: 'sad', label: 'Sad', emoji: '😢', accent: Color(0xFF64B5F6)),
  Reaction(
      key: 'angry', label: 'Angry', emoji: '😠', accent: Color(0xFFE65100)),
];

class ReactionButton extends StatefulWidget {
  final Reaction? value;
  final ValueChanged<Reaction?> onChanged;
  final List<Reaction> reactions;
  final Duration longPressDelay;
  final double barItemSize;
  final double barPadding;
  final bool tapTogglesLike;
  final bool isShowLabel;

  const ReactionButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.reactions = kDefaultReactions,
    this.longPressDelay = const Duration(milliseconds: 280),
    this.barItemSize = 52,
    this.barPadding = 10,
    this.tapTogglesLike = true,
    this.isShowLabel = false,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    final theme = Theme.of(context);
    final bool isPlaceholder = selected == null;

    final String label = isPlaceholder ? 'Like' : selected!.label;

    final Color accent = isPlaceholder
        ? (theme.colorScheme.outline)
        : selected.accent;

    Widget icon;
    if (isPlaceholder) {
      final r0 = widget.reactions.first;
      icon = (r0.asset != null)
          ? Image.asset(r0.asset!, width: 24, height: 24, fit: BoxFit.contain)
          : Text(r0.emoji ?? '👍', style: const TextStyle(fontSize: 18));
    } else {
      icon = (selected!.asset != null)
          ? Image.asset(selected.asset!,
              width: 24, height: 24, fit: BoxFit.contain)
          : Text(selected.emoji ?? '👍', style: const TextStyle(fontSize: 18));
    }

    return Semantics(
      button: true,
      label: selected == null ? 'React' : 'Reaction: $label',
      child: GestureDetector(
        key: _buttonKey,
        onTap: widget.tapTogglesLike ? _toggleLike : null,
        onLongPressStart: (_) => _showOverlay(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              if (widget.isShowLabel) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLike() {
    final like = widget.reactions.first;
    if (widget.value?.key == like.key) {
      widget.onChanged(null);
    } else {
      HapticFeedback.selectionClick();
      widget.onChanged(like);
    }
  }

  void _showOverlay() {
    final box = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final centerAbove =
        Offset(origin.dx + box.size.width / 2, origin.dy - 12);

    final controller = _ReactionOverlayController(
      reactions: widget.reactions,
      itemSize: widget.barItemSize,
      barPadding: widget.barPadding,
      anchor: centerAbove,
      onSelected: (r) {
        if (r != null) HapticFeedback.lightImpact();
        widget.onChanged(r);
      },
    );

    controller.show(context);
  }
}

class _ReactionOverlayController {
  _ReactionOverlayController({
    required this.reactions,
    required this.itemSize,
    required this.barPadding,
    required this.anchor,
    required this.onSelected,
  });

  final List<Reaction> reactions;
  final double itemSize;
  final double barPadding;
  final Offset anchor;
  final ValueChanged<Reaction?> onSelected;
  late final OverlayEntry _entry;

  void show(BuildContext context) {
    _entry = OverlayEntry(
      maintainState: true,
      builder: (ctx) => _ReactionOverlay(
        reactions: reactions,
        itemSize: itemSize,
        barPadding: barPadding,
        anchor: anchor,
        onSelected: (r) {
          _entry.remove();
          onSelected(r);
        },
        onCancelled: () {
          _entry.remove();
          onSelected(null);
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry);
  }
}

class _ReactionOverlay extends StatefulWidget {
  const _ReactionOverlay({
    required this.reactions,
    required this.itemSize,
    required this.barPadding,
    required this.anchor,
    required this.onSelected,
    required this.onCancelled,
  });

  final List<Reaction> reactions;
  final double itemSize;
  final double barPadding;
  final Offset anchor;
  final ValueChanged<Reaction?> onSelected;
  final VoidCallback onCancelled;

  @override
  State<_ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<_ReactionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _inCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180));
  late final AnimationController _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120));
  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _inCtrl.forward();
    _bgCtrl.forward();
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  Rect _barRect(Size screen) {
    const double safePad = 12.0;

    final double effectivePad = (widget.barPadding - 4).clamp(2.0, 100.0);
    final totalWidth = widget.reactions.length * widget.itemSize +
        (widget.reactions.length + 1) * effectivePad;

    final desiredLeft = widget.anchor.dx - totalWidth / 2;
    final minLeft = safePad;
    final maxLeft = screen.width - totalWidth - safePad;

    final left =
        (maxLeft >= minLeft) ? desiredLeft.clamp(minLeft, maxLeft) : minLeft;

    final top =
        math.max(safePad, widget.anchor.dy - widget.itemSize - 28);
    return Rect.fromLTWH(left, top, totalWidth, widget.itemSize + 20);
  }

  int? _indexFor(Offset position, Rect rect) {
    final double effectivePad = (widget.barPadding - 4).clamp(2.0, 100.0);
    final x = position.dx - rect.left - effectivePad;
    if (x < 0) return null;
    final span = widget.itemSize + effectivePad;
    final idx = (x / span).floor();
    if (idx < 0 || idx >= widget.reactions.length) return null;
    final cx = idx * span + widget.itemSize / 2;
    if ((x - cx).abs() > widget.itemSize / 1.1) return null;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double effectivePad = (widget.barPadding - 4).clamp(2.0, 100.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (d) => setState(
          () => _hoverIndex = _indexFor(d.globalPosition, _barRect(screen))),
      onPanUpdate: (d) => setState(
          () => _hoverIndex = _indexFor(d.globalPosition, _barRect(screen))),
      onPanEnd: (_) {
        if (_hoverIndex != null) {
          HapticFeedback.selectionClick();
          widget.onSelected(widget.reactions[_hoverIndex!]);
        } else {
          widget.onCancelled();
        }
      },
      onTap: widget.onCancelled,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Opacity(
              opacity: Curves.easeOut.transform(_bgCtrl.value) * 0.12,
              child: Container(color: Colors.black),
            ),
          ),
          Positioned.fromRect(
            rect: _barRect(screen),
            child: FadeTransition(
              opacity: _inCtrl.drive(CurveTween(curve: Curves.easeOut)),
              child: ScaleTransition(
                scale: _inCtrl.drive(Tween(begin: 0.95, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeOutBack))),
                child: _ReactionBar(
                  reactions: widget.reactions,
                  itemSize: widget.itemSize,
                  padding: effectivePad,
                  hoverIndex: _hoverIndex,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.reactions,
    required this.itemSize,
    required this.padding,
    required this.hoverIndex,
  });

  final List<Reaction> reactions;
  final double itemSize;
  final double padding;
  final int? hoverIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222428) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: List.generate(reactions.length, (i) {
          final r = reactions[i];
          final hovered = i == hoverIndex;
          return _ReactionItem(
              reaction: r, size: itemSize, hovered: hovered);
        }),
      ),
    );
  }
}

class _ReactionItem extends StatelessWidget {
  const _ReactionItem(
      {required this.reaction, required this.size, required this.hovered});
  final Reaction reaction;
  final double size;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final inner = (reaction.asset != null)
        ? Image.asset(reaction.asset!,
            width: size * 0.62, height: size * 0.62, fit: BoxFit.contain)
        : Text(reaction.emoji ?? '👍',
            style: TextStyle(fontSize: size * 0.6));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      width: size,
      height: size,
      transformAlignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..translate(0.0, hovered ? -8.0 : 0.0)
        ..scale(hovered ? 1.18 : 1.0),
      child: Center(child: inner),
    );
  }
}
