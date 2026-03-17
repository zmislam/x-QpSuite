import 'dart:math' as math;

import 'post_assets.dart';
import 'post_model.dart';
import 'reaction_model.dart';

/// Applies an optimistic reaction update on a PostModel.
///
/// Handles: toggle-off (same reaction), type change, and new reaction.
/// Works correctly even when [reactionTypeCountsByPost] is empty by falling
/// back to [reactionSummary.userReaction].
///
/// Mutates [post] in place and returns it for convenience.
PostModel applyOptimisticReaction({
  required PostModel post,
  required String userId,
  required String reactionType,
}) {
  final list = post.reactionTypeCountsByPost ?? [];
  post.reactionTypeCountsByPost = list;

  // 1. Find existing reaction
  String? prevType;
  int existingIdx = -1;
  for (int i = 0; i < list.length; i++) {
    if (list[i].user_id == userId) {
      existingIdx = i;
      prevType = list[i].reaction_type;
      break;
    }
  }
  if (prevType == null) {
    final ur = post.reactionSummary?['userReaction'];
    if (ur is Map && ur['hasReacted'] == true) {
      prevType = ur['type'] as String?;
    }
  }

  final isToggleOff = prevType == reactionType;

  // 2. Update the local list
  if (existingIdx != -1) {
    list.removeAt(existingIdx);
  }
  if (!isToggleOff) {
    list.add(ReactionCountModel.fromMap({
      'count': 1,
      'post_id': post.id,
      'reaction_type': reactionType,
      'user_id': userId,
    }));
  }

  // 3. Update count
  final currentCount = post.reactionCount ?? 0;
  if (isToggleOff) {
    post.reactionCount = math.max(0, currentCount - 1);
  } else if (prevType != null) {
    post.reactionCount = currentCount; // Changing type — count stays same
  } else {
    post.reactionCount = currentCount + 1; // New reaction
  }

  // 4. Update reactionSummary
  final breakdown = Map<String, dynamic>.from(
    post.reactionSummary?['breakdown'] ?? {},
  );
  if (prevType != null && breakdown.containsKey(prevType)) {
    final oldCount = (breakdown[prevType] as int? ?? 1) - 1;
    if (oldCount <= 0) {
      breakdown.remove(prevType);
    } else {
      breakdown[prevType] = oldCount;
    }
  }
  if (!isToggleOff) {
    breakdown[reactionType] = ((breakdown[reactionType] as int?) ?? 0) + 1;
  }
  post.reactionSummary = {
    ...(post.reactionSummary ?? {}),
    'userReaction': isToggleOff
        ? {'hasReacted': false, 'type': null}
        : {'hasReacted': true, 'type': reactionType},
    'breakdown': breakdown,
  };

  return post;
}

/// Returns the user's current reaction type from a PostModel.
String? getUserReactionType(PostModel postModel, String userId) {
  for (final r in postModel.reactionTypeCountsByPost ?? []) {
    if (r.user_id == userId) {
      return r.reaction_type;
    }
  }
  final ur = postModel.reactionSummary?['userReaction'];
  if (ur is Map && ur['hasReacted'] == true) {
    return ur['type'] as String?;
  }
  return null;
}

/// Returns distinct reaction type asset paths for display (up to maxCount).
List<String> getReactionAssets(PostModel postModel, {int maxCount = 3}) {
  final List<String> assets = [];
  final list = postModel.reactionTypeCountsByPost ?? [];

  if (list.isNotEmpty) {
    for (final reaction in list) {
      final asset = PostAssets.reactionAsset(reaction.reaction_type ?? '');
      if (asset != null && !assets.contains(asset)) {
        assets.add(asset);
      }
      if (assets.length >= maxCount) break;
    }
  } else {
    final breakdown = postModel.reactionSummary?['breakdown'];
    if (breakdown is Map) {
      for (final type in breakdown.keys) {
        final count = breakdown[type];
        if (count is int && count > 0) {
          final asset = PostAssets.reactionAsset(type.toString());
          if (asset != null && !assets.contains(asset)) {
            assets.add(asset);
          }
          if (assets.length >= maxCount) break;
        }
      }
    }
  }
  return assets;
}

/// Format time for post display
String formatPostTime(String? time) {
  if (time == null || time.isEmpty) return 'Unknown';

  try {
    final postDateTime = DateTime.parse(time).toLocal();
    final now = DateTime.now();
    final diff = now.difference(postDateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  } catch (e) {
    return 'Unknown';
  }
}

/// Format comment time
String formatCommentTime(String? time) {
  if (time == null || time.isEmpty) return '';

  try {
    final postDateTime = DateTime.parse(time).toLocal();
    final now = DateTime.now();
    final diff = now.difference(postDateTime);

    if (diff.inMinutes <= 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 2) return '1 h';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 2) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  } catch (e) {
    return '';
  }
}

/// Format count (1K, 1.5M, etc.)
String formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}
