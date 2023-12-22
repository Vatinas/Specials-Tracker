local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/color")

local Breeds = require("scripts/settings/breed/breeds")
-- local UISettings = require("scripts/settings/ui/ui_settings")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = mod:original_require("scripts/managers/ui/ui_renderer")
local ui_renderer_instance = Managers.ui:ui_constant_elements():ui_renderer()
local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local ItemPassTemplates = require("scripts/ui/pass_templates/item_pass_templates")

local HudElementSpecialsTracker = class("HudElementSpecialsTracker", "HudElementBase")

---------------------------
-- Various global constants

local max_possible_scale = 2
	-- The highest value the scale can take in the mod options
local x_padding_ratio = 0.07
	-- The width of the padding between the longest abreviated breed name and its unit count, as a percentage of the total width a line would have without padding
local y_padding_ratio = 0.4
	-- The added vertical spacing between two text widgets, as a percentage of a widget's height
local prty_lvl_group_separation_ratio = 0.6
	-- If this value is x, and the usual vertical padding between two widgets is y_pad, then the vertical padding between two priority groups will be y_pad + x*_y_pad
local base_background_offset = 14
	-- In pixels, the "padding" required to make the terminal background have its intended size.
	-- NB: It looks like this padding is 1. not scale dependent, 2. not horizontal/vertical dependent, and 3. not left/right or top/bottom dependent
local base_font_size = 25
	-- The font size at hud scale 1
local overlay_breed_names = {}
for _, breed_name in pairs(mod.interesting_breed_names.array) do
	table.insert(overlay_breed_names, mod:localize(breed_name.."_overlay_name"))
end
	-- An array containing the HUD names of all trackable units


-----------------------------------------------
-- Fetching the current font whenever necessary

mod.font = { }
mod.font.current_font = ""
mod.font.init = function()
	mod.font.current_font = mod:get("font") or "machine_medium"
end
mod.font.init()


------------------
-- A few utilities

local font_base_padding = function(font_name)
	-- The padding, in pixels, to be applied at each side of the HUD element at scale 1 when using the given font
	local res = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	}
	if font_name == "proxima_nova_light" then
		res.top = 2
		res.bottom = 6
	elseif font_name == "proxima_nova_bold" then
		res.top = 2
		res.bottom = 6
	elseif font_name == "proxima_nova_medium" then
		res.top = 2
		res.bottom = 6
	elseif font_name == "itc_novarese_medium" then
		res.bottom = 1
	elseif font_name == "itc_novarese_bold" then
		res.bottom = 1
	elseif font_name == "friz_quadrata" then
		res.top = 0
		res.bottom = 7
	elseif font_name == "rexlia" then
		res.top = 1
		res.bottom = 7
	elseif font_name == "machine_medium" then
		res.top = 6
		res.bottom = 0
	elseif font_name == "arial" then
		res.top = 1
		res.bottom = 5
	end
	return res
end

local show_breed = function(breed_name)
	-- Checks the mod options currently stored, and returns whether the breed's widget should be displayed
	if mod.tracked_units.overlay_breeds_inverted_table[breed_name] then
		if mod.tracked_units.overlay_only_if_active[breed_name] then
			return mod.tracked_units.unit_count[breed_name] ~= 0
		else
			return true
		end
	end
	return false
end

local x_offset = function(type)
	-- The x offset of a text or number pass
	if type == "_text" then
		return 0
	else
		return mod.hud_dimensions.number_pass_x_offset
	end
end
local y_offset = function(i, nb_gaps)
	-- The y offset for the i-th breed widget, after nb_gaps priority level group separations/paddings
	return i * mod.hud_dimensions.y_offset_onestep + nb_gaps * mod.hud_dimensions.prty_groups_added_y_padding
end
local pass_size = function(type)
	-- The size of a text or number pass
	if type == "_text" then
		return mod.hud_dimensions.text_pass_size
	else
		return mod.hud_dimensions.number_pass_size
	end
end

--------------------------------------------------------
-- Calculating various HUD dimensions whenever necessary

mod.get_text_size = function(text, scale)
	local width, height, _, caret = UIRenderer.text_size(ui_renderer_instance, text, mod.font.current_font, base_font_size * scale)
	width = math.max(width, caret[1])
	height = math.max(height, caret[2])
	return width, height
end

