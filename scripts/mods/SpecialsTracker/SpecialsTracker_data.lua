require("scripts/foundation/utilities/color")

local mod = get_mod("SpecialsTracker")

local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")
local Breeds = require("scripts/settings/breed/breeds")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Global constants
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod.global_constants = {
    events = {"spawn","death"},
    events_extended = {"spawn", "death", "hybrid"},
    priority_levels = {"0", "1", "2", "3", "4"},
    priority_levels_non_zero = {"1", "2", "3", "4"},
    trackable_breeds = {
        array = { },
        inv_table = { },
        overlay_names = {
            styles = {
                "short",
                "long",
                "full"
            }
        },
        sort = nil,
    },
    hud = {
        --screen_size = UIWorkspaceSettings.screen.size,
        min_possible_scale = 0.5,
        max_possible_scale = 2,
        base_font_size = 25,
        x_padding_ratio = 0,
	    -- The width of the padding between the longest currently displayed abreviated breed name and its unit count, as a percentage of the longest overlay name's width
        x_padding_flat = 11,
        -- Padding at scale 1, in pixels, between the longest currently displayed overlay name and its unit cound
        y_padding_ratio = 0.4,
	    -- The added vertical spacing between two text widgets, as a percentage of a widget's height
        prty_lvl_group_separation_ratio = 0.6,
	    -- If this value is x, and the usual vertical padding between two widgets is y_pad, then the vertical padding between two priority groups will be y_pad + x*_y_pad
        base_background_offset = 14,
	    -- In pixels, the "padding" required to make the terminal background have its intended size.
	    -- NB: It looks like this padding is 1. not scale dependent, 2. not horizontal/vertical dependent, and 3. not left/right or top/bottom dependent
        global_offset = function()
            -- Returns the global offset to apply to the overlay, depending on whether it should be moved to a "default" position or not
            if mod:get("overlay_move_from_center") then
                local screen_size = UIWorkspaceSettings.screen.size
                return {
                    1710/2 * screen_size[1]/1920,
                    230/2 * screen_size[2]/1080,
                    0,
                }
            else
                return {
                    0,
                    0,
                    0,
                }
            end
        end
    },
    color = {
        non_zero_units = {255, 255, 255, 255},
        zero_units = {160, 180, 180, 180},
        white = {255, 255, 255, 255},
        notif_multpl = {255, 255, 60, 0},
    }
}
local constants = mod.global_constants


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Global utilities
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod.utilities = {
    get_breed_setting = nil,
    sort_breed_names = nil,
    clean_breed_name = nil,
    is_monster = nil,
}
local util = mod.utilities

util.is_monster = function(clean_brd_name)
    -- NB: We check if Breeds[clean_brd_name] exists in case the *clean* breed name is, for instance "flamer" which isn't a valid breed
    if Breeds[clean_brd_name] and Breeds[clean_brd_name].tags and Breeds[clean_brd_name].tags.monster then
        return true
    else
        return string.match(clean_brd_name, "(.+)_wk")
    end
end

util.clean_breed_name = function(breed_name, is_weakened)
    local breed_name_no_mutator_marker = string.match(breed_name, "(.+)_mutator$") or breed_name
    local is_monster = util.is_monster(breed_name_no_mutator_marker)
    if string.match(breed_name_no_mutator_marker, "(.+)_flamer") then
        return "flamer"
    else
        if is_monster and is_weakened then
            return breed_name_no_mutator_marker.."_wk"
        else
            return breed_name_no_mutator_marker
        end
    end
end

