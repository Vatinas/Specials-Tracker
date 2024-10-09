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
    "monsters_wk",
}

local priority_lvls = {"0", "1", "2", "3", "4", "monsters", "monsters_wk"}
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
        ["zh-cn"] = "通知音效 & 背景色",
    },
    priority_lvls = {
        en = "Unit name colors by priority level",
        ["zh-cn"] = "单位名称颜色（按优先级）",
    },
    breed_widgets = {
        en = "Trackable units",
        ["zh-cn"] = "可追踪单位",
    },
}


-------------------------------------------------------
--                     subcategory
-------------------------------------------------------

loc_raw.subcategory = {
    color_spawn = {
        en = "Spawn notifications",
        ["zh-cn"] = "生成通知",
    },
    color_death = {
        en = "Death notifications",
        ["zh-cn"] = "死亡通知",
    },
    color_hybrid = {
        en = "Hybrid (spawn + death) notifications",
        ["zh-cn"] = "混合（生成+死亡）通知",
    },
}

for _, i in pairs(priority_lvls) do
    loc_raw.subcategory["color_"..i] = {
        en = "Priority level "..i,
        ["zh-cn"] = "优先级 "..i,
    }
end

loc_raw.subcategory["color_monsters"] = {
    en = "Monsters - Priority level 0",
    ["zh-cn"] = "怪物 - 优先级 0",
}

loc_raw.subcategory["color_monsters_wk"] = {
    en = "Monsters (Weakened) - Priority level 0",
    ["zh-cn"] = "怪物（虚弱）- 优先级 0",
}


-------------------------------------------------------
--                     setting
-------------------------------------------------------

loc_raw.setting = {
    global_toggle_notif = {
        en = cf(global_toggle_color) .. "Notifications",
        ["zh-cn"] = cf(global_toggle_color) .. "通知",
    },
    global_toggle_overlay = {
        en = cf(global_toggle_color) .. "HUD element (overlay)",
        ["zh-cn"] = cf(global_toggle_color) .. "HUD 元素（界面覆盖）",
    },
    notif_display_type = {
        en = "Notification style",
        ["zh-cn"] = "通知样式",
    },
    overlay_move_from_center = {
        en = "Move to the right of the screen",
        ["zh-cn"] = "移动到屏幕右侧",
    },
    notif_grouping = {
        en = "Group spawn/death notifs. of a given enemy",
        ["zh-cn"] = "组合指定敌人的生成/死亡通知",
    },
    hud_scale = {
        en = "Overlay scale",
        ["zh-cn"] = "界面覆盖缩放",
    },
    font = {
        en = "Overlay font",
        ["zh-cn"] = "界面覆盖字体",
    },
    hud_color_lerp_ratio = {
        en = "Overlay names color intensity",
        ["zh-cn"] = "界面覆盖名称颜色强度",
    },
    overlay_name_style = {
        en = "Overlay name style",
        ["zh-cn"] = "界面覆盖名称样式",
    },
    debugging = {
        en = "Debugging mode",
        ["zh-cn"] = "调试模式",
    },
}

for _, i in pairs(priority_lvls) do
    loc_raw.setting["color_used_in_hud_"..i] = {
        en = "Use color in overlay",
        ["zh-cn"] = "在界面覆盖中使用颜色",
    }
end

loc_raw.setting["monsters_pos"] = {
    en = "Monsters position in overlay",
    ["zh-cn"] = "界面覆盖中怪物位置",
}

for _, i in pairs(color_indices) do
    loc_raw.setting["sound_"..i] = {
        en = "Sound",
        ["zh-cn"] = "音效",
    }
end

