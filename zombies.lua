plugin = {
    name = "zombies",
    displayName = "Zombies",
    prefix = "§cHZ",
    version = "0.1.0",
    credits = "PingIsFun, Stachelbeere1248",
    description = "QOL features for Hypixel Zombies.",
    dependencies = {
        { name = "hypixel-mod-api", minVersion = "1.0.0" },
    },
}

-- Config schema

starfish.schema.section({
    key = "alerts",
    label = "Power-Up Alerts",
    description = "Announce power-up spawns and despawns.",
    settings = {
        { key = "alerts.enabled", type = "toggle", default = true, description = "Enable power-up alerts." },
        { key = "alerts.destination", type = "cycle", default = "self", displayLabel = "Send to",
            description = "Where to send power-up alerts.", values = {
            { text = "Self", value = "self" },
            { text = "Party", value = "party" },
            { text = "Chat", value = "chat" },
        }},
        { key = "alerts.sound", type = "soundToggle", default = true, description = "Play a sound with power-up alerts." },
    }
})

starfish.schema.section({
    key = "forecast",
    label = "Power-Up Forecast",
    description = "Predict which rounds power-ups will spawn in and announce them.",
    settings = {
        { key = "forecast.enabled", type = "toggle", default = true, description = "Enable the power-up forecast." },
        { key = "forecast.destination", type = "cycle", default = "self", displayLabel = "Send to",
            description = "Where to send the power-up forecast.", values = {
            { text = "Self", value = "self" },
            { text = "Party", value = "party" },
            { text = "Chat", value = "chat" },
        }},
    }
})

starfish.schema.section({
    key = "waveTimer",
    label = "Wave Timer",
    description = "Warning sound shortly before each zombie wave spawns.",
    settings = {
        { key = "waveTimer.audio", type = "soundToggle", default = true, description = "Play a warning sound shortly before each wave spawns." },
    }
})

starfish.schema.section({
    key = "playerVisibility",
    label = "Close Player Visibility",
    description = "Hide nearby teammates so they don't block your view.",
    settings = {
        { key = "playerVisibility.enabled", type = "toggle", default = false, description = "Hide other players within range." },
        { key = "playerVisibility.range", type = "cycle", default = 1.5, displayLabel = "Range",
            description = "Maximum distance at which nearby teammates are hidden.", values = {
            { text = "1 block", value = 1 }, { text = "1.5 blocks", value = 1.5 },
            { text = "2 blocks", value = 2 }, { text = "2.5 blocks", value = 2.5 },
        }},
    }
})

-- Power-up data

local POWER_UPS = {
    insta_kill     = { name = "Insta Kill",     short = "IK", color = "§c" },
    max_ammo       = { name = "Max Ammo",       short = "MX", color = "§9" },
    shopping_spree = { name = "Shopping Spree", short = "SS", color = "§5" },
}

local POWER_UP_BY_NAME = {}
for id, data in pairs(POWER_UPS) do
    POWER_UP_BY_NAME[data.name:upper()] = id
end

local PATTERNS = {
    dead_end = {
        insta_kill = { { 2, 8, 11, 14, 17, 23 }, {}, { 3, 6, 9, 12, 18, 21, 24 }, {} },
        max_ammo   = { { 2, 8, 12, 16, 21, 26 }, {}, { 3, 6, 9, 13, 17, 22, 27 }, {} },
    },
    bad_blood = {
        insta_kill = { { 2, 5, 8, 11, 14, 17, 23 }, {}, { 3, 6, 9, 12, 18, 21, 24 }, {} },
        max_ammo   = { { 2, 5, 8, 12, 16, 21, 26 }, {}, { 3, 6, 9, 13, 17, 22, 27 }, {} },
    },
    alien_arcadium = {
        insta_kill     = { { 2, 5, 8, 11, 14, 17, 20, 23 }, {}, { 3, 6, 9, 12, 15, 18, 21 }, {} },
        max_ammo       = { { 2, 5, 8, 12, 16 }, { 1, 6 }, { 3, 6, 9, 13, 17 }, { 2, 7 } },
        shopping_spree = { { 5, 15, 45 }, { 5 }, { 6 }, { 6 }, { 7 }, { 7 } },
    },
}

