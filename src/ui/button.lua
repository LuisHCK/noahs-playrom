local button = {}
button.__index = button

function button.new(params)
    local self = setmetatable({}, button)
    self.id = params.id
    self.x = params.x
    self.y = params.y
    self.width = params.width
    self.height = params.height
    self.text = params.text
    self.onClick = params.onClick
    self.pressed = false
    return self
end

function button:contains(px, py)
    return px >= self.x and px <= self.x + self.width and py >= self.y and py <= self.y + self.height
end

function button:press(px, py)
    self.pressed = self:contains(px, py)
end

function button:release(px, py)
    local wasPressed = self.pressed
    self.pressed = false

    if wasPressed and self:contains(px, py) and self.onClick then
        self.onClick(self.id)
    end
end

return button