for _, breed_name in pairs(trackable_breeds) do
    loc_raw.setting[breed_name.."_overlay"] = {
        en = "Show in overlay",
        ["zh-cn"] = "在界面覆盖中显示",
    }
    loc_raw.setting[breed_name.."_notif"] = {
        en = "Notifications",
        ["zh-cn"] = "通知",
    }
    loc_raw.setting[breed_name.."_priority"] = {
        en = "Priority level",
        ["zh-cn"] = "优先级",
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
        ["zh-cn"] = "\n如果相同类型敌人的生成和死亡通知会同时出现，则将它们折叠成混合通知",
    },
    tooltip_notif_display_type = {
        en = "\nAdd a marking to notifications to further separate spawn and death ones, on top of their background color\n\nIcon: Short text with an icon representing spawn or death\n\nText: Longer text with no icon",
        ["zh-cn"] = "\n向通知添加标记，在背景颜色的基础上进一步区分生成与死亡类型\n\n图标：区分生成与死亡的图标和短文本\n\n无图标的长文本",
    },
    tooltip_overlay_move_from_center = {
        en = "\nMove the overlay to a \"default\" position to the right of the screen.\n\nIf you want to move the overlay more precisely, I recommend you leave this option off, and use the mod " .. cf("ui_terminal") .. "Custom HUD{#reset()} to move it.",
        ["zh-cn"] = "\n将界面覆盖移动到屏幕右侧的“默认”位置。\n\n如果你要精细控制位置，我推荐你禁用此选项，然后使用 " .. cf("ui_terminal") .. "Custom HUD{#reset()} 模组来管理。",
    },
    tooltip_hud_color_lerp_ratio = {
        en = "\nHow strongly the color specific to an enemy's priority level is expressed in the overlay, 0 being not-at-all (white), and 1 being completely (the enemy's priority level's color)\n\nThis overlay-specific coloring can be disabled per priority level to simply have white instead",
        ["zh-cn"] = "\n在界面覆盖中，敌人优先级颜色的强度，0 表示无强度（白色），1 表示全强度（敌人优先级颜色本身）\n\n覆盖界面内的颜色可以分优先级禁用，以直接显示为白色",
    },
    tooltip_monsters_hud_only_if_alive = {
        en = "\nIf this is enabled, monster that are toggled on to be in the overlay will have their name and unit count only actually appear if at least one is alive\n\nThis is *strongly* recommended in order to keep the overlay as compact as possible",
        ["zh-cn"] = "\n如果启用，设定为在界面覆盖内显示的怪物名称和数量将仅在至少有一个单位存活时显示e\n\n*强烈*建议启用此选项，以保持界面覆盖的紧凑性",
    },
    tooltip_color_alpha = {
        en = "\nOpacity of the notification, 0 being fully transparent and 255 fully opaque",
        ["zh-cn"] = "\n通知的不透明度，0 表示完全透明，255 表示完全不透明",
    },
    tooltip_priority_lvls = {
        en = "\nEach tracked unit will be assigned a priority level, which determines its name color in notifications (and optionally the overlay), as well as how high it appears in the overlay\n\n1 is the highest priority, and 3 is the lowest, except for monsters which always have priority level of 0",
        ["zh-cn"] = "\n每种被追踪的单位会属于一个优先级，用于决定其名称在通知内（或者在界面覆盖内）的颜色，也用于确定它们在界面覆盖内的顺序\n\n1 为最高优先级，3 为最低优先级，但怪物的优先级始终为 0",
    },
    tooltip_overlay_tracking = {
        en = "\nAlways = Enemy type will always be shown in the overlay\n\nOnly when active = Enemy type will only appear in the overlay if one of more of those enemies are alive\n\nNever = Enemy type will never be shown in the overlay",
        ["zh-cn"] = "\n总是 = 这种敌人总会在界面覆盖内显示\n\n仅存活时 = 当前有这种敌人存活，则在界面覆盖内显示\n\n从不 = 这种敌人从不在界面覆盖内显示",
    },
    tooltip_monsters_pos = {
        en = "\nWhether the monsters will be listed at the top or the bottom of the list in the overlay\n\nIt is recommended to list them at the bottom, so the rest of the units don't get pushed up or down when a monster spawns or die",
        ["zh-cn"] = "\n在界面覆盖的顶部还是底部显示怪物\n\n建议设置为底部，防止当怪物生成或死亡时，影响其他单位的显示位置",
    },
    tooltip_global_toggle_notif = {
        en = "\nEnable or disable the display of notifications when desired units spawn or die.\n\nNotifications can be toggled on or off for each enemy type separately, though setting this to \"off\" disables them globally, regardless of other mod settings.",
        ["zh-cn"] = "\n显示或隐藏特定单位生成或死亡的通知。\n\n每种敌人可以单独配置通知选项，但如果禁用此全局选项，则单独的选项会被忽略。",
    },
    tooltip_global_toggle_overlay = {
        en = "\nEnable or disable the display of a permanent overlay, which tracks the number of currently active enemies of certain types.\n\nEach enemy type can have its overlay behaviour changed separately, though setting this to \"off\" disables the overlay globally, regardless of other overlay settings.",
        ["zh-cn"] = "\n显示或隐藏永久界面覆盖，用于跟踪当前存活的特定敌人数量。\n\n每种敌人可以单独配置界面覆盖选项，但如果禁用此全局选项，则单独的选项会被忽略。",
    },
    tooltip_debugging = {
        en = "\nLeave this off unless you want to see some dev stuff pop up in the chat. :)",
        ["zh-cn"] = "\n除非你想在聊天栏看到一些开发相关的信息，否则应该保持关闭。:)",
    },
}


