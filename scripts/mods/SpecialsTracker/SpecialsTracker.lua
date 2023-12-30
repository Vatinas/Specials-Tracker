local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/math")
require("scripts/foundation/utilities/color")

local Breeds = require("scripts/settings/breed/breeds")
local TextUtils = require("scripts/utilities/ui/text")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Global definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--                Refresh flags
-------------------------------------------------------

mod.hud_refresh_flags = {
    -- Each field is a flag to let the relevant piece of code to refresh the relevant values of the HUD element
    pos_or_scale = true,
    color = true,
    font = true,
    notif_settings = true,
}


-------------------------------------------------------
--                   Utilities
-------------------------------------------------------

local util = mod.utilities

util.get_breed_setting = function(breed_name, setting_suffix)
    local breed_options_name = ""
    if util.is_monster(breed_name) then
        breed_options_name = "monsters"
    else
        breed_options_name = breed_name
    end
    local setting_name = breed_options_name..setting_suffix
    if setting_name == "monsters_priority" then
        -- Monsters have their own "hidden" priority level, which is not set up in the options
        return 0
    else
        return mod:get(setting_name)
    end
end

util.sort_breed_names = function(a,b)
    -- Ordering on clean breed names, defined as a sequence of several orderings
    -- This function isn't called often, so it shouldn't be needed to store the setting above like we do with other settings; furthermore, since it's called very early, it's most likely safer and easier to fetch the settings directly
    -- Order 1 - Separate monsters and non-monsters according to the relevant setting
    local monsters_bottom = mod:get("monsters_pos") == "bottom"
    if util.is_monster(a) and not util.is_monster(b) then
        return(not monsters_bottom)
    elseif util.is_monster(b) and not util.is_monster(a) then
        return(monsters_bottom)
    else
        -- Order 2 - Separate by priority levels
        local priority_a = util.get_breed_setting(a, "_priority")
        local priority_b = util.get_breed_setting(b, "_priority")
        if priority_a < priority_b then
            return(true)
        elseif priority_a > priority_b then
            return(false)
        else
            -- Order 3 - Breeds with overlay setting "Always" come before those with "Only if active"
            local overlay_setting_a = util.get_breed_setting(a, "_overlay")
            local overlay_setting_b = util.get_breed_setting(b, "_overlay")
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


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                            Constants
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local constants = mod.global_constants

-- mod.global_constants is, hopefully, quite self-explanatory. Its components are defined in the data file, unless specified otherwise.

-------------------------------------------------------
--                  Miscellaneous
-------------------------------------------------------

--[[
constants.color.non_zero_units
    The default color used for HUD widgets when there's at least one active unit of the widget's breed.
constants.color.zero_units
    The color used for HUD widgets when there's no active unit of the widget's breed.
--]]


-------------------------------------------------------
--                trackable_breeds
-------------------------------------------------------

-- The first part of constants.trackable_breeds is defined in the data file
-- NB: A "clean breed name" is a breed_name cleaned by util.clean_breed_name, which removed possible a "_mutator" marker at the end of the breed name, *and* collapses "renegade_flamer" and "cultist_flamer" into the same clean_breed_name "flamer" in order to track them together. Unless specified otherwise, breed_name's are assumed to have been "cleaned".
--[[
constants.trackable_breeds.array
    The array of trackable breeds, sorted with monsters last, then by alphabetical order. Since we need it in this stage in the data file, it is defined there, which means we don't have access to priority level yet (see -.sort()).
constants.trackable_breeds.inv_table
    constants.trackable_breeds.inv_table[breed_name] = true if breed_name is trackable by the mod, nil otherwise.
constants.trackable_breeds.sort()
    Re-sorts interesting_breed_names, not only by tag then alphabetically, but also by priority order between those two orders.
--]]

-- constants.trackable_breeds:init()
constants.trackable_breeds.sort = function()
    -- Re-sorts interesting_breed_names, not only by tag then alphabetically, but also by priority order between those two
    -- Fetches the mod options directly, so no need to initialise any mod.settings field
    table.sort(constants.trackable_breeds.array, util.sort_breed_names)
end
constants.trackable_breeds.sort()

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                             Settings
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local settings = mod.settings

-- mod.settings stores various mod settings, as well as values/methods that depend on them. Its components are defined in the data file, unless specified otherwise.

-------------------------------------------------------
--                     notif
-------------------------------------------------------

