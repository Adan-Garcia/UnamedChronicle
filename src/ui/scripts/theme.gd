# res://addons/ThemeGen/themes/dark_golden_theme.gd
@tool
extends ProgrammaticTheme  # ThemeGen base class

const UPDATE_ON_SAVE = true
const VERBOSITY = Verbosity.NORMAL

# Realtime Colors palette
var primary = Color("#ebc000")
var secondary = Color("#e29608")
var accent = Color("#fff3bd")
var bg = Color("#06070e")
var card = Color("#0d0e15")


func setup():
	# Output theme resource path
	set_save_path("res://assets/ui/themes/ui_theme.tres")


func define_theme():
	# Default Inter font size
	define_default_font_size(14)

	# Base StyleBoxes
	var pane = stylebox_flat(
		{bg_color = card, corners_ = corner_radius(8), content_ = content_margins(8)}
	)
	var outlined = inherit(pane, {border_ = border_width(1), border_color = primary})
	var darkened = inherit(outlined, {bg_color = card.darkened(0.2)})
	var pressed = inherit(pane, {bg_color = primary.darkened(0.1)})
	var _secondary_sb = inherit(pane, {border_ = border_width(1), border_color = secondary})
	var accented = stylebox_flat(
		{bg_color = accent, corners_ = corner_radius(6), content_ = content_margins(8)}
	)
	var empty_focus = stylebox_empty({})

	# Additional styleboxes

	var radio_style = stylebox_flat({bg_color = primary, corners_ = corner_radius(8)})
	var selection_style = stylebox_flat(
		{bg_color = primary.darkened(0.2), corners_ = corner_radius(4)}
	)
	var progress_fg = stylebox_flat({bg_color = primary, corners_ = corner_radius(4)})
	var tree_lines = stylebox_flat({bg_color = card.darkened(0.4), corners_ = corner_radius(0)})
	var tooltip_style = stylebox_flat({bg_color = primary, corners_ = corner_radius(4)})

	# Panels & Containers
	define_style("Panel", {"panel": inherit(pane, {corners_ = corner_radius(32)})})
	define_variant_style(
		"bottom",
		"Panel",
		{
			"panel":
			inherit(pane, {corners_ = corner_radius(0, 0, 32, 32), bg_color = bg.darkened(.3)})
		}
	)
	define_variant_style(
		"top", "Panel", {"panel": inherit(pane, {corners_ = corner_radius(32, 32, 0, 0)})}
	)
	define_variant_style("Outlined", "Panel", {"panel": outlined})
	define_style("PanelContainer", {"panel": pane})

	define_style("ScrollContainer", {"panel": pane, "focus": empty_focus})
	define_variant_style(
		"outlined",
		"ScrollContainer",
		{"panel": inherit(outlined, {expand_ = expand_margins(8)}), "focus": empty_focus}
	)
	# Text & Labels
	define_style("Label", {"font_color": primary})
	define_style("RichTextLabel", {"default_color": primary})

	# Buttons & Toggles
	define_style(
		"Button",
		{
			"normal": outlined,
			"hover": darkened,
			"pressed": pressed,
			"focus": empty_focus,
			"font_color": primary,
			"disabled":
			inherit(outlined, {border_color = accent.darkened(0.5), bg_color = card.darkened(0.5)})
		}
	)
	define_style(
		"CheckBox",
		{"normal": outlined, "hover": darkened, "pressed": pressed, "focus": empty_focus}
	)
	define_style(
		"RadioButton",
		{"box": outlined, "grabber": empty_focus, "check": radio_style, "focus": empty_focus}
	)
	define_style(
		"TextureButton",
		{"normal": outlined, "hover": darkened, "pressed": pressed, "focus": empty_focus}
	)

	# Input Controls
	define_style("LineEdit", {"normal": outlined, "focus": empty_focus, "cursor_color": primary})
	define_style("TextEdit", {"normal": outlined, "focus": empty_focus, "caret_style": accented})
	define_style("SpinBox", {"up": outlined, "down": outlined, "box": pane, "focus": empty_focus})

	# Sliders & Progress
	define_style(
		"HSlider",
		{
			"slider": outlined,
			"grabber_area": pressed,
			"grabber_area_highlight": pressed,
			"focus": empty_focus
		}
	)
	define_style(
		"VSlider",
		{
			"slider": outlined,
			"grabber_area": pressed,
			"grabber_area_highlight": pressed,
			"focus": empty_focus
		}
	)
	define_style("ProgressBar", {"fill": progress_fg, "background": pane, "focus": empty_focus})
	define_style("TextureProgress", {"fg": progress_fg, "bg": pane, "focus": empty_focus})

	# Tabs & Menus
	define_style(
		"TabContainer",
		{
			"side_margin": 0,
			"tab_unselected": inherit(pane, {"corners_": corner_radius(8, 8, 0, 0)}),
			"tab_hovered": inherit(outlined, {"corners_": corner_radius(8, 8, 0, 0)}),
			"tab_selected": inherit(pressed, {"corners_": corner_radius(8, 8, 0, 0)}),
			"tab_focus": empty_focus,
			"panel": inherit(pane, {corners_ = corner_radius(0, 8, 0)})
		}
	)

	define_style("OptionButton", {"select": outlined, "popup": pane, "focus": empty_focus})
	define_style(
		"MenuButton",
		{"normal": pane, "hover": darkened, "pressed": pressed, "popup": pane, "focus": empty_focus}
	)
	define_style("PopupMenu", {"panel": pane, "focus": empty_focus})

	# Lists & Trees
	define_style("ItemList", {"bg": pane, "selection": selection_style, "focus": empty_focus})
	define_style("Tree", {"icon": pane, "lines": tree_lines, "focus": empty_focus})

	# Miscellaneous
	define_style("Tooltip", {"panel": tooltip_style, "font_color": bg, "focus": empty_focus})
	define_style(
		"TabBar", {"normal": pane, "hover": darkened, "pressed": pressed, "focus": empty_focus}
	)
