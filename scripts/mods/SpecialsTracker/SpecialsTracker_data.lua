require("scripts/foundation/utilities/color")

local mod = get_mod("SpecialsTracker")

local FontDefinitions = require("scripts/managers/ui/ui_fonts_definitions")
local Breeds = require("scripts/settings/breed/breeds")

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

--------------------------------------
-- Global definitions

mod.events = {"spawn","death"}
mod.priority_levels = {1, 2, 3}

mod.color = { }
mod.color.notif = { }
mod.color.notif.indices = { }
-- mod.color.notif.table and .init are defined in the main file

for _, event in pairs(mod.events) do
    table.insert(mod.color.notif.indices, event)
end
for _, lvl in pairs(mod.priority_levels) do
    table.insert(mod.color.notif.indices, tostring(lvl))
end

mod.interesting_breed_names = {}
-- mod.interesting_breed_names.array is the *sorted array* of the breeds *trackable* (not tracked!) by the mod
-- mod.interesting_breed_names.inverted_table[breed_name] = true if breed_name is in mod.interesting_breed_names.array, nil otherwise
-- mod.interesting_breed_names.init() initialises the array and table. This should only be necessary once per mod load.

mod.interesting_breed_names.array = {}
mod.interesting_breed_names.inverted_table = {}
mod.interesting_breed_names.init = function()
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

local font_options = {}
for font_name, _ in pairs(FontDefinitions.fonts) do
	table.insert(font_options, {
		text = font_name,
		value = font_name,
	})
end

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
            alpha = 255,
            r = 255,
            g = 140,
            b = 70,
        })
    elseif event_or_priority_lvl == "death" then
        return({
            alpha = 255,
            r = 100,
            g = 255,
            b = 100,
        })
    elseif event_or_priority_lvl == 1 then
        return({
            alpha = 255,
            r = 255,
            g = 0,
            b = 0,
        })
    elseif event_or_priority_lvl == 2 then
        return({
            alpha = 255,
            r = 255,
            g = 120,
            b = 0,
        })
    elseif event_or_priority_lvl == 3 then
        return({
            alpha = 255,
            r = 255,
            g = 230,
            b = 30,
        })
    end
end

local widgets = {
    {
        setting_id = "hud_element_scale",
        type = "numeric",
        range = { 1, 2 },
        default_value = 1,
        decimals_number = 1,
        step_size_value = 0.1,
    },
    {
        setting_id = "font",
        type = "dropdown",
        default_value = font_options[1].value,
        options = font_options,
    },
}

local color_widget = function(event_or_priority_lvl, alpha_wanted)
    local res = {
        setting_id = "color_"..event_or_priority_lvl,
        type = "group",
        tooltip = "tooltip_color_"..event_or_priority_lvl,
        sub_widgets = { }
    }
    if alpha_wanted then
        table.insert(res.sub_widgets, {
            setting_id = "color_alpha_"..event_or_priority_lvl,
            type = "numeric",
            default_value = default_colors(event_or_priority_lvl).alpha,
            range = {0, 255},
        })
    end
    for _, col in pairs({"r","g","b"}) do 
    table.insert(res.sub_widgets, {
            setting_id = "color_"..col.."_"..event_or_priority_lvl,
            type = "numeric",
            default_value = default_colors(event_or_priority_lvl)[col],
            range = {0, 255},
        })
    end
    return(res)
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
        default_value = breed_name == "renegade_sniper" or breed_name == "renegade_netgunner" or breed_name == "chaos_poxwalker_bomber" or breed_name == "renegade_grenadier",
    }
    local sub_wid_toggle_notif = {
        setting_id = breed_name.."_notif",
        type = "checkbox",
        default_value = breed_name == "renegade_sniper" or breed_name == "renegade_netgunner",
    }
    local sub_wid_priority_lvl = {
        setting_id = breed_name.."_priority",
        type = "numeric",
        default_value = (breed_name == "renegade_sniper" or breed_name == "renegade_netgunner") and 1 or 2,
        range = {1, 3},
    }
    widget.sub_widgets = {
        sub_wid_toggle_overlay,
        sub_wid_toggle_notif,
        sub_wid_priority_lvl,
    }
    return widget
end

--[[
local priority_level_widget = function(i)
    return {
        setting_id = "priority_"..tostring(i),
        type = "group",
        sub_widgets = color_widget(i, false),
    }
end
--]]


for _, event in pairs(mod.events) do
    table.insert(widgets, color_widget(event, true))
end

for i=1,3 do
    -- table.insert(widgets, priority_level_widget(i))
    table.insert(widgets, color_widget(i, false))
end

for _, breed_name in pairs(mod.interesting_breed_names.array) do
    table.insert(widgets, breed_widget(breed_name))
end

---[[
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