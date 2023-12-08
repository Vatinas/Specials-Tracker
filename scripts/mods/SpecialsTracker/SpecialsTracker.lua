local mod = get_mod("SpecialsTracker")

local Breeds = require("scripts/settings/breed/breeds")
local TextUtils = require("scripts/utilities/ui/text")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")

-----------------------------------------------------------------
--- Part 0: Defining the interesting_breed_names and tracked_units tables
-----------------------------------------------------------------

mod.hud_refresh_flags = {
    pos = false,
-- Will be true iff breed settings have been changed, and the widgets need to have their position refreshed
    color = false,
-- Will be true iff widget color settings have been changed, and the widgets need to have their color function refreshed
    scale = false,
-- You know the drill by now
    font = false,
}

mod.sort_breed_names = function(a,b)
    -- List monsters at the end, then breeds according to their priority level, then alphabetically
    if Breeds[a].tags.monster and not Breeds[b].tags.monster then
        return(false)
    elseif Breeds[b].tags.monster and not Breeds[a].tags.monster then
        return(true)
    else
        local priority_a = mod:get(a.."_priority")
        local priority_b = mod:get(b.."_priority")
        if priority_a < priority_b then
            return(true)
        elseif priority_a > priority_b then
            return(false)
        else
            return(a < b)
        end
    end
end

-- The first part of mod.color is defined in the data file
mod.color.notif.table = { }

mod.color.init = function()
    for _, color_index in pairs(mod.color.notif.indices) do
        local this_color = { }
        table.insert(this_color, mod:get("color_alpha_"..color_index) and mod:get("color_alpha_"..color_index) or 255)
        for _, col in pairs({"r","g","b"}) do
            table.insert(this_color, mod:get("color_"..col.."_"..color_index))
        end
        mod.color.notif.table[color_index] = this_color
    end
end

mod.color.init()


mod.interesting_breed_names.init()

mod.interesting_breed_names.sort = function()
    -- Re-sorts interesting_breed_names, not only by tag then alphabetically, but also by priority order between those two
    table.sort(mod.interesting_breed_names.array, mod.sort_breed_names)
end

mod.interesting_breed_names.sort()



