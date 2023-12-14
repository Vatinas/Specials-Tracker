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
    -- local default_color = table.clone(Color.terminal_text_header(255, true))
    local characteristic_time = 1.5
    local natural_time = t/characteristic_time
    local get_color_component = function(bright_col_comp, base_col_comp, p)
        return math.floor(math.lerp(
                bright_col_comp,
                base_col_comp,
                math.clamp(
                    p,
                    0,
                    1
                )
            ))
    end
    local res = {}
    for i=1,4 do
        table.insert(res, get_color_component(bright_color[i], base_color[i], natural_time))
    end
    return res
end

-- NB: mod.color is further defined in the main file (including its .init() method)


-------------------------------------------------------
--             interesting_breed_names
-------------------------------------------------------

mod.interesting_breed_names = {}
-- mod.interesting_breed_names.array is the *sorted array* of the breeds *trackable* (not tracked!) by the mod
-- mod.interesting_breed_names.inverted_table[breed_name] = true if breed_name is in mod.interesting_breed_names.array, nil otherwise
-- mod.interesting_breed_names.init() initialises the array and table. This should only be necessary once per mod load.

mod.interesting_breed_names.array = {}
mod.interesting_breed_names.inverted_table = {}

local tag_then_alphabetical_order = function(a,b)
    -- List monsters at the end, then breeds alphabetically
    if Breeds[a].tags.monster and not Breeds[b].tags.monster then
        return(false)
    elseif Breeds[b].tags.monster and not Breeds[a].tags.monster then
        return(true)
    else
        return(a < b)
    end
end

mod.interesting_breed_names.init = function()
    mod.interesting_breed_names.array = {}
    mod.interesting_breed_names.inverted_table = {}
    for breed_name, breed in pairs(Breeds) do
        if breed_name ~= "chaos_plague_ogryn_sprayer"
        and breed.display_name
        and breed.display_name ~= "loc_breed_display_name_undefined"
        and not breed.boss_health_bar_disabled
        and not string.match(breed_name, "_mutator$")
        and breed.tags and (breed.tags.special or breed.tags.monster) then
            table.insert(mod.interesting_breed_names.array, breed_name)
            mod.interesting_breed_names.inverted_table[breed_name] = true
        end
    end
    table.sort(mod.interesting_breed_names.array, tag_then_alphabetical_order)
end

mod.interesting_breed_names.init()

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

local color_options = {}
for _, color in ipairs(Color.list) do
	table.insert(color_options, {
		text = color,
		value = color,
	})
end

local default_colors = function(event_or_priority_lvl)
    if event_or_priority_lvl == "spawn" then
        return({
            alpha = 190,
            r = 118,
            g = 69,
            b = 18,
        })
    elseif event_or_priority_lvl == "death" then
        return({
            alpha = 190,
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

local is_monster = function(breed_name)
    if Breeds[breed_name].tags and Breeds[breed_name].tags.monster then
        return true
    else
        return false
    end
end

local default_priority_level = function(breed_name)
    -- This will be the value of the priority_lvl setting, and not an index, so it needs to be an integer
    -- It will be tostring'd when fetched by the mod (Lua can compare tostring'd digits as part of the default alphabetical order)
    if is_monster(breed_name) then
        return 1
    elseif breed_name == "renegade_sniper" or breed_name == "renegade_netgunner" then
        return 2
    elseif breed_name == "chaos_poxwalker_bomber" or breed_name == "renegade_grenadier" then
        return 3
    else
        return 4
    end
end

local breed_widget = function(breed_name)
    local widget = {
        setting_id = breed_name,
        type = "group",
        sub_widgets = { },
    }
    local sub_wid_toggle_overlay = {
        setting_id = breed_name.."_overlay",
        type = "checkbox",
        default_value = breed_name == "renegade_sniper" or breed_name == "renegade_netgunner" or breed_name == "chaos_poxwalker_bomber" or breed_name == "renegade_grenadier" or is_monster(breed_name),
    }
    local sub_wid_toggle_notif = {
        setting_id = breed_name.."_notif",
        type = "checkbox",
        default_value = breed_name == "renegade_sniper" or breed_name == "renegade_netgunner" or is_monster(breed_name),
    }
    local sub_wid_priority_lvl = {
        setting_id = breed_name.."_priority",
        tooltip = "tooltip_priority_lvls",
        type = "numeric",
        default_value = default_priority_level(breed_name),
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
        range = { 1, 2 },
        default_value = 1.3,
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
    {
        setting_id = "monsters_hud_only_if_alive",
        tooltip = "tooltip_monsters_hud_only_if_alive",
        type = "checkbox",
        default_value = true,
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
table.insert(widgets, {
    setting_id = "breed_widgets",
    type = "group",
    sub_widgets = { }
})
for _, breed_name in pairs(mod.interesting_breed_names.array) do
    table.insert(widgets[#widgets].sub_widgets, breed_widget(breed_name))
end

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