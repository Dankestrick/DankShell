.pragma library

// SettingsList — the sections of the Settings window and what's in each.
// Each item changes one value in services/Settings.qml.
//   slider: key, label, min, max, step, unit
//   switch: key, label, sub, icon, kind: "switch"
//   apps:   kind: "apps" (one switch per plugin: pin it to the top row)

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
  { key: "dashboard", name: "Top row", icon: "push_pin",
    sub: "Top of the list sits farthest left in the island.",
    words: "plugins apps pin pinned top row buttons hide show dashboard",
    items: [ { kind: "apps" } ] }
]