--[[
settings.notif:init()
    Fetches relevant game settings and stores them in various fields of settings.notif
settings.notif.display_type
    The current notif display type, either "icon" or "text".
    Associated setting: "notif_display_type"
settings.notif.grouping
    Boolean; whether spawn and death notifs pertaining to a same breed should be combined in a single "hybrid" notif
    Associated setting: "notif_grouping"
--]]

-------------------------------------------------------
--                     color
-------------------------------------------------------

-- settings.color:init() is defined in this file, below this summary
--[[
settings.color:init()
    Fetches relevant game settings and stores them in various fields of settings.color
settings.color.notif[index / "text_gradient"] - Everything related the notifications' colors.
    settings.color.notif[index], index being an extended event or a priority level (incl. 0)
        -.notif[event] is the color of the background of the extended event notification, and -.notif[priority_level] is the color of the name of units belonging to priority_level in notifications.
        NB: The priority_level indices are strings (e.g. "2", and not 2)
    settings.color.notif.text_gradient(t, base_color)
        t is the time since the notif's last update, and base_color is the color towards which we want the "x[count]" text to move. Returned is the color for said text at the given instant. See this function's definition for the definition of the characteristic time.

settings.color.hud[prty_lvl / "lerp_ratio"] - Everything related to the HUD element's colors. (0 incl. in the possible priority level indices)
    settings.color.hud.lerp_ratio - Stores setting "hud_color_lerp_ratio"
        The ratio used in the linear interpolation between white and the priority level notification name colors when creating the color their corresponding HUD elements will take (when at least one is active). Lower ratio = closer to white
    settings.color.hud[priority_level]
        ... is the color used for the widgets of breeds of priority level lvl when at least one unit of said breed is active.
--]]

settings.color.init = function(self)
    self.hud.lerp_ratio = mod:get("hud_color_lerp_ratio") or 0.8
    -- Initialise event notif colors, i.e. colors of the background of spawn/death/hybrid notifications
    for _, event in pairs(constants.events_extended) do
        local notif_color_evt = { }
        table.insert(notif_color_evt, mod:get("color_"..event.."_alpha"))
        for _, col in pairs({"r","g","b"}) do
            table.insert(notif_color_evt, mod:get("color_"..event.."_"..col))
        end
        self.notif[event] = notif_color_evt
    end
    for _, lvl in pairs(constants.priority_levels) do
        -- Initialise priority level notif colors, i.e. colors of the name of the units of a given priority level in their notifications
        local options_lvl_name = lvl == "0" and "monsters" or lvl
        local notif_color_lvl = { }
        local hud_color_lvl = { }
        table.insert(notif_color_lvl, 255)
        for _, col in pairs({"r","g","b"}) do
            table.insert(notif_color_lvl, mod:get("color_"..options_lvl_name.."_"..col))
        end
        self.notif[lvl] = notif_color_lvl
        -- Initialise priority level HUD colors, i.e. colors of the name of the units of a given priority level in the HUD element
        local apply_color_to_hud = mod:get("color_used_in_hud_"..options_lvl_name)
        for i=1, 4 do
            local color_code = 0
            color_code = apply_color_to_hud
            and
                math.lerp(constants.color.white[i], notif_color_lvl[i], self.hud.lerp_ratio)
            or
                constants.non_zero_units[i]
            table.insert(hud_color_lvl, color_code)
        end
        self.hud[lvl] = hud_color_lvl
    end
end

settings.color:init()


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                   Active notifs & units tables
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--                  active_notifs
-------------------------------------------------------

--[[
mod.active_notifs[extended_evt]:
    mod.active_notifs[breed_name]["spawn"/"death"]
        Has the form {id = latest_known_notif_id, count = notif_multiplicity}, where a notif's "multiplicity" is the number of relevant events it denotes - e.g. "Sniper died x4" has multiplicity 4.
    mod.active_notifs[breed_name]["hybrid"]
        Has the form {id = latest_known_notif_id, count_spawn = notif_spawn_multiplicity, count_spawn = notif_spawn_multiplicity}.
The notif id's are *not* necessarily cleared when a notif expires
--]]