util.monster_then_alphabetical_order = function(a,b)
    -- List monsters at the end, then breeds alphabetically
    if util.is_monster(a) and not util.is_monster(b) then
        return(false)
    elseif util.is_monster(b) and not util.is_monster(a) then
        return(true)
    else
        return(mod:localize(a) < mod:localize(b))
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                            Settings
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod.settings = {
    hud_scale = 1,
    global_toggle = {
        notif = true,
        overlay = true,
        init = function(self)
            self.notif = mod:get("global_toggle_notif")
            self.overlay = mod:get("global_toggle_overlay")
        end
    },
    overlay_name_style = {
        current = "short",
        init = function(self)
            self.current = mod:get("overlay_name_style") or self.current
        end,
    },
    font = {
        current = "machine_medium",
        init = function(self)
            self.current = mod:get("font") or self.current
        end,
    },
    notif = {
        display_type = "icon",
        grouping = true,
        sound = {
            enter_spawn = nil,
            exit_spawn = nil,
            enter_death = nil,
            exit_death = nil,
            enter_spawn_default = nil,
            exit_spawn_default = nil,
            enter_death_default = nil,
            exit_death_default = nil,
        },
        init = function(self)
            self.display_type = mod:get("notif_display_type")
            self.grouping = mod:get("notif_grouping")
            for _, event in pairs(constants.events) do
                for _, notif_evt in pairs({"enter", "exit"}) do
                    local default_sound_name = "notification_default_"..notif_evt
                    self.sound[notif_evt.."_"..event.."_default"] = UISoundEvents[default_sound_name]
                end
                self.sound["enter_"..event] = mod:get("sound_"..event)
                self.sound["exit_"..event] = self.sound["exit_"..event.."_default"]
                
            end
        end,
    },
    color = {
        notif = {
            text_gradient = nil,
            -- Other fields: Extended event (spawn/death/hybrid), priority levels (including 0)
        },
        hud = {
            lerp_ratio = 0.8,
            -- Other fields: Priority levels (including 0)
        },
        init = nil,
    }
}
local settings = mod.settings

-------------------------------------------------------
--                     color
-------------------------------------------------------

settings.color.notif.text_gradient = function(t, base_color)
    -- Argument: time since notif was last updated
    -- Returned: color to be applied to the "x[count]" text in the notif
    local bright_color = constants.color.notif_multpl
    local gradient_start_time = 0.9
    local gradient_end_time = 2
    local progression_ratio = math.clamp(
        (t - gradient_start_time) / (gradient_end_time - gradient_start_time),
        0,
        1
    )
    local get_color_component = function(bright_col_comp, base_col_comp, p)
        -- NB: p needs to be clamped between 0 and 1
        return math.floor(math.lerp(
                bright_col_comp,
                base_col_comp,
                p
            ))
    end
    local res = {}
    for i=1,4 do
        table.insert(res, get_color_component(bright_color[i], base_color[i], progression_ratio))
    end
    return res
end

-- NB: mod.settings.color is further defined in the main file (including its -:init() method)


-------------------------------------------------------
--                trackable_breeds
-------------------------------------------------------

-- NB: A "clean breed name" is a breed_name cleaned by util.clean_breed_name, which removed the possible "_mutator" marker at the end of the breed name, *and* collapses "renegade_flamer" and "cultist_flamer" into the same clean_breed_name "flamer" in order to track them together. Unless specified otherwise, "breed_name"'s are assumed to have been "cleaned". The names used here are the cleaned names of currently trackable units.
-- constants.trackable_breeds.array is the *sorted array* of the *cleaned* breed_name's trackable by the mod.
    -- NB: The order used for this file, and thus the mod options, only involves the monster tag, and alphabetical ordering, since we don't yet have access to the mod options. Additional layers of ordering will be added in the main file, for the HUD element widgets.
-- constants.trackable_breeds.inv_table[breed_name] = true if breed_name is in constants.trackable_breeds.array, nil otherwise
-- constants.trackable_breeds.sort() is defined in the main file

constants.trackable_breeds.array = {
    "chaos_beast_of_nurgle",
    "chaos_beast_of_nurgle_wk",
    "chaos_hound",
    "chaos_plague_ogryn",
    "chaos_plague_ogryn_wk",
    "chaos_poxwalker_bomber",
    "chaos_spawn",
    "chaos_spawn_wk",
    "cultist_grenadier",
    "cultist_mutant",
    "flamer",
    "renegade_grenadier",
    "renegade_netgunner",
    "renegade_sniper",
}
constants.trackable_breeds.inv_table = {}

table.sort(constants.trackable_breeds.array, util.monster_then_alphabetical_order)

for _, style in pairs(constants.trackable_breeds.overlay_names.styles) do
    constants.trackable_breeds.overlay_names[style] = { }
end

for _, clean_brd_name in pairs(constants.trackable_breeds.array) do
    constants.trackable_breeds.inv_table[clean_brd_name] = true
    for _, style in pairs(constants.trackable_breeds.overlay_names.styles) do
        constants.trackable_breeds.overlay_names[style][clean_brd_name] = mod:localize(clean_brd_name.."_overlay_name_"..style) or "[X]"
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                    Local utilities definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--                     Font
-------------------------------------------------------

