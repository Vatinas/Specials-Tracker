local mod = get_mod("SpecialsTracker")

require("scripts/foundation/utilities/math")
require("scripts/foundation/utilities/color")

local Breeds = require("scripts/settings/breed/breeds")
local TextUtils = require("scripts/utilities/ui/text")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local ViewElementProfilePresetsSettings = require("scripts/ui/view_elements/view_element_profile_presets/view_element_profile_presets_settings")

local util = mod.utilities
local constants = mod.global_constants
local settings = mod.settings
settings.notif:init()


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Global definitions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--                   Terminology
-------------------------------------------------------

--[[
> Raw / clean breed name
    A clean breed name is a breed name that has been "cleaned" by util.clean_breed_name. By opposition, a raw breed name is one that hasn't been cleaned yet.
    This mod uses clean breed names in most every part of its code, and thus, breed names are assumed to be clean unless explicitly specified otherwise, except in the data file where we specify every time due to how frequently we need to juggle between raw and cleaned names.
    The operations applied to breed names are as follows:
        1. Removal of their possible "_mutator" marker at the end.
        2. "renegade_flamer" and "cultist_flamer" are collapsed into the same clean breed name "flamer" in order to track them together.
> Extended / base events
    A base event is "spawn" or "death". An extended event is either a base event, or "hybrid". The base events correspond to what relevant event can happen to a tracked unit that this mod will want to track, and "hybrid" is the word used to designate notifs that combine a spawn notif and a death notif - e.g. "Sniper - Spawned x3 - Died x2". By default, "event" can be assumed to correspond to base events unless specified otherwise.
> Priority levels
    An integer, ranging from 0 to 4 as of writing this, describing how "important" a breed is considered to be by the mod. A lower priority level is a higher priority, with 0 being exclusive to, and enforced on, monsters.
    A breed's priority level currently affects the following:
        1. How high it appears in the overlay, with lower priority levels beeing higher (except lvl 0, monsters, which can be displayed at the top or the bottom).
        2. The breeds are separated by priority levels in the overlay, in the form of a padding between lines when we "jump" from a priority level to another.
        3. The breed name's color in its spawn/death/hybrid notifs.
        4. Optionally, the color mentioned in 3. can be applied to the breed's text and unit number in the overlay. This HUD color is toggleable per priority level, and the lerp ratio applied between a base color and the color in 3. to get the HUD color is global and defined in the mod settings.
        5. The breed's notifications priority.
> (Color) index
    A color index (or simply index) is either an extended event or a priority level (including 0).
> Tracking method
    Either "notif" or "overlay".
> Notification multiplicity
    The count of the number of events displayed on a notif. For instance:
    - "Sniper died x3" has multiplicity 3.
    - "Sniper died" technically has multiplicity 1, but isn't used in any way that uses multiplicity.
    - "Sniper spawned x2 - died x3" has spawn multiplicity 2 and death multiplicity 3.
--]]

-------------------------------------------------------
--                Refresh flags
-------------------------------------------------------

mod.hud_refresh_flags = {
-- Each field is a flag to let the relevant piece of code know to refresh some relevant values it might be using
    pos_or_scale = true,
    color = true,
    font = true,
    notif = true,
    name_style = true,
}


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                          Utilities
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- See the creation of mod.utilities in the data file for a brief summary of what it contains
-- util is an alias for mod.utilities

util.get_breed_setting = function(breed_name, setting_suffix)
    local breed_options_name = ""
    if string.match(breed_name, "(.+)_wk") then
        breed_options_name = "monsters_wk"
    elseif util.is_monster(breed_name) then
        breed_options_name = "monsters"
    else
        breed_options_name = breed_name
    end
    local setting_name = breed_options_name.."_"..setting_suffix
    if setting_name == "monsters_priority" or setting_name == "monsters_wk_priority" then
        return 0
    else
        return mod:get(setting_name)
    end
end

