require('util')
require('ui/basic')
require('ui/address_field')
require('client_mcs/ping_client_buttons')

---@type boolean
ping_client_set_address = false

-- tumfl preserve
function onTick()
    isPress1 = input.getBool(1)
    isPress2 = input.getBool(2)

    input1X = input.getNumber(3)
    input1Y = input.getNumber(4)
    input2X = input.getNumber(5)
    input2Y = input.getNumber(6)

    for i=1,32 do
        output.setBool(i, false)
    end

    if ping_client_set_address then
        local pressX, pressY = 0, 0
        if isPress1 then
            pressX = input1X
            pressY = input1Y
        elseif isPress2 then
            pressX = input2X
            pressY = input2Y
        end
        _, tick_result = address_field_on_tick(pressX, pressY)
        if tick_result ~= nil then
            ping_client_set_address = false
        else
            output.setBool(11, true)
        end
        output.setNumber(18, (("f"):unpack(address_field_current_address.."    ")))
    else
        Button(on_button, 9)
        Button(ping_button, 10)
        if (isPress1 and buttonIsPressed(destination_address, input1X, input1Y)) or (isPress2 and buttonIsPressed(destination_address, input2X, input2Y)) then
            ping_client_set_address = true
        end
    end
end

function Button(button, channel)
	if (isPress1 and buttonIsPressed(button, input1X, input1Y)) or (isPress2 and buttonIsPressed(button, input2X, input2Y)) then
		output.setBool(channel,true)
	end
end