mod.tracked_units = {}
--[[
Data:
    mod.tracked_units.units[breed_name]
        An *array* containing active units of breed_name. Will be tracked to purge dead units regardless of whether breed_name is tracked or not, but spawned units will only be added to it if the breed is tracked.
    mod.tracked_units.unit_count[breed_name]
        The number of active units of breed_name (which is simply #mod.tracked_units.unit_count[breed_name], but is stored separately to avoid checking the array size at every HUD element update)
    mod.tracked_units.[tracking method]_breeds_array
        Array containing the breed names tracked with [tracking_method], which can be "notif" or "overlay". Array is sorted according to the mod.sort_breed_names order.
    mod.tracked_units.[tracking_method]_breeds_inverted_table = {}
        mod.tracked_units.[tracking_method]_breeds_inverted_table[breed_name] = true if breed_name is tracked by [tracking_method], nil otherwise.

Methods:
    mod.tracked_units.init()
        Initialises mod.tracked_units.breeds_array and mod.tracked_units.breeds_inverted_table so they can be used to fetch tracked breeds
    mod.tracked_units.clean_dead_units()
        Goes through all tracked units to look for dead ones. If one is found, they are removed from their mod.tracked_units.units[breed_name] array.
        Returns a table t such that t[breed_name] is the number of dead units of breed_name that were removed.
    mod.tracked_units.refresh_unit_count(breed_name)
        Refreshes the value of mod.tracked_units.unit_count[breed_name].
    mod.tracked_units.record_unit_spawn(breed_name, unit)
        If breed_name is tracked, adds unit to mod.tracked_units.units[breed_name], refreshes the value of mod.tracked_units.unit_count[breed_name], and returns true. Otherwise, does and returns nothing.
        NB: This method has 2 arguments because we were getting breed_name from the network (see the hook of "_add_network_unit"). But is it really necessary, or can we just use the unit's breed directly?
    mod.tracked_units.record_unit_death(unit)
        If breed_name is tracked, removes unit from mod.tracked_units.units[breed_name], refreshes the value of mod.tracked_units.unit_count[breed_name], and returns breed_name. Otherwise, does and returns nothing.
--]]

mod.tracked_units.units = {}
mod.tracked_units.unit_count = {}
for _, breed_name in pairs(mod.interesting_breed_names.array) do
    mod.tracked_units.units[breed_name] = {}
    mod.tracked_units.unit_count[breed_name] = 0
end

mod.tracked_units.init = function()
    -- mod.tracked_units.units = {}
    -- mod.tracked_units.unit_count = {}
    mod.tracked_units.notif_breeds_array = {}
    mod.tracked_units.notif_breeds_inverted_table = {}
    mod.tracked_units.overlay_breeds_array = {}
    mod.tracked_units.overlay_breeds_inverted_table = {}
    for _, breed_name in pairs(mod.interesting_breed_names.array) do
        if mod:get(breed_name.."_notif") then
            -- mod.tracked_units.units[breed_name] = {}
            -- mod.tracked_units.unit_count[breed_name] = 0
            table.insert(mod.tracked_units.notif_breeds_array, breed_name)
            mod.tracked_units.notif_breeds_inverted_table[breed_name] = true
        end
        if mod:get(breed_name.."_overlay") then
            -- mod.tracked_units.units[breed_name] = {}
            -- mod.tracked_units.unit_count[breed_name] = 0
            table.insert(mod.tracked_units.overlay_breeds_array, breed_name)
            mod.tracked_units.overlay_breeds_inverted_table[breed_name] = true
        end
    end
    table.sort(mod.tracked_units.notif_breeds_array, mod.sort_breed_names)
    table.sort(mod.tracked_units.overlay_breeds_array, mod.sort_breed_names)
    mod.hud_refresh_flags.pos = true
end

mod.tracked_units.init()

mod.tracked_units.refresh_unit_count = function(breed_name)
    -- if mod.tracked_units.breeds_inverted_table[breed_name] then
    mod.tracked_units.unit_count[breed_name] = #mod.tracked_units.units[breed_name] or 0
    --else
    --    Managers.event:trigger("event_add_notification_message", "alert", { text = "Tried to refresh the unit count of untracked unit: "..Localize(breed_name)})
    --end
end

mod.tracked_units.clean_dead_units = function()
    local nb_of_deaths_per_breed = {}
    for breed_name, active_units in pairs(mod.tracked_units.units) do
        for i,unit in pairs(active_units) do
            if not Unit.alive(unit) then
                table.remove(active_units, i)
                nb_of_deaths_per_breed[breed_name] = (nb_of_deaths_per_breed[breed_name] or 0) + 1
            end
        end
    end
    for breed_name, _ in pairs(nb_of_deaths_per_breed) do
        mod.tracked_units.refresh_unit_count(breed_name)
    end
    return(nb_of_deaths_per_breed)
end

mod.tracked_units.record_unit_death = function(unit)
    local unit_data_ext = ScriptUnit.extension(unit, "unit_data_system")
    local breed = unit_data_ext and unit_data_ext:breed()
    local breed_name = breed and breed.name
    if mod.tracked_units.units[breed_name] then
        local unit_index = table.index_of(mod.tracked_units.units[breed_name], unit)
        if unit_index ~= -1 then
            -- Unit might not be there if the mod was reset while the unit was already alive
            table.remove(mod.tracked_units.units[breed_name], unit_index)
            mod.tracked_units.refresh_unit_count(breed_name)
            return(breed_name)
        else
            if mod.tracked_units.notif_breeds_inverted_table[breed_name] then
                Managers.event:trigger("event_add_notification_message", "alert", { text = "Dead unit was not known to be alive: "..Localize(breed.display_name)})
            end
        end
    end
end

mod.tracked_units.record_unit_spawn = function(breed_name, unit)
    local tracked_notif = mod.tracked_units.notif_breeds_inverted_table[breed_name]
    local tracked_overlay = mod.tracked_units.overlay_breeds_inverted_table[breed_name]
    if tracked_notif or tracked_overlay then
        table.insert(mod.tracked_units.units[breed_name], unit)
        mod.tracked_units.refresh_unit_count(breed_name)
    end
    return({notif = tracked_notif, overlay = tracked_overlay})
end

-----------------------------------------------------------------
--- Part 1: Initialising the HUD element
-----------------------------------------------------------------

local hud_element = {
	class_name = "HudElementSpecialsTracker",
	filename = "SpecialsTracker/scripts/mods/SpecialsTracker/SpecialsTracker_HUDElement",
    use_hud_scale = true,
	visibility_groups = {
		"dead",
		"alive",
	},
}

mod:add_require_path(hud_element.filename)

local add_hud_element = function(elements)
	local i, t = table.find_by_key(elements, "class_name", hud_element.class_name)
	if not i or not t then
		table.insert(elements, hud_element)
	else
		elements[i] = hud_element
	end
end

mod:hook_require("scripts/ui/hud/hud_elements_player", add_hud_element)
mod:hook_require("scripts/ui/hud/hud_elements_player_onboarding", add_hud_element)

-----------------------------------------------------------------
--- Part 2: Callbacks & keybind-triggered utilities
-----------------------------------------------------------------

mod.on_game_state_changed = function(status, state_name)
    if status == "enter" and state_name == "GameplayStateRun" then
        mod.tracked_units.init()
    end
end

mod.on_setting_changed = function(setting_id)
    local messages = {}
    local is_tracking_method_setting = string.match(setting_id, "(.+)_overlay$") or string.match(setting_id, "(.+)_notif$") -- or setting_id
    local is_priority_setting = string.match(setting_id, "(.+)_priority$") -- or setting_id
    local is_color_setting = string.match(setting_id, "color_(.+)$")
    -- if mod.interesting_breed_names.inverted_table[setting_id_tracking_method] then
    if is_tracking_method_setting then
        mod.tracked_units.init()
        table.insert(messages, "Breed tracking method changed - Tracked breeds reset")
    end
    if setting_id == "hud_element_scale" then
        mod.hud_refresh_flags.scale = true
        table.insert(messages, "HUD scale changed - Flagged for redefinition")
    end
    if is_priority_setting then
        mod.hud_refresh_flags.color = true
        table.insert(messages, "Breed priority changed - Flagged for redefinition")
    end
    if is_color_setting then
        -- Currently, color settings are for priority levels, which only affect notifs, not the HUD overlay
        mod.color.init()
        -- mod.hud_refresh_flags.color = true
        table.insert(messages, "Color changed - Colors reinitialised")
    end
    if setting_id == "font" then
        mod.hud_refresh_flags.font = true
        table.insert(messages, "Font changed - Flagged for redefinition")
    end
    for _, message in pairs(messages) do
        Managers.event:trigger("event_add_notification_message", "default", message)
    end
end

function mod.reset_unit_counter()
    mod.tracked_units.init()
    mod.hud_refresh_flags.color = true
    local message = "Tracked breeds reset - HUD colors flagged for redefinition"
    Managers.event:trigger("event_add_notification_message", "default", message)
end

-----------------------------------------------------------------
--- Part 3: Notification utilities
-----------------------------------------------------------------

mod:hook("ConstantElementNotificationFeed", "_generate_notification_data", function(func, self, message_type, data)
    if message_type == "spawn" or message_type == "death" then
        local notif_data = {
            type = "default",
            show_shine = true,
            glow_opacity = 0.35,
            texts = {
                {
                    display_name = data
                }
            },
            color = mod.color.notif.table[message_type],
            line_color = {255, 255, 255, 255},
            -- scale_icon = true,
            -- icon = icon,
            -- item = visual_item,
            -- icon_size = icon_size,
            -- icon_material_values = icon_material_values,
            -- enter_sound_event = enter_sound_event
            -- exit_sound_event = exit_sound_event
        }
        notif_data.enter_sound_event = notif_data.enter_sound_event or UISoundEvents.notification_default_enter
        notif_data.exit_sound_event = notif_data.exit_sound_event or UISoundEvents.notification_default_exit
        return notif_data
    else
        func(self, message_type, data)
    end
end)

local get_breed_presentation_name = function(breed)
    -- Argument: A breed name
    -- Returns: nil if the unit doesn't have a breed or display name, the unit's (colored) display name otherwise
    local clean_breed_name = string.match(breed.name, "(.+)_mutator$") or breed.name
    -- breed_name and breed.name would return the same thing because of how breeds are coded EXCEPT for mutator units, which have "_mutator" at the end of breed.name, but not breed_name
    local localised_name = mod:localize(clean_breed_name) or Localize(breed.display_name)
    local breed_priority = tostring(mod:get(clean_breed_name.."_priority"))
    --[[
    local r = mod:get("color_r_"..tostring(breed_priority))
    local g = mod:get("color_g_"..tostring(breed_priority))
    local b = mod:get("color_b_"..tostring(breed_priority))
    local color = { 255, r, g, b }
    --]]
    local this_color = mod.color.notif.table[breed_priority]

    -- return display_name and TextUtils.apply_color_to_text(Localize(display_name), color)
    return localised_name and TextUtils.apply_color_to_text(localised_name, this_color)
end

local display_notification = function(breed_name, event)
    -- Updates the active unit counter for breed and displays a spawn/death message, along with the new active unit count.
    -- NB: This function should only be called on valid *and* tracked breeds!
    -- local active_units = #mod.tracked_units.units[breed_name]
    local breed = Breeds[breed_name]
    local display_name = get_breed_presentation_name(breed)
    local message = mod:localize(event.."_message", display_name) --.." | "..tostring(active_units)
    -- local sound_event = mod:get("enable_sound") and UISoundEvents.notification_trait_received_rarity_4

    -- Managers.event:trigger("event_add_notification_message", "default", message, nil, sound_event)
    Managers.event:trigger("event_add_notification_message", event, message)
end

-----------------------------------------------------------------
--- Part 4: Enemy death notifications
-----------------------------------------------------------------

-- Hook the near-instant, but inconsistent, function that sets units dead:
mod:hook_safe(CLASS.MinionDeathManager, "set_dead", function (self, unit, attack_direction, hit_zone_name, damage_profile_name, do_ragdoll_push, herding_template_name)
    local breed_name = mod.tracked_units.record_unit_death(unit)
    if breed_name and mod.tracked_units.notif_breeds_inverted_table[breed_name] then -- mod:get(breed_name.."_notif") then
        display_notification(breed_name, "death")
    end
end)

-- Catch any dead unit that wasn't correctly caught by the hook:
mod.update = function(dt)
    local nb_of_deaths_per_breed = mod.tracked_units.clean_dead_units()
    for breed_name, nb_of_deaths in pairs(nb_of_deaths_per_breed) do
        -- NB: This will work well when we get to grouping notifications together!
        if mod.tracked_units.notif_breeds_inverted_table[breed_name] then -- mod:get(breed_name.."_notif") then
            for _ = 1, nb_of_deaths do
                display_notification(breed_name, "death")
            end
        end
    end
end


-----------------------------------------------------------------
--- Part 5: Enemy spawn notifications
-----------------------------------------------------------------

mod:hook_safe(CLASS.UnitSpawnerManager, "_add_network_unit", function(self, unit, game_object_id, is_husk)
    local game_session = Managers.state.game_session:game_session()
    if GameSession.has_game_object_field(game_session, game_object_id, "breed_id") then
        local breed_id = GameSession.game_object_field(game_session, game_object_id, "breed_id")
        local breed_name = NetworkLookup.breed_names[breed_id]
        local spawn_record_result = mod.tracked_units.record_unit_spawn(breed_name, unit)
        if spawn_record_result.notif then -- and mod:get(breed_name.."_notif") then
           display_notification(breed_name, "spawn")
        end
    end
end)