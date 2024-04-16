local mod = get_mod("SpecialsTracker")
local Breeds = require("scripts/settings/breed/breeds")


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--                        Local utilities
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local clean_brd_name = function(breed_name)
    local breed_name_no_mutator_marker = string.match(breed_name, "(.+)_mutator$") or breed_name
    if string.match(breed_name_no_mutator_marker, "(.+)_flamer") then
        return "flamer"
    else
        return breed_name_no_mutator_marker
    end
end

local trackable_breeds = {
    "chaos_hound",
    "chaos_poxwalker_bomber",
    "cultist_grenadier",
    "cultist_mutant",
    "flamer",
    "renegade_grenadier",
    "renegade_netgunner",
    "renegade_sniper",
    "monsters",
}

local priority_lvls = {"0", "1", "2", "3", "4", "monsters"}
-- NB: We shouldn't need 0 for localisation purposes, but as long as it doesn't add that much unnecessary data, better safe than sorry
local color_indices = table.clone(priority_lvls)
table.insert(color_indices, "spawn")
table.insert(color_indices, "death")
table.insert(color_indices, "hybrid")

local col_locs = {
    _r = "R",
    _g = "G",
    _b = "B",
    _alpha = "Alpha",
}

local function cf(color_name)
	local color = Color[color_name](255, true)
	return string.format("{#color(%s,%s,%s)}", color[2], color[3], color[4])
end

local global_toggle_color = "terminal_icon"

---------------------------------------------------------------------------
---------------------------------------------------------------------------
--              Generic raw localisation entries per type
---------------------------------------------------------------------------
---------------------------------------------------------------------------

local loc_raw = { }


-------------------------------------------------------
--                    category
-------------------------------------------------------

loc_raw.category = {
    extended_events = {
        en = "Notification sound & background color",
    },
    priority_lvls = {
        en = "Unit name colors by priority level",
    },
    breed_widgets = {
        en = "Trackable units",
    },
}


-------------------------------------------------------
--                     subcategory
-------------------------------------------------------

loc_raw.subcategory = {
    color_spawn = {
        en = "Spawn notifications",
    },
    color_death = {
        en = "Death notifications",
    },
    color_hybrid = {
        en = "Hybrid (spawn + death) notifications",
    },
}

for _, i in pairs(priority_lvls) do
    loc_raw.subcategory["color_"..i] = {
        en = "Priority level "..i,
    }
end

loc_raw.subcategory["color_monsters"] = {
    en = "Monsters (priority level 0)",
}


-------------------------------------------------------
--                     setting
-------------------------------------------------------

loc_raw.setting = {
    global_toggle_notif = {
        en = cf(global_toggle_color) .. "Notifications",
    },
    global_toggle_overlay = {
        en = cf(global_toggle_color) .. "HUD element (overlay)",
    },
    notif_display_type = {
        en = "Notification style",
    },
    overlay_move_from_center = {
        en = "Move to the right of the screen",
    },
    notif_grouping = {
        en = "Group spawn/death notifs. of a given enemy",
    },
    hud_scale = {
        en = "Overlay scale",
    },
    font = {
        en = "Overlay font",
    },
    hud_color_lerp_ratio = {
        en = "Overlay names color intensity",
    },
    overlay_name_style = {
        en = "Overlay name style",
    },
}

for _, i in pairs(priority_lvls) do
    loc_raw.setting["color_used_in_hud_"..i] = {
        en = "Use color in overlay",
    }
end

loc_raw.setting["monsters_pos"] = {
    en = "Position in overlay",
}

for _, i in pairs(color_indices) do
    loc_raw.setting["sound_"..i] = {
        en = "Sound",
    }
end

for _, breed_name in pairs(trackable_breeds) do
    loc_raw.setting[breed_name.."_overlay"] = {
        en = "Show in overlay",
    }
    loc_raw.setting[breed_name.."_notif"] = {
        en = "Notifications",
    }
    loc_raw.setting[breed_name.."_priority"] = {
        en = "Priority level",
    }
end

for _, i in pairs(color_indices) do
    for col, col_loc in pairs(col_locs) do
        loc_raw.setting["color_"..i..col] = {
            en = col_loc,
        }
    end
end


-------------------------------------------------------
--                     tooltip
-------------------------------------------------------