mod.active_notifs = {}
for _, breed_name in pairs(constants.trackable_breeds.array) do
    mod.active_notifs[breed_name] = {}
    for _, event in pairs(constants.events) do
        mod.active_notifs[breed_name][event] = {
            id = nil,
            count = 0
        }
    end
    mod.active_notifs[breed_name]["hybrid"] = {
        id = nil,
        count_spawn = 0,
        count_death = 0,
    }
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
    mod.tracked_units.<tracking method>_breeds_array
        Array containing the breed names tracked with [tracking_method], which can be "notif" or "overlay". Array is sorted according to the util.sort_breed_names order
    mod.tracked_units.<tracking method>_breeds_inverted_table
        mod.tracked_units.[tracking_method]_breeds_inverted_table[breed_name] = true if breed_name is tracked by [tracking_method], nil otherwise
    mod.tracked_units.overlay_breeds.only_if_active
        mod.tracked_units.overlay_breeds.only_if_active[breed_name] = true if breed_name should only be shown in the overlay if it's active, nil otherwise
    mod.tracked_units.priority_levels
        mod.tracked_units.priority_levels[breed_name] is the tostring'd version of the breed's priority level

Methods:
    mod.tracked_units:init()
        Initialises mod.tracked_units.breeds_array and mod.tracked_units.breeds_inverted_table so they can be used to fetch tracked breeds.
        NB: This does not reset the -.units and -.unit_count tables, but since we constantly purge the dead units from -.units and only insert it with spawning units that are tracked (i.e. in the tables the -:init() function refreshes), untracked breeds will slowly be emptied of units naturally when they died.
        Initialises mod.tracked_units.breeds_array and mod.tracked_units.breeds_inverted_table so they can be used to fetch tracked breeds.
        NB: This does not reset the -.units and -.unit_count tables, but since we constantly purge the dead units from -.units and only insert it with spawning units that are tracked (i.e. in the tables the -:init() function refreshes), untracked breeds will slowly be emptied of units naturally when they died.
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
for _, breed_name in pairs(constants.trackable_breeds.array) do
    mod.tracked_units.units[breed_name] = {}
    mod.tracked_units.unit_count[breed_name] = 0
end

mod.tracked_units.init = function(self)
    self.priority_levels = { }
    self.notif_breeds = {
        array = { },
        inv_table = { },
    }
    self.overlay_breeds = {
        array = { },
        inv_table = { },
        only_if_active = { },
    }
    for _, breed_name in pairs(constants.trackable_breeds.array) do
        self.priority_levels[breed_name] = tostring(util.get_breed_setting(breed_name, "_priority"))
        if util.get_breed_setting(breed_name, "_notif") then
            table.insert(self.notif_breeds.array, breed_name)
            self.notif_breeds.inv_table[breed_name] = true
        end
        local overlay_setting = util.get_breed_setting(breed_name, "_overlay")
        if overlay_setting == "always" or overlay_setting == "only_if_active" then
            table.insert(self.overlay_breeds.array, breed_name)
            self.overlay_breeds.inv_table[breed_name] = true
        end
        if overlay_setting == "only_if_active" then
            self.overlay_breeds.only_if_active[breed_name] = true
        end
    end
    table.sort(self.notif_breeds.array, util.sort_breed_names)
    table.sort(self.overlay_breeds.array, util.sort_breed_names)
    mod.hud_refresh_flags.pos_or_scale = true
end

mod.tracked_units:init()


mod.tracked_units.refresh_unit_count = function(breed_name)
    -- Should only be called on a valid breed_name!
    local old_unit_count = mod.tracked_units.unit_count[breed_name] or 0
    local new_unit_count = #mod.tracked_units.units[breed_name] or 0
    mod.tracked_units.unit_count[breed_name] = new_unit_count
    if mod.tracked_units.overlay_breeds.only_if_active[breed_name] then
        local one_count_was_zero = old_unit_count * new_unit_count == 0
        local one_count_was_non_zero = old_unit_count + new_unit_count ~= 0
        local up_to_mult_of_ten = (new_unit_count%10 == 0 and old_unit_count%10 == 9)
        local down_from_mult_of_ten = (new_unit_count%10 == 9 and old_unit_count%10 == 0)
        if one_count_was_zero and one_count_was_non_zero then
        -- If the relevant option is toggled on, check whether the unit count changed from zero to non-zero or vice-versa
            mod.hud_refresh_flags.pos_or_scale = true
        end
        if up_to_mult_of_ten or down_from_mult_of_ten then
        -- If a unit count goes from a multiple of 10 to the multiple of 10 minus 1 (or vice-versa), flag the hud pos/scale to be redefined to account for the fact that, for instance, "10" is larger in visual size than "9", and as such, the size of the background might need to be extended or shortened to the right of the numbers
            mod.hud_refresh_flags.pos_or_scale = true
        end
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
    local breed_name = raw_breed_name and util.clean_breed_name(raw_breed_name)
    local units_table = mod.tracked_units.units[breed_name]
    if not units_table then
        return
    end
    local unit_index = table.index_of(units_table, unit)
    if unit_index ~= -1 then
        table.remove(units_table, unit_index)
        mod.tracked_units.refresh_unit_count(breed_name)
        return(breed_name)
    else
        if mod.tracked_units.notif_breeds.inv_table[breed_name] then
            Managers.event:trigger("event_add_notification_message", "alert", { text = "Dead unit was not known to be alive: "..Localize(breed.display_name)})
        end
    end
