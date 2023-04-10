s=screen
setColor=s.setColor

---@class Placement
---@field x number
---@field y number
---@field w number
---@field h number

---@param placement Placement
---@param text string
function drawTextBox(placement, text)
    s.drawTextBox(placement.x, placement.y, placement.w + 1, placement.h, text, 0, 0)
end

---@param placement Placement
function drawRect(placement)
    s.drawRect(placement.x, placement.y, placement.w, placement.h)
end

---@param placement Placement
function drawRectFilled(placement)
    s.drawRectF(placement.x, placement.y, placement.w, placement.h)
end

function setDefaultColor()
    setColor(100, 100, 100)
end

---@param px number
---@param py number
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
function is_in_rect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

---@param placement Placement
---@param px number
---@param py number
---@return boolean
function buttonIsPressed(placement,px,py)
    return is_in_rect(px, py, placement.x, placement.y, placement.w, placement.h)
end

---@param placement Placement
---@param text string
---@param is_pressed boolean
function drawButton(placement, text, is_pressed)
    if is_pressed then
        setColor(50, 50, 50)
    else
        setColor(10, 10, 10)
    end
    drawRectFilled(placement)
    setDefaultColor()
    drawTextBox(placement, text)
end
