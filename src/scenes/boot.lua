local config = require("src.core.config")

local boot = {}

function boot:load(context)
    self.context = context
    if config.deviceProfile == "watch" then
        self.setScene("watch_main_menu", context)
    else
        self.setScene("main_menu", context)
    end
end

return boot
