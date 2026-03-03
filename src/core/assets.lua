local config = require("src.core.config")
local manifest = require("src.data.asset_manifest")

local profileCache = {}

local assets = {
    activeProfile = config.defaultAssetProfile
}

-- Lazy-load and cache profile tables.
local function loadProfile(profileName)
    if profileCache[profileName] then
        return profileCache[profileName]
    end

    local ok, profile = pcall(require, "src.data.asset_profiles." .. profileName)
    if not ok then
        profile = require("src.data.asset_profiles.prototype")
    end

    profileCache[profileName] = profile
    return profile
end

function assets:setProfile(profileName)
    self.activeProfile = profileName
end

function assets:getProfile()
    return self.activeProfile
end

function assets:get(key)
    -- Always fallback to manifest defaults if profile key is missing.
    local profile = loadProfile(self.activeProfile)
    local manifestEntry = manifest[key]
    if not manifestEntry then
        return nil
    end
    return profile[key] or manifestEntry.fallback
end

return assets
