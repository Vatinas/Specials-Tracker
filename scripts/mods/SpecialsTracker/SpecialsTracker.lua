local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/math")
require("scripts/foundation/utilities/color")

local Breeds = require("scripts/settings/breed/breeds")
local TextUtils = require("scripts/utilities/ui/text")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local ConstantElementNotificationFeed = require("scripts/ui/constant_elements/elements/notification_feed/constant_element_notification_feed")

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Global definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--               Generic utilities
-------------------------------------------------------

mod.hud_refresh_flags = {
    -- Each field is a flag to let the relevant piece of code to refresh the relevant values of the HUD element
    pos_or_scale = false,
    color = false,
    font = false,
}

mod.get_breed_setting = function(breed_name, setting_suffix)
    local breed_options_name = ""
    if mod.is_monster(breed_name) then
        breed_options_name = "monsters"
    else
        breed_options_name = breed_name
    end
    return mod:get(breed_options_name..setting_suffix)
end

mod.sort_breed_names = function(a,b)
    -- Ordering on clean breed names, defined as a sequence of several orderings
    -- NB: We check if Breeds[a] exists in case a, a clean breed_name, is "flamer" (for instance) which isn't a valid breed
    -- Order 1 - Monsters after non-monsters
    if mod.is_monster(a) and not mod.is_monster(b) then
        return(false)
    elseif mod.is_monster(b) and not mod.is_monster(a) then
        return(true)
    else
        -- Order 2 - Separate by priority levels
        local priority_a = mod.get_breed_setting(a, "_priority")
        local priority_b = mod.get_breed_setting(b, "_priority")
        if priority_a < priority_b then
            return(true)
        elseif priority_a > priority_b then
            return(false)
        else
            -- Order 3 - Breeds with overlay setting "Always" come before those with "Only if active"
            local overlay_setting_a = mod.get_breed_setting(a, "_overlay")
            local overlay_setting_b = mod.get_breed_setting(b, "_overlay")
            if overlay_setting_a == "always" and overlay_setting_b == "only_if_active" then
                return true
            elseif overlay_setting_b == "always" and overlay_setting_a == "only_if_active" then
                return false
            else
                -- Order 4 - Alphabetical order
                return(mod:localize(a) < mod:localize(b))
            end
        end
    end
end

-------------------------------------------------------
--                     color
-------------------------------------------------------

-- The first part of mod.color is defined in the data file
--[[
mod.color.init()
    fetches the game settings and stores them in various attributes of mod.color.
mod.color.indices
    All valid color indices, i.e. events ("spawn" and "death") and the priority levels (as of writing this, integers from 1 to 4)
mod.color.notif_multpl
    The bright color used for the "x[count]" text in event notifs right when the count changes.
mod.color.new_notif_gradient(t, base_color)
    t is the time since the notif's last update, and base_color is the color towards which we want the "x[count]" text to move. Returned is the color for said text at the given instant. See this function's definition for the definition of the characteristic time.
mod.color.notif - Everything else related the notifications' colors.
    mod.color.notif.table - Table indexed by valid indices.
        -.table[event] is the color of the background of the event notification, and -.table[priority_level] is the color of the name of units belonging to priority_level in notifications.
        NB: The priority_level indices are strings (e.g. "2", and not 2) - although with the discovery of tonumber, we could maybe try to handle priority levels as integers if it turns out to be easier.
mod.color.hud - Everything related to the HUD element's colors.
    -- NEXT FIELD SHOULD BE OBSOLETE
    -- mod.color.hud.monster_only_if_alive - Stores setting "monsters_hud_only_if_alive"
    --     A boolean describing whether the widgets tracking monsters should be hidden when none are active
    mod.color.hud.use_color_priority_lvl - Table such that -.use_color_priority[lvl] stores setting "color_used_in_hud_"..lvl
        The stored setting for priority level lvl is a boolean that determines whether priority level lvl uses a color different from the base "non-zero units active" color in its HUD widget. (This color is further described in the following entries)
        mod.color.hud.use_color_priority_lvl[color_index] = mod:get("color_used_in_hud_"..color_index)
    mod.color.hud.lerp_ratio - Stores setting "hud_color_lerp_ratio"
        The ratio used in the linear interpolation between white and the priority level notification name colors when creating the color their corresponding HUD elements will take (when at least one is active).
        NB: Lower ratio = closer to white
    mod.color.hud.table - Table storing various HUD colors:
        mod.color.hud.table.non_zero_units = {255, 255, 255, 255}
            The default color used for HUD widgets when there's at least one active unit of the widget's breed.
        mod.color.hud.table.zero_units = {160, 180, 180, 180}
            The color used for HUD widgets when there's no active unit of the widget's breed.
        mod.color.hud.table[lvl]
            ... is the color used for the widgets of breeds of priority level lvl when at least one unit of said breed is active.
--]]

