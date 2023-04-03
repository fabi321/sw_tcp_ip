require('util')
require('dhcp_client')

---@type string
dns_client_dns_server = "0000"
---@type table<string, {addr: string, age: number}>
dns_client_cache = {}
---@type number
dns_client_status = 0
---@type number
dns_client_retry_count = 0

---@param name string
---@param packet Packet
---@return string | nil | boolean
function dns_lookup(name, packet)
    if packet and packet.proto == 4 and packet.src_port == 1 then
        dns_client_status = 0
        dns_client_retry_count = 0
        if #packet.data == 4 then
            dns_client_cache[name] = --[[---@type]] {
                addr = packet.data,
                age = 0,
            }
        else
            return false
        end
    end
    if dns_client_cache[name] then
        return dns_client_cache[name].addr
    else
        if dns_client_status == 0 then
            send_own_packet(dns_client_dns_server, 4, name, 0)
            dns_client_status = 1
        elseif dns_client_status < TIMEOUT then
            dns_client_status = dns_client_status + 1
        else
            dns_client_status = 0
            dns_client_retry_count = dns_client_retry_count + 1
            if dns_client_retry_count > 5 then
                dns_client_retry_count = 0
                return false
            end
        end
    end
end

function tick_dns_cache()
    for k, v in pairs(dns_client_cache) do
        v.age = v.age + 1
        if v.age > 3600 then
            dns_client_cache[k] = nil
        end
    end
end
