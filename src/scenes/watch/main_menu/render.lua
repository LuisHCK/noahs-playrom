local render = {}
local DOT_RADIUS = 5
local DOT_SPACING = 16
local CARD_COLOR = { 0.96, 0.93, 0.87, 1 }
local OVERLAY_COLOR = { 0, 0, 0, 0.45 }

local function wrapIndex(index, total)
    return ((index - 1 + total) % total) + 1
end

function render.draw(state, layout)
    local viewport = state.context.viewport
    local i18n = state.context.i18n
    local cardRect = layout.cardRect
    local total = #state.modules

    -- Background.
    love.graphics.setColor(CARD_COLOR)
    love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)

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

        -- Card background.
        love.graphics.setColor(CARD_COLOR)
        love.graphics.rectangle("fill", cardX, cardRect.y, cardRect.width, cardRect.height, 12, 12)

        -- Module name label.
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.printf(module.key, cardX, cardRect.y + cardRect.height * 0.4, cardRect.width, "center")

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
        local cy = dotsY
        if i == state.currentIndex then
            love.graphics.setColor(0.2, 0.5, 0.8, 1)
            love.graphics.circle("fill", cx, cy, DOT_RADIUS)
        else
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
            love.graphics.circle("line", cx, cy, DOT_RADIUS)
        end
    end

    -- Title text.
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf(i18n:t("appTitle"), layout.titleRect.x, layout.titleRect.y + 10, layout.titleRect.width, "center")

    -- Toast for "Coming Soon".
    if state.toastTimer > 0 then
        local alpha = math.min(1, state.toastTimer / 0.3)
        love.graphics.setColor(0, 0, 0, 0.7 * alpha)
        local tw = 160
        local th = 36
        local tx = (viewport.width - tw) * 0.5
        local ty = layout.toastRect.y
        love.graphics.rectangle("fill", tx, ty, tw, th, 18, 18)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(i18n:t("comingSoon"), tx, ty + 8, tw, "center")
    end
end

return render