mod.color.init = function()
    mod.color.hud.lerp_ratio = mod:get("hud_color_lerp_ratio") or 0.8

    -- Initialise event mod colors, i.e. colors of the background of spawn/death notifications
    for _, event in pairs(mod.events) do
        local notif_color_evt = { }
        table.insert(notif_color_evt, mod:get("color_"..event.."_alpha"))
        for _, col in pairs({"r","g","b"}) do
            table.insert(notif_color_evt, mod:get("color_"..event.."_"..col))
        end
        mod.color.notif.table[event] = notif_color_evt
    end

    -- Initialise hud mod colors, i.e. the color a breed's widget will take if at least one unit is alive
    -- This color can be a linear extrapolation between white and the breed's priority level's notification color, or a default non-zero color if toggled off
    for _, lvl in pairs(mod.priority_levels) do
        local notif_color_lvl = { }
        local hud_color_lvl = { }
        table.insert(notif_color_lvl, 255)
        for _, col in pairs({"r","g","b"}) do
            table.insert(notif_color_lvl, mod:get("color_"..lvl.."_"..col))
        end
        mod.color.notif.table[lvl] = notif_color_lvl
        for i=1, 4 do
            local color_code = 0
            if mod:get("color_used_in_hud_"..lvl) then
                color_code = math.lerp(mod.color.white[i], notif_color_lvl[i], mod.color.hud.lerp_ratio)
            else
                color_code = mod.color.hud.table.non_zero_units[i]
            end
            table.insert(hud_color_lvl, color_code)
        end
        mod.color.hud.table[lvl] = hud_color_lvl
    end
end

mod.color.init()


-------------------------------------------------------
--             interesting_breed_names
-------------------------------------------------------

-- The first part of mod.interesting_breed_names is defined in the data file
-- NB: A "clean breed name" is a breed_name cleaned by mod.clean_breed_name, which removed possible a "_mutator" marker at the end of the breed name, *and* collapses "renegade_flamer" and "cultist_flamer" into the same clean_breed_name "flamer" in order to track them together. Unless specified otherwise, breed_name's are assumed to have been "cleaned".
--[[
mod.interesting_breed_names.array
    The array of trackable breeds, sorted with monsters last, then by alphabetical order. Since we need it in this stage in the data file, it is defined there, which means we don't have access to priority level yet (see -.sort()).
mod.interesting_breed_names.inverted_table
    mod.interesting_breed_names.inverted_table[breed_name] = true if breed_name is trackable by the mod, nil otherwise.
mod.interesting_breed_names.sort()
    Re-sorts interesting_breed_names, not only by tag then alphabetically, but also by priority order between those two orders.
--]]

-- mod.interesting_breed_names.init()
mod.interesting_breed_names.sort = function()
    -- Re-sorts interesting_breed_names, not only by tag then alphabetically, but also by priority order between those two
    table.sort(mod.interesting_breed_names.array, mod.sort_breed_names)
end
mod.interesting_breed_names.sort()


-------------------------------------------------------
--                 active_notifs
-------------------------------------------------------

-- Doubly indexed table containing the last known id of active notifications, as well as their multiplicity (e.g. "Sniper died x4" has multiplicity 4).
-- The notif id's are *not* cleared when a notif expires!

mod.active_notifs = {}
for _, breed_name in pairs(mod.interesting_breed_names.array) do
    mod.active_notifs[breed_name] = {}
    for _, event in pairs(mod.events) do
        mod.active_notifs[breed_name][event] = {
            id = nil,
            count = 0
        }
    end
end

-------------------------------------------------------
--                 tracked_units
-------------------------------------------------------

