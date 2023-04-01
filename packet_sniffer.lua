require('packeting')

function onTick()
    packet = to_packet(1)
    if packet.ttl > 0 then
        output.setBool(1, true)
        sn(1, tonumber(packet.src_addr, 16))
        sn(2, tonumber(packet.dest_addr, 16))
        sn(3, packet.src_port)
        sn(4, packet.dest_port)
        sn(5, packet.seq_nmb)
        sn(6, packet.ack_nmb)
        sn(7, packet.proto)
        sn(8, packet.ttl + 1)
    end
end
