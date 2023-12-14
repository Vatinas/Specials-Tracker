local mod = get_mod("SpecialsTracker")
local Breeds = require("scripts/settings/breed/breeds")


-- We need the following variables, but since they won't have been generated yet when this file is run, we'll use a makeshift version of them

local interesting_breeds = {}
for breed_name, breed in pairs(Breeds) do
    if breed_name ~= "chaos_plague_ogryn_sprayer"
    and breed.display_name
    and breed.display_name ~= "loc_breed_display_name_undefined"
    and not breed.boss_health_bar_disabled
    and not string.match(breed_name, "_mutator$")
    and breed.tags and (breed.tags.special or breed.tags.monster) then
        table.insert(interesting_breeds, breed_name)
    end
end

local priority_lvls = {"1", "2", "3", "4"}
local color_indices = table.clone(priority_lvls)
table.insert(color_indices, "spawn")
table.insert(color_indices, "death")

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
        en = "Shows a notification when certain enemies spawn or die, as well as a counter of how many such units are currently alive.",
    },
    spawn_message = {
        en = "%s spawned %s",
    },
    death_message = {
        en = "%s died %s",
    },
    spawn_message_simple = {
        en = "%s spawned",
    },
    death_message_simple = {
        en = "%s died",
    },
    hud_scale = {
        en = "Overlay scale",
    },
    font = {
        en = "Font",
    },
    hud_color_lerp_ratio = {
        en = "Overlay text color intensity",
    },
    tooltip_hud_color_lerp_ratio = {
        en = "\nHow strongly the color specific to an enemy's priority level is expressed in the overlay, 0 being not-at-all (white), and 1 being completely (the enemy's priority level's color).\n\nThis overlay-specific coloring can be disabled per priority level to simply have white instead.",
    },
    monsters_hud_only_if_alive = {
        en = "Monsters in overlay only if active",
    },
    tooltip_monsters_hud_only_if_alive = {
        en = "\nIf this is enabled, monster that are toggled on to be in the overlay will have their name and unit count only actually appear if at least one is alive.\n\nThis is *strongly* recommended in order to keep the overlay as compact as possible.",
    },
    color_spawn = {
        en = "Enemy spawn notif. background color",
    },
    color_death = {
        en = "Enemy death notif. background color",
    },
    tooltip_color_alpha = {
        en = "\nOpacity of the notification, 0 being fully transparent and 255 fully opaque.",
    },
    priority_lvls = {
        en = "Enemy priority levels",
    },
    breed_widgets = {
        en = "Tracked units",
    },
    tooltip_priority_lvls = {
        en = "\nEach tracked unit will be assigned a priority level, which determines its name color in notifications (and optionally the overlay), as well as how high it appears in the overlay.\n\n1 is the highest priority, 4 is the lowest.",
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
        en = "Monstrosities",
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
        en = "Level "..i,
    }
    loc["color_used_in_hud_"..i] = {
        en = "Use color in overlay",
    }
end

for _, i in pairs(color_indices) do
    for col, col_loc in pairs(col_locs) do
        loc["color_"..i..col] = {
            en = col_loc,
        }
    end
end

for _, breed_name in pairs(interesting_breeds) do
    loc[breed_name.."_overlay"] = {
        en = "Overlay",
    }
    loc[breed_name.."_notif"] = {
        en = "Notifications",
    }
    loc[breed_name.."_priority"] = {
        en = "Priority level",
    }
end


-- Add localisation for all breeds in case the next part misses some breeds / some languages
for breed_name, breed in pairs(Breeds) do
    if breed_name ~= "human" and breed_name ~= "ogryn" and breed.display_name then
        loc[breed_name] = {
            en = Localize(breed.display_name),
        }
    end
end

-- Shorter names for notifications

--[[
-- As of now, the two kinds of flamer are tracked separately, and probably shouldn't have the same name
loc["cultist_flamer"] = {
    en = "Flamer"
}
loc["renegade_flamer"] = {
    en = "Flamer"
}
-- The mutant isn't needed, but leaving it here for the sake of completeness
loc["cultist_mutant"] = {
    en = "Mutant"
}
--]]
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


-- Breed names abreviations for the HUD element

for _, breed_name in pairs(interesting_breeds) do
    loc[breed_name.."_overlay"] = {
        en = "Overlay",
    }
    loc[breed_name.."_notif"] = {
        en = "Notifications",
    }
    loc[breed_name.."_priority"] = {
        en = "Priority level",
    }
end

for _, breed_name in pairs(interesting_breeds) do
    loc[breed_name.."_overlay_name"] = {
        en = "[X]",
    }
end

loc["chaos_hound_overlay_name"] = {
    en = "HND"
}
loc["cultist_flamer_overlay_name"] = {
    en = "FLM"
}
loc["renegade_flamer_overlay_name"] = {
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