end

mod.tracked_units.record_unit_spawn = function(breed_name, unit)
    local tracked_notif = mod.tracked_units.notif_breeds.inv_table[breed_name]
    local tracked_overlay = mod.tracked_units.overlay_breeds.inv_table[breed_name]
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
mod:hook_require("scripts/ui/hud/hud_elements_spectator", add_hud_element)


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Notification utilities
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local ViewElementProfilePresetsSettings = require("scripts/ui/view_elements/view_element_profile_presets/view_element_profile_presets_settings")

local event_icon = function(event)
    local event_number = event == "spawn" and "13" or (event == "death" and "11" or "19")
    return ViewElementProfilePresetsSettings.optional_preset_icons_lookup["icon_"..event_number]
end

mod:hook("ConstantElementNotificationFeed", "_generate_notification_data", function(func, self, message_type, data)
    -- Add a "spawn" and a "death" notification types for our mod
    if message_type ~= "spawn" and message_type ~= "death" and message_type ~= "hybrid" then
        return(func(self, message_type, data))
    else
        local notif_data = {
            type = "default",
            show_shine = true,
            glow_opacity = 0.45,
            color = settings.color.notif[message_type],
            line_color = constants.color.white,
            priority_order = data.notif_priority,
            -- item = visual_item,
            -- icon_material_values = icon_material_values,
            -- enter_sound_event = message_type ~= "hybrid" and mod:get("sound_"..message_type) or mod:get("sound_spawn"),
            -- exit_sound_event = exit_sound_event,
        }
        if message_type == "spawn" or message_type == "death" then
            notif_data.texts = {
                {
                    display_name = data.message
                },
            }
            notif_data.enter_sound_event = mod:get("sound_"..message_type)
        else
            notif_data.texts = {
                {
                    display_name = data.message_1
                },
                {
                    display_name = data.message_2
                }
            }
            notif_data.enter_sound_event = mod:get("sound_"..data.triggering_event)
            -- NB: For hybrid notifs, the actual enter_sound_event is only played once when it's created; for instance, if a hybrid notif is created by a spawn, and thus has the spawn sound, and then a death is added to it, the sound that is replayed is the death sound directly, and not the notif's enter_sound_event (which is the spawn one)
        end
        if settings.notif.display_type == "icon" then
            notif_data.icon = event_icon(message_type)
            notif_data.scale_icon = true
            notif_data.icon_size = "medium"
        end
        notif_data.enter_sound_event = notif_data.enter_sound_event or UISoundEvents.notification_default_enter
        notif_data.exit_sound_event = notif_data.exit_sound_event or UISoundEvents.notification_default_exit
        return notif_data
    end
end)


local get_breed_color = function(breed_name)
    if mod.hud_refresh_flags.color then
        settings.color:init()
        mod.hud_refresh_flags.color = false
    end
    local breed_priority = mod.tracked_units.priority_levels[breed_name]
    return settings.color.notif[breed_priority] or constants.color.white
end

local get_breed_presentation_name = function(breed_name)
    -- Takes a cleaned breed_name, and returns the unit's (colored) display name (or nil if the cleaned breed_name is invalid, aka not localized)
    local localised_name = mod:localize(breed_name.."_notif_name")
    local this_color = get_breed_color(breed_name)

    return localised_name and TextUtils.apply_color_to_text(localised_name, this_color)
end

local add_new_notif = function(breed_name, event, data)
    -- NB: event can be "spawn", "death", or "hybrid"
    -- If event is "spawn" or "death", data doesn't matter; if it's "hybrid", data.spawn and -.death will be the respective counts
    local display_name = get_breed_presentation_name(breed_name)
    local message = mod:localize(event.."_message_simple_"..settings.notif.display_type, display_name)
    local breed_priority = mod.tracked_units.priority_levels[breed_name]
    local notif_priority = 5 - tonumber(breed_priority)
    -- Breed priorities are such that higher number = lower priority, but the game's notif priorities are such that higher number = higher priority, so we need to reverse our priority
    local texts = { }
    if event ~= "hybrid" then
        texts = {
            message = message,
            notif_priority = notif_priority,
        }
    else
        texts = {
            message_1 = message,
            message_2 = message,
            notif_priority = notif_priority,
            triggering_event = data.triggering_event,
        }
    end
    Managers.event:trigger(
        "event_add_notification_message",
        event,
        texts,
        function(id)
            mod.active_notifs[breed_name][event].id = id
            if event == "hybrid" then
                for _, evt in pairs(constants.events) do
                    mod.active_notifs[breed_name]["hybrid"]["count_"..evt] = data[evt]
                end
            else
                mod.active_notifs[breed_name][event].count = 1
            end
        end
    )
