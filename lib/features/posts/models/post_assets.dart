/// Reaction icon asset paths
class PostAssets {
  PostAssets._();

  static const String likeIcon = 'assets/icons/reactions/like_icon.png';
  static const String loveIcon = 'assets/icons/reactions/love_icon.png';
  static const String hahaIcon = 'assets/icons/reactions/haha_icon.png';
  static const String wowIcon = 'assets/icons/reactions/wow_icon.png';
  static const String sadIcon = 'assets/icons/reactions/sad_icon.png';
  static const String angryIcon = 'assets/icons/reactions/angry_icon.png';
  static const String dislikeIcon = 'assets/icons/reactions/dislike.png';

  /// Map reaction type string to asset path
  static String? reactionAsset(String type) {
    switch (type) {
      case 'like':
        return likeIcon;
      case 'love':
        return loveIcon;
      case 'haha':
        return hahaIcon;
      case 'wow':
        return wowIcon;
      case 'sad':
        return sadIcon;
      case 'angry':
        return angryIcon;
      case 'dislike':
        return dislikeIcon;
      default:
        return null;
    }
  }
}