local max_number_size = function(scale)
	mod.font.init()
	local max_width = 0
	local max_height = 0
	local max_number = 0
	for _, count in pairs(mod.tracked_units.unit_count) do
		max_number = math.max(max_number, count)
	end
	max_number = 10 * math.floor(max_number / 10 + 1) - 1
	-- max_number is meant to represent the highest number to be considered to get the maximum number size
	-- For instance, if the highest current unit count is 6, max_number will be 9; if the highest count is 12, max_number will be 19
	for i=0, max_number do
		local this_width, this_height = mod.get_text_size(tostring(i), scale)
		max_width = math.max(max_width, this_width)
		max_height = math.max(max_height, this_height)
	end
	return max_width, max_height
end

mod.hud_dimensions = {}
mod.hud_dimensions.hud_scale = 1
mod.hud_dimensions.text_pass_size = {0, 0}
mod.hud_dimensions.number_pass_size = {0, 0}
mod.hud_dimensions.x_padding = 0
mod.hud_dimensions.line_spacing = 0
mod.hud_dimensions.number_pass_x_offset = 0
mod.hud_dimensions.y_offset_onestep = 0
mod.hud_dimensions.prty_groups_added_y_padding = 0
mod.hud_dimensions.container_size = {0, 0}
mod.hud_dimensions.init = function()
	mod.font.init()
	local scale = mod:get("hud_scale")
	mod.hud_dimensions.hud_scale = scale
	local max_text_width = 0
	local max_text_height = 0
	for _, name in pairs(overlay_breed_names) do
		local this_width, this_height = mod.get_text_size(name, scale)
		max_text_width = math.max(max_text_width, this_width)
		max_text_height = math.max(max_text_height, this_height)
	end
	local number_width, number_height = max_number_size(scale)
	local height = math.max(max_text_height, number_height)

	mod.hud_dimensions.text_pass_size = {max_text_width, height}
	mod.hud_dimensions.number_pass_size = {number_width, height}

	mod.hud_dimensions.x_padding = x_padding_ratio * (max_text_width + number_width)
	mod.hud_dimensions.number_pass_x_offset = max_text_width + mod.hud_dimensions.x_padding

	local y_padding = y_padding_ratio * height
	mod.hud_dimensions.y_offset_onestep = mod.hud_dimensions.text_pass_size[2] + y_padding
	mod.hud_dimensions.prty_groups_added_y_padding = y_padding * prty_lvl_group_separation_ratio

	local scaled_container_width = mod.hud_dimensions.text_pass_size[1] + mod.hud_dimensions.number_pass_size[1] + mod.hud_dimensions.x_padding
	local scaled_container_height = #mod.interesting_breed_names.array * mod.hud_dimensions.y_offset_onestep - y_padding + (#mod.priority_levels - 1) * mod.hud_dimensions.prty_groups_added_y_padding

	mod.hud_dimensions.container_size = {
		scaled_container_width,
		scaled_container_height
	}
end

mod.tracked_units.init()
mod.hud_dimensions.init()

local show_breed = function(breed_name)
	-- Checks the mod options currently stored, and returns whether the breed's widget should be displayed
	if mod.tracked_units.overlay_breeds_inverted_table[breed_name] then
		if mod.color.hud.monster_only_if_alive and Breeds[breed_name].tags and Breeds[breed_name].tags.monster then
			return mod.tracked_units.unit_count[breed_name] ~= 0
		else
			return true
		end
	end
	return false
end

---------------------------------
-- Creating the scenegraph object

local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = mod.hud_dimensions.container_size,
		position = {
			0,
			0,
			0,
		},
	},
}


---------------------------------------------------------------------------------------------------------
-- Defining breed widgets, containing a text pass for the unit name, and a number pass for the unit count

local breed_widget_z_offset = 10
local breed_widget = function(breed_name)
	-- Argument: A (cleaned) breed_name
	-- Returns: A widget built from the two passes of breed_name
	-- NB: Its position and visibility will be upgraded as is needed in the init and update methods of the UI element
	local breed_passes =
		{
			{
			value_id = breed_name.."_text",
			style_id = breed_name.."_text",
			pass_type = "text",
			value = mod:localize(breed_name.."_overlay_name") or "ERR",
			style = {
				text_color = mod.color.white,
				font_size = base_font_size,
				drop_shadow = true,
				font_type = mod:get("font") or "machine_medium",
				size = mod.hud_dimensions.text_pass_size,
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				offset = {
					0
				,
					0
				,
					breed_widget_z_offset
				},
			},
			visibility_function = function(content, style)
				return show_breed(breed_name)
			end,
		},
		{
			value_id = breed_name.."_value",
			style_id = breed_name.."_value",
			pass_type = "text",
			value = "--",
			style = {
				text_color = mod.color.white,
				font_size = base_font_size,
				drop_shadow = true,
				font_type = mod:get("font") or "machine_medium",
				size = mod.hud_dimensions.number_pass_size,
				text_horizontal_alignment = "center",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				offset = {
					mod.hud_dimensions.number_pass_x_offset
				,
					0
				,
					breed_widget_z_offset
				},
			},
			visibility_function = function(content, style)
				return show_breed(breed_name)
			end,
		},
	}
	return(
		UIWidget.create_definition(
			breed_passes
		,
			"container"
		)
	)
