local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/color")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = mod:original_require("scripts/managers/ui/ui_renderer")
local ui_renderer_instance = Managers.ui:ui_constant_elements():ui_renderer()

local HudElementSpecialsTracker = class("HudElementSpecialsTracker", "HudElementBase")

local constants = mod.global_constants
local settings = mod.settings


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

local show_breed = function(breed_name)
	-- Checks the mod options currently stored, and returns whether the breed's widget should be displayed
	if not settings.global_toggle.overlay then
		return false
	elseif mod.tracked_units.overlay_breeds.inv_table[breed_name] then
		if mod.tracked_units.overlay_breeds.only_if_active[breed_name] then
			return mod.tracked_units.unit_count[breed_name] ~= 0
		else
			return true
		end
	end
	return false
end

local show_background = function()
	return settings.global_toggle.overlay and mod.hud_dimensions.nb_of_displayed_breeds ~= 0
end


--------------------------------------------------------
-- Calculating various HUD dimensions whenever necessary

mod.get_text_size = function(text, scale)
	local width, height, _, caret = UIRenderer.text_size(ui_renderer_instance, text, settings.font.current, constants.hud.base_font_size * scale)
	width = math.max(width, caret[1])
	height = math.max(height, caret[2])
	return width, height
end

local max_number_size = function(scale)
	settings.font:init()
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


---------------------
-- mod.hud_dimensions

mod.hud_dimensions = {
	nb_of_prty_lvls_used = #constants.priority_levels,
	nb_of_displayed_breeds = #constants.trackable_breeds.array,
	-- NB: The above fields are not calculated during -:init(), but when the HUD element's position and scale are flagged for refreshing, since the number of priority levels that are actually used is only calculated then
}

mod.hud_dimensions.init = function(self)
	settings.font:init()
	local scale = mod:get("hud_scale")
	settings.hud_scale = scale
	local max_text_width = 0
	for cln_brd_name, overlay_name in pairs(constants.trackable_breeds.overlay_names[mod:get("overlay_name_style")]) do
		if show_breed(cln_brd_name) then
			local this_width, this_height = mod.get_text_size(overlay_name, scale)
			max_text_width = math.max(max_text_width, this_width)
		end
	end
	local number_width, number_height = max_number_size(scale)
	local height = number_height

	self.text_pass_size = {max_text_width, height}
	self.number_pass_size = {number_width, height}

	self.global_offset = {}
	if mod:get("overlay_move_from_center") then
		local screen_size = UIWorkspaceSettings.screen.size
		self.global_offset = {
			800 * screen_size[1]/1920,
			-100 * screen_size[2]/1080,
			0,
		}
	else
		self.global_offset = {
			0,
			0,
			0,
		}
	end

	self.x_padding = constants.hud.x_padding_ratio * max_text_width + constants.hud.x_padding_flat * scale
	self.number_pass_x_offset = max_text_width + self.x_padding

	local y_padding = constants.hud.y_padding_ratio * height
	self.y_offset_onestep = self.text_pass_size[2] + y_padding
	self.prty_groups_added_y_padding = y_padding * constants.hud.prty_lvl_group_separation_ratio

	local scaled_container_width = self.text_pass_size[1] + self.number_pass_size[1] + self.x_padding
	local scaled_container_height = self.nb_of_displayed_breeds * self.y_offset_onestep - y_padding + (self.nb_of_prty_lvls_used - 1) * self.prty_groups_added_y_padding

	self.container_size = {
		scaled_container_width,
		scaled_container_height
	}
end

mod.tracked_units:init()
mod.hud_dimensions:init()


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
		position = { 0, 0, 0 },
	},
}


---------------------------------------------------------------------------------------------------------
-- Defining breed widgets, containing a text pass for the unit name, and a number pass for the unit count