-------------------------------------------------------
--                     option
-------------------------------------------------------

loc_raw.option = {
    icon = {
        en = "Icon",
        ["zh-cn"] = "图标",
    },
    text = {
        en = "Text",
        ["zh-cn"] = "文本",
    },
    notification_default_enter = {
        en = "Default notification sound - Enter",
        ["zh-cn"] = "默认通知音效 - 进入",
    },
    notification_default_exit = {
        en = "Default notification sound - Exit",
        ["zh-cn"] = "默认通知音效 - 退出",
    },
    mission_vote_popup_show_details = {
        en = "Mission vote popup - Show details",
        ["zh-cn"] = "任务投票弹窗 - 显示详情",
    },
    mission_vote_popup_hide_details = {
        en = "Mission vote popup - Hide details",
        ["zh-cn"] = "任务投票弹窗 - 隐藏详情",
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
        ["zh-cn"] = "顶部",
    },
    bottom = {
        en = "Bottom",
        ["zh-cn"] = "底部",
    },
    always = {
        en = "Always",
        ["zh-cn"] = "总是",
    },
    only_if_active = {
        en = "Only when active",
        ["zh-cn"] = "仅存活时",
    },
    off = {
        en = "Never",
        ["zh-cn"] = "从不",
    },
    short = {
        en = "Short",
        ["zh-cn"] = "短",
    },
    long = {
        en = "Long",
        ["zh-cn"] = "长",
    },
    full = {
        en = "Full",
        ["zh-cn"] = "完整",
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
        ["zh-cn"] = "%s 生成了 - %s",
    },
    death_message_text = {
        en = "%s died - %s",
        ["zh-cn"] = "%s 死亡了 - %s",
    },
    spawn_message_simple_text = {
        en = "%s spawned",
        ["zh-cn"] = "%s 生成了",
    },
    death_message_simple_text = {
        en = "%s died",
        ["zh-cn"] = "%s 死亡了",
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
        ["zh-cn"] = "生成了 %s - 死亡了 %s",
    },
}

-------------------------------------------------------
--                      misc
-------------------------------------------------------

loc_raw.misc = {
    mod_name = {
        en = "Specials Tracker",
        ["zh-cn"] = "专家追踪器",
    },
    mod_description = {
        en = "Shows a notification when certain enemies spawn or die, as well as a counter of how many such units are currently alive",
        ["zh-cn"] = "在特定敌人生成或死亡时显示通知，同时显示当前存活的单位数量",
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
        ["zh-cn"] = "喷火",
    },
    cultist_grenadier = {
        en = "TOXB",
        ["zh-cn"] = "毒雷",
    },
    cultist_mutant = {
        en = "MTNT",
        ["zh-cn"] = "变种",
    },
    chaos_hound = {
        en = "HND",
        ["zh-cn"] = "猎犬",
    },
    renegade_grenadier = {
        en = "BMB",
        ["zh-cn"] = "火雷",
    },
    renegade_netgunner = {
        en = "TRP",
        ["zh-cn"] = "陷阱",
    },
    renegade_sniper = {
        en = "SNP",
        ["zh-cn"] = "狙击",
    },
    chaos_poxwalker_bomber = {
        en = "BRST",
        ["zh-cn"] = "爆破",
    },
    chaos_beast_of_nurgle = {
        en = "BST",
        ["zh-cn"] = "纳兽",
    },
    chaos_beast_of_nurgle_wk = {
        en = "BST*",
        ["zh-cn"] = "纳兽*",
    },
    chaos_plague_ogryn = {
        en = "PLG",
        ["zh-cn"] = "瘟欧",
    },
    chaos_plague_ogryn_wk = {
        en = "PLG*",
        ["zh-cn"] = "瘟欧*",
    },
    chaos_spawn = {
        en = "SPWN",
        ["zh-cn"] = "混卵",
    },
    chaos_spawn_wk = {
        en = "SPWN*",
        ["zh-cn"] = "混卵*",
    },
}