loc_raw.tooltip = {
    tooltip_notif_grouping = {
        en = "\nIf a spawn and a death notification of the same enemy would appear simultaneously, collapse them into one hybrid notification instead",
    },
    tooltip_notif_display_type = {
        en = "\nAdd a marking to notifications to further separate spawn and death ones, on top of their background color\n\nIcon: Short text with an icon representing spawn or death\n\nText: Longer text with no icon",
    },
    tooltip_overlay_move_from_center = {
        en = "\nMove the overlay to a \"default\" position to the right of the screen.\n\nIf you want to move the overlay more precisely, I recommend you leave this option off, and use the mod " .. cf("ui_terminal") .. "Custom HUD{#reset()} to move it.",
    },
    tooltip_hud_color_lerp_ratio = {
        en = "\nHow strongly the color specific to an enemy's priority level is expressed in the overlay, 0 being not-at-all (white), and 1 being completely (the enemy's priority level's color)\n\nThis overlay-specific coloring can be disabled per priority level to simply have white instead",
    },
    tooltip_monsters_hud_only_if_alive = {
        en = "\nIf this is enabled, monster that are toggled on to be in the overlay will have their name and unit count only actually appear if at least one is alive\n\nThis is *strongly* recommended in order to keep the overlay as compact as possible",
    },
    tooltip_color_alpha = {
        en = "\nOpacity of the notification, 0 being fully transparent and 255 fully opaque",
    },
    tooltip_priority_lvls = {
        en = "\nEach tracked unit will be assigned a priority level, which determines its name color in notifications (and optionally the overlay), as well as how high it appears in the overlay\n\n1 is the highest priority, and 3 is the lowest, except for monsters which always have priority level of 0",
    },
    tooltip_overlay_tracking = {
        en = "\nAlways = Enemy type will always be shown in the overlay\n\nOnly when active = Enemy type will only appear in the overlay if one of more of those enemies are alive\n\nNever = Enemy type will never be shown in the overlay",
    },
    tooltip_monsters_pos = {
        en = "\nWhether the monsters will be listed at the top or the bottom of the list in the overlay\n\nIt is recommended to list them at the bottom, so the rest of the units don't get pushed up or down when a monster spawns or die",
    },
    tooltip_global_toggle_notif = {
        en = "\nEnable or disable the display of notifications when desired units spawn or die.\n\nNotifications can be toggled on or off for each enemy type separately, though setting this to \"off\" disables them globally, regardless of other mod settings."
    },
    tooltip_global_toggle_overlay = {
        en = "\nEnable or disable the display of a permanent overlay, which tracks the number of currently active enemies of certain types.\n\nEach enemy type can have its overlay behaviour changed separately, though setting this to \"off\" disables the overlay globally, regardless of other overlay settings."
    },
}


-------------------------------------------------------
--                     option
-------------------------------------------------------

loc_raw.option = {
    icon = {
        en = "Icon",
    },
    text = {
        en = "Text",
    },
    notification_default_enter = {
        en = "Default notification sound - Enter",
    },
    notification_default_exit = {
        en = "Default notification sound - Exit",
    },
    mission_vote_popup_show_details = {
        en = "Mission vote popup - Show details",
    },
    mission_vote_popup_hide_details = {
        en = "Mission vote popup - Hide details",
    },
    arial = {
        en = "Arial",
    },
    itc_novarese_medium = {
        en = "ITC Novarese - Medium",
    },
    itc_novarese_bold = {
        en = "ITC Novarese - Bold",
    },
    proxima_nova_light = {
        en = "Proxima Nova - Light",
    },
    proxima_nova_medium = {
        en = "Proxima Nova - Medium",
    },
    proxima_nova_bold = {
        en = "Proxima Nova - Bold",
    },
    friz_quadrata = {
        en = "Friz Quadrata",
    },
    rexlia = {
        en = "Rexlia",
    },
    machine_medium = {
        en = "Machine Medium",
    },
    top = {
        en = "Top",
    },
    bottom = {
        en = "Bottom",
    },
    always = {
        en = "Always",
    },
    only_if_active = {
        en = "Only when active",
    },
    off = {
        en = "Never",
    },
    short = {
        en = "Short",
    },
    long = {
        en = "Long",
    },
    full = {
        en = "Full",
    },
}


-------------------------------------------------------
--                     mod_ui
-------------------------------------------------------

