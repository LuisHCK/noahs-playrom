local camera = {}

function camera.clamp(x, worldWidth, viewWidth)
    local maxX = math.max(0, worldWidth - viewWidth)
    if x < 0 then
        return 0
    elseif x > maxX then
        return maxX
    end
    return x
end

function camera.update(cam, dt, config, worldWidth, viewWidth)
    local velocity = cam.velocity or 0

    if velocity ~= 0 then
        cam.x = cam.x + velocity * dt
        velocity = velocity * math.exp(-config.friction * dt)
        if math.abs(velocity) < config.minVelocity then
            velocity = 0
        end
        cam.velocity = velocity
    end

    local maxX = math.max(0, worldWidth - viewWidth)
    if cam.x < 0 then
        cam.x = 0
        cam.velocity = 0
    elseif cam.x > maxX then
        cam.x = maxX
        cam.velocity = 0
    end
end

function camera.parallax(camX, factor)
    return camX * factor
end

return camera