end


---------------------------------
-- Defining the background widget

local background_passes = {
	{
		style_id = "terminal_texture",
		pass_type = "texture",
		value = "content/ui/materials/backgrounds/terminal_basic",
		style = {
			scale_to_material = true,
			color = {
				255,
				50,
				75,
				50,
			},
			size_addition = {
				0,--50,
				0,--59
			},
			offset = {
				0,
				0,
				0
			}
		}
	},
	{
		style_id = "background_gradient",
		pass_type = "texture",
		value = "content/ui/materials/gradients/gradient_vertical",
		style = {
			--vertical_alignment = "center",
			--horizontal_alignment = "center",
			color = Color.terminal_background_gradient(100, true),
			offset = {
				0,
				0,
				1
			}
		},
	},
	--[[
	{
		value = "content/ui/materials/frames/dropshadow_medium",
		style_id = "outer_shadow",
		pass_type = "texture",
		style = {
			vertical_alignment = "center",
			horizontal_alignment = "center",
			scale_to_material = true,
			color = Color.black(200, true),
			size_addition = {
				20,
				20
			},
			offset = {
				0,
				0,
				3
			}
		}
	},
	--]]
	--[[
	{
		pass_type = "texture",
		style_id = "frame",
		value = "content/ui/materials/frames/frame_tile_2px",
		style = {
			vertical_alignment = "center",
			horizontal_alignment = "center",
			--color = Color.terminal_frame(255, true),
			--color = Color.terminal_frame_selected(255, true),
			color = Color.ui_grey_medium(255, true),
			--hover_color = Color.terminal_frame_hover(nil, true),
			offset = {
				0,
				0,
				30
			}
		},
	},
	--]]
	--[[
	{
		pass_type = "texture",
		style_id = "corner",
		value = "content/ui/materials/frames/frame_corner_2px",
		style = {
			scale_to_material = true,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			color = Color.terminal_corner(nil, true),
			default_color = Color.terminal_corner(nil, true),
			selected_color = Color.terminal_corner_selected(nil, true),
			offset = {
				0,
				0,
				15
			}
		},
	},
	--]]
}

local background_widget = UIWidget.create_definition(
	background_passes
,
	"container"
)
--[[ Testing/debugging stuff
local background_test_passes = {
		{
		style_id = "base_background",
		pass_type = "rect",
		style = {
			color = {0, 0, 0, 0},
			size = mod.hud_dimensions.container_size,
			offset = {
				0,
				0,
				1
			},
		},
	},
	{
		style_id = "padded_background",
		pass_type = "rect",
		style = {
			color = {0, 0, 0, 0},
			size = mod.hud_dimensions.container_size,
			offset = {
				0,
				0,
				0
			},
		},
	}
}

local background_test_widget = UIWidget.create_definition(
	background_test_passes
,
	"container"
)
--]]

---------------------------------------------
-- Combining the different widget definitions

local widget_definitions = {}

for _, breed_name in pairs(mod.interesting_breed_names.array) do
	widget_definitions["widget_"..breed_name] = breed_widget(breed_name)
end
widget_definitions["widget_background"] = background_widget
--widget_definitions["widget_background_test"] = background_test_widget


--------------------------------------
-- Initialising the HUD element itself
HudElementSpecialsTracker.init = function(self, parent, draw_layer, start_scale)
	for element,_ in pairs(mod.hud_refresh_flags) do
		mod.hud_refresh_flags[element] = true
	end
	HudElementSpecialsTracker.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions,
	})
end

