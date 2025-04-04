import 'package:flutter/material.dart';
import '../net/profile/profile_service.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final Color? borderColor;
  final double borderWidth;
  final _profileService = ProfileService();

  UserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 80,
    this.onTap,
    this.showEditIcon = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: borderColor ?? Colors.white,
                width: borderWidth,
              ),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl!,
                      headers: _profileService.getHeaders(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Avatar load error: $error');
                        return _buildPlaceholder();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : _buildPlaceholder(),
            ),
          ),
          if (showEditIcon)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Icon(
        Icons.person_outline,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
