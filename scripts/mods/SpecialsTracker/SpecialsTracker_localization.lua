local mod = get_mod("SpecialsTracker")
local Breeds = require("scripts/settings/breed/breeds")

local loc = {
    mod_name = {
        en = "Specials Tracker",
    },
    mod_description = {
        en = "Shows a notification when certain enemies spawn or die, as well as a counter of how many such units are currently alive.",
    },
    spawn_message = {
        en = "%s spawned",
    },
    death_message = {
        en = "%s died",
    },
    name_color_spawn = {
        en = "Spawned units name color"
    },
    tooltip_name_color_spawn = {
        en = "The color of the names of spawning units in the notifications",
    },
    name_color_r_spawn = {
        en = "R",
    },
    name_color_g_spawn = {
        en = "G",
    },
    name_color_b_spawn = {
        en = "B",
    },
    name_color_death = {
        en = "Dead units name color",
    },
    tooltip_name_color_death = {
        en = "The color of the names of dying units in the notifications",
    },
    name_color_r_death = {
        en = "R",
    },
    name_color_g_death = {
        en = "G",
    },
    name_color_b_death = {
        en = "B",
    },
    breed_spawn = {
        en = "Spawned units",
    },
    tooltip_spawn = {
        en = "Choose which units should prompt a notification when spawned",
    },
    breed_specialist_spawn = {
        en = "Specialists",
        ja = "スペシャリスト",
        ["zh-cn"] = "专家",
        ru = "Специалисты",
    },
    breed_monster_spawn = {
        en = "Monstrosities",
        ja = "バケモノ",
        ["zh-cn"] = "怪物",
        ru = "Монстры",
    },
    breed_death = {
        en = "Killed units",
    },
    tooltip_death = {
        en = "Choose which units should prompt a notification when killed",
    },
    breed_specialist_death = {
        en = "Specialists",
        ja = "スペシャリスト",
        ["zh-cn"] = "专家",
        ru = "Специалисты",
    },
    breed_monster_death = {
        en = "Monstrosities",
        ja = "バケモノ",
        ["zh-cn"] = "怪物",
        ru = "Монстры",
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

for breed_name, breed in pairs(Breeds) do
    if breed_name ~= "human" and breed_name ~= "ogryn" and breed.display_name then
        loc[breed_name] = {
            en = Localize(breed.display_name),
        }
    end
end

loc["chaos_hound"] = {
    en = "Hound"
}
--[[
    As of now, the two kinds of flamer are tracked separately, and probably shouldn't have the same name
loc["cultist_flamer"] = {
    en = "Flamer"
}
loc["renegade_flamer"] = {
    en = "Flamer"
}
--]]
loc["cultist_mutant"] = {
    en = "Mutant"
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


loc["chaos_hound_overlay"] = {
    en = "HND"
}
loc["cultist_flamer_overlay"] = {
    en = "FLM"
}
loc["renegade_flamer_overlay"] = {
    en = "FLM"
}
loc["cultist_mutant_overlay"] = {
    en = "MTNT"
}
loc["renegade_grenadier_overlay"] = {
    en = "BMB"
}
loc["renegade_netgunner_overlay"] = {
    en = "TRP"
}
loc["renegade_sniper_overlay"] = {
    en = "SNP"
}
loc["chaos_poxwalker_bomber_overlay"] = {
    en = "BRST"
}
loc["chaos_beast_of_nurgle_overlay"] = {
    en = "BST"
}
loc["chaos_plague_ogryn_overlay"] = {
    en = "PLG"
}
loc["chaos_spawn_overlay"] = {
    en = "SPWN"
}


return loc