-- Wave-spawn timing

local WAVE_DATA = {
    dead_end = {
        normal = {
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{900,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{960,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW","BLAZES"}},{500,{"WINDOW"}},{920,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW","BLAZES"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{980,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{860,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{860,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{720,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{900,{"WINDOW","BOSS"}}},
        },
        hard = {
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{900,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{960,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW","BLAZES"}},{500,{"WINDOW","BOSS"}},{920,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW","BLAZES"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{980,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{860,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{860,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{720,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW","BOSS"}},{900,{"WINDOW","BOSS"}}},
        },
        rip = {
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{740,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW","BOSS"}},{900,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{960,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW","BLAZES"}},{500,{"WINDOW","BOSS"}},{920,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{940,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{980,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{860,{"WINDOW"}}},
            {{200,{"WINDOW","BOSS"}},{460,{"WINDOW","BOSS"}},{860,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{720,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{880,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW","BOSS"}},{480,{"WINDOW","BOSS"}},{900,{"WINDOW","BOSS"}}},
        },
    },
    bad_blood = {
        normal = {
            {{200,{"WINDOW"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON","BOSS"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","HBM"}},{440,{"WINDOW","HBM"}},{680,{"WINDOW","HBM"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"HBM"}},{480,{"HBM"}},{760,{"HBM"}}},
            {{200,{"WINDOW","HBM"}},{480,{"WINDOW","HBM"}},{760,{"WINDOW","HBM"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","HBM"}},{480,{"WINDOW","HBM"}},{760,{"WINDOW","HBM"}}},
            {{200,{"WINDOW","HBM"}},{440,{"WINDOW","HBM","BOSS"}},{680,{"WINDOW","HBM"}}},
        },
        hard = {
            {{200,{"WINDOW"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON","BOSS"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","HBM"}},{440,{"WINDOW","HBM"}},{680,{"WINDOW","HBM"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"HBM"}},{480,{"HBM"}},{760,{"HBM"}}},
            {{200,{"WINDOW","HBM"}},{480,{"WINDOW","HBM"}},{760,{"WINDOW","HBM"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","HBM"}},{480,{"WINDOW","HBM"}},{760,{"WINDOW","HBM"}}},
            {{200,{"WINDOW","HBM"}},{440,{"WINDOW","HBM","BOSS"}},{680,{"HBM","WINDOW"}}},
        },
        rip = {
            {{200,{"WINDOW"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","SLIME"}},{440,{"WINDOW","SLIME"}},{680,{"WINDOW","SLIME"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","BOSS"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON"}},{680,{"WINDOW","WITHER_SKELETON"}}},
            {{200,{"WINDOW","WITHER_SKELETON"}},{440,{"WINDOW","WITHER_SKELETON","BOSS"}},{680,{"WINDOW","WITHER_SKELETON","BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","HBM"}},{440,{"WINDOW","HBM"}},{680,{"WINDOW","HBM"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW","BOSS"}}},
            {{200,{"HBM"}},{480,{"HBM"}},{760,{"HBM"}}},
            {{200,{"WINDOW","HBM"}},{480,{"WINDOW","HBM"}},{760,{"WINDOW","HBM"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW","HBM"}},{480,{"WINDOW","HBM"}},{760,{"WINDOW","HBM"}}},
            {{200,{"WINDOW","HBM","BOSS"}},{440,{"WINDOW","HBM","BOSS"}},{680,{"WINDOW","HBM"}}},
        },
    },
    alien_arcadium = {
        normal = {
            {{200,{"WINDOW"}},{260,{"WINDOW"}},{320,{"WINDOW"}},{380,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}}},
            {{200,{"WINDOW"}},{260,{"WINDOW"}},{320,{"WINDOW"}},{380,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{340,{"WINDOW"}},{420,{"WINDOW"}},{500,{"WINDOW"}},{560,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{300,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{540,{"WINDOW"}},{620,{"WINDOW"}}},
            {{200,{"WINDOW"}},{300,{"WINDOW"}},{400,{"WINDOW"}},{500,{"WINDOW"}},{600,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{440,{"WINDOW"}},{540,{"WINDOW"}},{660,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{420,{"WINDOW"}},{540,{"WINDOW"}},{640,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{440,{"WINDOW"}},{560,{"WINDOW"}},{680,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{440,{"WINDOW"}},{560,{"WINDOW"}},{680,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{420,{"WINDOW"}},{520,{"WINDOW"}},{620,{"WINDOW"}},{720,{"WINDOW"}}},
            {{200,{"WINDOW"}},{340,{"WINDOW"}},{480,{"WINDOW"}},{620,{"WINDOW"}},{760,{"WINDOW"}},{920,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{440,{"WINDOW"}},{540,{"WINDOW"}},{660,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{300,{"WINDOW"}},{420,{"WINDOW"}},{520,{"WINDOW"}},{620,{"WINDOW"}},{720,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{380,{"WINDOW"}},{460,{"WINDOW"}},{560,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"BOSS"}}},
            {{200,{"WINDOW"}},{460,{"WINDOW"}},{720,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{480,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{420,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"BOSS"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{620,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}},{740,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{420,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{260,{"WINDOW"}},{440,{"WINDOW"}},{500,{"WINDOW"}},{680,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{420,{"WINDOW"}},{640,{"WINDOW"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{600,{"WINDOW"}},{660,{"WINDOW"}}},
            {{200,{"WINDOW"}},{420,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{600,{"WINDOW"}},{660,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{640,{"WINDOW"}},{700,{"WINDOW"}},{780,{"WINDOW"}}},
            {{200,{"WINDOW"}},{320,{"WINDOW"}},{440,{"WINDOW"}},{560,{"WINDOW"}},{680,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}},{740,{"WINDOW"}},{760,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{600,{"WINDOW"}},{660,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{540,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{540,{"WINDOW"}},{640,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{200,{"WINDOW"}},{280,{"WINDOW"}},{360,{"WINDOW"}},{440,{"WINDOW"}},{520,{"WINDOW"}},{600,{"WINDOW"}}},
            {{100,{"BOSS"}}},
            {{100,{"WINDOW"}}},
            {{100,{"WINDOW"}}},
            {{100,{"WINDOW"}}},
            {{100,{"WINDOW"}}},
        },
    },
    prison = {
        normal = {
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"CELL"}},{600,{"WINDOW"}}},
            {{200,{"CELL"}},{340,{"CELL"}},{480,{"CELL"}},{620,{"CELL","POLICE"}}},
            {{200,{"WINDOW","POLICE"}},{340,{"CELL"}},{480,{"WINDOW"}},{620,{"CELL","POLICE"}}},
            {{200,{"WINDOW","POLICE"}},{400,{"WINDOW","POLICE"}},{600,{"WINDOW","POLICE"}}},
            {{200,{"WINDOW","CELL","POLICE"}},{400,{"WINDOW"}},{600,{"CELL"}}},
            {{200,{"WINDOW","POLICE"}},{400,{"WINDOW","CELL"}},{600,{"WINDOW","CELL"}}},
            {{200,{"CELL","POLICE"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"CELL"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"CELL"}},{900,{"BOSS"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"BOSS","WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}},{1100,{"WINDOW"}},{1500,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1100,{"WINDOW"}}},
            {{200,{"BOSS"}}},
            {{0,{"WINDOW"}},{300,{"WINDOW"}},{600,{"WINDOW"}},{900,{"WINDOW"}},{1200,{"BOSS","WINDOW"}},{1500,{"WINDOW"}},{1800,{"WINDOW"}},{2100,{"WINDOW"}}},
        },
        hard = {
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"CELL"}},{600,{"WINDOW"}}},
            {{200,{"CELL"}},{340,{"CELL"}},{480,{"CELL"}},{620,{"CELL","POLICE"}}},
            {{200,{"WINDOW","POLICE"}},{340,{"CELL"}},{480,{"WINDOW"}},{620,{"CELL","POLICE"}}},
            {{200,{"WINDOW","POLICE"}},{400,{"WINDOW","POLICE"}},{600,{"WINDOW","POLICE"}}},
            {{200,{"WINDOW","CELL","POLICE"}},{400,{"WINDOW"}},{600,{"CELL"}}},
            {{200,{"WINDOW","POLICE"}},{400,{"WINDOW","CELL"}},{600,{"WINDOW","CELL"}}},
            {{200,{"CELL","POLICE"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"CELL"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"CELL"}},{900,{"BOSS"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"BOSS","WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}},{1100,{"WINDOW"}},{1500,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1100,{"WINDOW"}}},
            {{200,{"BOSS"}}},
            {{0,{"WINDOW"}},{300,{"WINDOW"}},{600,{"WINDOW"}},{900,{"WINDOW"}},{1200,{"BOSS","WINDOW"}},{1500,{"WINDOW"}},{1800,{"WINDOW"}},{2100,{"WINDOW"}}},
        },
        rip = {
            {{200,{"WINDOW"}},{400,{"WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"CELL"}},{600,{"WINDOW"}}},
            {{200,{"CELL"}},{340,{"CELL"}},{480,{"CELL"}},{620,{"CELL","POLICE"}}},
            {{200,{"WINDOW","POLICE"}},{340,{"CELL"}},{480,{"WINDOW"}},{620,{"CELL","POLICE"}}},
            {{200,{"WINDOW","POLICE"}},{400,{"WINDOW","POLICE"}},{600,{"WINDOW","POLICE"}}},
            {{200,{"WINDOW","CELL","POLICE"}},{400,{"WINDOW"}},{600,{"CELL"}}},
            {{200,{"WINDOW","POLICE"}},{400,{"WINDOW","CELL"}},{600,{"WINDOW","CELL"}}},
            {{200,{"CELL","POLICE"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"CELL"}},{700,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"CELL"}},{900,{"BOSS"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW","POLICE"}},{500,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{680,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{740,{"WINDOW"}}},
            {{200,{"WINDOW"}},{440,{"WINDOW"}},{840,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"BOSS","WINDOW"}}},
            {{200,{"WINDOW"}},{400,{"WINDOW"}},{700,{"WINDOW"}},{1100,{"WINDOW"}},{1500,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{800,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{500,{"WINDOW"}},{900,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1000,{"WINDOW"}}},
            {{200,{"WINDOW"}},{600,{"WINDOW"}},{1100,{"WINDOW"}}},
            {{200,{"BOSS"}}},
            {{0,{"WINDOW"}},{300,{"WINDOW"}},{600,{"WINDOW"}},{900,{"WINDOW"}},{1200,{"BOSS","WINDOW"}},{1500,{"WINDOW"}},{1800,{"WINDOW"}},{2100,{"WINDOW"}}},
        },
    },
}

local ZOMBIES_MAPS_BY_NAME = { ["dead end"] = "dead_end", ["bad blood"] = "bad_blood", ["alien arcadium"] = "alien_arcadium", ["prison"] = "prison" }

local function zombiesMapOf(mapName)
    return mapName and ZOMBIES_MAPS_BY_NAME[mapName:lower()]
end

-- Session state

local inGame = false
local currentMap = nil
local currentDifficulty = "normal"
local currentRound = nil
local observedPatternIndex = {}
local roundStartMs = nil
local firedAudioCues = {}
local trackedPowerUps = {}
local hiddenPlayers = {}

local function resetGame()
    currentDifficulty = "normal"
    currentRound = nil
    observedPatternIndex = {}
    roundStartMs = nil
    firedAudioCues = {}
end

-- Close player visibility

local EQUIPMENT_SLOTS = {
    { slot = "chestplate", source = "chestplate" },
    { slot = "helmet", source = "helmet" },
}

local function setPlayerFlags(entity, invisible)
    local state = entity.state or {}
    local flags = (state.onFire and 0x01 or 0)
        + (state.sneaking and 0x02 or 0)
        + (state.sprinting and 0x08 or 0)
        + (state.usingItem and 0x10 or 0)
        + (invisible and 0x20 or 0)
    starfish.client.entity.setMetadata(entity.id, { { index = 0, type = "byte", value = flags } })
end

local function hidePlayer(entity)
    setPlayerFlags(entity, true)
    for _, piece in ipairs(EQUIPMENT_SLOTS) do
        starfish.client.entity.setEquipment(entity.id, piece.slot, nil)
    end
    hiddenPlayers[entity.id] = entity.equipment or {}
end

local function showPlayer(entityId, equipment)
    local entity = starfish.entities.byId(entityId)
    if not entity then return end
    setPlayerFlags(entity, false)
    for _, piece in ipairs(EQUIPMENT_SLOTS) do
        starfish.client.entity.setEquipment(entityId, piece.slot, equipment[piece.source])
    end
end

local function restoreAllPlayerVisibility()
    for entityId, equipment in pairs(hiddenPlayers) do
        showPlayer(entityId, equipment)
    end
    hiddenPlayers = {}
end

local function refreshPlayerVisibility()
    if not starfish.config.get("playerVisibility.enabled") then
        if next(hiddenPlayers) then restoreAllPlayerVisibility() end
        return
    end

    local me = starfish.players.me()
    if not me then return end
    local range = starfish.config.get("playerVisibility.range")
    for _, entity in ipairs(starfish.entities.players()) do
        if entity.uuid ~= me.uuid then
            local shouldHide = starfish.players.distance(me, entity) <= range
            local isHidden = hiddenPlayers[entity.id] ~= nil
            if shouldHide and not isHidden then
                hidePlayer(entity)
            elseif not shouldHide and isHidden then
                showPlayer(entity.id, hiddenPlayers[entity.id])
                hiddenPlayers[entity.id] = nil
            end
        end
    end
end

-- Prediction engine

local function contains(set, value)
    for _, v in ipairs(set) do
        if v == value then return true end
    end
    return false
end

local function maxOf(set)
    local m = set[1]
    for i = 2, #set do
        if set[i] > m then m = set[i] end
    end
    return m
end

local function firstAtOrAfter(set, target)
    for _, value in ipairs(set) do
        if value >= target then return value end
    end
    return nil
end

local function patternIndexForRound(pattern, round)
    for i = 1, #pattern, 2 do
        if contains(pattern[i], round) then return i end
    end
    return nil
end

local function predictNextRound(pattern, patternIndex, round)
    if patternIndex % 2 == 0 then return nil end
    local rounds, digits = pattern[patternIndex], pattern[patternIndex + 1]
    if #rounds == 0 then return nil end

    local biggest = maxOf(rounds)
    if biggest >= round then
        return firstAtOrAfter(rounds, round)
    end
    if #digits == 0 then return nil end

    local tensDown = round - round % 10
    for _ = 1, 10 do
        for _, digit in ipairs(digits) do
            local candidate = tensDown + digit
            if candidate >= round then return candidate end
        end
        tensDown = tensDown + 10
    end
    return nil
end

local function recordObservation(powerUpId, round)
    if not currentMap or not round or observedPatternIndex[powerUpId] then return end
    local pattern = PATTERNS[currentMap] and PATTERNS[currentMap][powerUpId]
    if not pattern then return end
    local index = patternIndexForRound(pattern, round)
    if index then observedPatternIndex[powerUpId] = index end
end

local function predictedRound(powerUpId)
    if not currentMap or not currentRound then return nil end
    local index = observedPatternIndex[powerUpId]
    if not index then return nil end
    return predictNextRound(PATTERNS[currentMap][powerUpId], index, currentRound)
end

-- Alerts

local function formatPowerUpName(powerUpId)
    return POWER_UPS[powerUpId].color .. "§l" .. POWER_UPS[powerUpId].name:upper() .. "§r"
end

local function announce(section, text)
    local destination = starfish.config.get(section .. ".destination")
    if destination == "self" then starfish.chat.info(text)
    elseif destination == "party" then starfish.chat.sendToServer("/pc " .. text)
    elseif destination == "chat" then starfish.chat.sendToServer("/ac " .. text)
    end
end

local function sendAlert(text)
    if not starfish.config.get("alerts.enabled") then return end
    if starfish.config.get("alerts.sound") then
        starfish.client.world.playSound("random.orb", { volume = 1.0, pitch = 1.2 })
    end
    announce("alerts", text)
end

local function announceForecast()
    if not starfish.config.get("forecast.enabled") then return end

    local powerUpsByRound = {}
    for id in pairs(PATTERNS[currentMap] or {}) do
        local round = predictedRound(id)
        if round then
            powerUpsByRound[round] = powerUpsByRound[round] or {}
            table.insert(powerUpsByRound[round], id)
        end
    end

    local rounds = {}
    for round in pairs(powerUpsByRound) do table.insert(rounds, round) end
    table.sort(rounds)

    local parts = {}
    for _, round in ipairs(rounds) do
        local names = {}
        for _, id in ipairs(powerUpsByRound[round]) do
            table.insert(names, formatPowerUpName(id))
        end
        table.insert(parts, round .. ": " .. table.concat(names, ", "))
    end

    if #parts > 0 then
        announce("forecast", "Power-up rounds - " .. table.concat(parts, " | "))
    end
end

-- Wave timer

local ROUND_START_SOUNDS = { ["mob.wither.spawn"] = true }
local WAVE_AUDIO_LEAD_MS = { 2000, 1000, 0 }
local MS_PER_TICK = 50

local function currentWaves()
    local mapWaves = WAVE_DATA[currentMap]
    local difficultyWaves = mapWaves and (mapWaves[currentDifficulty] or mapWaves.normal)
    return difficultyWaves and difficultyWaves[currentRound]
end

local function updateWaveCountdown()
    if not roundStartMs or not currentRound then return end
    if not starfish.config.get("waveTimer.audio") then return end

    local waves = currentWaves()
    if not waves then return end

    local elapsedMs = starfish.time.now() - roundStartMs
    for index, wave in ipairs(waves) do
        local cueKey = currentRound .. ":" .. index
        local remainingMs = wave[1] * MS_PER_TICK - elapsedMs
        for cue = (firedAudioCues[cueKey] or 0) + 1, #WAVE_AUDIO_LEAD_MS do
            if remainingMs > WAVE_AUDIO_LEAD_MS[cue] then break end
            starfish.client.world.playSound("note.pling", { volume = 1.0, pitch = 1.5 })
            firedAudioCues[cueKey] = cue
        end
    end
end

-- Game state

local function onRoundStart()
    roundStartMs = starfish.time.now()
    firedAudioCues = {}
end

local function onNewRound(round)
    currentRound = round
    announceForecast()
end

local function onGameOver()
    resetGame()
    restoreAllPlayerVisibility()
end

local function onPowerUpSpawn(powerUpId)
    recordObservation(powerUpId, currentRound)
    sendAlert(formatPowerUpName(powerUpId) .. " spawned")
end

local function onPowerUpDespawn(powerUpId)
    sendAlert(formatPowerUpName(powerUpId) .. " is going to despawn soon")
end

-- Chat message parsing

local POWERUP_DURATION_PATTERN = "^([%w_]+) activated ([%a ]+) for %d+s!$"
local POWERUP_PATTERN = "^([%w_]+) activated ([%a ]+)!$"

local function handlePowerUpPickupMessage(text)
    local buyer, powerUpName = text:match(POWERUP_DURATION_PATTERN)
    if not buyer then buyer, powerUpName = text:match(POWERUP_PATTERN) end
    if not buyer then return end

    local powerUpId = POWER_UP_BY_NAME[powerUpName:upper()]
    if powerUpId then
        recordObservation(powerUpId, currentRound)
    end
end

local function handleDifficultyMessage(text)
    if text:find("Hard Difficulty", 1, true) then
        currentDifficulty = "hard"
    elseif text:find("RIP Difficulty", 1, true) then
        currentDifficulty = "rip"
    end
end

-- Power-up nametag detection

local NAMETAG_METADATA_INDEX = 2

local function powerUpFromNametag(rawName)
    local plain = starfish.text.plain(rawName):upper()
    for name, id in pairs(POWER_UP_BY_NAME) do
        if plain:find(name, 1, true) then return id end
    end
    return nil
end

local function isDespawning(rawName)
    return rawName:sub(1, 3) == "§f"
end

local function onNametagChange(entityId, rawName)
    local powerUpId = powerUpFromNametag(rawName)
    if not powerUpId then return end

    local tracked = trackedPowerUps[entityId]
    if not tracked then
        trackedPowerUps[entityId] = { powerUpId = powerUpId, despawning = isDespawning(rawName) }
        onPowerUpSpawn(powerUpId)
        return
    end

    if isDespawning(rawName) and not tracked.despawning then
        tracked.despawning = true
        onPowerUpDespawn(powerUpId)
    end
end

-- In-game event handlers

local function handleEntityMetadata(event)
    if not event.entity then return end
    local entity = starfish.entities.byId(event.entity.entityId)
    if not entity or entity.kind ~= "minecraft:armor_stand" then return end

    for _, entry in ipairs(event.metadata) do
        if entry.key == NAMETAG_METADATA_INDEX and entry.type == "string" then
            onNametagChange(entity.id, entry.value)
        end
    end
end

local function handleEntityDespawn(event)
    for _, id in ipairs(event.entityIds) do
        trackedPowerUps[id] = nil
    end
end

local function handleTitle(event)
    if event.message and event.message:find("Game Over!", 1, true) then
        onGameOver()
    end
end

local function handleTeamUpdate(event)
    if not event.prefix then return end
    local round = tonumber(event.prefix:match("^§c§lRound (%d+)$"))
    if round and round ~= currentRound then
        onNewRound(round)
    end
end

local function handleChatMessage(msg)
    if msg.kind ~= "chat" then return end

    local text = starfish.text.plain(msg.legacy)
    handleDifficultyMessage(text)
    handlePowerUpPickupMessage(text)
end

local function handleSound(event)
    if ROUND_START_SOUNDS[event.name] then
        onRoundStart()
    end
end

-- Session lifecycle

local sessionSubscriptions = {}

local function subscribeInGame()
    sessionSubscriptions = {
        starfish.events.on("entity:metadata", handleEntityMetadata),
        starfish.events.on("chat:title", handleTitle),
        starfish.events.on("team:update", handleTeamUpdate),
        starfish.events.on("world:sound", handleSound),
        starfish.entities.onDespawn(handleEntityDespawn),
        starfish.chat.onReceive(handleChatMessage),
        starfish.timers.everyTick(updateWaveCountdown),
        starfish.timers.everyTick(refreshPlayerVisibility),
    }
end

local function unsubscribeInGame()
    for _, subscription in ipairs(sessionSubscriptions) do
        subscription:off()
    end
    sessionSubscriptions = {}
end

local function beginSession(map)
    if map ~= currentMap then
        currentMap = map
        observedPatternIndex = {}
    end
    if inGame then return end

    inGame = true
    subscribeInGame()
    starfish.log.debug("Session started on " .. map)
end

local function endSession()
    if not inGame then return end

    inGame = false
    unsubscribeInGame()
    resetGame()
    restoreAllPlayerVisibility()
    trackedPowerUps = {}
    starfish.log.debug("Session ended")
end

-- Event wiring

starfish.events.on("hypixel:location", function(event)
    local map = event.success and event.location and zombiesMapOf(event.location.map)
    if map then
        beginSession(map)
    else
        endSession()
    end
end)

starfish.events.on("world:respawn", endSession)
starfish.events.on("session:join", endSession)

function plugin.onDisable()
    unsubscribeInGame()
    restoreAllPlayerVisibility()
end

-- Startup

local restoredLocation = starfish.plugins.require("hypixel-mod-api").getLocation()
local restoredMap = restoredLocation and zombiesMapOf(restoredLocation.map)
if restoredMap then
    beginSession(restoredMap)
end
