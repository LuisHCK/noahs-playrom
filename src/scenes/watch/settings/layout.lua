local VOLUME_LEVELS = { 0, 0.1, 0.3, 0.6, 0.8, 1 }
local VOLUME_LABELS = { "0%", "10%", "30%", "60%", "80%", "100%" }

local function findLevel(vol)
    for i, v in ipairs(VOLUME_LEVELS) do
        if v == vol then return i end
    end
    return 6
end

local function build(viewport)
    local w = viewport.width
    local h = viewport.height

    return {
        backButton = { x = 8, y = 8, width = 120, height = 120 },
        volumeRect = { x = w * 0.1, y = h * 0.35, width = w * 0.8, height = 80 },
        titleRect = { x = 0, y = h * 0.15, width = w, height = 40 },

        nextVolume = function(currentVol)
            local idx = findLevel(currentVol)
            idx = (idx % #VOLUME_LEVELS) + 1
            return VOLUME_LEVELS[idx]
        end,

        volumeLabel = function(currentVol)
            return VOLUME_LABELS[findLevel(currentVol)]
        end
    }
end

return { build = build }
