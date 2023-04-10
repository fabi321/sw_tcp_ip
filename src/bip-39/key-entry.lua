require('bip-39/prompt')

function onTick()
    pressX = 0
    pressY = 0
    if input.getBool(2) then
        pressX = input.getNumber(5)
        pressY = input.getNumber(6)
    end
    if input.getBool(1) then
        pressX = input.getNumber(3)
        pressY = input.getNumber(4)
    end
    result = bip_39_keyboard_on_tick(pressX, pressY)
    if result ~= nil then
        output.setNumber(1, result)
    end
end

function onDraw()
    bip_39_keyboard_on_draw("enter wifi pw")
end
