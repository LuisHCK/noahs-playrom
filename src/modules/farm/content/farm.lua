-- Farm world layout. `x` values are world-space centers. `y` sets an entry's
-- baseline (the world Y of its bottom edge); omit it to use the default baseline
-- (config.baselineY, 620). Increase `y` to move an entry down, decrease to move up.
return {
    structures = {
        { id = "barn", kind = "barn", x = 280, w = 360, h = 300 },
        { id = "stable", kind = "stable", x = 860, w = 340, h = 260 },
        { id = "coop", kind = "coop", x = 1300, w = 260, h = 190 },
        { id = "pond", kind = "pond", x = 1830, w = 460, h = 150 },
        { id = "mudPen", kind = "mudPen", x = 2380, w = 380, h = 150 },
        { id = "field", kind = "field", x = 3080, w = 660, h = 120 },
        { id = "doghouse", kind = "doghouse", x = 3720, w = 170, h = 160 },
        { id = "cottage", kind = "cottage", x = 4300, w = 330, h = 290 },
        { id = "windmill", kind = "windmill", x = 4880, w = 240, h = 400 }
    },
    animals = {
        { key = "cow", home = "barn", x = 520, w = 210, h = 150 },
        { key = "horse", home = "stable", x = 1000, w = 200, h = 180 },
        { key = "hen", home = "coop", x = 1350, w = 90, h = 85 },
        { key = "rooster", home = "coop", x = 1460, w = 95, h = 100 },
        { key = "duck", home = "pond", x = 1900, w = 130, h = 90 },
        { key = "pig", home = "mudPen", x = 2450, w = 170, h = 115 },
        { key = "sheep", home = "field", x = 3080, w = 160, h = 125 },
        { key = "dog", home = "doghouse", x = 3880, w = 125, h = 105 },
        { key = "cat", home = "cottage", x = 4400, w = 105, h = 95 }
    }
}
