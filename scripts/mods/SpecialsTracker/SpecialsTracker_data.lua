require("scripts/foundation/utilities/color")

local mod = get_mod("SpecialsTracker")

local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")
local Breeds = require("scripts/settings/breed/breeds")


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Global definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod.events = {"spawn","death"}
mod.priority_levels = {"1", "2", "3", "4"}
mod.clean_breed_name = function(breed_name)
    local breed_name_no_mutator_marker = string.match(breed_name, "(.+)_mutator$") or breed_name
    if string.match(breed_name_no_mutator_marker, "(.+)_flamer") then
        return "flamer"
    else
        return breed_name_no_mutator_marker
    end
end

mod.is_monster = function(clean_brd_name)
    if Breeds[clean_brd_name] and Breeds[clean_brd_name].tags and Breeds[clean_brd_name].tags.monster then
        return true
    else
        return false
    end
end

local monster_then_alphabetical_order = function(a,b)
    -- List monsters at the end, then breeds alphabetically
    if mod.is_monster(a) and not mod.is_monster(b) then
        return(false)
    elseif mod.is_monster(b) and not mod.is_monster(a) then
        return(true)
    else
        return(mod:localize(a) < mod:localize(b))
    end
end

-------------------------------------------------------
--                     color
-------------------------------------------------------

mod.color = { }

mod.color.white = {255, 255, 255, 255}
mod.color.notif_multpl = {255, 255, 60, 0}

mod.color.indices = { }

mod.color.notif = { }
mod.color.notif.table = { }

mod.color.hud = {}
mod.color.hud.monster_only_if_alive = true
mod.color.hud.lerp_ratio = 0.5
-- Lower ratio = closer to white (or the other base color)
-- The former two will be updated when necessary to keep track of the mod options

mod.color.hud.use_color_priority_lvl = { }
mod.color.hud.table = { }

mod.color.hud.table.non_zero_units = {255, 255, 255, 255}
mod.color.hud.table.zero_units = {160, 180, 180, 180}

for _, event in pairs(mod.events) do
    table.insert(mod.color.indices, event)
end
for _, lvl in pairs(mod.priority_levels) do
    table.insert(mod.color.indices, tostring(lvl))
end

mod.color.new_notif_gradient = function(t, base_color)
    -- Argument: time since notif was last updated
    -- Returned: color to be applied to the "x[count]" text in the notif
    local bright_color = mod.color.notif_multpl
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

-- NB: mod.color is further defined in the main file (including its -.init() method)


-------------------------------------------------------
--             interesting_breed_names
-------------------------------------------------------

mod.interesting_breed_names = {}
-- NB: A "clean breed name" is a breed_name cleaned by mod.clean_breed_name, which removed the possible "_mutator" marker at the end of the breed name, *and* collapses "renegade_flamer" and "cultist_flamer" into the same clean_breed_name "flamer" in order to track them together. Unless specified otherwise, "breed_name"'s are assumed to have been "cleaned".
-- mod.interesting_breed_names.array is the *sorted array* of the *cleaned* breed_name's *trackable* (not tracked!) by the mod.
    -- NB: The order used for this file, and thus the mod options, only involves the monster tag, and alphabetical ordering, since we don't yet have access to the mod options. Additional layers of ordering will be added in the main file, for the HUD element widgets.
-- mod.interesting_breed_names.inverted_table[breed_name] = true if breed_name is in mod.interesting_breed_names.array, nil otherwise
-- mod.interesting_breed_names.sort() is defined in the main file

--[[
mod.interesting_breed_names.array = {}
mod.interesting_breed_names.inverted_table = {}

mod.interesting_breed_names.init = function()
    mod.interesting_breed_names.array = {}
    mod.interesting_breed_names.inverted_table = {}
    for breed_name, breed in pairs(Breeds) do
        if breed_name ~= "chaos_plague_ogryn_sprayer"
        and breed.display_name
        and breed.display_name ~= "loc_breed_display_name_undefined"
        and not breed.boss_health_bar_disabled
        and breed.tags and (breed.tags.special or breed.tags.monster) then
            local clean_name = mod.clean_breed_name(breed_name)
            if not mod.interesting_breed_names.inverted_table[clean_name] then
                table.insert(mod.interesting_breed_names.array, clean_name)
                mod.interesting_breed_names.inverted_table[clean_name] = true
            end
        end
    end
    table.sort(mod.interesting_breed_names.array, monster_then_alphabetical_order)
end

mod.interesting_breed_names.init()
--]]

mod.interesting_breed_names.array = {
    "chaos_beast_of_nurgle",
    "chaos_hound",
    "chaos_plague_ogryn",
    "chaos_poxwalker_bomber",
    "chaos_spawn",
    "cultist_mutant",
    "flamer",
    "renegade_grenadier",
    "renegade_netgunner",
    "renegade_sniper",
}
mod.interesting_breed_names.inverted_table = {}

table.sort(mod.interesting_breed_names.array, monster_then_alphabetical_order)
for _, clean_brd_name in pairs(mod.interesting_breed_names.array) do
    mod.interesting_breed_names.inverted_table[clean_brd_name] = true
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Utilities definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Utilities definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

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


local overlay_tracking_dropdown = { }
for _, i in pairs({
    "always",
    "only_if_active",
    "off"
}) do
    table.insert(overlay_tracking_dropdown, {text = i, value = i})
end

local default_overlay_tracking = function(clean_brd_name)
    -- if mod.is_monster(clean_brd_name) then
    if clean_brd_name == "monsters" then
        return "only_if_active"
    elseif clean_brd_name == "renegade_sniper" or clean_brd_name == "renegade_netgunner" or clean_brd_name == "chaos_poxwalker_bomber" or clean_brd_name == "renegade_grenadier" then
        return "always"
    else
        return "off"
    end