local font_options = {}
for font_name, _ in pairs(FontDefinitions.fonts) do
	table.insert(font_options, {
		text = font_name,
		value = font_name,
	})
end

local font_equality = function(font1, font2)
    for i, _ in pairs(font1) do
        if font1[i] ~= font2[i] then
            return false
        end
    end
    return true
end

local contains_font = function(font_table,font)
    for _, f in pairs(font_table) do
        if font_equality(f, font) then
            return(true)
        end
    end
    return(false)
end

local wanted_default =  {
    text = "proxima_nova_light",
    value = "proxima_nova_light",
}
local default_font = contains_font(font_options, wanted_default) and wanted_default.value or font_options[1].value


-------------------------------------------------------
--                   Sounds
-------------------------------------------------------

local create_sound_entry = function(sound_name)
    return table.clone({
        text = sound_name,
        value = UISoundEvents[sound_name],
    })
end

local sound_events = {
    create_sound_entry("mission_vote_popup_show_details"),
    create_sound_entry("mission_vote_popup_hide_details"),
    create_sound_entry("notification_default_enter"),
    create_sound_entry("notification_default_exit"),
}

local other_sound_events = { }
for k, v in pairs(UISoundEvents) do
    if not table.find_by_key(sound_events, "text", k) and
       not table.find_by_key(sound_events, "value", v) and
       not table.find_by_key(other_sound_events, "text", k) and
       not table.find_by_key(other_sound_events, "value", v) and
       not string.match(k, "start") and
       not string.match(k, "stoo") and
       not string.match(v, "start") and
       not string.match(v, "stoo")
    then
        table.insert(other_sound_events, { text = k, value = v })
    end
end

table.sort(other_sound_events, function(a, b)
    return a.text < b.text
end)

for _, i in pairs(other_sound_events) do
    table.insert(sound_events, i)
end


-------------------------------------------------------
--             Other dropdown tables
-------------------------------------------------------

local position_dropdown = { }
for _, i in pairs({
    "top",
    "bottom"
}) do
    table.insert(position_dropdown, {text = i, value = i})
end


local notif_display_dropdown = { }
for _, i in pairs({
    "icon",
    "text",
}) do
    table.insert(notif_display_dropdown, {text = i, value = i})
end


local overlay_tracking_dropdown = { }
for _, i in pairs({
    "always",
    "only_if_active",
    "off"
}) do
    table.insert(overlay_tracking_dropdown, {text = i, value = i})
end

local overlay_name_style = { }
for _, i in pairs(constants.trackable_breeds.overlay_names.styles) do
    table.insert(overlay_name_style, {text = i, value = i})
end

local default_overlay_name_style = "short"


-------------------------------------------------------
--                Default values
-------------------------------------------------------

local default_overlay_tracking = function(clean_brd_name)
    if clean_brd_name == "monsters" or clean_brd_name == "monsters_wk" or clean_brd_name == "cultist_grenadier" or clean_brd_name == "renegade_grenadier" then
        return "only_if_active"
    elseif clean_brd_name == "renegade_sniper" or clean_brd_name == "renegade_netgunner" or clean_brd_name == "chaos_poxwalker_bomber" then
        return "always"
    else
        return "off"
    end
end

local default_priority_level = function(clean_brd_name)
    -- This will be the value of the priority_lvl setting, and not an index, so it needs to be an integer
    -- It will be tostring'd when fetched by the mod (Lua can compare tostring'd digits as part of the default alphabetical order)
    if clean_brd_name == "renegade_sniper" or clean_brd_name == "renegade_netgunner" then
        return 1
    elseif clean_brd_name == "chaos_poxwalker_bomber" or clean_brd_name == "renegade_grenadier" or clean_brd_name == "cultist_grenadier" then
        return 2
    else
        return 3
    end
end

local default_sound = function(extended_evt)
    if extended_evt == "spawn" then
        return sound_events[1].value
    else
        return sound_events[2].value
    end
end

