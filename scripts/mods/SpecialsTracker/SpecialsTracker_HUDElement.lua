local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/color")
local UISettings = require("scripts/settings/ui/ui_settings")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local HudElementSpecialsTracker = class("HudElementSpecialsTracker", "HudElementBase")

local line_spacing = 3
local font_size = 25
local font_height_size = 12

local text_pass_width = 70
local number_pass_width = 20
local padding_width = 10

local text_pass_size = { text_pass_width, font_height_size }
local number_pass_size = { number_pass_width, font_height_size }

local color = {}
color.non_zero_units = {}
color.zero_units = {}
color.init = function()
	color.non_zero_units = {255, 255, 255, 255}
	color.zero_units = {160, 180, 180, 180}
end

local container_size = {
	2 * (text_pass_width + number_pass_width + padding_width)
,
	2 * math.max(0, #mod.interesting_breed_names.array * (text_pass_size[2] + line_spacing) - line_spacing)
}

mod.tracked_units.init()


local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	container = {
		parent = "screen",
		scale = "fit",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = container_size,
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
			value = mod:localize(breed_name.."_overlay"),
			style = {
				text_color = {255,255,255,255},
				font_size = 25, --mod:get("font_size") or 25,
				drop_shadow = true,
				font_type = mod:get("font") or "machine_medium",
				size = text_pass_size,
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
				return mod.tracked_units.overlay_breeds_inverted_table[breed_name]
			end,
		},
		{
			value_id = breed_name.."_value",
			style_id = breed_name.."_value",
			pass_type = "text",
			value = "-",
			style = {
				text_color = {255,255,255,255},
				font_size = font_size, --mod:get("font_size") or 25,
				drop_shadow = true,
				font_type = mod:get("font") or "machine_medium",
				size = number_pass_size,
				text_horizontal_alignment = "left",
				text_vertical_alignment = "top",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				offset = {
					text_pass_width + number_pass_width
				,
					0
				},
			},
			visibility_function = function(content, style)
				return mod.tracked_units.overlay_breeds_inverted_table[breed_name]
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
		color.init()
		mod.hud_refresh_flags.color = false
	end
	-- Check if the widget positions need to be reset or the HUD scale needs to be changed
	-- NB: This changes the widgets, not the HUD element itself, which means the scenegraph container itself doesn't change in size. This might cause an issue
	if mod.hud_refresh_flags.pos or mod.hud_refresh_flags.scale then
		mod.tracked_units.init()
		local hud_scale = mod:get("hud_element_scale")
		local base_x_offset = function(type)
			if type == "_text" then
				return 0
			else
				return text_pass_width + padding_width
			end
		end
		local base_y_offset = function(i)
			return (i-1) * (text_pass_size[2] + line_spacing)
		end
		local base_pass_size = function(type)
			if type == "_text" then
				return text_pass_size
			else
				return number_pass_size
			end
		end
		-- local i = 0
		for i, breed_name in pairs(mod.tracked_units.overlay_breeds_array) do
			-- if mod:get(breed_name.."_overlay") then
			-- i = i + 1
			local widget_style = self._widgets_by_name["widget_"..breed_name].style
			for _,type in pairs({"_text","_value"}) do
				local widget_style_pass = widget_style[breed_name..type]
				for j=1,2 do
					widget_style_pass.size[j] = base_pass_size(type)[j] * hud_scale
				end
				widget_style_pass.offset[1] = base_x_offset(type) * hud_scale
				widget_style_pass.offset[2] = base_y_offset(i) * hud_scale
				widget_style_pass.font_size = font_size * hud_scale
			end
			--end
		end
	mod.hud_refresh_flags.pos = false
	mod.hud_refresh_flags.scale = false
	end
	---[[
	if mod.hud_refresh_flags.font then
		for _, breed_name in pairs(mod.interesting_breed_names.array) do -- pairs(mod.tracked_units.breeds_array) do
			local new_font = mod:get("font") or "machine_medium"
			local widget_style = self._widgets_by_name["widget_"..breed_name].style
			for _,type in pairs({"_text","_value"}) do
				local widget_style_pass = widget_style[breed_name..type]
				widget_style_pass.font_type = new_font
			end
		end
		mod.hud_refresh_flags.font = false
	end
	--]]
	-- Refresh the widgets themselves
	for _, breed_name in pairs(mod.tracked_units.overlay_breeds_array) do
		local active_units_number = mod.tracked_units.unit_count[breed_name]
		local active_units_text = active_units_number and tostring(active_units_number) or "X"
		local current_color = active_units_number ~= 0 and color.non_zero_units or color.zero_units
		self._widgets_by_name["widget_"..breed_name].content[breed_name.."_value"] = active_units_text
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_text"].text_color = current_color
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_value"].text_color = current_color
	end
end

return HudElementSpecialsTracker