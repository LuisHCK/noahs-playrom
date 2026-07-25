local render = {}
local Spritesheet = require("src.core.spritesheet")
local BACK_FILL = { 0.9, 0.85, 0.75, 1 }
local BACK_BORDER = { 0.1, 0.1, 0.1, 1 }
local BTN_FILL = { 0.2, 0.5, 0.8, 1 }
local guiSpriteSheet

local function getGuiSpriteSheet()
	if guiSpriteSheet then
		return guiSpriteSheet
	end

	guiSpriteSheet = Spritesheet.new({
		path = "assets/images/spritesheets/ui-buttons.png",
		columns = 4,
		rows = 5,
		spriteWidth = 60,
		spriteHeight = 57,
	})

	return guiSpriteSheet
end

function render.draw(state, layout)
	local viewport = state.context.viewport
	local fonts = state.context.fonts
	local uiButtons = getGuiSpriteSheet()

	-- Background.
	love.graphics.setColor(0.96, 0.93, 0.87, 1)
	love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)

	-- Back button.
	local bb = layout.backButton
	love.graphics.setColor(BACK_FILL)
	love.graphics.rectangle("fill", bb.x, bb.y, bb.width, bb.height, 12, 12)
	love.graphics.setColor(BACK_BORDER)
	love.graphics.rectangle("line", bb.x, bb.y, bb.width, bb.height, 12, 12)
	love.graphics.setColor(0.1, 0.1, 0.1, 1)
	love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.055))
	love.graphics.printf("←", bb.x, bb.y + (bb.height - 30) * 0.5, bb.width, "center")

	-- Title.
	love.graphics.setColor(0.1, 0.1, 0.1, 1)
	love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.045))
	love.graphics.printf("Settings", layout.titleRect.x, layout.titleRect.y, layout.titleRect.width, "center")

	-- Volume button.
	local vr = layout.volumeRect
	love.graphics.setColor(BTN_FILL)
	love.graphics.rectangle("fill", vr.x, vr.y, vr.width, vr.height, 16, 16)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.04))
	love.graphics.printf("Volume: " .. layout.volumeLabel(state.volume), vr.x, vr.y + 24, vr.width, "center")
end

return render