util.sort_breed_names = function(a,b)
-- Ordering on clean breed names, defined as a sequence of several orderings
-- This function isn't called often, so it shouldn't be necessary to store the relevant settings like we do for other functions. Furthermore, since it's called very early, it's most likely safer and easier to fetch the settings directly
    --> Order 1 - Separate monsters and non-monsters according to the relevant setting
    local monsters_bottom = mod:get("monsters_pos") == "bottom"
    if util.is_monster(a) and not util.is_monster(b) then
        return(not monsters_bottom)
    elseif util.is_monster(b) and not util.is_monster(a) then
        return(monsters_bottom)
    else
        --> Order 2 - Weakened monsters below non-weakened monsters
        local is_weak_a = string.match(a, "(.+)_wk")
        local is_weak_b = string.match(b, "(.+)_wk")
        if util.is_monster(a) and util.is_monster(b) and is_weak_b and not is_weak_a then
            return true
        elseif util.is_monster(a) and util.is_monster(b) and is_weak_a and not is_weak_b then
            return false
        else
            --> Order 3 - Separate by priority levels
            local priority_a = util.get_breed_setting(a, "priority")
            local priority_b = util.get_breed_setting(b, "priority")
            if priority_a < priority_b then
                return true
            elseif priority_a > priority_b then
                return false
            else
                --> Order 4 - Breeds with overlay setting "Always" come before those with "Only if active"
                local overlay_setting_a = util.get_breed_setting(a, "overlay")
                local overlay_setting_b = util.get_breed_setting(b, "overlay")
                if overlay_setting_a == "always" and overlay_setting_b == "only_if_active" then
                    return true
                elseif overlay_setting_b == "always" and overlay_setting_a == "only_if_active" then
                    return false
                else
                    --> Order 5 - Alphabetical order
                    return(mod:localize(a) < mod:localize(b))
                end
            end
        end
    end
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                        Global constants
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- See the creation of mod.utilities in the data file for a brief summary of what it contains and first definitions
-- constants is an alias for mod.global_constants

-------------------------------------------------------
--                trackable_breeds
-------------------------------------------------------

-- The first part of constants.trackable_breeds is defined in the data file
--[[
constants.trackable_breeds.array
    The array of trackable breeds. Originally sorted with monsters last, then by alphabetical order. Can be sorted with the complete ordering with -.sort()
constants.trackable_breeds.inv_table
    constants.trackable_breeds.inv_table[breed_name] = true if breed_name is trackable by the mod, nil otherwise
constants.trackable_breeds.sort()
    Re-sorts interesting_breed_names with a more complete ordering than what is applied to is at its creation
--]]

constants.trackable_breeds.sort = function()
    -- Fetches the mod options directly, so no need to initialise any mod.settings field
    table.sort(constants.trackable_breeds.array, util.sort_breed_names)
end
constants.trackable_breeds.sort()


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                             Settings
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- mod.settings stores various mod settings, as well as values/methods that depend on them
-- See the creation of mod.settings in the data file for a brief summary of what it contains and first definitions
-- settings is an alias for mod.settings

settings.global_toggle:init()

-------------------------------------------------------
--                     notif
-------------------------------------------------------

