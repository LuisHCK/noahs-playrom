local Button = require("src.ui.button")
local modules = require("src.core.modules")

local model = {}

function model.createState(context, layout)
    local state = {
        context = context,
        layout = layout,
        viewportLayout = {
            width = context.viewport.width,
            height = context.viewport.height
        },
        moduleButtons = {},
        languageButton = nil,
        transitionDelay = 0.5,
        transitionTimer = 0,
        queuedScene = nil
    }

    for index, module in ipairs(modules.list()) do
        local slot = layout.moduleSlots[index]
        state.moduleButtons[index] = Button.new({
            id = module.id,
            x = slot.x,
            y = slot.y,
            width = slot.width,
            height = slot.height,
            text = module.id,
            onClick = function(id)
                -- Delay transition to let tap animation breathe.
                if state.transitionTimer <= 0 then
                    local descriptor = modules.get(id)
                    if descriptor then
                        state.queuedScene = descriptor.scene
                        state.transitionTimer = state.transitionDelay
                    end
                end
            end
        })
        state.moduleButtons[index].visualScale = 1
        state.moduleButtons[index].assetKey = module.cardAssetKey
    end

    state.languageButton = Button.new({
        id = "language",
        x = layout.languageButton.x,
        y = layout.languageButton.y,
        width = layout.languageButton.width,
        height = layout.languageButton.height,
        text = "LANG",
        onClick = function()
            context.i18n:toggleLanguage()
            context.saveSettings()
        end
    })

    return state
end

function model.applyLayout(state, layout)
    state.layout = layout

    for index, button in ipairs(state.moduleButtons) do
        local slot = layout.moduleSlots[index]
        button.x = slot.x
        button.y = slot.y
        button.width = slot.width
        button.height = slot.height
    end

    state.languageButton.x = layout.languageButton.x
    state.languageButton.y = layout.languageButton.y
    state.languageButton.width = layout.languageButton.width
    state.languageButton.height = layout.languageButton.height

    state.viewportLayout.width = state.context.viewport.width
    state.viewportLayout.height = state.context.viewport.height
end

function model.ensureLayout(state, layoutBuilder)
    local viewport = state.context.viewport
    local current = state.viewportLayout
    if current.width ~= viewport.width or current.height ~= viewport.height then
        model.applyLayout(state, layoutBuilder(viewport))
    end
end

return model
