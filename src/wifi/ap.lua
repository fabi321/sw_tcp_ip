i=input;o=output
gn=i.getNumber;gb=i.getBool;sn=o.setNumber;sb=o.setBool

require('packeting')
require('packet_queue')
require('wifi/frequency_core')

---@param f number
---@returns number
function f_to_i(f)
    return ("I4"):unpack((("f"):pack(f)))
end

---@param i number
---@returns number
function i_to_f(i)
    return ("f"):unpack((("I4"):pack(i)))
end

---@type number
tick = 0
---@type number
secret = -1
is_wifi = true
largest_interface_id = 2

function onTick()
    is_wifi = true
    largest_interface_id = 2
    for i=1,32 do
        sn(i, 0)
    end
    rand_source = gn(17)
    if secret == -1 then
        if rand_source ~= 0 then
            xorshift:seed(f_to_i(rand_source))
            xorshift:skip()
            secret = xorshift:next_int()  & 0x7fffff
        end
    else
        tick = tick + 1
        local wifi_packet = to_packet(1)
        if wifi_packet.ttl > 0 then
            receive_packet(wifi_packet, 1)
        end
        local router_packet = to_packet(9)
        if router_packet.ttl > 0 then
            receive_packet(router_packet, 2)
        end
        wifi_packet = send_packet(1)
        if wifi_packet ~= nil then
            to_channels(wifi_packet, 1)
        end
        router_packet = send_packet(2)
        if router_packet ~= nil then
            to_channels(router_packet, 9)
        end
        sn(17, tick)
        sn(18, secret)
        freq_1, freq_2 = get_frequencies(tick, secret)
        sn(20, freq_1)
        sn(21, freq_2)
    end
end