--[[
settings.notif:init()
    Fetches relevant game settings and stores them in the fields of settings.notif
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

--[[
settings.color:init()
    Fetches relevant game settings and stores them in the fields of settings.color
settings.color.notif[index / "text_gradient"]
    settings.color.notif[index], index being an extended event or a priority level (incl. 0)
        -.notif[event] is the color of the background of the extended event notification, and -.notif[priority_level] is the color of the name of units belonging to priority_level in notifications.
        NB: The priority_level indices are strings (e.g. "2", and not 2)
    settings.color.notif.text_gradient(t, base_color)
        t is the time since the notif's last update, and base_color is the color towards which we want the "x[count]" text to move. Returned is the color for said text at the given instant.
settings.color.hud[prty_lvl / "lerp_ratio"]
    settings.color.hud.lerp_ratio - Stores setting "hud_color_lerp_ratio"
        The ratio used in the linear interpolation between white and the priority level notification name colors when creating the color their corresponding HUD elements will take (when at least one is active).
        Lower ratio = closer to white.
    settings.color.hud[priority_level]
        The color used for the widgets of breeds of given priority level (0 included) when at least one unit of said breed is active.
--]]

settings.color.init = function(self)
    self.hud.lerp_ratio = mod:get("hud_color_lerp_ratio") or 0.8
    -- Event notif background colors
    for _, event in pairs(constants.events_extended) do
        local notif_color_evt = { }
        table.insert(notif_color_evt, mod:get("color_"..event.."_alpha"))
        for _, col in pairs({"r","g","b"}) do
            table.insert(notif_color_evt, mod:get("color_"..event.."_"..col))
        end
        self.notif[event] = notif_color_evt
    end
    -- Priority level colors
    for _, lvl in pairs(constants.priority_levels) do
        -- Name color in notifs
        local options_lvl_name = lvl == "0" and "monsters" or lvl
        local notif_color_lvl = { }
        local hud_color_lvl = { }
        table.insert(notif_color_lvl, 255)
        for _, col in pairs({"r","g","b"}) do
            table.insert(notif_color_lvl, mod:get("color_"..options_lvl_name.."_"..col))
        end
        self.notif[lvl] = notif_color_lvl
        -- Name color in overlay
        local apply_color_to_hud = mod:get("color_used_in_hud_"..options_lvl_name)
        for i=1, 4 do
            local color_code = 0
            color_code = apply_color_to_hud
            and
                math.lerp(constants.color.white[i], notif_color_lvl[i], self.hud.lerp_ratio)
            or
                constants.color.non_zero_units[i]
            table.insert(hud_color_lvl, color_code)
        end
        self.hud[lvl] = hud_color_lvl
    end
end

settings.color:init()


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                         Package handling
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- The notif icons are from a package, which we need to load manually to ensure it is available.

mod.package = {
    name = "packages/ui/views/inventory_background_view/inventory_background_view",
    reference_name = "SpecialsTracker",
    flags = {
        loaded = false,
        loading_started = false,
        check_if_in_round = function()
            local game_state_manager = Managers.state.game_mode
            if game_state_manager and game_state_manager:game_mode_name() ~= "hub" then
                return true
            else
                return false
            end
        end,
    },
    id = nil,
    load = function(self)
        if not Managers.package:has_loaded_id(self.id) then
            self.id = Managers.package:load(
                self.name,
                self.reference_name,
                function(id)
                    self.id = id
                    self.flags.loaded = true
                end
            )
            self.flags.loading_started = true
        else
            self.flags.loaded = true
        end
    end,
    unload = function(self)
        if Managers
        and Managers.package
        and Managers.package.release then
            mod.active_notifs:clear()
            self.flags.loading_started = false
            self.flags.loaded = false
            if Managers.package:has_loaded_id(self.id) then
                Managers.package:release(self.id)
            end
            self.id = nil
        end
    end
}

-------------------------------------
-- Loading package (once and for all)

mod.package:load()


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                   Active notifs & units tables
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--                  active_notifs
-------------------------------------------------------

--[[
mod.active_notifs
    mod.active_notifs.table
        Contains the data of the last known active notif for each breed_name and extended event
        mod.active_notifs.table[breed_name]["spawn"/"death"]
            Has the form {id = latest_known_notif_id, count = notif_multiplicity}, where a notif's "multiplicity" is the number of relevant events it denotes - e.g. "Sniper died x4" has multiplicity 4.
        mod.active_notifs.table[breed_name]["hybrid"]
            Has the form {
                id = latest_known_notif_id,
                count_spawn = notif_spawn_multiplicity,
                time_spawn = time since last spawn tracked by this notif,
                count_death = notif_death_multiplicity}.
                time_death = time since last spawn tracked by this notif }
        -> NB: The notif id's/counts are *not* necessarily cleared when a notif expires
    mod.active_notifs:update(dt)
        Called each tick of global update. Clears all active notifs if relevant, or updates their various properties otherwise.
    mod.active_notifs:clear()
        Clears all active notifs.
    mod.active_notifs.is_cleared
        Is set to true whenever notifs are cleared by the previous method, and to false whenever a notif is added to the feed. Used to make -:update() faster in cutscenes/loading screens, while still allowing it to clear notifs in such situations.
    mod.active_notifs.flags
        Contains various flags used by other fields.
        mod.active_notifs.flags.game_state_clear
            Whether the game is in a state where notifs should be cleared (except for end-of-game cutscenes, which are handled separately)
        mod.active_notifs.flags.cutscene_loaded
            Whether a game win/fail cutscene is currently playing, or has been played recently. (Reset to false on entering loading screens)
        mod.active_notifs.flags.custcene_loaded_by_name["outro_win"/"outro_fail"]
            Whether the index outro has been loaded when entering a game, and is ready to played if necessary
        mod.active_notifs.flags.clear_needed
            Stores the value of (-.game_state_clear or -.cutscene_loaded).
        mod.active_notifs.flags:set(flag_name, value)
            Sets -[flag_name] to value, and updates -.clear_needed accordingly.
        mod.active_notifs.flags:init()
            Initialises all flags. Called when entering a loading screen.
--]]

mod.active_notifs = {
    table = { },
    update = nil,
    clear = nil,
    is_cleared = true,
    flags = {
        game_state_clear = false,
        cutscene_loaded = false,
        cutscene_loaded_by_name = {
            outro_win = false,
            outro_fail = false,
        },
        clear_needed = false,
        set = function(self, flag_name, value)
            self[flag_name] = value
            self.clear_needed = self.game_state_clear or self.cutscene_loaded
        end,
        init = function(self)
        -- This is called upon entering loading screens
            self.game_state_clear = true
            self.cutscene_loaded = false
            self.cutscene_loaded_by_name = {
                outro_win = false,
                outro_fail = false,
            }
            self.clear_needed = true
        end,
    },
}

for _, breed_name in pairs(constants.trackable_breeds.array) do
    mod.active_notifs.table[breed_name] = {}
    for _, event in pairs(constants.events) do
        mod.active_notifs.table[breed_name][event] = {
            id = nil,
            count = 0
        }
    end
    mod.active_notifs.table[breed_name]["hybrid"] = {
        id = nil,
        count_spawn = 0,
        time_spawn = 10000, -- Using a large number to simulate, by default, a non-recent spawn/death
        count_death = 0,
        time_death = 10000,
    }
end

mod.active_notifs.clear = function(self)
    for _, breed_name in pairs(constants.trackable_breeds.array) do
        for _, event in pairs(constants.events_extended) do
            Managers.event:trigger("event_remove_notification", self.table[breed_name][event].id)
            self.table[breed_name][event].id = nil
        end
    end
    self.is_cleared = true
end


-------------------------------------------------------
--                 tracked_units
-------------------------------------------------------

--[[
> Data:
mod.tracked_units.units[breed_name]
    An array containing active units of breed_name. Will be tracked to, every tick of update, purge dead units regardless of whether breed_name is tracked or not, but spawned units will only be added to it if the breed is tracked.
mod.tracked_units.unit_count[breed_name]
    The number of active units of breed_name (which is simply #mod.tracked_units.unit_count[breed_name], but is stored separately to avoid checking the array size at every update tick of the HUD element)
mod.tracked_units.<tracking method>_breeds_array
    Array containing the breed names tracked with <tracking_method> ("notif" or "overlay").
    Array is sorted according to util.sort_breed_names
mod.tracked_units.<tracking method>_breeds_inv_table
    Inverted table corresponding to the former array
mod.tracked_units.overlay_breeds.only_if_active
    mod.tracked_units.overlay_breeds.only_if_active[breed_name] = true if breed_name should only be shown in the overlay if it's active, nil otherwise
mod.tracked_units.priority_levels
    mod.tracked_units.priority_levels[breed_name] is the tostring'd version of the breed's priority level

> Methods:
mod.tracked_units:init()
    Initialises mod.tracked_units.<tracking_method>_breeds_array and mod.tracked_units.<tracking_method>_breeds_inv_table so they can be used to check currently tracked breeds.
    NB: This does not reset the -.units and -.unit_count tables, but since we constantly purge the dead units from -.units and only insert it with spawning units that are tracked (i.e. in the tables the -:init() function refreshes), untracked breeds will slowly be emptied of units naturally when they died.
mod.tracked_units.clean_dead_units()
    Goes through all tracked units to look for dead ones. If one is found, they are removed from their mod.tracked_units.units[breed_name] array.
    Returns a table t such that t[breed_name] is the number of dead units of breed_name that were removed, or nil if none were.
mod.tracked_units.refresh_unit_count(breed_name)
    Refreshes the value of mod.tracked_units.unit_count[breed_name].
mod.tracked_units.record_unit_spawn(breed_name, unit)
    If breed_name is tracked, adds unit to mod.tracked_units.units[breed_name], refreshes the value of mod.tracked_units.unit_count[breed_name], and returns true.
    Otherwise, does and returns nothing.
    NB: This method has 2 arguments because we were getting breed_name from the network (see the hook of "_add_network_unit"). But is it really necessary, or can we just use the unit's breed directly?
mod.tracked_units.record_unit_death(unit)
    If breed_name is tracked, removes unit from mod.tracked_units.units[breed_name], refreshes the value of mod.tracked_units.unit_count[breed_name], and returns breed_name. Otherwise, does and returns nothing.
--]]

mod.tracked_units = {
    units = {},
    unit_count = {},
}
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
        self.priority_levels[breed_name] = tostring(util.get_breed_setting(breed_name, "priority"))
        if util.get_breed_setting(breed_name, "notif") then
            table.insert(self.notif_breeds.array, breed_name)
            self.notif_breeds.inv_table[breed_name] = true
        end
        local overlay_setting = util.get_breed_setting(breed_name, "overlay")
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
    -- Should only be called on a valid breed_name
    local old_unit_count = mod.tracked_units.unit_count[breed_name] or 0
    local new_unit_count = #mod.tracked_units.units[breed_name] or 0
    mod.tracked_units.unit_count[breed_name] = new_unit_count
    if mod.tracked_units.overlay_breeds.only_if_active[breed_name] then
        local one_count_was_zero = old_unit_count * new_unit_count == 0
        local one_count_was_non_zero = old_unit_count + new_unit_count ~= 0
        if one_count_was_zero and one_count_was_non_zero then
        -- If the relevant option is toggled on, check whether the unit count changed from zero to non-zero or vice-versa
            mod.hud_refresh_flags.pos_or_scale = true
        end
    end
    local up_to_mult_of_ten = (new_unit_count%10 == 0 and old_unit_count%10 == 9)
    local down_from_mult_of_ten = (new_unit_count%10 == 9 and old_unit_count%10 == 0)
    if up_to_mult_of_ten or down_from_mult_of_ten then
        -- If a unit count goes from a multiple of 10 to one below it (or vice-versa), flag the hud pos/scale to be redefined to account for the fact that, for instance, "10" is larger visually than "9", and as such, the size of the background might need to be resized to the right of the numbers
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
    -- Get breed
    local unit_data_ext = ScriptUnit.extension(unit, "unit_data_system")
    local breed = unit_data_ext and unit_data_ext:breed()
    local raw_breed_name = breed and breed.name
    -- Get weakened boss status
    --local boss_extension = ScriptUnit.has_extension(unit, "boss_system")
    --local is_weakened = boss_extension and boss_extension:is_weakened()
    local is_weakened = util.is_weakened(unit)
    -- Get (clean) breed name and tracked units table
    local breed_name = raw_breed_name and util.clean_breed_name(raw_breed_name, is_weakened)
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

-- See the HUDElement file for the HUD element definitions

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

-------------------------------------------------------
--             Preliminary utilities
-------------------------------------------------------

local event_icon = function(event)
    local event_number = event == "spawn" and "13" or (event == "death" and "11" or "19")
    return ViewElementProfilePresetsSettings.optional_preset_icons_lookup["icon_"..event_number]
end

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


-------------------------------------------------------
--             Notification generation
-------------------------------------------------------

mod:hook("ConstantElementNotificationFeed", "_generate_notification_data", function(func, self, message_type, data)
    -- Adds "spawn", "death" and "hybrid" notification types for our mod
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
        }
        if message_type == "spawn" or message_type == "death" then
            notif_data.texts = {
                {
                    display_name = data.message
                },
            }
            notif_data.enter_sound_event = settings.notif.sound["enter_"..message_type]
        else
            notif_data.texts = {
                {
                    display_name = data.message_1
                },
                {
                    display_name = data.message_2
                }
            }
            notif_data.enter_sound_event = settings.notif.sound["enter_"..data.triggering_event]
        end
        if settings.notif.display_type == "icon"
        and Managers.package:has_loaded_id(mod.package.id) then
            notif_data.icon = event_icon(message_type)
            notif_data.scale_icon = true
            notif_data.icon_size = "medium"
        end
        notif_data.enter_sound_event = notif_data.enter_sound_event or UISoundEvents.notification_default_enter
        notif_data.exit_sound_event = notif_data.exit_sound_event or UISoundEvents.notification_default_exit
        return notif_data
    end
end)


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
            mod.active_notifs.table[breed_name][event].id = id
            if event == "hybrid" then
                for _, evt in pairs(constants.events) do
                    mod.active_notifs.table[breed_name]["hybrid"]["count_"..evt] = data[evt]
                    mod.active_notifs.table[breed_name]["hybrid"]["time_"..evt] = 0
                end
                if data["count_spawn"] == 1 then
                    mod.active_notifs.table[breed_name]["hybrid"]["time_spawn"] = data.notif_age
                else
                    mod.active_notifs.table[breed_name]["hybrid"]["time_death"] = data.notif_age
                end
                --]]
            else
                mod.active_notifs.table[breed_name][event].count = 1
            end
        end
    )
    mod.active_notifs.is_cleared = false
