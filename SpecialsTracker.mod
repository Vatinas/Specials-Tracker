return {
    run = function()
        fassert(rawget(_G, "new_mod"), "`SpecialsTracker` encountered an error loading the Darktide Mod Framework.")

        new_mod("SpecialsTracker", {
            mod_script       = "SpecialsTracker/scripts/mods/SpecialsTracker/SpecialsTracker",
            mod_data         = "SpecialsTracker/scripts/mods/SpecialsTracker/SpecialsTracker_data",
            mod_localization = "SpecialsTracker/scripts/mods/SpecialsTracker/SpecialsTracker_localization",
        })
    end,
    packages = {},
}