end


local display_notification = function(breed_name, event)
    -- Updates mod.tracked_units.unit_count[breed_name], and either displays a spawn/death notif if none are active for breed_name and event, updates and refreshes the existing one if it exists, or converts a singlar (spawn/death) notif into a hybrid one.
    -- NB: This function should only be called on valid breeds
    local constant_elements = Managers.ui and Managers.ui:ui_constant_elements()
    local notif_element = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
    local active_notif_info = mod.active_notifs[breed_name][event]
    local id_or_nil = active_notif_info.id

    if id_or_nil and notif_element:_notification_by_id(id_or_nil) then
        -->> The notif for breed_name and event still exists, let's update it
        local notif = notif_element:_notification_by_id(id_or_nil)
        -- Increase the multiplicity counter (which will cause the text to be updated at the next tick of update)
        active_notif_info.count = active_notif_info.count + 1
        -- Reset notif time:
        notif.time = 0
        -- Replay notif sound:
        local sound_event = notif.enter_sound_event
        if sound_event then
            Managers.ui:play_2d_sound(sound_event)
        end
    else
        -->> There's no notif for breed_name and event
        if not settings.notif.grouping then
            --> If notifs are not grouped, display a new one
            add_new_notif(breed_name, event, nil)
        else
            --> If they are grouped:
            local other_event = event == "spawn" and "death" or "spawn"
            local other_evt_active_notif_info = mod.active_notifs[breed_name][other_event]
            local other_evt_id_or_nil = other_evt_active_notif_info.id
            local hybrid_active_notif_info = mod.active_notifs[breed_name]["hybrid"]
            local hybrid_id_or_nil = hybrid_active_notif_info.id

            if hybrid_id_or_nil and notif_element:_notification_by_id(hybrid_id_or_nil) then
                -- There already is a hybrid notif to update
                local hybrid_notif = notif_element:_notification_by_id(hybrid_id_or_nil)
                -- Increase the multiplicity counter
                hybrid_active_notif_info["count_"..event] = hybrid_active_notif_info["count_"..event] + 1
                -- Reset notif time:
                hybrid_notif.time = 0
                -- Replay notif sound:
                local sound_event = mod:get("sound_"..event)--hybrid_notif.enter_sound_event
                if sound_event then
                    Managers.ui:play_2d_sound(sound_event)
                end
            elseif other_evt_id_or_nil and notif_element:_notification_by_id(other_evt_id_or_nil) then
                -- There is an other_evt notif to turn hybrid
                local data = {}
                data[event] = 1
                data[other_event] = other_evt_active_notif_info.count
                data.triggering_event = event
                --hybrid_active_notif_info["count_"..event] = 1
                --hybrid_active_notif_info["count_"..other_event] = other_evt_notif.count
                add_new_notif(breed_name, "hybrid", data)
                Managers.event:trigger("event_remove_notification", other_evt_id_or_nil)
                mod.active_notifs[breed_name][event] = {
                    id = nil,
                    count = 0,
                }
                mod.active_notifs[breed_name][other_event] = {
                    id = nil,
                    count = 0,
                }
            else
                -- Otherwise, just create a new notif
                add_new_notif(breed_name, event, nil)
            end
        end
    end
end