end


local display_notification = function(breed_name, base_event)
--> If there already is an active notif for breed_name and base_event, update and refresh it.
--> If there isn't, and notifs are not set to be grouped into hybrid notifs, display a new one.
--> If there isn't, and notifs are set to be grouped when possible:
    -- If there already is a hybrid notif for breed_name, update it.
    -- If there isn't, but there is a notif for the other event from base_event, remove said notif and create a new hybrid one.
    -- If there is neither a hybrid nor an other_base_event notif active, create a new one for base_event.

    -- NB: This function should only be called on valid breeds
    if mod.active_notifs.flags.clear_needed
    or not settings.global_toggle.notif then
    --or not mod:get("global_toggle_notif") then
        return
    end
    local constant_elements = Managers.ui and Managers.ui:ui_constant_elements()
    local notif_element = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
    local active_notif_info = mod.active_notifs.table[breed_name][base_event]
    local id_or_nil = active_notif_info.id

    if id_or_nil and notif_element:_notification_by_id(id_or_nil) then
        -->> The notif for breed_name and base_event still exists, let's update it
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
        -->> There's no notif for breed_name and base_event
        if not settings.notif.grouping then
            --> If notifs are not grouped, display a new one
            add_new_notif(breed_name, base_event, nil)
        else
            --> If they are grouped:
            local other_base_event = base_event == "spawn" and "death" or "spawn"
            local other_evt_active_notif_info = mod.active_notifs.table[breed_name][other_base_event]
            local other_evt_id_or_nil = other_evt_active_notif_info.id
            local hybrid_active_notif_info = mod.active_notifs.table[breed_name]["hybrid"]
            local hybrid_id_or_nil = hybrid_active_notif_info.id

            if hybrid_id_or_nil and notif_element:_notification_by_id(hybrid_id_or_nil) then
                -- There already is a hybrid notif to update
                local hybrid_notif = notif_element:_notification_by_id(hybrid_id_or_nil)
                -- Increase the multiplicity counter
                hybrid_active_notif_info["count_"..base_event] = hybrid_active_notif_info["count_"..base_event] + 1
                -- Reset notif time
                hybrid_notif.time = 0
                hybrid_active_notif_info["time_"..base_event] = 0
                -- Replay notif sound:
                local sound_event = settings.notif.sound["enter_"..base_event] --mod:get("sound_"..base_event)--hybrid_notif.enter_sound_event
                if sound_event then
                    Managers.ui:play_2d_sound(sound_event)
                end
            elseif other_evt_id_or_nil and notif_element:_notification_by_id(other_evt_id_or_nil) then
                -- There is an other_evt notif to turn hybrid
                local data = { }
                data[base_event] = 1
                data[other_base_event] = other_evt_active_notif_info.count
                data.notif_age = notif_element:_notification_by_id(other_evt_id_or_nil).time
                data.triggering_event = base_event
                add_new_notif(breed_name, "hybrid", data)
                Managers.event:trigger("event_remove_notification", other_evt_id_or_nil)
                mod.active_notifs.table[breed_name][base_event] = {
                    id = nil,
                    count = 0,
                }
                mod.active_notifs.table[breed_name][other_base_event] = {
                    id = nil,
                    count = 0,
                }
            else
                -- Otherwise, just create a new notif
                add_new_notif(breed_name, base_event, nil)
            end
        end
    end
