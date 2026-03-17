import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../models/post_assets.dart';
import '../models/reaction_model.dart';
import '../models/user_id_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ReactionsBottomSheet — Facebook-style reaction viewer
//  Shows filter tabs (All | 👍 | ❤️ | 😄 | 😮 | 😢 | 😠) + user list
// ─────────────────────────────────────────────────────────────────────────────

class ReactionsBottomSheet extends StatefulWidget {
  final String postId;
  final ApiService api;

  const ReactionsBottomSheet({
    super.key,
    required this.postId,
    required this.api,
  });

  /// Show the reactions bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String postId,
    required ApiService api,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReactionsBottomSheet(postId: postId, api: api),
    );
  }

  @override
  State<ReactionsBottomSheet> createState() => _ReactionsBottomSheetState();
}

class _ReactionsBottomSheetState extends State<ReactionsBottomSheet> {
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  List<ReactionModel> _allReactions = [];
  List<ReactionModel> _likeList = [];
  List<ReactionModel> _loveList = [];
  List<ReactionModel> _hahaList = [];
  List<ReactionModel> _wowList = [];
  List<ReactionModel> _sadList = [];
  List<ReactionModel> _angryList = [];
  List<ReactionModel> _dislikeList = [];

  static const List<_TabDef> _tabDefs = [
    _TabDef(type: null, asset: null), // "All"
    _TabDef(type: 'like', asset: PostAssets.likeIcon),
    _TabDef(type: 'love', asset: PostAssets.loveIcon),
    _TabDef(type: 'haha', asset: PostAssets.hahaIcon),
    _TabDef(type: 'wow', asset: PostAssets.wowIcon),
    _TabDef(type: 'sad', asset: PostAssets.sadIcon),
    _TabDef(type: 'angry', asset: PostAssets.angryIcon),
  ];

  @override
  void initState() {
    super.initState();
    _fetchReactions();
  }

  Future<void> _fetchReactions() async {
    try {
      final response =
          await widget.api.get(ApiConstants.reactionUserList(widget.postId));
      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        final rawList = data['reactions'];
        if (rawList is List) {
          _allReactions = rawList
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => ReactionModel.fromMap(e as Map<String, dynamic>))
              .toList();
          _sortByType();
        }
      }
    } catch (e) {
      debugPrint('Error fetching reactions: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _sortByType() {
    _likeList = [];
    _loveList = [];
    _hahaList = [];
    _wowList = [];
    _sadList = [];
    _angryList = [];
    _dislikeList = [];

    for (final r in _allReactions) {
      switch (r.reaction_type) {
        case 'like':
          _likeList.add(r);
          break;
        case 'love':
          _loveList.add(r);
          break;
        case 'haha':
          _hahaList.add(r);
          break;
        case 'wow':
          _wowList.add(r);
          break;
        case 'sad':
          _sadList.add(r);
          break;
        case 'angry':
          _angryList.add(r);
          break;
        case 'dislike':
          _dislikeList.add(r);
          break;
      }
    }
  }

  List<ReactionModel> _listForType(String? type) {
    if (type == null) return _allReactions;
    switch (type) {
      case 'like':
        return _likeList;
      case 'love':
        return _loveList;
      case 'haha':
        return _hahaList;
      case 'wow':
        return _wowList;
      case 'sad':
        return _sadList;
      case 'angry':
        return _angryList;
      case 'dislike':
        return _dislikeList;
      default:
        return _allReactions;
    }
  }

  List<_TabDef> _visibleTabs() {
    final visible = <_TabDef>[_tabDefs[0]]; // "All" always visible
    for (int i = 1; i < _tabDefs.length; i++) {
      if (_listForType(_tabDefs[i].type).isNotEmpty) {
        visible.add(_tabDefs[i]);
      }
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.55, 0.85],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Filter tabs ──
              _buildFilterTabs(),

              Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.grey.shade300),

              // ── User list ──
              Expanded(child: _buildUserList(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    final tabs = _visibleTabs();
    if (_selectedTabIndex >= tabs.length) _selectedTabIndex = 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isActive = index == _selectedTabIndex;
          final count = _listForType(tab.type).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        isActive ? AppColors.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.asset != null) ...[
                    Image.asset(tab.asset!, width: 20, height: 20),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    tab.type == null ? 'All $count' : '$count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final tabs = _visibleTabs();
    if (_selectedTabIndex >= tabs.length) return const SizedBox.shrink();
    final selectedType = tabs[_selectedTabIndex].type;
    final list = _listForType(selectedType);

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No reactions yet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reaction = list[index];
        final user = reaction.user_id;
        if (user == null) return const SizedBox.shrink();

        final name =
            '${user.first_name ?? ''} ${user.last_name ?? ''}'.trim();
        final profilePicUrl = ApiConstants.userProfileUrl(user.profile_pic);
        final reactionAsset =
            PostAssets.reactionAsset(reaction.reaction_type ?? '') ??
                PostAssets.likeIcon;

        return _ReactionUserTile(
          name: name.isEmpty ? 'Unknown' : name,
          profilePicUrl: profilePicUrl,
          reactionAsset: reactionAsset,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  User tile — avatar with reaction badge + name
// ─────────────────────────────────────────────────────────────────────────────
class _ReactionUserTile extends StatelessWidget {
  final String name;
  final String profilePicUrl;
  final String reactionAsset;

  const _ReactionUserTile({
    required this.name,
    required this.profilePicUrl,
    required this.reactionAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ── Avatar with reaction badge ──
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: profilePicUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profilePicUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.grey.shade400,
                          ),
                  ),
                ),
                // ── Reaction badge (bottom-right) ──
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        reactionAsset,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // ── User name ──
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab definition
// ─────────────────────────────────────────────────────────────────────────────
class _TabDef {
  final String? type; // null = "All"
  final String? asset;
  const _TabDef({required this.type, required this.asset});
}