end

--[[
local color_options = {}
for _, color in ipairs(Color.list) do
	table.insert(color_options, {
		text = color,
		value = color,
	})
end
--]]

local default_colors = function(event_or_priority_lvl)
    if event_or_priority_lvl == "spawn" then
        return({
            alpha = 140,
            r = 118,
            g = 69,
            b = 18,
        })
    elseif event_or_priority_lvl == "death" then
        return({
            alpha = 140,
            r = 24,
            g = 110,
            b = 90,
        })
    elseif event_or_priority_lvl == "1" then
        return({
            alpha = 255,
            r = 255,
            g = 0,
            b = 0,
        })
    elseif event_or_priority_lvl == "2" then
        return({
            alpha = 255,
            r = 255,
            g = 174,
            b = 0,
        })
    elseif event_or_priority_lvl == "3" then
        -- This is the game's color of specials in the killfeed
        return({
            alpha = 255,
            r = 237,
            g = 220,
            b = 135,
        })
    elseif event_or_priority_lvl == "4" then
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

local color_widget = function(event_or_priority_lvl, alpha_wanted)
    local res = {
        setting_id = "color_"..event_or_priority_lvl,
        type = "group",
        tooltip = "tooltip_color_"..event_or_priority_lvl,
        sub_widgets = { }
    }
    -- If event_or_priority_lvl is a priority level, add a widget to determine whether to use the notif color to color the HUD
    if table.array_contains(mod.priority_levels, event_or_priority_lvl) then
        table.insert(res.sub_widgets, {
            setting_id = "color_used_in_hud_"..event_or_priority_lvl,
            type = "checkbox",
            default_value = true,
            })
    end
    if alpha_wanted then
        table.insert(res.sub_widgets, {
            setting_id = "color_"..event_or_priority_lvl.."_alpha",
            tooltip = "tooltip_color_alpha",
            type = "numeric",
            default_value = default_colors(event_or_priority_lvl).alpha,
            range = {0, 255},
        })
    end
    for _, col in pairs({"r","g","b"}) do 
        table.insert(res.sub_widgets, {
            setting_id = "color_"..event_or_priority_lvl.."_"..col,
            type = "numeric",
            default_value = default_colors(event_or_priority_lvl)[col],
            range = {0, 255},
        })
    end
    return(res)
end

local default_priority_level = function(clean_brd_name)
    -- This will be the value of the priority_lvl setting, and not an index, so it needs to be an integer
    -- It will be tostring'd when fetched by the mod (Lua can compare tostring'd digits as part of the default alphabetical order)
    --if mod.is_monster(clean_brd_name) then
    if clean_brd_name == "monsters" then
        return 1
    elseif clean_brd_name == "renegade_sniper" or clean_brd_name == "renegade_netgunner" then
        return 2
    elseif clean_brd_name == "chaos_poxwalker_bomber" or clean_brd_name == "renegade_grenadier" then
        return 3
    else
        return 4
    end
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
        default_value = clean_brd_name == "renegade_sniper" or clean_brd_name == "renegade_netgunner" or clean_brd_name == "monsters", --mod.is_monster(clean_brd_name),
    }
    local sub_wid_priority_lvl = {
        setting_id = clean_brd_name.."_priority",
        tooltip = "tooltip_priority_lvls",
        type = "numeric",
        default_value = default_priority_level(clean_brd_name),
        range = {
            tonumber(mod.priority_levels[1])
        ,
            tonumber(mod.priority_levels[#mod.priority_levels])
        },
    }
    widget.sub_widgets = {
        sub_wid_toggle_overlay,
        sub_wid_toggle_notif,
        sub_wid_priority_lvl,
    }
    return widget
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Widgets initialisation
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local widgets = {
    {
        setting_id = "hud_scale",
        type = "numeric",
        range = { 0.5, 2 },
        default_value = 1,
        decimals_number = 1,
        step_size_value = 0.1,
    },
    {
        setting_id = "font",
        type = "dropdown",
        default_value = default_font, --font_options[1].value,
        options = font_options,
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
}

-- Add event notif. widgets
for _, event in pairs(mod.events) do
    table.insert(widgets, color_widget(event, true))
end

-- Add priority level widgets
table.insert(widgets, {
    setting_id = "priority_lvls",
    type = "group",
    tooltip = "tooltip_priority_lvls",
    sub_widgets = { }
})
for _, i in pairs(mod.priority_levels) do
    table.insert(widgets[#widgets].sub_widgets, color_widget(i, false))
end

-- Add Breed widgets
-- NB: Each interesting_breed_name has its own widget, *except* monsters (beast/chaos spawn/plague ogryn) which are collapsed into one "monsters" widget (but they are still tracked separately)
table.insert(widgets, {
    setting_id = "breed_widgets",
    type = "group",
    sub_widgets = { }
})
for _, clean_brd_name in pairs(mod.interesting_breed_names.array) do
    if not mod.is_monster(clean_brd_name) then
        table.insert(widgets[#widgets].sub_widgets, breed_widget(clean_brd_name))
    end
end

table.insert(widgets[#widgets].sub_widgets, breed_widget("monsters"))


--[[
-- Add manual refresh key widget
table.insert(widgets, {
    setting_id = "unit_counter_reset_key",
    type = "keybind",
    default_value = { "f6" },
    keybind_trigger = "pressed",
    keybind_type = "function_call",
    function_name = "reset_unit_counter",
})
--]]


return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = widgets
    }
}