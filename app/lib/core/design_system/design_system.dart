/// Matchday Design System
///
/// Encodes foundational tokens, layout rules, semantic typography, and
/// components according to Matchday UI architecture standards.
///
/// Layer order (innermost → outermost):
///   Foundation → Theme → Components → Layout → Navigation
library;

// ── Foundations ────────────────────────────────────────────────────────────
export 'foundation/borders.dart';
export 'foundation/elevation.dart';
export 'foundation/motion.dart';
export 'foundation/palette.dart';
export 'foundation/radii.dart';
export 'foundation/sizing.dart';
export 'foundation/spacing.dart';

// ── Theme & Tokens ─────────────────────────────────────────────────────────
export 'theme/app_theme.dart';
export 'theme/layout_tokens.dart';
export 'theme/status_colors.dart';
export 'theme/text_tokens.dart';

// ── Components: Actions ─────────────────────────────────────────────────────
export 'components/actions/action_button.dart';
export 'components/actions/action_icon_button.dart';

// ── Components: Inputs ──────────────────────────────────────────────────────
export 'components/inputs/text_input.dart';
export 'components/inputs/search_field.dart';

// ── Components: Selection ───────────────────────────────────────────────────
export 'components/selection/selection_chip.dart';
export 'components/selection/segmented_control.dart';
export 'components/selection/choice_card.dart';
export 'components/selection/selection_tile.dart';

// ── Components: Feedback ────────────────────────────────────────────────────
export 'components/feedback/status_badge.dart';
export 'components/feedback/empty_state.dart';
export 'components/feedback/error_state.dart';
export 'components/feedback/loading_state.dart';

// ── Components: Surfaces ────────────────────────────────────────────────────
export 'components/surfaces/surface.dart';
export 'components/surfaces/divider.dart';
export 'components/surfaces/avatar.dart';

// ── Components: Overlays ────────────────────────────────────────────────────
export 'components/overlays/app_bottom_sheet.dart';
export 'components/overlays/confirmation_dialog.dart';

// ── Navigation ──────────────────────────────────────────────────────────────
export 'navigation/composer_header.dart';
export 'navigation/push_header.dart';
export 'navigation/root_header.dart';
export 'navigation/wizard_header.dart';

// ── Adaptive & Responsive ──────────────────────────────────────────────────
export 'adaptive/window_class.dart';
export 'layout/content_constraint.dart';

// ── Layout ──────────────────────────────────────────────────────────────────
export 'layout/screen_layout.dart';
export 'layout/scroll_screen_layout.dart';
export 'layout/section.dart';
export 'layout/section_header.dart';
export 'layout/sticky_footer.dart';
