local Button = require("src.ui.button")
local audioMap = require("src.data.audio_map")

local moduleScene = {}

local function colorFrom(asset)
    if asset and asset.type == "color" then
        return asset.value
    end
    return { 1, 1, 1, 1 }
end

function moduleScene.build(moduleId)
    local scene = {}
    local EDGE_MARGIN = 32

    function scene:load(context)
        self.context = context
        self.moduleId = moduleId
        self.backButton = Button.new({
            id = "back",
            x = EDGE_MARGIN,
            y = EDGE_MARGIN,
            width = 140,
            height = 50,
            onClick = function()
                self.setScene("main_menu", self.context)
            end
        })
    end

    function scene:draw()
        local i18n = self.context.i18n
        local assets = self.context.assets
        local viewport = self.context.viewport
        local content = viewport:getContentArea()
        local moduleData = i18n:getModuleData(self.moduleId)
        local cards = moduleData.cards or {}

        love.graphics.setColor(colorFrom(assets:get("panelBackground")))
        love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)

        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.printf(moduleData.title or self.moduleId, content.x, content.y + 70, content.width, "center")
        love.graphics.printf(moduleData.subtitle or "", content.x, content.y + 110, content.width, "center")

        love.graphics.setColor(0.9, 0.85, 0.75, 1)
        love.graphics.rectangle("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("line", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
        love.graphics.printf(i18n:t("back"), self.backButton.x, self.backButton.y + 16, self.backButton.width, "center")

        local cardWidth, cardHeight = 220, 220
        local totalWidth = #cards * cardWidth + (#cards - 1) * 24
        local startX = content.x + (content.width - totalWidth) * 0.5

        for index, label in ipairs(cards) do
            local x = startX + (index - 1) * (cardWidth + 24)
            local y = content.y + 260
            love.graphics.setColor(0.78, 0.63, 0.45, 1)
            love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 14, 14)
            love.graphics.setColor(0.12, 0.12, 0.12, 1)
            love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 14, 14)
            love.graphics.printf(label, x, y + 98, cardWidth, "center")
        end

        local lang = i18n:getLanguage()
        local map = audioMap[self.moduleId] and audioMap[self.moduleId][lang] or {}
        love.graphics.printf("Audio key: " .. (map.intro or "n/a"), content.x, content.y + 660, content.width, "center")
    end

    function scene:mousepressed(x, y)
        self.backButton:press(x, y)
    end

    function scene:mousereleased(x, y)
        self.backButton:release(x, y)
    end

    function scene:touchpressed(_, x, y)
        self.backButton:press(x, y)
    end

    function scene:touchreleased(_, x, y)
        self.backButton:release(x, y)
    end

    function scene:touchmoved(_, x, y)
        self.backButton:press(x, y)
    end

    return scene
end

return moduleScene