end


mod.active_notifs.update = function(self, dt)
-- This function is called every tick of mod.update
-- If the relevant conditions are met, clears all notifs
-- Otherwise, if the notifs haven't been "cleared" and it's possible that there are notifs to update, updates each active notif to do the following:
-- 1. Make the "x[count]" text's color start with a bright color, and move along a gradient towards another, more "tame" color
-- 2. Gives notifications with multiplicity the right text.
    if self.is_cleared then
        return
    elseif self.flags.clear_needed then
        self:clear()
        return
    end
    local constant_elements = Managers.ui and Managers.ui:ui_constant_elements()
    local notif_element = constant_elements and constant_elements:element("ConstantElementNotificationFeed")
    local notif_type = settings.notif.display_type
    for _, breed_name in pairs(constants.trackable_breeds.array) do
        --> Hybrid notifs:
        local hybrid_notif_info = self.table[breed_name]["hybrid"]
        local hybrid_notif_id = hybrid_notif_info.id
        if hybrid_notif_id and notif_element:_notification_by_id(hybrid_notif_id) then
            local display_name_hybrid = get_breed_presentation_name(breed_name)
            local hybrid_notif = notif_element:_notification_by_id(hybrid_notif_id)
            local hybrid_notif_age = hybrid_notif.time
            local hybrid_notif_age_spawn = hybrid_notif_info.time_spawn
            local hybrid_notif_age_death = hybrid_notif_info.time_death
            local hybrid_notif_color = {
                spawn = settings.color.notif.text_gradient(hybrid_notif_age_spawn, get_breed_color(breed_name)),
                death = settings.color.notif.text_gradient(hybrid_notif_age_death, get_breed_color(breed_name)),
            }
            local mltpl_text_hbrd = {}
            for _, evt in pairs(constants.events) do
                mltpl_text_hbrd[evt] = notif_type == "icon"
                and tostring(hybrid_notif_info["count_"..evt])
                or "x"..tostring(hybrid_notif_info["count_"..evt])
                mltpl_text_hbrd[evt] = TextUtils.apply_color_to_text(mltpl_text_hbrd[evt], hybrid_notif_color[evt])
            end
            local hybrid_message_1 = mod:localize("hybrid_message_grouped_1_"..notif_type, display_name_hybrid)
            local hybrid_message_2 = mod:localize("hybrid_message_grouped_2_"..notif_type, mltpl_text_hbrd["spawn"], mltpl_text_hbrd["death"])
            local hybrid_texts = { hybrid_message_1, hybrid_message_2 }
            notif_element:_set_texts(hybrid_notif, hybrid_texts)
            hybrid_notif_info.time_spawn = hybrid_notif_info.time_spawn + dt
            hybrid_notif_info.time_death = hybrid_notif_info.time_death + dt
        end
        --> Spawn/death notifs:
        for _, event in pairs(constants.events) do
            local this_notif_info = self.table[breed_name][event]
            local this_notif_id = this_notif_info.id
            local this_notif_multiplicity = this_notif_info.count or 0
            if this_notif_id
            and notif_element:_notification_by_id(this_notif_id)
            and this_notif_multiplicity > 1 then
                local this_notif = notif_element:_notification_by_id(this_notif_id)
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


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--              Callbacks & other triggered functions
---------------------------------------------------------------------------
---------------------------------------------------------------------------

