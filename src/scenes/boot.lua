local boot = {}

function boot:load(context)
    self.context = context
    self.setScene("main_menu", context)
end

return boot