HudElementSpecialsTracker.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementSpecialsTracker.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	-->> Check for HUD refresh flags, and refreshes the corresponding components of the HUD element:
	--> Color
	if mod.hud_refresh_flags.color then
		mod.color.init()
		mod.hud_refresh_flags.color = false
	end
	--> Position & scale
	-- NB: This changes the widgets, not the scenegraph object
	if mod.hud_refresh_flags.pos_or_scale then
		mod.tracked_units.init()
		mod.hud_dimensions.init()
		local scale = mod.hud_dimensions.hud_scale
		local i = -1
		local nb_prty_lvl_gaps = -1
		local current_prty_lvl = "X"
		-- Redefining style fields for breed widgets
		for _, breed_name in pairs(mod.tracked_units.overlay_breeds_array) do
			if show_breed(breed_name) then
				i = i + 1
				-- We found a new visible widget, so we count up, and update its style
				local new_prty_lvl = mod.tracked_units.priority_levels[breed_name]
				if new_prty_lvl ~= current_prty_lvl then
					nb_prty_lvl_gaps = nb_prty_lvl_gaps + 1
					-- We moved to a new priority level group, so we count up to account for the prty lvl group separation/padding
					current_prty_lvl = new_prty_lvl
				end
				local widget_style = self._widgets_by_name["widget_"..breed_name].style
				for _,type in pairs({"_text","_value"}) do
					local widget_style_pass = widget_style[breed_name..type]
					for j=1,2 do
						widget_style_pass.size[j] = pass_size(type)[j]
					end
					widget_style_pass.offset[1] = x_offset(type)
					widget_style_pass.offset[2] = y_offset(i, nb_prty_lvl_gaps)
					widget_style_pass.font_size = base_font_size * scale
				end
			end
		end
		-- Redefining style fields for background widgets
		local padding = font_base_padding(mod:get("font") or "machine_medium")
		--[[ Testing/debugging widget:
		local test_widget_style = self._widgets_by_name["widget_background_test"].style
		test_widget_style["base_background"].offset = {
			0,
			0,
		}
		test_widget_style["base_background"].size = {
			mod.hud_dimensions.container_size[1],
			y_offset(i+1, nb_prty_lvl_gaps),
		}
		test_widget_style["padded_background"].offset = {
			-padding.left * scale,
			-padding.top * scale,
		}
		test_widget_style["padded_background"].size = {
			mod.hud_dimensions.container_size[1] + (padding.left + padding.right) * scale,
			y_offset(i+1, nb_prty_lvl_gaps) + (padding.top + padding.bottom) * scale,
		}
		--]]
		-- Actual background widget:
		local widget_style = self._widgets_by_name["widget_background"].style
		for id, widget_style_pass in pairs(widget_style) do
			local applied_base_offset = id == "terminal_texture" and base_background_offset or 0
			widget_style_pass.offset = {
				- applied_base_offset - padding.left * scale,
				- applied_base_offset - padding.top * scale,
			}
			widget_style_pass.size = {
				mod.hud_dimensions.container_size[1] + (padding.left + padding.right) * scale + 2 * applied_base_offset,
				y_offset(i+1, nb_prty_lvl_gaps) + (padding.top + padding.bottom) * scale + 2 * applied_base_offset,
			}
		end
		mod.hud_refresh_flags.pos_or_scale = false
	end
	--> Font
	if mod.hud_refresh_flags.font then
		for _, breed_name in pairs(mod.interesting_breed_names.array) do
			local new_font = mod:get("font") or "machine_medium"
			local widget_style = self._widgets_by_name["widget_"..breed_name].style
			for _,type in pairs({"_text","_value"}) do
				local widget_style_pass = widget_style[breed_name..type]
				widget_style_pass.font_type = new_font
			end
		end
		mod.hud_refresh_flags.font = false
		-- If we refresh the font, we need to refresh the HUD positions to adapt to the new font's dimensions
		mod.hud_refresh_flags.pos_or_scale = true
	end
	--> Now we refresh the widgets themselves every update tick
	for _, breed_name in pairs(mod.tracked_units.overlay_breeds_array) do
		local active_units_number = mod.tracked_units.unit_count[breed_name] or 0
		local active_units_text = active_units_number and tostring(active_units_number) or "X"
		local priority_level = mod.tracked_units.priority_levels[breed_name]
		local color_non_zero_units = mod.color.hud.table[priority_level]
		local current_color = active_units_number ~= 0 and color_non_zero_units or mod.color.hud.table.zero_units
		self._widgets_by_name["widget_"..breed_name].content[breed_name.."_value"] = active_units_text
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_text"].text_color = current_color
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_value"].text_color = current_color
	end
end

return HudElementSpecialsTracker