mod.on_game_state_changed = function(status, state_name)
    if state_name == "GameplayStateRun" and status == "enter" then
        mod.tracked_units:init()
    elseif state_name == "StateLoading" and status == "enter" then
        mod.active_notifs.flags:init()
        --mod.package:unload()
    elseif state_name == "StateExitToMainMenu"
    or state_name == "StateMainMenu"
    or state_name == "StateLoading" then
        mod.active_notifs.flags:set("game_state_clear", status == "enter")
    end
end

mod.on_setting_changed = function(setting_id)
-- Monitor setting changes, and flag changed settings to have the variable used to store them refreshed when they're next needed
    -- If the changed setting is a sound, play it
    local sound_name_or_nil = string.match(setting_id, "sound_(.+)$")
    if sound_name_or_nil then
        local ui_manager = Managers.ui
        local new_sound = mod:get(setting_id)
        local old_sound = settings.notif.sound["enter_"..sound_name_or_nil]
        if ui_manager and new_sound ~= old_sound then
            ui_manager:stop_2d_sound(old_sound)
            ui_manager:play_2d_sound(new_sound)
            old_sound = new_sound
        end
    end
    local is_tracking_method_setting = string.match(setting_id, "(.+)_overlay$") or string.match(setting_id, "(.+)_notif$")
    local is_priority_setting = string.match(setting_id, "(.+)_priority$")
    local is_color_setting = string.match(setting_id, "color_(.+)$")
    local is_notif_setting = string.match(setting_id, "notif_(.+)$") or string.match(setting_id, "sound_(.+)$")
    local is_global_toggle_setting = string.match(setting_id, "global_toggle_(.+)$")
    if is_global_toggle_setting then
        settings.global_toggle:init()
    elseif is_tracking_method_setting then
        mod.tracked_units:init()
        -- NB: mod.tracked_units:init() sets the pos_or_scale flag to true, so no need to do it manually here
    elseif setting_id == "hud_scale" or setting_id == "overlay_move_from_center" then
        mod.hud_refresh_flags.pos_or_scale = true
    elseif is_priority_setting then
        mod.hud_refresh_flags.color = true
    elseif is_color_setting then
        mod.hud_refresh_flags.color = true
    elseif setting_id == "font" then
        mod.hud_refresh_flags.font = true
    elseif is_notif_setting then
        mod.hud_refresh_flags.notif = true
    elseif setting_id == "overlay_name_style" then
        mod.hud_refresh_flags.name_style = true
    end