overlay_name_sets.long = {
    flamer = {
        en = "FLAM",
        ["zh-cn"] = "火焰兵",
    },
    cultist_grenadier = {
        en = "TOXB",
        ["zh-cn"] = "毒雷兵",
    },
    cultist_mutant = {
        en = "MUTNT",
        ["zh-cn"] = "变种人",
    },
    chaos_hound = {
        en = "HOUND",
        ["zh-cn"] = "猎犬",
    },
    renegade_grenadier = {
        en = "BOMB",
        ["zh-cn"] = "火雷兵",
    },
    renegade_netgunner = {
        en = "TRAP",
        ["zh-cn"] = "陷阱手",
    },
    renegade_sniper = {
        en = "SNIP",
        ["zh-cn"] = "狙击手",
    },
    chaos_poxwalker_bomber = {
        en = "BURST",
        ["zh-cn"] = "爆破手",
    },
    chaos_beast_of_nurgle = {
        en = "BEAST",
        ["zh-cn"] = "纳垢兽",
    },
    chaos_beast_of_nurgle_wk = {
        en = "BEAST*",
        ["zh-cn"] = "纳垢兽*",
    },
    chaos_plague_ogryn = {
        en = "OGRYN",
        ["zh-cn"] = "瘟疫欧",
    },
    chaos_plague_ogryn_wk = {
        en = "OGRYN*",
        ["zh-cn"] = "瘟疫欧*",
    },
    chaos_spawn = {
        en = "SPAWN",
        ["zh-cn"] = "混沌卵",
    },
    chaos_spawn_wk = {
        en = "SPAWN*",
        ["zh-cn"] = "混沌卵*",
    },
}

