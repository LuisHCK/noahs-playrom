local Button = require("src.ui.button")
local modulesData = require("src.data.content.modules")

local model = {}

local moduleOrder = { "alphabet", "animals", "numbers", "universe" }

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
        profileButton = nil,
        transitionDelay = 0.5,
        transitionTimer = 0,
        queuedScene = nil
    }

    state.toggleAssetProfile = function()
        if context.assets:getProfile() == "prototype" then
            context.assets:setProfile("final")
        else
            context.assets:setProfile("prototype")
        end
        context.saveSettings()
    end

    for index, moduleId in ipairs(moduleOrder) do
        local slot = layout.moduleSlots[index]
        state.moduleButtons[index] = Button.new({
            id = moduleId,
            x = slot.x,
            y = slot.y,
            width = slot.width,
            height = slot.height,
            text = moduleId,
            onClick = function(id)
                -- Delay transition to let tap animation breathe.
                if state.transitionTimer <= 0 then
                    state.queuedScene = modulesData[id].scene
                    state.transitionTimer = state.transitionDelay
                end
            end
        })
        state.moduleButtons[index].visualScale = 1
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

    state.profileButton = Button.new({
        id = "profile",
        x = layout.profileButton.x,
        y = layout.profileButton.y,
        width = layout.profileButton.width,
        height = layout.profileButton.height,
        text = "PROFILE",
        onClick = function()
            state.toggleAssetProfile()
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

    state.profileButton.x = layout.profileButton.x
    state.profileButton.y = layout.profileButton.y
    state.profileButton.width = layout.profileButton.width
    state.profileButton.height = layout.profileButton.height

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
