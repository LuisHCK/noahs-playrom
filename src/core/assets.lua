local manifest = require("src.data.asset_manifest")

local assets = {}

function assets:get(key)
    return manifest[key]
end

return assets
