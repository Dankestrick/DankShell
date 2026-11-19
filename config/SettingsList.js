.pragma library

// SettingsList — the sections of the Settings window and what's in each.
// Each item changes one value in services/Settings.qml.
//   slider: key, label, min, max, step, unit
//   switch: key, label, sub, icon, kind: "switch"
//   apps:   kind: "apps" (one switch per plugin: pin it to the top row)
//   hypr:   a Hyprland option instead of `key` (services/Hypr.qml)
//   idle:   kind: "choice", Omarchy's screensaver/lock time (scripts/idle-set)
//   look:   Omarchy's window look: solid, see-through or glass
// Search in the Settings window matches every item's label too.

var SECTIONS = [
  { key: "island", name: "Bar & Island", icon: "crop_16_9",
    sub: "Shape and size of the pill, the hover card and the dashboard.",
    words: "bar height width gap bubble hover dashboard corner radius pill",
    items: [
      { key: "barHeight", label: "Bar height", min: 24, max: 48, step: 1, unit: "px" },
      { key: "collapsedWidth", label: "Collapsed width", min: 60, max: 220, step: 1, unit: "px" },
      { key: "gapFromEdge", label: "Gap from screen edge", min: 0, max: 30, step: 1, unit: "px" },
      { key: "hoverLift", label: "Bubble on touch", min: 0, max: 30, step: 1, unit: "px" },
      { key: "hoverWidth", label: "Hover card width", min: 320, max: 640, step: 4, unit: "px" },
      { key: "hoverHeight", label: "Hover card height", min: 70, max: 200, step: 2, unit: "px" },
      { key: "dashWidth", label: "Dashboard width", min: 400, max: 640, step: 4, unit: "px" },
      { key: "radiusExpanded", label: "Corner rounding (open)", min: 8, max: 40, step: 1, unit: "px" }
    ] },
  { key: "motion", name: "Motion", icon: "animation",
    sub: "How fast things grow, fade and bounce.",
    words: "speed animation bounce delay fast slow reduce",
    items: [
      { key: "reduceMotion", label: "Reduce motion", sub: "No animation at all", icon: "motion_photos_off", kind: "switch" },
      { key: "move", label: "Grow speed", min: 120, max: 900, step: 10, unit: "ms" },
      { key: "fade", label: "Fade speed", min: 60, max: 400, step: 10, unit: "ms" },
      { key: "bounce", label: "Bounce", min: 0, max: 1, step: 0.05, unit: "" },
      { key: "openDelay", label: "Hover wait before the card opens", min: 0, max: 1000, step: 10, unit: "ms" },
      { key: "closeDelay", label: "Wait before it shrinks back", min: 0, max: 1000, step: 10, unit: "ms" }
    ] },
  { key: "look", name: "Appearance", icon: "palette",
    sub: "Colors, outline, clock and icons.",
    words: "black color outline clock icon font weight fill look",
    items: [
      { key: "pureBlack", label: "Pure black island", sub: "Off = your theme's background color", icon: "contrast", kind: "switch" },
      { key: "outline", label: "Faint outline", sub: "Helps the island show on dark windows", icon: "border_outer", kind: "switch" },
      { key: "iconFilled", label: "Solid icons", sub: "Off = outlined", icon: "format_paint", kind: "switch" },
      { key: "clockSize", label: "Clock size", min: 11, max: 20, step: 1, unit: "px" },
      { key: "iconWeight", label: "Icon weight", min: 100, max: 700, step: 100, unit: "" }
    ] },
  { key: "windows", name: "Windows", icon: "select_window",
    sub: "Gaps, borders, rounding, see-through, blur and shadows. Changes show right away.",
    words: "gaps border rounding corners opacity transparent blur shadow animations hyprland glass glassy solid see-through look",
    items: [
      { kind: "look", label: "Window look" },
      { hypr: "general:gaps_in", label: "Gap between windows", min: 0, max: 40, step: 1, unit: "px" },
      { hypr: "general:gaps_out", label: "Gap to the screen edge", min: 0, max: 60, step: 1, unit: "px" },
      { hypr: "general:border_size", label: "Border", min: 0, max: 8, step: 1, unit: "px" },
      { hypr: "decoration:rounding", label: "Corner rounding", min: 0, max: 30, step: 1, unit: "px" },
      { hypr: "decoration:active_opacity", label: "Focused window see-through", min: 0.5, max: 1, step: 0.01, unit: "" },
      { hypr: "decoration:inactive_opacity", label: "Other windows see-through", min: 0.5, max: 1, step: 0.01, unit: "" },
      { hypr: "decoration:blur:enabled", label: "Blur", sub: "Behind see-through windows", icon: "blur_on", kind: "switch" },
      { hypr: "decoration:blur:size", label: "Blur size", min: 1, max: 20, step: 1, unit: "" },
      { hypr: "decoration:blur:passes", label: "Blur passes", min: 1, max: 6, step: 1, unit: "" },
      { hypr: "decoration:shadow:enabled", label: "Shadows", sub: "Under windows", icon: "ev_shadow", kind: "switch" },
      { hypr: "decoration:shadow:range", label: "Shadow size", min: 0, max: 50, step: 1, unit: "px" },
      { hypr: "animations:enabled", label: "Animations", sub: "Windows sliding and fading", icon: "animation", kind: "switch" }
    ] },
  { key: "timeouts", name: "Timeouts", icon: "timer",
    sub: "When the screensaver starts and the screen locks.",
    words: "idle lock screensaver timeout sleep minutes",
    items: [
      { idle: "screensaver", label: "Screensaver after", kind: "choice",
        choices: [[60, "1 min"], [120, "2 min"], [300, "5 min"], [600, "10 min"], [900, "15 min"], [1800, "30 min"]] },
      { idle: "lock", label: "Lock after", kind: "choice",
        choices: [[300, "5 min"], [900, "15 min"], [1800, "30 min"], [3600, "1 hour"], [14400, "4 hours"], [86400, "24 hours"]] }
    ] },
  { key: "glance", name: "Glance row", icon: "visibility",
    sub: "The icons in the hover card: tray apps and bar widgets you want to see right away. Running Docker containers show at the end by themselves.",
    words: "glance row tray apps icons hover weather vpn hide show order docker",
    items: [ { kind: "glance" } ] },
  { key: "dashboard", name: "Top row", icon: "push_pin",
    sub: "Top of the list sits farthest left in the island.",
    words: "plugins apps pin pinned top row buttons hide show dashboard",
    items: [ { kind: "apps" } ] }
]
