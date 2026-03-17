import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';

/// Photos tab with Albums horizontal scroll + All photos grid.
class PhotosTab extends StatefulWidget {
  const PhotosTab({super.key});

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab> {
  String? _lastPageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPhotos());
  }

  void _loadPhotos() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      context.read<ContentProvider>().fetchContentByType(pageId, 'Photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for page changes
    final currentPageId = context.watch<ManagedPagesProvider>().activePageId;
    if (currentPageId != null && currentPageId != _lastPageId) {
      _lastPageId = currentPageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ContentProvider>().fetchContentByType(currentPageId, 'Photo');
        }
      });
    }

    final content = context.watch<ContentProvider>();
    final photos = content.photoItems;

    if (content.isTypeLoading && photos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: QpLoading(itemCount: 6, height: 150),
      );
    }

    if (photos.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No photos yet',
        subtitle: 'Photos you post will appear here.',
      );
    }

    // Group photos into albums by content type
    final albums = _buildAlbums(photos);

    return RefreshIndicator(
      onRefresh: () async => _loadPhotos(),
      child: CustomScrollView(
        slivers: [
          // ── Albums Section ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'Albums',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Horizontal album list
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return _AlbumCard(
                        name: album.name,
                        count: album.count,
                        thumbnailUrl: album.thumbnailUrl,
                      );
                    },
                  ),
                ),

                // See all
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    label: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),

                // Divider
                const Divider(height: 1, color: AppColors.dividerLight),

                // All photos header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'All photos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add Photos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── All Photos Grid ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = photos[index];
                  return _PhotoGridItem(item: photo);
                },
                childCount: photos.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  List<_Album> _buildAlbums(List<ContentItem> photos) {
    // Create default albums
    final firstMedia = photos.isNotEmpty && photos.first.media.isNotEmpty
        ? photos.first.media.first
        : null;
    final allPhotosThumbnail = firstMedia != null
        ? ApiConstants.contentMediaDisplayUrl(
            url: firstMedia.url,
            thumbnailUrl: firstMedia.thumbnailUrl,
            type: firstMedia.type,
            mediaBaseDir: firstMedia.mediaBaseDir,
          )
        : '';

    return [
      _Album(
        name: 'Photos',
        count: photos.length,
        thumbnailUrl: allPhotosThumbnail,
      ),
      _Album(
        name: 'Profile pictures',
        count: photos.where((p) => p.contentType.toLowerCase().contains('profile')).length.clamp(0, photos.length),
        thumbnailUrl: allPhotosThumbnail,
      ),
      _Album(
        name: 'Mobile uploads',
        count: photos.where((p) => p.contentType.toLowerCase().contains('mobile')).length.clamp(0, photos.length),
        thumbnailUrl: photos.length > 1 && photos[1].media.isNotEmpty
            ? ApiConstants.contentMediaDisplayUrl(
                url: photos[1].media.first.url,
                thumbnailUrl: photos[1].media.first.thumbnailUrl,
                type: photos[1].media.first.type,
                mediaBaseDir: photos[1].media.first.mediaBaseDir,
              )
            : allPhotosThumbnail,
      ),
    ];
  }
}

class _Album {
  final String name;
  final int count;
  final String thumbnailUrl;

  _Album({
    required this.name,
    required this.count,
    required this.thumbnailUrl,
  });
}

class _AlbumCard extends StatelessWidget {
  final String name;
  final int count;
  final String thumbnailUrl;

  const _AlbumCard({
    required this.name,
    required this.count,
    required this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: Icon(Icons.photo, size: 32, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(Icons.photo, size: 32, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '$count ${count == 1 ? 'photo' : 'photos'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  final ContentItem item;
  const _PhotoGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final m = item.media.isNotEmpty ? item.media.first : null;
    final imageUrl = m != null
        ? ApiConstants.contentMediaDisplayUrl(
            url: m.url,
            thumbnailUrl: m.thumbnailUrl,
            type: m.type,
            mediaBaseDir: m.mediaBaseDir,
          )
        : '';

    return imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceLight,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          )
        : Container(
            color: AppColors.surfaceLight,
            child: const Icon(Icons.photo, size: 32, color: Colors.grey),
          );
  }
}
