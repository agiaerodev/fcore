String resolveAvatarUrl({required String displayName, String? imageUrl}) {
  final normalizedImageUrl = imageUrl?.trim();
  if (normalizedImageUrl != null && normalizedImageUrl.isNotEmpty) {
    return normalizedImageUrl;
  }

  final encodedName = Uri.encodeComponent(displayName);
  return 'https://ui-avatars.com/api/?name=$encodedName&background=D6EDFF&color=1A3B5D&bold=true&size=512';
}