end


-------------------------------------------------------
--      Clearing mod notifs at the end of rounds
-------------------------------------------------------

mod:hook_safe("CinematicSceneExtension", "setup_from_component", function(self)
    local name = self._cinematic_name
    if (name == "outro_win" or name == "outro_fail") then
        if mod.active_notifs.flags.cutscene_loaded_by_name[name] then
            mod.active_notifs.flags:set("cutscene_loaded", true)
        else
            mod.active_notifs.flags.cutscene_loaded_by_name[name] = true
        end
    end
end)

mod:command("clear_notifs", "Clears all the active notifications.", function()
    Managers.event:trigger("event_clear_notifications")
end)


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Monitoring enemy deaths
---------------------------------------------------------------------------
---------------------------------------------------------------------------

--[[
Two methods are used conjointly to monitor enemy deaths:

[1] Hook the function that sets units dead. This allows us to catch and record unit deaths instantly, but only when a death actually calls this function, which (strangely) doesn't seem to happen for all enemy deaths.

[2] Check all currently tracked units to check if they are dead. This allows us to catch *all* enemy deaths, but enemies are sometimes set to dead a few seconds after they die from a gameplay point of view.

Method [2] is more reliable than method [1] when it comes to actually catching enemy deaths, but less reliable when it comes to being fast at recording deaths - which is why we use the two conjointly.
--]]

-- Monitoring method [1]
mod:hook_safe(CLASS.MinionDeathManager, "set_dead", function (self, unit, attack_direction, hit_zone_name, damage_profile_name, do_ragdoll_push, herding_template_name)
    local breed_name = mod.tracked_units.record_unit_death(unit)
    if breed_name and mod.tracked_units.notif_breeds.inv_table[breed_name] then
        display_notification(breed_name, "death")
    end
end)

