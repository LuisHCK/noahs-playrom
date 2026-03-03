local config = require("src.core.config")
local en = require("src.data.locales.en")
local es = require("src.data.locales.es")

local locales = {
    en = en,
    es = es
}

local i18n = {
    language = config.defaultLanguage
}

function i18n:setLanguage(language)
    if locales[language] then
        self.language = language
    end
end

function i18n:toggleLanguage()
    if self.language == "en" then
        self.language = "es"
    else
        self.language = "en"
    end
end

function i18n:getLanguage()
    return self.language
end

function i18n:t(key)
    -- Fallback chain: selected locale -> EN -> raw key.
    local selected = locales[self.language] or locales.en
    return selected[key] or locales.en[key] or key
end

function i18n:getModuleData(moduleId)
    -- Module-scoped localized payload used by scene renderers.
    local selected = locales[self.language] or locales.en
    local modules = selected.modules or {}
    return modules[moduleId] or {}
end

return i18n
