local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/color")

local Breeds = require("scripts/settings/breed/breeds")
-- local UISettings = require("scripts/settings/ui/ui_settings")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = mod:original_require("scripts/managers/ui/ui_renderer")
local ui_renderer_instance = Managers.ui:ui_constant_elements():ui_renderer()

local HudElementSpecialsTracker = class("HudElementSpecialsTracker", "HudElementBase")

local max_possible_scale = 2
local x_padding_ratio = 0.1
-- The width of the padding between the longest abreviated breed name and its unit count, as a percentage of the total width a line would have without padding
local y_padding_ratio = 0.34
-- The added vertical spacing between two text widgets, as a percentage of a widget's height
local prty_lvl_group_separation_ratio = 0.75
-- If this value is x, and their usual vertical padding *between* two widgets is y_pad, then the vertical padding between two priority groups will be y_pad + x*_y_pad

local base_font_size = 25

mod.font = { }
mod.font.current_font = ""
mod.font.init = function()
	mod.font.current_font = mod:get("font") or "machine_medium"
end
mod.font.init()


mod.get_text_size = function(text, scale)
	mod.font.init() -- Not necessary maybe?
	local width, height, _, caret = UIRenderer.text_size(ui_renderer_instance, text, mod.font.current_font, base_font_size * scale)
	return width, height, caret
end

local overlay_breed_names = {}
-- mod.interesting_breed_names.init()
for _, breed_name in pairs(mod.interesting_breed_names.array) do
	table.insert(overlay_breed_names, mod:localize(breed_name.."_overlay_name"))
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
		local this_width, this_height, this_caret = mod.get_text_size(name, scale)
		max_text_width = math.max(max_text_width, this_width, this_caret[1])
		max_text_height = math.max(max_text_height, this_height, this_caret[2])
	end
	local number_width, number_height, number_caret = mod.get_text_size("99", scale)
	number_width = math.max(number_width, number_caret[1])
	local height = math.max(max_text_height, number_height, number_caret[2])

	mod.hud_dimensions.text_pass_size = {1 + max_text_width, 1 + height}
	mod.hud_dimensions.number_pass_size = {1 + number_width, 1 + height}

	mod.hud_dimensions.x_padding = x_padding_ratio * (max_text_width + number_width)
	mod.hud_dimensions.number_pass_x_offset = max_text_width + mod.hud_dimensions.x_padding

	local y_padding = y_padding_ratio * height
	mod.hud_dimensions.y_offset_onestep = mod.hud_dimensions.text_pass_size[2] + y_padding
	mod.hud_dimensions.prty_groups_added_y_padding = y_padding * prty_lvl_group_separation_ratio

	local scaled_container_width = mod.hud_dimensions.text_pass_size[1] + mod.hud_dimensions.number_pass_size[1] + mod.hud_dimensions.x_padding
	local scaled_container_height = #mod.interesting_breed_names.array * mod.hud_dimensions.y_offset_onestep - y_padding + (#mod.priority_levels - 1) * mod.hud_dimensions.prty_groups_added_y_padding

	mod.hud_dimensions.container_size = {
		1 + scaled_container_width * max_possible_scale/scale,
		1 + scaled_container_height * max_possible_scale/scale
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

local breed_widget = function(breed_name)
	-- Argument: a breed_name
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
				},
			},
			visibility_function = function(content, style)
				-- return mod.tracked_units.breeds_inverted_table[breed_name]
				-- return mod:get(breed_name.."_overlay")
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
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				offset = {
					mod.hud_dimensions.number_pass_x_offset
				,
					0
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


local widget_definitions = {}
-- widget_definitions.table["widget_".breed_name] is the widget containing the text and number passes of breed_name
-- widget_definitions.init() creates the widget table, but nothing more (all widgets will have the same position)

widget_definitions.table = {}

widget_definitions.init = function()
	-- Create the definition for *all* widgets, which have a built-in visibility function
	for _, breed_name in pairs(mod.interesting_breed_names.array) do
		widget_definitions.table["widget_"..breed_name] = breed_widget(breed_name)
	end
end


HudElementSpecialsTracker.init = function(self, parent, draw_layer, start_scale)
	-- Create widgets for *all trackable* breeds, with default positions
	widget_definitions.init()

	for element,_ in pairs(mod.hud_refresh_flags) do
		mod.hud_refresh_flags[element] = true
	end

	HudElementSpecialsTracker.super.init(self, parent, draw_layer, start_scale, {
		scenegraph_definition = scenegraph_definition,
		widget_definitions = widget_definitions.table,
	})
end

HudElementSpecialsTracker.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementSpecialsTracker.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	-- Check if the widget colors need to be re-fetched from the mod options (currently only happens once at HUD element initialisation, since no HUD element color is currently settable from the mod options)
	if mod.hud_refresh_flags.color then
		mod.color.init()
		mod.hud_refresh_flags.color = false
	end
	-- Check if the widget positions need to be reset or the HUD scale needs to be changed
	-- NB: This changes the widgets, not the HUD element itself, which means the scenegraph container itself doesn't change in size. This might cause an issue
	if mod.hud_refresh_flags.pos or mod.hud_refresh_flags.scale then
		mod.tracked_units.init()
		-- local hud_scale = mod:get("hud_scale")
		mod.hud_dimensions.init()
		local x_offset = function(type)
			if type == "_text" then
				return 0
			else
				return mod.hud_dimensions.number_pass_x_offset
			end
		end
		local y_offset = function(i, nb_gaps)
			return (i-1) * mod.hud_dimensions.y_offset_onestep + nb_gaps * mod.hud_dimensions.prty_groups_added_y_padding
		end
		local pass_size = function(type)
			if type == "_text" then
				return mod.hud_dimensions.text_pass_size
			else
				return mod.hud_dimensions.number_pass_size
			end
		end
		local i = 0
		local nb_prty_lvl_gaps = 0
		local current_prty_lvl = mod.tracked_units.priority_levels[mod.tracked_units.overlay_breeds_array[1]]
		for _, breed_name in pairs(mod.tracked_units.overlay_breeds_array) do
			if show_breed(breed_name) then
				i = i + 1
				local new_prty_lvl = mod.tracked_units.priority_levels[breed_name]
				if new_prty_lvl ~= current_prty_lvl then
					nb_prty_lvl_gaps = nb_prty_lvl_gaps + 1
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
					widget_style_pass.font_size = base_font_size * mod.hud_dimensions.hud_scale
				end
			end
		end
	mod.hud_refresh_flags.pos = false
	mod.hud_refresh_flags.scale = false
	end
	-- Now the font
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
		mod.hud_refresh_flags.scale = true
	end
	-- And now the widgets themselves
	for _, breed_name in pairs(mod.tracked_units.overlay_breeds_array) do
		local active_units_number = mod.tracked_units.unit_count[breed_name] or 0
		local active_units_text = active_units_number and tostring(active_units_number) or "X"
		local priority_level = mod.tracked_units.priority_levels[breed_name] -- This is already a string!
		local color_non_zero_units = mod.color.hud.table[priority_level]
		local current_color = active_units_number ~= 0 and color_non_zero_units or mod.color.hud.table.zero_units
		self._widgets_by_name["widget_"..breed_name].content[breed_name.."_value"] = active_units_text
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_text"].text_color = current_color
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_value"].text_color = current_color
	end
end

return HudElementSpecialsTracker