overlay_name_sets.full = {
    flamer = {
        en = "Flamer",
        ["zh-cn"] = "火焰兵",
    },
    cultist_grenadier = {
        en = "Tox Bmb.",
        ["zh-cn"] = "剧毒轰炸者",
    },
    cultist_mutant = {
        en = "Mutant",
        ["zh-cn"] = "变种人",
    },
    chaos_hound = {
        en = "Hound",
        ["zh-cn"] = "瘟疫猎犬",
    },
    renegade_grenadier = {
        en = "Bomber",
        ["zh-cn"] = "火焰轰炸者",
    },
    renegade_netgunner = {
        en = "Trapper",
        ["zh-cn"] = "陷阱手",
    },
    renegade_sniper = {
        en = "Sniper",
        ["zh-cn"] = "狙击手",
    },
    chaos_poxwalker_bomber = {
        en = "Burster",
        ["zh-cn"] = "爆破手",
    },
    chaos_beast_of_nurgle = {
        en = "Beast",
        ["zh-cn"] = "纳垢兽",
    },
    chaos_beast_of_nurgle_wk = {
        en = "Beast*",
        ["zh-cn"] = "纳垢兽*",
    },
    chaos_plague_ogryn = {
        en = "Ogryn",
        ["zh-cn"] = "瘟疫欧格林",
    },
    chaos_plague_ogryn_wk = {
        en = "Ogryn*",
        ["zh-cn"] = "瘟疫欧格林*",
    },
    chaos_spawn = {
        en = "Spawn",
        ["zh-cn"] = "混沌魔物",
    },
    chaos_spawn_wk = {
        en = "Spawn*",
        ["zh-cn"] = "混沌魔物*",
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
    en = "Flamers (Scab / Tox)",
    ["zh-cn"] = "火焰兵（血痂 / 剧毒）",
}
loc_raw.mod_ui["flamer_notif_name"] = {
    en = "Flamer",
    ["zh-cn"] = "火焰兵",
}

-------------
-- Tox Bomber

loc_raw.subcategory["cultist_grenadier"] = {
    en = "Tox Bomber",
    ["zh-cn"] = "剧毒轰炸者",
}
loc_raw.mod_ui["cultist_grenadier_notif_name"] = {
    en = "Tox Bomber",
    ["zh-cn"] = "剧毒轰炸者",
}

---------
-- Mutant

loc_raw.subcategory["cultist_mutant"] = {
    en = "Mutant",
    ["zh-cn"] = "变种人",
}
loc_raw.mod_ui["cultist_mutant_notif_name"] = {
    en = "Mutant",
    ["zh-cn"] = "变种人",
}

--------
-- Hound

loc_raw.subcategory["chaos_hound"] = {
    en = "Hound",
    ["zh-cn"] = "瘟疫猎犬",
}
loc_raw.mod_ui["chaos_hound_notif_name"] = {
    en = "Hound",
    ["zh-cn"] = "瘟疫猎犬",
}

---------
-- Bomber

loc_raw.subcategory["renegade_grenadier"] = {
    en = "Scab Bomber",
    ["zh-cn"] = "血痂轰炸者",
}
loc_raw.mod_ui["renegade_grenadier_notif_name"] = {
    en = "Scab Bomber",
    ["zh-cn"] = "血痂轰炸者",
}

----------
-- Trapper

loc_raw.subcategory["renegade_netgunner"] = {
    en = "Trapper",
    ["zh-cn"] = "陷阱手",
}
loc_raw.mod_ui["renegade_netgunner_notif_name"] = {
    en = "Trapper",
    ["zh-cn"] = "陷阱手",
}

---------
-- Sniper

loc_raw.subcategory["renegade_sniper"] = {
    en = "Sniper",
    ["zh-cn"] = "狙击手",
}
loc_raw.mod_ui["renegade_sniper_notif_name"] = {
    en = "Sniper",
    ["zh-cn"] = "狙击手",
}

-------------
-- Poxburster

loc_raw.subcategory["chaos_poxwalker_bomber"] = {
    en = "Poxburster",
    ["zh-cn"] = "瘟疫爆破手",
}
loc_raw.mod_ui["chaos_poxwalker_bomber_notif_name"] = {
    en = "Poxburster",
    ["zh-cn"] = "瘟疫爆破手",
}

-----------
-- Monsters

-- Combined mod options subcategory

loc_raw.subcategory["monsters"] = {
    en = "Monsters",
    ["zh-cn"] = "怪物",
}

loc_raw.subcategory["monsters_wk"] = {
    en = "Monsters (weakened)",
    ["zh-cn"] = "怪物（虚弱）",
}

-- Beast of Nurgle - Other locs

loc_raw.mod_ui["chaos_beast_of_nurgle_notif_name"] = {
    en = "BEAST OF NURGLE",
    ["zh-cn"] = "纳垢兽",
}

loc_raw.mod_ui["chaos_beast_of_nurgle_wk_notif_name"] = {
    en = "BEAST OF NURGLE (Weak)",
    ["zh-cn"] = "纳垢兽（虚弱）",
}

-- Plague Ogryn - Other locs

loc_raw.mod_ui["chaos_plague_ogryn_notif_name"] = {
    en = "PLAGUE OGRYN",
    ["zh-cn"] = "瘟疫欧格林",
}

loc_raw.mod_ui["chaos_plague_ogryn_wk_notif_name"] = {
    en = "PLAGUE OGRYN (Weak)",
    ["zh-cn"] = "瘟疫欧格林（虚弱）",
}

-- Chaos Spawn - Other locs

loc_raw.mod_ui["chaos_spawn_notif_name"] = {
    en = "CHAOS SPAWN",
    ["zh-cn"] = "混沌魔物",
}

loc_raw.mod_ui["chaos_spawn_wk_notif_name"] = {
    en = "CHAOS SPAWN (Weak)",
    ["zh-cn"] = "混沌魔物（虚弱）",
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
