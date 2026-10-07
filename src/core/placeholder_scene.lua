local scene_shell = require("src.core.scene_shell")

local placeholder = {}

function placeholder.build(moduleId)
    local scene = {}

    function scene:load(context)
        self.context = context
        self.moduleId = moduleId
        self.backButton = scene_shell.buildBackButton(function()
            self.setScene("main_menu", self.context)
        end)
    end

    function scene:draw()
        local i18n = self.context.i18n
        local assets = self.context.assets
        local viewport = self.context.viewport
        local content = viewport:getContentArea()
        local moduleData = i18n:getModuleData(self.moduleId)
        local cards = moduleData.cards or {}

        scene_shell.drawBackground(assets:get("panelBackground"), viewport)
        scene_shell.drawTitle(moduleData.title or self.moduleId, moduleData.subtitle or "", content, 70, 110)
        scene_shell.drawBackButton(self.backButton, i18n)

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

        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.printf(i18n:t("comingSoon"), content.x, content.y + 660, content.width, "center")
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

return placeholder
