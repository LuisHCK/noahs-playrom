local grid = {}

function grid.build(rect, columns, rows, gap)
    local items = {}
    local cellWidth = (rect.width - (columns - 1) * gap) / columns
    local cellHeight = (rect.height - (rows - 1) * gap) / rows

    local index = 1
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            items[index] = {
                x = rect.x + column * (cellWidth + gap),
                y = rect.y + row * (cellHeight + gap),
                width = cellWidth,
                height = cellHeight
            }
            index = index + 1
        end
    end

    return items
end

return grid
