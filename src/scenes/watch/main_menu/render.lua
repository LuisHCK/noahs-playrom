local Spritesheet = require("src.core.spritesheet")
local drawUtils = require("src.ui.draw_utils")

local render = {}
local DOT_RADIUS = 5
local DOT_SPACING = 16
local OVERLAY_COLOR = { 0, 0, 0, 0.45 }
local guiSpritesheet

local function getUIButtons()
	-- Lazy-load and reuse the gui spritesheet.
	if guiSpritesheet ~= nil then
		return guiSpritesheet
	end

	guiSpritesheet = Spritesheet.new({
		path = "assets/images/spritesheets/ui-buttons.png",
		columns = 4,
		rows = 5,
		spriteWidth = 60,
		spriteHeight = 57,
	})

	return guiSpritesheet
end

local function drawMenuBackground(asset, viewport)
	if asset and asset.type == "image" then
		local image = drawUtils.getImage(asset.path)
		if image then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(image, 0, 0, 0, viewport.width / image:getWidth(), viewport.height / image:getHeight())
			return
		end
	end
	love.graphics.setColor(drawUtils.colorFrom(asset))
	love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)
end

local function wrapIndex(index, total)
	return ((index - 1 + total) % total) + 1
end

function render.draw(state, layout)
	local viewport = state.context.viewport
	local i18n = state.context.i18n
	local assets = state.context.assets
	local fonts = state.context.fonts
	local cardRect = layout.cardRect
	local total = #state.modules
	local uiButtons = getUIButtons()

	-- Background via asset profile.
	drawMenuBackground(assets:get("menuBackground"), viewport)

	-- Compute slide offset.
	local slideOffset = 0
	if state.swipeAnim.active then
		slideOffset = state.swipeAnim.progress * viewport.width * state.swipeAnim.direction * -1
	elseif state.touchCurrentX then
		slideOffset = state.touchCurrentX - state.touchStartX
	end

	-- Draw carousel cards: previous, current, next.
	for _, offset in ipairs({ -1, 0, 1 }) do
		local index = wrapIndex(state.currentIndex + offset, total)
		local module = state.modules[index]
		local cardX = cardRect.x + offset * viewport.width + slideOffset
		local rect = { x = cardX, y = cardRect.y, width = cardRect.width, height = cardRect.height }

		-- Card image via asset profile (e.g. "moduleCardAlphabet").
		local cardKey = "moduleCard" .. module.key:sub(1, 1):upper() .. module.key:sub(2)
		local cardAsset = assets:get(cardKey) or assets:get("moduleCard")
		drawUtils.drawAssetToRect(cardAsset, rect, 12)

		-- Module name label below card.
		local moduleTitle = (i18n:getModuleData(module.key) or {}).title or module.key
		love.graphics.setColor(0.1, 0.1, 0.1, 1)
		love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.04))
		love.graphics.printf(moduleTitle, cardX, layout.cardTextRect.y, layout.cardTextRect.width, "center")

		-- Overlay if disabled.
		if not module.enabled then
			love.graphics.setColor(OVERLAY_COLOR)
			love.graphics.rectangle("fill", cardX, cardRect.y, cardRect.width, cardRect.height, 12, 12)
		end
	end

	-- Page indicator dots.
	local dotsY = layout.dotsRect.y + layout.dotsRect.height * 0.5
	local totalDotsWidth = total * (DOT_RADIUS * 2) + (total - 1) * DOT_SPACING
	local dotsStartX = (viewport.width - totalDotsWidth) * 0.5 + DOT_RADIUS

	for i = 1, total do
		local cx = dotsStartX + (i - 1) * (DOT_RADIUS * 2 + DOT_SPACING)
		if i == state.currentIndex then
			love.graphics.setColor(0.2, 0.5, 0.8, 1)
			love.graphics.circle("fill", cx, dotsY, DOT_RADIUS)
		else
			love.graphics.setColor(0.6, 0.6, 0.6, 1)
			love.graphics.circle("line", cx, dotsY, DOT_RADIUS)
		end
	end

	-- Title text.
	love.graphics.setColor(0.1, 0.1, 0.1, 1)
	love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.055))
	love.graphics.printf(
		i18n:t("appTitle"),
		layout.titleRect.x,
		layout.titleRect.y + 10,
		layout.titleRect.width,
		"center"
	)

	-- Settings button.
	local sb = layout.settingsButton
	-- love.graphics.setColor(0.9, 0.85, 0.75, 1)
	-- love.graphics.rectangle("fill", sb.x, sb.y, sb.width, sb.height, 10, 10)
	-- love.graphics.setColor(0.1, 0.1, 0.1, 1)
	-- love.graphics.rectangle("line", sb.x, sb.y, sb.width, sb.height, 10, 10)
	-- love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.035))
	-- love.graphics.printf("⚙", sb.x, sb.y + 10, sb.width, "center")
	love.graphics.setColor(1, 1, 1, 1)
	uiButtons:drawByIndex(1, sb.x, sb.y, sb.width, sb.height)

	-- Toast for "Coming Soon".
	if state.toastTimer > 0 then
		local alpha = math.min(1, state.toastTimer / 0.3)
		love.graphics.setColor(0, 0, 0, 0.7 * alpha)
		local tw, th = 160, 36
		local tx = (viewport.width - tw) * 0.5
		love.graphics.rectangle("fill", tx, layout.toastRect.y, tw, th, 18, 18)
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.setFont(fonts:getForViewport(viewport, "cardLetter", 0.028))
		love.graphics.printf(i18n:t("comingSoon"), tx, layout.toastRect.y + 8, tw, "center")
	end
end

return render