loc_raw.mod_ui = {
    spawn_message_icon = {
        en = "%s \u{2014} %s",
    },
    death_message_icon = {
        en = "%s \u{2014} %s",
    },
    spawn_message_simple_icon = {
        en = "%s"
    },
    death_message_simple_icon = {
        en = "%s",
    },
    spawn_message_text = {
        en = "%s spawned - %s",
    },
    death_message_text = {
        en = "%s died - %s",
    },
    spawn_message_simple_text = {
        en = "%s spawned",
    },
    death_message_simple_text = {
        en = "%s died",
    },
    hybrid_message_grouped = {
        en = "%s \u{2014}\n %s \u{25B2} \u{2014} %s \u{25BC}",
    },
    hybrid_message_grouped_1_icon = {
        en = "%s",
    },
    hybrid_message_grouped_2_icon = {
        en = "%s \u{25B2} \u{2014} %s \u{25BC}",
    },
    hybrid_message_grouped_1_text = {
        en = "%s",
    },
    hybrid_message_grouped_2_text = {
        en = "Spawned %s - Died %s",
    },
}

-------------------------------------------------------
--                      misc
-------------------------------------------------------

loc_raw.misc = {
    mod_name = {
        en = "Specials Tracker",
    },
    mod_description = {
        en = "Shows a notification when certain enemies spawn or die, as well as a counter of how many such units are currently alive",
    },
}


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--              Breed-specific raw localisation entries
---------------------------------------------------------------------------
---------------------------------------------------------------------------


-- Add localisations for all breeds and all loc. types in case the next part misses some breeds / some languages
for breed_name, breed in pairs(Breeds) do
    if breed_name ~= "human" and breed_name ~= "ogryn" and breed.display_name then
        local clean_name = clean_brd_name(breed_name)
        -- Mod options menu names
        loc_raw.subcategory[clean_name] = {
            en = Localize(breed.display_name),
        }
        -- Breed names in notifs
        loc_raw.mod_ui[clean_name.."_notif_name"] = {
            en = Localize(breed.display_name),
        }
        -- Breed names in overlay
        loc_raw.mod_ui[clean_name.."_overlay_name_short"] = {
            en = "[X]",
        }
        loc_raw.mod_ui[clean_name.."_overlay_name_long"] = {
            en = "[X]",
        }
        loc_raw.mod_ui[clean_name.."_overlay_name_full"] = {
            en = "[X]",
        }
    end
end

-------------------------------------------------------
--                  Overlay names
-------------------------------------------------------

---------------------
-- Defining name sets

local overlay_name_sets = { }

overlay_name_sets.short = {
    flamer = {
        en = "FLM",
    },
    cultist_grenadier = {
        en = "TOXB",
    },
    cultist_mutant = {
        en = "MTNT",
    },
    chaos_hound = {
        en = "HND",
    },
    renegade_grenadier = {
        en = "BMB",
    },
    renegade_netgunner = {
        en = "TRP",
    },
    renegade_sniper = {
        en = "SNP",
    },
    chaos_poxwalker_bomber = {
        en = "BRST",
    },
    chaos_beast_of_nurgle = {
        en = "BST",
    },
    chaos_plague_ogryn = {
        en = "PLG",
    },
    chaos_spawn = {
        en = "SPWN",
    },
}

overlay_name_sets.long = {
    flamer = {
        en = "FLAM",
    },
    cultist_grenadier = {
        en = "TOXB",
    },
    cultist_mutant = {
        en = "MUTNT",
    },
    chaos_hound = {
        en = "HOUND",
    },
    renegade_grenadier = {
        en = "BOMB",
    },
    renegade_netgunner = {
        en = "TRAP",
    },
    renegade_sniper = {
        en = "SNIP",
    },
    chaos_poxwalker_bomber = {
        en = "BURST",
    },
    chaos_beast_of_nurgle = {
        en = "BEAST",
    },
    chaos_plague_ogryn = {
        en = "OGRYN",
    },
    chaos_spawn = {
        en = "SPAWN",
    },
}