mod.tracked_units = {}
--[[
Data:
    mod.tracked_units.units[breed_name]
        An *array* containing active units of breed_name. Will be tracked to purge dead units regardless of whether breed_name is tracked or not, but spawned units will only be added to it if the breed is tracked.
        NB: -.units[breed_name] will never be nil
    mod.tracked_units.unit_count[breed_name]
        The number of active units of breed_name (which is simply #mod.tracked_units.unit_count[breed_name], but is stored separately to avoid checking the array size at every HUD element update)
        NB: -.unit_count[breed_name] will never be nil
    mod.tracked_units.[tracking method]_breeds_array
        Array containing the breed names tracked with [tracking_method], which can be "notif" or "overlay". Array is sorted according to the mod.sort_breed_names order
    mod.tracked_units.[tracking_method]_breeds_inverted_table
        mod.tracked_units.[tracking_method]_breeds_inverted_table[breed_name] = true if breed_name is tracked by [tracking_method], nil otherwise
    mod.tracked_units.overlay_only_if_active
        mod.tracked_units.overlay_only_if_active[breed_name] = true if breed_name should only be shown in the overlay if it's active, nil otherwise
    mod.tracked_units.priority_levels
        mod.tracked_units.priority_levels[breed_name] is the tostring'd version of the breed's priority level

Methods:
    mod.tracked_units.init()
        Initialises mod.tracked_units.breeds_array and mod.tracked_units.breeds_inverted_table so they can be used to fetch tracked breeds.
        NB: This does not reset the -.units and -.unit_count tables, but since we constantly purge the dead units from -.units and only insert it with spawning units that are tracked (i.e. in the tables the -.init() function refreshes), untracked breeds will slowly be emptied of units naturally when they died.
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
    mod.tracked_units.priority_levels = {}
    mod.tracked_units.notif_breeds_array = {}
    mod.tracked_units.notif_breeds_inverted_table = {}
    mod.tracked_units.overlay_breeds_array = {}
    mod.tracked_units.overlay_breeds_inverted_table = {}
    mod.tracked_units.overlay_only_if_active = {}
    for _, breed_name in pairs(mod.interesting_breed_names.array) do
        mod.tracked_units.priority_levels[breed_name] = tostring(mod.get_breed_setting(breed_name, "_priority"))
        if mod.get_breed_setting(breed_name, "_notif") then
            table.insert(mod.tracked_units.notif_breeds_array, breed_name)
            mod.tracked_units.notif_breeds_inverted_table[breed_name] = true
        end
        local overlay_setting = mod.get_breed_setting(breed_name, "_overlay")
        if overlay_setting == "always" or overlay_setting == "only_if_active" then
            table.insert(mod.tracked_units.overlay_breeds_array, breed_name)
            mod.tracked_units.overlay_breeds_inverted_table[breed_name] = true
        end
        if overlay_setting == "only_if_active" then
            mod.tracked_units.overlay_only_if_active[breed_name] = true
        end
    end
    table.sort(mod.tracked_units.notif_breeds_array, mod.sort_breed_names)
    table.sort(mod.tracked_units.overlay_breeds_array, mod.sort_breed_names)
    mod.hud_refresh_flags.pos_or_scale = true
end

mod.tracked_units.init()


mod.tracked_units.refresh_unit_count = function(breed_name)
    -- Should only be called on a valid breed_name!
    local old_unit_count = mod.tracked_units.unit_count[breed_name] or 0
    local new_unit_count = #mod.tracked_units.units[breed_name] or 0
    mod.tracked_units.unit_count[breed_name] = new_unit_count
    if mod.tracked_units.overlay_only_if_active[breed_name] then
    -- If the relevant option is toggled on, check whether the unit count changed from zero to non-zero or vice-versa
        local one_count_was_zero = old_unit_count * new_unit_count == 0
        local one_count_was_non_zero = old_unit_count + new_unit_count ~= 0
        if one_count_was_zero and one_count_was_non_zero then
            mod.hud_refresh_flags.pos_or_scale = true
        end
    end
    if (new_unit_count%10 == 0 and old_unit_count%10 == 9)
    or (new_unit_count%10 == 9 and old_unit_count%10 == 0) then
        -- If a unit count goes from a multiple of 10 to the multiple of 10 minus 1 (or vice-versa), flag the hud pos/scale to be redefined to account for the fact that, for instance, "10" is larger in visual size than "9", and as such, the size of the background might need to be extended or shortened to the right of the numbers
        mod.hud_refresh_flags.pos_or_scale = true
    end
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
    local raw_breed_name = breed and breed.name
    local breed_name = raw_breed_name and mod.clean_breed_name(raw_breed_name)
    if mod.tracked_units.units[breed_name] then
        local unit_index = table.index_of(mod.tracked_units.units[breed_name], unit)
        if unit_index ~= -1 then
            table.remove(mod.tracked_units.units[breed_name], unit_index)
            mod.tracked_units.refresh_unit_count(breed_name)
            return(breed_name)
        else
            -- Unit might not be there if the mod was reset/started while the unit was already alive
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

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                HUD element (overlay) initialisation
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- See the SpecialsTracker_HUDElement file for the actual definitions

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


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Notification utilities
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod:hook("ConstantElementNotificationFeed", "_generate_notification_data", function(func, self, message_type, data)
    -- Add a "spawn" and a "death" notification types for our mod
    if message_type == "spawn" or message_type == "death" then
        local notif_data = {
            type = "default",
            show_shine = true,
            glow_opacity = 0.45,
            texts = {
                {
                    display_name = data.message
                }
            },
            color = mod.color.notif.table[message_type],
            line_color = mod.color.white,
            priority_order = data.notif_priority
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
        return(func(self, message_type, data))
    end
end)

local get_breed_color = function(breed_name)
    local breed_priority = mod.tracked_units.priority_levels[breed_name]
    return mod.color.notif.table[breed_priority]
end

local get_breed_presentation_name = function(breed_name)
    -- Argument: A cleaned breed_name
    -- Returns: nil if the breed_name is nil, the unit's (colored) display name otherwise
    local localised_name = mod:localize(breed_name.."_notif_name")
    local this_color = get_breed_color(breed_name)

    return localised_name and TextUtils.apply_color_to_text(localised_name, this_color)
end

local add_new_notif = function(breed_name, event)
    local display_name = get_breed_presentation_name(breed_name)
    local message = mod:localize(event.."_message_simple", display_name)
    local breed_priority = mod.tracked_units.priority_levels[breed_name]
    local notif_priority = 5 - tonumber(breed_priority)
    -- Breed priorities are such that higher number = lower priority, but the game's notif priorities are such that higher number = higher priority, so we need to reverse our priority
    Managers.event:trigger(
        "event_add_notification_message",
        event,
        {
            message = message,
            notif_priority = notif_priority,
        },
        function(id)
            mod.active_notifs[breed_name][event] = {id = id, count = 1}
        end
    )
end


local display_notification = function(breed_name, event)
    -- Updates mod.tracked_units.unit_count[breed_name], and either displays a spawn/death notif if none are active for breed_name and event, or updates and refreshes the existing one if it exists.
    -- NB: This function should only be called on valid breeds!
    local constant_elements = Managers.ui and Managers.ui:ui_constant_elements()
    local notif_element = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
    local display_name = get_breed_presentation_name(breed_name)
    local active_notif_info = mod.active_notifs[breed_name][event]
    local id_or_nil = active_notif_info.id

    if not id_or_nil then
        add_new_notif(breed_name, event)
    else
        local notif_or_nil = notif_element:_notification_by_id(id_or_nil)
        if not notif_or_nil then
            -- The notif id existed, but the corresponding notif expired
            add_new_notif(breed_name, event)
        else
            -- The found notif still exists, let's update it
            active_notif_info.count = active_notif_info.count + 1
            local notif_multiplicity = "  "..TextUtils.apply_color_to_text("x"..tostring(active_notif_info.count), mod.color.notif_multpl)
            local message = mod:localize(event.."_message", display_name, notif_multiplicity)
            -- Update notif text:
            local texts = { message }
            notif_element:_set_texts(notif_or_nil, texts)
            -- Reset notif time:
            notif_or_nil.time = 0
            -- Replay notif sound:
            local sound_event = notif_or_nil.enter_sound_event
			if sound_event then
				Managers.ui:play_2d_sound(sound_event)
			end
        end
    end
end

-- The following function is called every tick of mod.update to make the "x[count]" text's color start with a bright color, and move along a gradient towards another, more "tame" color
local refresh_notif_text_colors = function()
    local constant_elements = Managers.ui and Managers.ui:ui_constant_elements()
    local notif_element = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
    for _, breed_name in pairs(mod.interesting_breed_names.array) do
        for _, event in pairs(mod.events) do
            local this_notif_info = mod.active_notifs[breed_name][event]
            local this_notif_id = this_notif_info.id
            local this_notif_multiplicity = this_notif_info.count
            local this_notif = notif_element:_notification_by_id(this_notif_id)
            if this_notif and this_notif_multiplicity > 1 then
                -- In this case, the notif's text's color should be updated
                local this_notif_age = this_notif.time
                local this_notif_color = mod.color.new_notif_gradient(this_notif_age, get_breed_color(breed_name))
                --local breed = Breeds[breed_name]
                local display_name = get_breed_presentation_name(breed_name)
                local mltpl_text = "- "..TextUtils.apply_color_to_text("x"..tostring(this_notif_multiplicity), this_notif_color)
                local message = mod:localize(event.."_message", display_name, mltpl_text)
                local texts = { message }
                notif_element:_set_texts(this_notif, texts)
            end
        end
    end
end

-- Removes all mod notifs from the notification feed. Meant to be called at the end of a game, but not yet implemented.
--[[
local clear_notifs = function()
    for _, breed_name in pairs(mod.interesting_breed_names.array) do
        for _, event in pairs(mod.events) do
            local this_notif_info = mod.active_notifs[breed_name][event]
            local this_notif_id = this_notif_info.id
            Managers.event:trigger("event_remove_notification", this_notif_id)
        end
    end
end
--]]


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--              Callbacks & keybind-triggered functions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod.on_game_state_changed = function(status, state_name)
    if status == "enter" and state_name == "GameplayStateRun" then
        mod.tracked_units.init()
    end
    --[[
    if status == "exit" and state_name == "GameplayStateRun" then
        clear_notifs()
    end
    --]]
end

mod.on_setting_changed = function(setting_id)
    -- Monitor setting changes, and flag changed settings to have the variable used to store them refreshed when they're next needed
    local is_tracking_method_setting = string.match(setting_id, "(.+)_overlay$") or string.match(setting_id, "(.+)_notif$")
    local is_priority_setting = string.match(setting_id, "(.+)_priority$")
    local is_color_setting = string.match(setting_id, "color_(.+)$")
    if is_tracking_method_setting then
        mod.tracked_units.init()
        -- NB: mod.tracked_units.init() sets the pos_or_scale flag to true, so no need to do it manually here
    end
    if setting_id == "hud_scale" then
        mod.hud_refresh_flags.pos_or_scale = true
    end
    if is_priority_setting then
        mod.hud_refresh_flags.color = true
    end
    if is_color_setting then
        mod.color.init()
        mod.hud_refresh_flags.color = true
    end
    if setting_id == "font" then
        mod.hud_refresh_flags.font = true
    end
end

--[[
function mod.reset_unit_counter()
    mod.tracked_units.init()
    mod.hud_refresh_flags.color = true
    local message = "Tracked breeds reset - HUD colors flagged for redefinition"
    Managers.event:trigger("event_add_notification_message", "default", message)
end
--]]


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Tracking enemy deaths
---------------------------------------------------------------------------
---------------------------------------------------------------------------

--[[
Two methods are used conjointly to track enemy deaths:

[1] Hook the function that sets units dead. This allows us to catch and record unit deaths instantly, but only when a death actually calls this function, which strangely doesn't seem to happen for all enemy deaths.

[2] Check all currently tracked units to check if they are dead. This allows us to catch *all* enemy deaths, but enemies are sometimes set to dead a few seconds after they die from a gameplay point of view.

Method [2] is more reliable than method [1] when it comes to actually catching enemy deaths, but less reliable when it comes to being fast at recording deaths - which is why we use the two conjointly.
--]]

-- Tracking method [1]
mod:hook_safe(CLASS.MinionDeathManager, "set_dead", function (self, unit, attack_direction, hit_zone_name, damage_profile_name, do_ragdoll_push, herding_template_name)
    local breed_name = mod.tracked_units.record_unit_death(unit)
    if breed_name and mod.tracked_units.notif_breeds_inverted_table[breed_name] then
        display_notification(breed_name, "death")
    end
end)

-- Tracking method [2]
mod.update = function(dt)
    local nb_of_deaths_per_breed = mod.tracked_units.clean_dead_units()
    for breed_name, nb_of_deaths in pairs(nb_of_deaths_per_breed) do
        -- NB: This works well with how we handle the grouping of "duplicate" notifs
        if mod.tracked_units.notif_breeds_inverted_table[breed_name] then
            for _ = 1, nb_of_deaths do
                display_notification(breed_name, "death")
            end
        end
    end
    -- Update multiplicit notifs color
    refresh_notif_text_colors()
end



---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Tracking enemy spawns
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- Hook the function which adds a new unit
mod:hook_safe(CLASS.UnitSpawnerManager, "_add_network_unit", function(self, unit, game_object_id, is_husk)
    local game_session = Managers.state.game_session:game_session()
    if GameSession.has_game_object_field(game_session, game_object_id, "breed_id") then
        local breed_id = GameSession.game_object_field(game_session, game_object_id, "breed_id")
        local raw_breed_name = NetworkLookup.breed_names[breed_id]
        local breed_name = mod.clean_breed_name(raw_breed_name)
        local spawn_record_result = mod.tracked_units.record_unit_spawn(breed_name, unit)
        if spawn_record_result.notif then
           display_notification(breed_name, "spawn")
        end
    end
end)