local breed_widget_z_offset = 10
local breed_widget = function(breed_name)
	-- Takes a (clean) breed name, and returns its widget, built from the two passes for breed_name
	-- NB: Its position will be updated as is needed in the init and update methods of the UI element
	local breed_passes =
		{
			{
			value_id = breed_name.."_text",
			style_id = breed_name.."_text",
			pass_type = "text",
			value = "-", --constants.trackable_breeds.overlay_names[settings.overlay_name_style][breed_name],
			style = {
				text_color = constants.color.white,
				font_size = constants.hud.base_font_size,
				drop_shadow = true,
				font_type = settings.font.current,
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
			value = "-",
			style = {
				text_color = constants.color.white,
				font_size = constants.hud.base_font_size,
				drop_shadow = true,
				font_type = settings.font.current,
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

local frame_color = {
	220,
	106,
	130,
	106,
}
local frame_z_offset = 3
local corner_color = {
	255,
	230,
	230,
	230,
}
local corner_z_offset = 6

local base_frame_thickness = 1
local base_corner_length = 5

local base_corner_thickness = base_frame_thickness

local background_passes = {
	{ -- Base texture
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
			offset = {
				0,
				0,
				1
			},
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{ -- Gradient texture
		style_id = "background_gradient",
		pass_type = "texture",
		value = "content/ui/materials/gradients/gradient_vertical",
		style = {
			color = Color.terminal_background_gradient(130, true),
			offset = {
				0,
				0,
				2
			},
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	-- Frame borders (four, one of for each side)
	{
		style_id = "frame_left",
		pass_type = "rect",
		style = {
		  	color = frame_color,
			vertical_alignment = "top",
			horizontal_alignment = "left",
		},
		offset = {
			0,
			0,
			frame_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "frame_right",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = frame_color,
		},
		offset = {
			0,
			0,
			frame_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "frame_top",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = frame_color,
		},
		offset = {
			0,
			0,
			frame_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "frame_bottom",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = frame_color,
		},
		offset = {
			0,
			0,
			frame_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	-- Frame corners (four sets of two, one set for each corner)
	-- Naming convention: to determine what corner element "corner_dir1_dir2" refers to, mentally start from the center of the background, then go in direction dir1 first to join a frame border in its middle point; then, from that frame border middle point, follow direction dir2 to join a corner. "corner_dir1_dir2" is the unique corner element that your path traced near its end.
	-- e.g.: "corner_right_top" - From the center of the background, join the middle of the right frame, then go up - you traced the vertical component of the top right corner, which is what "corner_right_top" refers to. The horizontal element of the top right corner is "corner_top_right".
	{
		style_id = "corner_top_left",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_left_top",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_top_right",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_right_top",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_bot_left",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_left_bot",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_bot_right",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},
	{
		style_id = "corner_right_bot",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
		  	color = corner_color,
		},
		offset = {
			0,
			0,
			corner_z_offset
		},
		visibility_function = function(content, style)
			return show_background()
		end,
	},

}

local background_widget = UIWidget.create_definition(
	background_passes
,
	"container"
)


---------------------------------------------
-- Combining the different widget definitions

local widget_definitions = {}

for _, breed_name in pairs(constants.trackable_breeds.array) do
	widget_definitions["widget_"..breed_name] = breed_widget(breed_name)
end
widget_definitions["widget_background"] = background_widget


----------------------------------
-- Defining the HUD element itself

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
	-->>> Check for HUD refresh flags, and refresh the corresponding components of the HUD element
	-->> Color
	if mod.hud_refresh_flags.color then
		settings.color:init()
		mod.hud_refresh_flags.color = false
	end
	-->> Font
	if mod.hud_refresh_flags.font then
		settings.font:init()
		for _, breed_name in pairs(constants.trackable_breeds.array) do
			local widget_style = self._widgets_by_name["widget_"..breed_name].style
			for _,type in pairs({"_text","_value"}) do
				local widget_style_pass = widget_style[breed_name..type]
				widget_style_pass.font_type = settings.font.current
			end
		end
		mod.hud_refresh_flags.font = false
		-- If we refresh the font, we need to refresh the HUD positions to adapt to the new font's dimensions
		mod.hud_refresh_flags.pos_or_scale = true
	end
	-->> Overlay name style
	if mod.hud_refresh_flags.name_style then
		settings.overlay_name_style:init()
		for _, breed_name in pairs(constants.trackable_breeds.array) do
			self._widgets_by_name["widget_"..breed_name].content[breed_name.."_text"] = constants.trackable_breeds.overlay_names[settings.overlay_name_style.current][breed_name]
		end
		mod.hud_refresh_flags.name_style = false
		-- If we refresh the name style, we need to refresh the HUD positions to adapt to the new names' dimensions
		mod.hud_refresh_flags.pos_or_scale = true
	end
	-->> Position & scale
	-- NB: This changes the widgets, not the scenegraph object
	if mod.hud_refresh_flags.pos_or_scale then
		mod.tracked_units:init()
		mod.hud_dimensions:init()
		local scale = settings.hud_scale
		local global_offset = mod.hud_dimensions.global_offset
		local i = -1
		local nb_prty_lvl_gaps = -1
		local current_prty_lvl = ""
		--> Redefining style fields for breed widgets
		for _, breed_name in pairs(mod.tracked_units.overlay_breeds.array) do
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
					widget_style_pass.offset[1] = x_offset(type) + global_offset[1]
					widget_style_pass.offset[2] = y_offset(i, nb_prty_lvl_gaps) + global_offset[2]
					widget_style_pass.font_size = constants.hud.base_font_size * scale
				end
			end
		end
		--> Refresh the hud dimensions to access the new container height, which depends on the number of priority levels used, which we only just calculated
		mod.hud_dimensions.nb_of_prty_lvls_used = nb_prty_lvl_gaps + 1
		mod.hud_dimensions.nb_of_displayed_breeds = i + 1
		mod.hud_dimensions:init()
		--> Redefining style fields for background widgets
		-- 0. Preliminary definitions
		local padding = font_base_padding(settings.font.current)
		local widget_style = self._widgets_by_name["widget_background"].style
		local actual_container_width = mod.hud_dimensions.container_size[1] + (padding.left + padding.right) * scale
		local actual_container_height = y_offset(i+1, nb_prty_lvl_gaps) + (padding.top + padding.bottom) * scale
		local left_pad = padding.left * scale
		local top_pad = padding.top * scale
		local frame_thickness = math.max(1, math.floor(base_frame_thickness * scale + 0.5))
		local corner_thickness = math.max(1, math.floor(base_corner_thickness * scale + 0.5))
		local corner_length = math.max(1, math.floor(base_corner_length * scale + 0.5))
		local horiz_corner_size = {
			corner_length,
			corner_thickness,
		}
		local vertic_corner_size = {
			corner_thickness,
			corner_length,
		}
		-- Offsets former frame borders and corners depending on their assigned position:
		local top_left_offset = function(z_offset)
			return {
				- frame_thickness - left_pad +1 + global_offset[1],
				- frame_thickness - top_pad +1 + global_offset[2],
				z_offset,
			}
		end
		local top_right_offset = function(z_offset)
			return {
				actual_container_width - left_pad -1 + global_offset[1],
				- frame_thickness - top_pad +1 + global_offset[2],
				z_offset,
			}
		end
		local bot_left_offset = function(z_offset)
			return {
				- frame_thickness - left_pad +1 + global_offset[1],
				actual_container_height - top_pad -1 + global_offset[2],
				z_offset,
			}
		end
		local bot_right_offset = function(z_offset)
			return {
				actual_container_width - left_pad -1 + global_offset[1],
				actual_container_height - top_pad -1 + global_offset[2],
				z_offset,
			}
		end
		-- 1. Background textures
		for _, pass_name in pairs({"terminal_texture", "background_gradient"}) do
			local widget_style_pass = widget_style[pass_name]
			local applied_base_offset = pass_name == "terminal_texture" and constants.hud.base_background_offset or 0
			widget_style_pass.offset = {
				- applied_base_offset - left_pad + global_offset[1],
				- applied_base_offset - top_pad + global_offset[2],
				widget_style_pass.offset[3]
			}
			widget_style_pass.size = {
				actual_container_width + 2 * applied_base_offset,
				actual_container_height + 2 * applied_base_offset,
			}
		end
		-- 2. Frame borders
		local left_style_pass = widget_style["frame_left"]
		left_style_pass.size = {
			frame_thickness,
			actual_container_height + 2 * frame_thickness -2,
		}
		left_style_pass.offset = top_left_offset(frame_z_offset)
		local right_style_pass = widget_style["frame_right"]
		right_style_pass.size = {
			frame_thickness,
			actual_container_height + 2 * frame_thickness -2,
		}
		right_style_pass.offset = top_right_offset(frame_z_offset)
		local top_style_pass = widget_style["frame_top"]
		top_style_pass.size = {
			actual_container_width + 2 * frame_thickness -2,
			frame_thickness,
		}
		top_style_pass.offset = top_left_offset(frame_z_offset)
		local bottom_style_pass = widget_style["frame_bottom"]
		bottom_style_pass.size = {
			actual_container_width + 2 * frame_thickness -2,
			frame_thickness,
		}
		bottom_style_pass.offset = bot_left_offset(frame_z_offset)
		-- 3. Frame corners
		local top_left_style_pass = widget_style["corner_top_left"]
		top_left_style_pass.size = table.clone(horiz_corner_size)
		top_left_style_pass.offset = top_left_offset(corner_z_offset)
		local left_top_style_pass = widget_style["corner_left_top"]
		left_top_style_pass.size = table.clone(vertic_corner_size)
		left_top_style_pass.offset = top_left_offset(corner_z_offset)

		local top_right_style_pass = widget_style["corner_top_right"]
		top_right_style_pass.size = table.clone(horiz_corner_size)
		top_right_style_pass.offset = top_right_offset(corner_z_offset)
		top_right_style_pass.offset[1] = top_right_style_pass.offset[1] - corner_length +corner_thickness
		local right_top_style_pass = widget_style["corner_right_top"]
		right_top_style_pass.size = table.clone(vertic_corner_size)
		right_top_style_pass.offset = top_right_offset(corner_z_offset)

		local bot_left_style_pass = widget_style["corner_bot_left"]
		bot_left_style_pass.size = table.clone(horiz_corner_size)
		bot_left_style_pass.offset = bot_left_offset(corner_z_offset)
		local left_bot_style_pass = widget_style["corner_left_bot"]
		left_bot_style_pass.size = table.clone(vertic_corner_size)
		left_bot_style_pass.offset = bot_left_offset(corner_z_offset)
		left_bot_style_pass.offset[2] = left_bot_style_pass.offset[2] - corner_length +corner_thickness

		local bot_right_style_pass = widget_style["corner_bot_right"]
		bot_right_style_pass.size = table.clone(horiz_corner_size)
		bot_right_style_pass.offset = bot_right_offset(corner_z_offset)
		bot_right_style_pass.offset[1] = bot_right_style_pass.offset[1] - corner_length +corner_thickness
		local right_bot_style_pass = widget_style["corner_right_bot"]
		right_bot_style_pass.size = table.clone(vertic_corner_size)
		right_bot_style_pass.offset = bot_right_offset(corner_z_offset)
		right_bot_style_pass.offset[2] = right_bot_style_pass.offset[2] - corner_length +corner_thickness

		mod.hud_refresh_flags.pos_or_scale = false
	end
	-->>> Now we refresh the widgets themselves every update tick
	for _, breed_name in pairs(mod.tracked_units.overlay_breeds.array) do
		local active_units_number = mod.tracked_units.unit_count[breed_name] or 0
		local active_units_text = active_units_number and tostring(active_units_number) or "X"
		local priority_level = mod.tracked_units.priority_levels[breed_name]
		local current_color = active_units_number ~= 0 and settings.color.hud[priority_level] or constants.color.zero_units
		self._widgets_by_name["widget_"..breed_name].content[breed_name.."_value"] = active_units_text
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_text"].text_color = current_color
		self._widgets_by_name["widget_"..breed_name].style[breed_name.."_value"].text_color = current_color
	end
end

return HudElementSpecialsTracker