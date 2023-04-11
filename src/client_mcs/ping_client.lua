require('util')
require('packeting')
require('icmp/client')
require('ui/basic')
require('ui/address_field')
require('client_mcs/ping_client_buttons')

---@type number[]
ping_results = {}

function onTick()
    for i=1,8 do
        sn(i, 0)
    end
    sn(17, 65535)
    is_on = gb(9)
    sb(1, is_on)
    ping_active = gb(10)
    own_address = ADDRESS_FORMAT:format(gn(17))
    ping_client_address = (("f"):pack(gn(18))):gsub(" ", "")
    address_field_current_address = ping_client_address
    ping_client_set_address = gb(11)
    local packet = to_packet(1)
    if ping_active then
        local result = icmp_ping(packet, ping_client_address)
        if type(result) == "table" then
            to_channels(result, 1)
        elseif result then
            ping_results[#ping_results + 1] = result
        end
    end
end

function onDraw()
    drawTextBox(own_address_label, own_address)
    drawButton(on_button, "on", is_on)
    drawButton(ping_button, "ping", ping_active)
    drawButton(destination_address, ping_client_address, ping_client_set_address)
    local pos = 3
    for i=math.max(#ping_results - 6, 1),#ping_results do
        local text = ("ping resp %i ticks"):format(ping_results[i])
        if ping_results[i] < 0 then
            text = "timeout"
        end
        screen.drawText(0, pos * 6, text)
        pos = pos + 1
    end
    if ping_client_set_address then
        address_field_on_draw("enter dest addr")
    end
end
