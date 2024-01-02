local mod = get_mod("SpecialsTracker")
local Breeds = require("scripts/settings/breed/breeds")


-- We need the following variables, but since they won't have been defined yet when this file is run, we'll use a makeshift version of them

local clean_brd_name = function(breed_name)
    local breed_name_no_mutator_marker = string.match(breed_name, "(.+)_mutator$") or breed_name
    if string.match(breed_name_no_mutator_marker, "(.+)_flamer") then
        return "flamer"
    else
        return breed_name_no_mutator_marker
    end
end

local trackable_breeds = {
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

local priority_lvls = {"0", "1", "2", "3"}
local color_indices = table.clone(priority_lvls)
table.insert(color_indices, "monsters")
table.insert(color_indices, "spawn")
table.insert(color_indices, "death")
table.insert(color_indices, "hybrid")

local col_locs = {
    _r = "R",
    _g = "G",
    _b = "B",
    _alpha = "Alpha",
}

local loc = {
    mod_name = {
        en = "Specials Tracker",
    },
    mod_description = {
        en = "Shows a notification when certain enemies spawn or die, as well as a counter of how many such units are currently alive",
    },
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
        --en = "%s \u{2014} \u{2191} %s  \u{2193} %s",\u{00B7}
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
    notif_display_type = {
        en = "Notification style",
    },
    tooltip_notif_display_type = {
        en = "\nAdd a marking to notifications to further separate spawn and death ones, on top of their background color\n\nIcon: Short text with an icon representing spawn or death\n\nText: Longer text with no icon",
    },
    notif_grouping = {
        en = "Group spawn/death notifs. of a given enemy",
    },
    tooltip_notif_grouping = {
        en = "\nIf a spawn and a death notification of the same enemy would appear simultaneously, collapse them into one hybrid notification instead",
    },
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
    hud_scale = {
        en = "Overlay scale",
    },
    font = {
        en = "Overlay font",
    },
    hud_color_lerp_ratio = {
        en = "Overlay names color intensity",
    },
    tooltip_hud_color_lerp_ratio = {
        en = "\nHow strongly the color specific to an enemy's priority level is expressed in the overlay, 0 being not-at-all (white), and 1 being completely (the enemy's priority level's color)\n\nThis overlay-specific coloring can be disabled per priority level to simply have white instead",
    },
    monsters_hud_only_if_alive = {
        en = "Monsters in overlay only if active",
    },
    tooltip_monsters_hud_only_if_alive = {
        en = "\nIf this is enabled, monster that are toggled on to be in the overlay will have their name and unit count only actually appear if at least one is alive\n\nThis is *strongly* recommended in order to keep the overlay as compact as possible",
    },
    color_spawn = {
        en = "Spawn notifications",
    },
    color_death = {
        en = "Death notifications",
    },
    color_hybrid = {
        en = "Hybrid (spawn + death) notifications",
    },
    tooltip_color_alpha = {
        en = "\nOpacity of the notification, 0 being fully transparent and 255 fully opaque",
    },
    extended_events = {
        en = "> Notification sound & background color",
    },
    priority_lvls = {
        en = "> Unit name colors by priority level",
    },
    breed_widgets = {
        en = "> Trackable units",
    },
    tooltip_priority_lvls = {
        en = "\nEach tracked unit will be assigned a priority level, which determines its name color in notifications (and optionally the overlay), as well as how high it appears in the overlay\n\n1 is the highest priority, and 3 is the lowest, except for monsters which always have priority level of 0",
    },
    tooltip_overlay_tracking = {
        en = "\nAlways = Enemy type will always be shown in the overlay\n\nOnly when active = Enemy type will only appear in the overlay if one of more of those enemies are alive\n\nNever = Enemy type will never be shown in the overlay",
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
    breed_specialist = {
        en = "Specialists",
        ja = "スペシャリスト",
        ["zh-cn"] = "专家",
        ru = "Специалисты",
    },
    breed_monster = {
        en = "Monsters",
        ja = "バケモノ",
        ["zh-cn"] = "怪物",
        ru = "Монстры",
    },
    debug = {
        en = "Debug",
        ja = "デバッグ",
        ["zh-cn"] = "调试",
        ru = "Отладка",
    },
    enable_debug_mode = {
        en = "Enable Debug Mode",
        ja = "デバッグモードを有効にする",
        ["zh-cn"] = "启用调试模式",
        ru = "Включить режим отладки",
    }
}

for _, i in pairs(priority_lvls) do
    loc["color_"..i] = {
        en = "Priority level "..i,
    }
    loc["color_used_in_hud_"..i] = {
        en = "Use color in overlay",
    }
end

loc["color_monsters"] = {
    en = "Monsters (priority level 0)",
}
loc["color_used_in_hud_monsters"] = {
    en = "Use color in overlay",
}
loc["monsters_pos"] = {
    en = "Position in overlay",
}
loc["tooltip_monsters_pos"] = {
    en = "\nWhether the monsters will be listed at the top or the bottom of the list in the overlay\n\nIt is recommended to list them at the bottom, so the rest of the units don't get pushed up or down when a monster spawns or die",
}
loc["top"] = {
    en = "Top",
}
loc["bottom"] = {
    en = "Bottom",
}

for _, i in pairs(color_indices) do
    loc["sound_"..i] = {
        en = "Sound",
    }
    for col, col_loc in pairs(col_locs) do
        loc["color_"..i..col] = {
            en = col_loc,
        }
    end
end

for _, breed_name in pairs(trackable_breeds) do
    loc[breed_name.."_overlay"] = {
        en = "Show in overlay",
    }
    loc[breed_name.."_notif"] = {
        en = "Notifications",
    }
    loc[breed_name.."_priority"] = {
        en = "Priority level",
    }
end

loc["monsters_overlay"] = {
    en = "Show in overlay",
}
loc["monsters_notif"] = {
    en = "Notifications",
}
loc["monsters_priority"] = {
    en = "Priority level",
}

loc["always"] = {
    en = "Always",
}
loc["only_if_active"] = {
    en = "Only when active",
}
loc["off"] = {
    en = "Never",
}

-- Add localisation for all breeds and all loc. types in case the next part misses some breeds / some languages
for breed_name, breed in pairs(Breeds) do
    if breed_name ~= "human" and breed_name ~= "ogryn" and breed.display_name then
        local clean_name = clean_brd_name(breed_name)
        -- Mod options menu names
        loc[clean_name] = {
            en = Localize(breed.display_name),
        }
        -- Breed names in notifs
        loc[clean_name.."_notif_name"] = {
            en = Localize(breed.display_name),
        }
        -- Breed names in overlay
        loc[clean_name.."_overlay_name"] = {
            en = "[X]",
        }
    end
end

-----------------------------------------
-- Shorter names for mod the options menu

loc["monsters"] = {
    en = "Monsters"
}
loc["flamer"] = {
    en = "Flamers (Scab / Tox)"
}
loc["cultist_mutant"] = { 
    en = "Mutant" -- The mutant isn't needed, but leaving it here for the sake of completeness
}
loc["chaos_hound"] = {
    en = "Hound"
}
loc["renegade_grenadier"] = {
    en = "Bomber"
}
loc["renegade_netgunner"] = {
    en = "Trapper"
}
loc["renegade_sniper"] = {
    en = "Sniper"
}

---------------------------
-- Shorter names for notifs

loc["flamer_notif_name"] = {
    en = "Flamer"
}
loc["cultist_mutant_notif_name"] = {
    en = "Mutant"
}
loc["chaos_hound_notif_name"] = {
    en = "Hound"
}
loc["renegade_grenadier_notif_name"] = {
    en = "Bomber"
}
loc["renegade_netgunner_notif_name"] = {
    en = "Trapper"
}
loc["renegade_sniper_notif_name"] = {
    en = "Sniper"
}
loc["chaos_beast_of_nurgle_notif_name"] = {
    en = "BEAST OF NURGLE"
}
loc["chaos_plague_ogryn_notif_name"] = {
    en = "PLAGUE OGRYN"
}
loc["chaos_spawn_notif_name"] = {
    en = "CHAOS SPAWN"
}

--------------------------------
-- Shorter names for the overlay

loc["chaos_hound_overlay_name"] = {
    en = "HND"
}
loc["flamer_overlay_name"] = {
    en = "FLM"
}
loc["cultist_mutant_overlay_name"] = {
    en = "MTNT"
}
loc["renegade_grenadier_overlay_name"] = {
    en = "BMB"
}
loc["renegade_netgunner_overlay_name"] = {
    en = "TRP"
}
loc["renegade_sniper_overlay_name"] = {
    en = "SNP"
}
loc["chaos_poxwalker_bomber_overlay_name"] = {
    en = "BRST"
}
loc["chaos_beast_of_nurgle_overlay_name"] = {
    en = "BST"
}
loc["chaos_plague_ogryn_overlay_name"] = {
    en = "PLG"
}
loc["chaos_spawn_overlay_name"] = {
    en = "SPWN"
}


return loc
