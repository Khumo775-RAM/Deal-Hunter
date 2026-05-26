/// Steam CDN image URL helpers.
const _steamCdn = 'https://cdn.akamai.steamstatic.com/steam/apps';

/// High-resolution store hero banner (~1920×620).
String steamHeroUrl(String? steamAppId) {
  if (steamAppId == null || steamAppId.isEmpty || steamAppId == '0') {
    return '';
  }
  return '$_steamCdn/$steamAppId/library_hero.jpg';
}

/// Small store header (~460×215) — fallback when hero is unavailable.
String steamHeaderUrl(String? steamAppId) {
  if (steamAppId == null || steamAppId.isEmpty || steamAppId == '0') {
    return '';
  }
  return '$_steamCdn/$steamAppId/header.jpg';
}