local default_colors = function(extended_evt_or_priority_lvl)
    if extended_evt_or_priority_lvl == "spawn" then
        return({
            alpha = 140,
            r = 118,
            g = 69,
            b = 18,
        })
    elseif extended_evt_or_priority_lvl == "death" then
        return({
            alpha = 140,
            r = 24,
            g = 110,
            b = 90,
        })
    elseif extended_evt_or_priority_lvl == "hybrid" then
        return({
            alpha = 140,
            r = 122,
            g = 102,
            b = 0,
        })
    elseif extended_evt_or_priority_lvl == "monsters" then
        return({
            alpha = 255,
            r = 255,
            g = 0,
            b = 0,
        })
    elseif extended_evt_or_priority_lvl == "monsters_wk" then
        return({
            alpha = 255,
            r = 255,
            g = 0,
            b = 0,
        })
    elseif extended_evt_or_priority_lvl == "1" then
        return({
            alpha = 255,
            r = 255,
            g = 174,
            b = 0,
        })
    elseif extended_evt_or_priority_lvl == "2" then
        -- This is the game's color of specials in the killfeed
        return({
            alpha = 255,
            r = 237,
            g = 220,
            b = 135,
        })
    elseif extended_evt_or_priority_lvl == "3" or extended_evt_or_priority_lvl == "4" then
        -- This is the game's color of specials in the killfeed
        return({
            alpha = 255,
            r = 237,
            g = 220,
            b = 135,
        })
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                     Widget creation functions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local color_widget = function(extended_evt_or_priority_lvl, alpha_wanted)
    -- extended_evt_or_priority_lvl can be an extended event ("spawn"/"death"/"hybrid"), a non-zero priority level, or "monsters" (which, conceptually, corresponds to priority level 0)
    local res = {
        setting_id = "color_"..extended_evt_or_priority_lvl,
        type = "group",
        sub_widgets = { }
    }
    if extended_evt_or_priority_lvl == "monsters" or extended_evt_or_priority_lvl == "monsters_wk" or table.array_contains(constants.priority_levels_non_zero, extended_evt_or_priority_lvl) then
        -- If extended_evt_or_priority_lvl is a priority level, add a widget to determine whether to use the notif color to color the HUD
        table.insert(res.sub_widgets, {
            setting_id = "color_used_in_hud_"..extended_evt_or_priority_lvl,
            type = "checkbox",
            default_value = true,
            })
    elseif extended_evt_or_priority_lvl ~= "hybrid" then
        -- If it's a base event, add a sound cue widget
        table.insert(res.sub_widgets, {
                setting_id = "sound_"..extended_evt_or_priority_lvl,
                type = "dropdown",
                default_value = default_sound(extended_evt_or_priority_lvl),
                options = table.clone(sound_events)
            })
    end
    if alpha_wanted then
        table.insert(res.sub_widgets, {
            setting_id = "color_"..extended_evt_or_priority_lvl.."_alpha",
            tooltip = "tooltip_color_alpha",
            type = "numeric",
            default_value = default_colors(extended_evt_or_priority_lvl).alpha,
            range = {0, 255},
        })
    end
    for _, col in pairs({"r","g","b"}) do 
        table.insert(res.sub_widgets, {
            setting_id = "color_"..extended_evt_or_priority_lvl.."_"..col,
            type = "numeric",
            default_value = default_colors(extended_evt_or_priority_lvl)[col],
            range = {0, 255},
        })
    end
    return(res)
end