overlay_name_sets.full = {
    flamer = {
        en = "Flamer",
    },
    cultist_grenadier = {
        en = "Tox Bmb.",
    },
    cultist_mutant = {
        en = "Mutant",
    },
    chaos_hound = {
        en = "Hound",
    },
    renegade_grenadier = {
        en = "Bomber",
    },
    renegade_netgunner = {
        en = "Trapper",
    },
    renegade_sniper = {
        en = "Sniper",
    },
    chaos_poxwalker_bomber = {
        en = "Burster",
    },
    chaos_beast_of_nurgle = {
        en = "Beast",
    },
    chaos_plague_ogryn = {
        en = "Ogryn",
    },
    chaos_spawn = {
        en = "Spawn",
    },
}

----------------------------------
-- Adding overlay names to the loc

for style, name_set in pairs(overlay_name_sets) do
    for breed_name, loc in pairs(name_set) do
        loc_raw.mod_ui[breed_name.."_overlay_name_"..style] = loc
    end
end

-------------------------------------------------------
--              Other breed name locs
-------------------------------------------------------

----------
-- Flamers

loc_raw.subcategory["flamer"] = {
    en = "Flamers (Scab / Tox)"
}
loc_raw.mod_ui["flamer_notif_name"] = {
    en = "Flamer"
}

-------------
-- Tox Bomber

loc_raw.subcategory["cultist_grenadier"] = {
    en = "Tox Bomber"
}
loc_raw.mod_ui["cultist_grenadier_notif_name"] = {
    en = "Tox Bomber"
}

---------
-- Mutant

loc_raw.subcategory["cultist_mutant"] = {
    en = "Mutant"
}
loc_raw.mod_ui["cultist_mutant_notif_name"] = {
    en = "Mutant"
}

--------
-- Hound

loc_raw.subcategory["chaos_hound"] = {
    en = "Hound"
}
loc_raw.mod_ui["chaos_hound_notif_name"] = {
    en = "Hound"
}

---------
-- Bomber

loc_raw.subcategory["renegade_grenadier"] = {
    en = "Scab Bomber"
}
loc_raw.mod_ui["renegade_grenadier_notif_name"] = {
    en = "Scab Bomber"
}

----------
-- Trapper

loc_raw.subcategory["renegade_netgunner"] = {
    en = "Trapper"
}
loc_raw.mod_ui["renegade_netgunner_notif_name"] = {
    en = "Trapper"
}

---------
-- Sniper

loc_raw.subcategory["renegade_sniper"] = {
    en = "Sniper"
}
loc_raw.mod_ui["renegade_sniper_notif_name"] = {
    en = "Sniper"
}

-------------
-- Poxburster

loc_raw.subcategory["chaos_poxwalker_bomber"] = {
    en = "Poxburster"
}
loc_raw.mod_ui["chaos_poxwalker_bomber_notif_name"] = {
    en = "Poxburster"
}

-----------
-- Monsters

-- Combined mod options subcategory

loc_raw.subcategory["monsters"] = {
    en = "Monsters"
}

-- Beast of Nurgle - Other locs

loc_raw.mod_ui["chaos_beast_of_nurgle_notif_name"] = {
    en = "BEAST OF NURGLE"
}

-- Plague Ogryn - Other locs

loc_raw.mod_ui["chaos_plague_ogryn_notif_name"] = {
    en = "PLAGUE OGRYN"
}

-- Chaos Spawn - Other locs

loc_raw.mod_ui["chaos_spawn_notif_name"] = {
    en = "CHAOS SPAWN"
}


---------------------------------------------------------------------------
---------------------------------------------------------------------------
--           Applying prefixes & combining raw loc. entries
---------------------------------------------------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------
--                Defining prefixes
-------------------------------------------------------

local prefixe_per_type = { }
for prefix_type, _ in pairs(loc_raw) do
    prefixe_per_type[prefix_type] = ""
end
prefixe_per_type.category = ""
prefixe_per_type.subcategory = "    "
prefixe_per_type.setting = ""
prefixe_per_type.tooltip = ""
prefixe_per_type.option = ""
prefixe_per_type.mod_ui = ""
prefixe_per_type.misc = ""


-------------------------------------------------------
--          Contructing final loc table
-------------------------------------------------------

local loc = { }

for prefix_type, raw_loc_entries in pairs(loc_raw) do
    for loc_entry_name, loc_entry in pairs(raw_loc_entries) do
        loc[loc_entry_name] = { }
        for lang, text in pairs(loc_entry) do
            loc[loc_entry_name][lang] = prefixe_per_type[prefix_type]..text
        end
    end
end

return loc