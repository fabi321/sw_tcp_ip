require('ui/basic')

---@type string
address_field_current_address = ""
---@type boolean
address_field_last_press = false

address_field_keyboard_layout = {
    "01234567>",
    "89abcdef<"
}

---@param to_execute fun(posX: number, posY: number, w: number, h: number, key: string, highlighted: boolean): boolean
---@return boolean
function address_field_iterate_over_keys(to_execute)
    ---@type boolean
    local result = false
    for i, row in ipairs(address_field_keyboard_layout) do
        for j = 1, #row do
            local posX, posY, w, h, key, highlighted = j * 8, i * 6 + 6, 7, 5, row:sub(j, j), false
            if key == "<" then
                w = 15
                key = "<-"
                highlighted = #address_field_current_address > 0
            elseif key == ">" then
                w = 15
                key = "->"
                highlighted = #address_field_current_address == 4
            else
                highlighted = #address_field_current_address < 4
            end
            result = result or to_execute(posX, posY, w, h, key, highlighted)
        end
    end
    return result
end

---@param posX number
---@param posY number
---@param w number
---@param h number
---@param key string
---@param highlighted boolean
---@return boolean
function address_field_press_key(posX, posY, w, h, key, highlighted)
    if highlighted and is_in_rect(address_field_press_x, address_field_press_y, posX, posY, w, h) then
        sn(1, (key:byte(1, 1)))
        if key == "->" then
            return true
        elseif key == "<-" then
            address_field_current_address = address_field_current_address:sub(1, -2)
        else
            address_field_current_address = address_field_current_address .. key
        end
    end
    return false
end

---@param pressX number
---@param pressY number
---@return boolean, nil | string
function address_field_on_tick(pressX, pressY)
    local current_press = pressX ~= 0 or pressY ~= 0
    local relevant_press = current_press and not address_field_last_press
    address_field_last_press = current_press
    address_field_press_x = pressX
    address_field_press_y = pressY
    if relevant_press then
        local result = address_field_iterate_over_keys(address_field_press_key)
        if result then
            return true, address_field_current_address
        end
    end
    return current_press, nil
end

---@param posX number
---@param posY number
---@param w number
---@param h number
---@param key string
---@param highlighted boolean
---@return boolean
function address_field_draw_key(posX, posY, w, h, key, highlighted)
    if highlighted then
        setColor(10, 10, 10)
        screen.drawRectF(posX, posY, w, h)
        setColor(100, 100, 100)
    else
        setColor(10, 10, 10)
    end
    screen.drawTextBox(posX, posY, w, h, key, 0, 0)
    return false
end

---@param title string
function address_field_on_draw(title)
    setColor(0, 0, 0)
    screen.drawRectF(0, 0, 96, 30)
    setColor(100, 100, 100)
    screen.drawTextBox(0, 0, 96, 6, title, 0)
    screen.drawText(0, 6, address_field_current_address)
    address_field_iterate_over_keys(address_field_draw_key)
end