local breed_widget = function(clean_brd_name)
    local widget = {
        setting_id = clean_brd_name,
        type = "group",
        sub_widgets = { },
    }
    local sub_wid_toggle_overlay = {
        setting_id = clean_brd_name.."_overlay",
        tooltip = "tooltip_overlay_tracking",
        type = "dropdown",
        default_value = default_overlay_tracking(clean_brd_name),
        options = table.clone(overlay_tracking_dropdown),
    }
    local sub_wid_toggle_notif = {
        setting_id = clean_brd_name.."_notif",
        type = "checkbox",
        default_value = clean_brd_name == "renegade_sniper" or clean_brd_name == "renegade_netgunner" or clean_brd_name == "monsters" or clean_brd_name == "monsters_wk",
    }
    local sub_wid_priority_lvl = {
        setting_id = clean_brd_name.."_priority",
        tooltip = "tooltip_priority_lvls",
        type = "numeric",
        default_value = default_priority_level(clean_brd_name),
        range = {
            tonumber(constants.priority_levels_non_zero[1])
        ,
            tonumber(constants.priority_levels_non_zero[#constants.priority_levels_non_zero])
        },
    }
    --[[
    local sub_wid_monsters_pos = {
        setting_id = "monsters_pos",
        tooltip = "tooltip_monsters_pos",
        type = "dropdown",
        default_value = "bottom",
        options = table.clone(position_dropdown),
    }
    --]]
    if clean_brd_name ~= "monsters" and clean_brd_name ~= "monsters_wk" then
        table.insert(widget.sub_widgets, sub_wid_priority_lvl)
    end
    table.insert(widget.sub_widgets, sub_wid_toggle_overlay)
    table.insert(widget.sub_widgets, sub_wid_toggle_notif)
    --[[
    if clean_brd_name == "monsters" then
        table.insert(widget.sub_widgets, sub_wid_monsters_pos)
    end
    --]]
    return widget
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                        Widgets creation
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local widgets = {
    {
        setting_id = "global_toggle_notif",
        tooltip = "tooltip_global_toggle_notif",
        type = "checkbox",
        default_value = true,
        sub_widgets = {
            {
                setting_id = "notif_display_type",
                type = "dropdown",
                default_value = "icon",
                options = table.clone(notif_display_dropdown),
            },
            {
                setting_id = "notif_grouping",
                -- tooltip = "tooltip_notif_grouping",
                type = "checkbox",
                default_value = true,
            },
        },
    },
    {
        setting_id = "global_toggle_overlay",
        tooltip = "tooltip_global_toggle_overlay",
        type = "checkbox",
        default_value = true,
        sub_widgets = {
            {
                setting_id = "overlay_move_from_center",
                tooltip = "tooltip_overlay_move_from_center",
                type = "checkbox",
                default_value = false,
            },
            {
                setting_id = "hud_scale",
                type = "numeric",
                range = { constants.hud.min_possible_scale, constants.hud.max_possible_scale },
                default_value = 1,
                decimals_number = 1,
                step_size_value = 0.1,
            },
            {
                setting_id = "monsters_pos",
                tooltip = "tooltip_monsters_pos",
                type = "dropdown",
                default_value = "bottom",
                options = table.clone(position_dropdown),
            },
            {
                setting_id = "overlay_name_style",
                tooltip = "tooltip_overlay_name_style",
                type = "dropdown",
                default_value = default_overlay_name_style,
                options = overlay_name_style,
            },
            {
                setting_id = "hud_color_lerp_ratio",
                tooltip = "tooltip_hud_color_lerp_ratio",
                type = "numeric",
                range = { 0, 1 },
                default_value = 0.8,
                decimals_number = 1,
                step_size_value = 0.1,
            },
            {
                setting_id = "font",
                type = "dropdown",
                default_value = default_font,
                options = font_options,
            },
        }
    },
}

-- Add extended event notif. widgets
table.insert(widgets, {
    setting_id = "extended_events",
    type = "group",
    --tooltip = "tooltip_extended_events",
    sub_widgets = { }
})
for _, event in pairs(constants.events_extended) do
    table.insert(widgets[#widgets].sub_widgets, color_widget(event, true))
end

-- Add priority level (and monsters) widgets
table.insert(widgets, {
    setting_id = "priority_lvls",
    type = "group",
    --tooltip = "tooltip_priority_lvls",
    sub_widgets = { }
})
table.insert(widgets[#widgets].sub_widgets, color_widget("monsters", false))
table.insert(widgets[#widgets].sub_widgets, color_widget("monsters_wk", false))
for _, i in pairs(constants.priority_levels_non_zero) do
    table.insert(widgets[#widgets].sub_widgets, color_widget(i, false))
end

-- Add Breed widgets
-- NB: Each interesting_breed_name has its own widget, *except* monsters (beast/chaos spawn/plague ogryn) which are collapsed into one "monsters" widget (but they are still tracked separately)
table.insert(widgets, {
    setting_id = "breed_widgets",
    type = "group",
    sub_widgets = { }
})
table.insert(widgets[#widgets].sub_widgets, breed_widget("monsters"))
table.insert(widgets[#widgets].sub_widgets, breed_widget("monsters_wk"))
for _, clean_brd_name in pairs(constants.trackable_breeds.array) do
    if not util.is_monster(clean_brd_name) then
        table.insert(widgets[#widgets].sub_widgets, breed_widget(clean_brd_name))
    end
end

table.insert(widgets, {
    setting_id = "debugging",
    tooltip = "tooltip_debugging",
    type = "checkbox",
    default_value = false,
})

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = widgets
    }
}