-- The following function is called every tick of mod.update to make the "x[count]" text's color start with a bright color, and move along a gradient towards another, more "tame" color
local refresh_notif_text_colors = function()
    local constant_elements = Managers.ui and Managers.ui:ui_constant_elements()
    local notif_element = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
    for _, breed_name in pairs(constants.trackable_breeds.array) do
        local notif_type = settings.notif.display_type
        -- Hybrid notifs:
        local hybrid_notif_info = mod.active_notifs[breed_name]["hybrid"]
        local hybrid_notif_id = hybrid_notif_info.id
        if hybrid_notif_id and notif_element:_notification_by_id(hybrid_notif_id) then
            local display_name = get_breed_presentation_name(breed_name)
            local hybrid_notif = notif_element:_notification_by_id(hybrid_notif_id)
            local hybrid_notif_age = hybrid_notif.time
            local hybrid_notif_color = settings.color.notif.text_gradient(hybrid_notif_age, get_breed_color(breed_name))
            local mltpl_text = {}
            for _, evt in pairs(constants.events) do
                mltpl_text[evt] = notif_type == "icon"
                and tostring(hybrid_notif_info["count_"..evt])
                or "x"..tostring(hybrid_notif_info["count_"..evt])
                mltpl_text[evt] = TextUtils.apply_color_to_text(mltpl_text[evt], hybrid_notif_color)
            end
            --local mltpl_text_death = TextUtils.apply_color_to_text(tostring(hybrid_notif_info["count_death"]), hybrid_notif_color)
            local hybrid_message_1 = mod:localize("hybrid_message_grouped_1_"..notif_type, display_name)
            local hybrid_message_2 = mod:localize("hybrid_message_grouped_2_"..notif_type, mltpl_text["spawn"], mltpl_text["death"])
            local hybrid_texts = { hybrid_message_1, hybrid_message_2 }
            notif_element:_set_texts(hybrid_notif, hybrid_texts)
        end
        -- Spawn/death notifs:
        for _, event in pairs(constants.events) do
            local this_notif_info = mod.active_notifs[breed_name][event]
            local this_notif_id = this_notif_info.id
            local this_notif_multiplicity = this_notif_info.count
            local this_notif = notif_element:_notification_by_id(this_notif_id)
            if this_notif and this_notif_multiplicity > 1 then
                -- In this case, the notif's text's color should be updated
                local display_name = get_breed_presentation_name(breed_name)
                local this_notif_age = this_notif.time
                local this_notif_color = settings.color.notif.text_gradient(this_notif_age, get_breed_color(breed_name))
                local mltpl_text = notif_type == "icon"
                and TextUtils.apply_color_to_text("x"..tostring(this_notif_multiplicity), this_notif_color) 
                or TextUtils.apply_color_to_text("x"..tostring(this_notif_multiplicity), this_notif_color)
                local message = mod:localize(event.."_message_"..notif_type, display_name, mltpl_text)
                local texts = { message }
                notif_element:_set_texts(this_notif, texts)
            end
        end
    end
end

-- Removes all mod notifs from the notification feed. Meant to be called at the end of a game, but not yet implemented.
--[[
local clear_notifs = function()
    for _, breed_name in pairs(constants.trackable_breeds.array) do
        for _, event in pairs(constants.events) do
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
        mod.tracked_units:init()
    end
    local message = state_name.." ("..status..")"
    mod:echo(message)
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
        mod.tracked_units:init()
        -- NB: mod.tracked_units:init() sets the pos_or_scale flag to true, so no need to do it manually here
    elseif setting_id == "hud_scale" then
        mod.hud_refresh_flags.pos_or_scale = true
    elseif is_priority_setting then
        mod.hud_refresh_flags.color = true
    elseif is_color_setting then
        mod.hud_refresh_flags.color = true
    elseif setting_id == "font" then
        mod.hud_refresh_flags.font = true
    elseif setting_id == "notif_display_type" or setting_id == "notif_grouping" then
        mod.hud_refresh_flags.notif = true
    end
end


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
    if breed_name and mod.tracked_units.notif_breeds.inv_table[breed_name] then
        display_notification(breed_name, "death")
    end
end)

-- Tracking method [2]
mod.update = function(dt)
    local nb_of_deaths_per_breed = mod.tracked_units.clean_dead_units()
    for breed_name, nb_of_deaths in pairs(nb_of_deaths_per_breed) do
        -- NB: This works well with how we handle the grouping of "duplicate" notifs
        if mod.tracked_units.notif_breeds.inv_table[breed_name] then
            for _ = 1, nb_of_deaths do
                display_notification(breed_name, "death")
            end
        end
    end
    -- Update multiplicit notifs color
    refresh_notif_text_colors()
    -- Refresh notif settings if needed
    if mod.hud_refresh_flags.notif then
        settings.notif:init()
        mod.hud_refresh_flags.notif = false
    end
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
        local breed_name = util.clean_breed_name(raw_breed_name)
        local spawn_record_result = mod.tracked_units.record_unit_spawn(breed_name, unit)
        if spawn_record_result.notif then
           display_notification(breed_name, "spawn")
        end
    end
end)