-- Monitoring method [2]
mod.update = function(dt)
    local nb_of_deaths_per_breed = mod.tracked_units.clean_dead_units()
    for breed_name, nb_of_deaths in pairs(nb_of_deaths_per_breed) do
        if mod.tracked_units.notif_breeds.inv_table[breed_name] then
            for _ = 1, nb_of_deaths do
                display_notification(breed_name, "death")
            end
        end
    end
    -- Update notif text & text color, and clear all mod notifs if needed
    mod.active_notifs:update(dt)
    -- Refresh notif settings if needed
    if mod.hud_refresh_flags.notif then
        settings.notif:init()
        mod.hud_refresh_flags.notif = false
    end
    --[[
    -- Start loading the package if needed
    if not mod.package.flags.loading_started
    and mod.package.flags.check_if_in_round()
    and settings.notif.display_type == "icon" then
        mod.package:load()
    end
    -- Start unloading the package if needed
    if mod.package.flags.loaded
    and not mod.package.flags.check_if_in_round() then
        mod.package:unload()
    end
    --]]
end


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                      Monitoring enemy spawns
---------------------------------------------------------------------------
---------------------------------------------------------------------------

--[[
Two methods are used conjointly to monitor enemy spawns:

[1] Hooking UnitSpawnerManager._add_network_unit - This function is called in both private and public games, but monsters haven't had their monster extension initialised yet when this function is called in public games (which means their weakened status can't be accessed yet), so it is only used in private games.

[2] Hooking UnitSpawnerManager.spawn_husk_unit - This function is only called in public games, but monsters already have had their monster extension initialised when this is called.
--]]

-- Monitoring method [1]
mod:hook_safe(CLASS.UnitSpawnerManager, "_add_network_unit", function(self, unit, game_object_id, is_husk)
    local is_server = Managers.state.game_session:is_server()
    if mod:get("debugging") then
        mod:echo("is_server = "..tostring(is_server))
    end
    if not is_server then
        return
    end
    local game_session = Managers.state.game_session:game_session()
    if GameSession.has_game_object_field(game_session, game_object_id, "breed_id") then
        -- Get breed
        local breed_id = GameSession.game_object_field(game_session, game_object_id, "breed_id")
        local raw_breed_name = NetworkLookup.breed_names[breed_id]
        -- Get weakened boss status
        --local boss_extension = ScriptUnit.has_extension(unit, "boss_system")
        --local is_weakened = boss_extension and boss_extension:is_weakened()
        local is_weakened = util.is_weakened(unit)
        -- Debugging
        if mod:get("debugging") and constants.trackable_breeds.inv_table[breed_name] then
            mod:echo("--")
            mod:echo("raw_breed_name = "..tostring(raw_breed_name))
            --mod:echo("boss_extension = "..tostring(boss_extension))
            mod:echo("is_weakened = "..tostring(is_weakened))
        end
        -- Get (clean) breed name
        local breed_name = util.clean_breed_name(raw_breed_name, is_weakened)
        local spawn_record_result = mod.tracked_units.record_unit_spawn(breed_name, unit)
        if spawn_record_result.notif then
           display_notification(breed_name, "spawn")
        end
    end
end)

-- Monitoring method [2]
mod:hook_safe(CLASS.UnitSpawnerManager, "spawn_husk_unit", function(self, game_object_id, owner_id)
    local unit_spawner_manager = Managers.state.unit_spawner
    if mod:get("debugging") and not unit_spawner_manager then
        mod:echo("unit_spawner_manager = "..tostring(unit_spawner_manager))
    end
    if not unit_spawner_manager then
        return
    end
    local unit = unit_spawner_manager._network_units[game_object_id]
    -- Get breed
    local unit_data_ext = ScriptUnit.extension(unit, "unit_data_system")
    local breed = unit_data_ext and unit_data_ext:breed()
    local raw_breed_name = breed and breed.name
    -- Get weakened boss status
    --local boss_extension = ScriptUnit.has_extension(unit, "boss_system")
    --local is_weakened = boss_extension and boss_extension:is_weakened()
    local is_weakened = util.is_weakened(unit)
    -- Get clean breed name
    local breed_name = raw_breed_name and util.clean_breed_name(raw_breed_name, is_weakened)
    -- Debugging
    if mod:get("debugging") and constants.trackable_breeds.inv_table[breed_name] then
        mod:echo("--")
        mod:echo("raw_breed_name = "..tostring(raw_breed_name))
        --mod:echo("boss_extension = "..tostring(boss_extension))
        mod:echo("is_weakened = "..tostring(is_weakened))
    end
    local spawn_record_result = mod.tracked_units.record_unit_spawn(breed_name, unit)
    if spawn_record_result.notif then
       display_notification(breed_name, "spawn")
    end
end)