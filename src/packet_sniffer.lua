require('util')
require('packeting')
label = property.getText('label')

---@type number
tick = 0

-- tumfl: preserve
function onTick()
    tick = tick + 1
    packet = to_packet(1)
    if packet.ttl > 0 then
        output.setBool(1, true)
        output.setNumber(1, tonumber(packet.src_addr, 16))
        output.setNumber(2, tonumber(packet.dest_addr, 16))
        output.setNumber(3, packet.src_port)
        output.setNumber(4, packet.dest_port)
        output.setNumber(5, packet.seq_nmb)
        output.setNumber(6, packet.ack_nmb)
        output.setNumber(7, packet.proto)
        output.setNumber(8, packet.ttl + 1)
        async.httpGet(8080, string.format(
                "/%s?tick=%i&src_addr=%s&dest_addr=%s&src_port=%i&dest_port=%i&seq_nmb=%i&ack_nmb=%i&proto=%i&ttl=%i&len=%i&data=%s",
                label,
                tick,
                packet.src_addr,
                packet.dest_addr,
                packet.src_port,
                packet.dest_port,
                packet.seq_nmb,
                packet.ack_nmb,
                packet.proto,
                packet.ttl + 1,
                #packet.data,
                packet.data
        ))
    end
end
