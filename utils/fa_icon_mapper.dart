import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'fa_icon_map.g.dart';

/// Icon used when the backend value cannot be resolved.
const FaIconData kDefaultServiceIcon = FontAwesomeIcons.circleInfo;

/// Converts a Font Awesome CSS class string (as returned by the backend, e.g.
/// `"fa-solid fa-golf-ball-tee"` or `"fa-jelly-fill fa-regular fa-car"`) into a
/// [FaIconData] that can be rendered with a [FaIcon] widget.
///
/// The free `font_awesome_flutter` package intentionally disables dynamic
/// name-based lookups (the [FontAwesomeIcons] class is a `@staticIconProvider`
/// so unused icons can be tree-shaken away), so we resolve the icon through the
/// generated name -> [FaIconData] maps in `fa_icon_map.g.dart`, which cover
/// every Solid / Regular / Brands icon in the free set.
///
/// Only Solid, Regular and Brands are shipped in the free package; family
/// modifiers such as `fa-jelly-fill`, `fa-sharp` or `fa-duotone` are ignored and
/// the icon resolves to its closest available style. Any unknown or unparsable
/// value falls back to [fallback].
FaIconData faIconFromClasses(String? classes, {FaIconData fallback = kDefaultServiceIcon}) {
  if (classes == null || classes.trim().isEmpty) return fallback;

  final tokens = classes
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  var style = _FaStyle.solid; // Font Awesome defaults to solid.
  String? iconName;

  for (final token in tokens) {
    switch (token) {
      case 'fas':
      case 'fa-solid':
        style = _FaStyle.solid;
        continue;
      case 'far':
      case 'fa-regular':
        style = _FaStyle.regular;
        continue;
      case 'fab':
      case 'fa-brands':
        style = _FaStyle.brands;
        continue;
    }

    // Styles the free package can't render (light/thin/duotone) — approximate
    // with regular so we still try a non-solid variant when available.
    if (token == 'fal' || token == 'fa-light' ||
        token == 'fat' || token == 'fa-thin' ||
        token == 'fad' || token == 'fa-duotone') {
      style = _FaStyle.regular;
      continue;
    }

    // Ignore the base `fa` token and family/utility modifiers we can't use
    // (fa-sharp, fa-jelly-fill, fa-fw, fa-2x, ...).
    if (token == 'fa' || !token.startsWith('fa-')) continue;

    // The first remaining `fa-*` token is the icon name.
    iconName ??= token.substring(3);
  }

  if (iconName == null) return fallback;
  return _resolve(iconName, style) ?? fallback;
}

enum _FaStyle { solid, regular, brands }

/// Looks the name up in the requested style, then falls back to the other
/// styles so a name that only exists as solid still resolves when the backend
/// asked for regular (and vice versa).
FaIconData? _resolve(String name, _FaStyle style) {
  switch (style) {
    case _FaStyle.brands:
      return faBrandIcons[name] ?? faSolidIcons[name] ?? faRegularIcons[name];
    case _FaStyle.regular:
      return faRegularIcons[name] ?? faSolidIcons[name] ?? faBrandIcons[name];
    case _FaStyle.solid:
      return faSolidIcons[name] ?? faRegularIcons[name] ?? faBrandIcons[name];
  }
}
