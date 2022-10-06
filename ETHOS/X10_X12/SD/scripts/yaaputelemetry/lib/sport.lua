local sport = {}

local TELEMETRY_RX_BUFFER_SIZE = 19  -- 9 bytes (full packet), worst case 18 bytes with byte-stuffing (+1)
local SPORT_PACKET_SIZE = 9

local FRAME_HEAD = 0x7E
local FRAME_DLE = 0x7D
local STUFF_MASK = 0x20

local parse_states = {
  IDLE = 1,
  START = 2,
  IN_FRAME = 3,
  XOR = 4,
}

local parser = {
  rx_buffer = {},
  rx_buffer_count = 0,
  state = parse_states.IDLE,
}

local function check_crc(rx_buffer)
  local crc = 0
  for i=1,SPORT_PACKET_SIZE-1
  do
    crc = crc + rx_buffer[i]
    crc = crc + (crc >> 8)
    crc = crc & 0x00ff
  end
  return crc == 0x00ff
end

local function toLe16(rx_buffer, offset)
  local res = rx_buffer[offset+1] << 8
  res = res | rx_buffer[offset]
  return res
end

local function toLe32(rx_buffer, offset)
  local res = rx_buffer[offset+3] << 24
  res = res | rx_buffer[offset+2] << 16
  res = res | rx_buffer[offset+1] << 8
  res = res | rx_buffer[offset]
  return res
end

local function get_packet(packet, rx_buffer)
  --[[
  if not check_crc(rx_buffer) then
    return false
  end
  --]]
  packet.physId = rx_buffer[0]
  packet.primId = rx_buffer[1]
  packet.appId = toLe16(rx_buffer,2)
  packet.data = toLe32(rx_buffer,4)

  return true;
end

function sport.process_byte(packet, c)
  if parser.state == parse_states.START then
    if parser.rx_buffer_count < TELEMETRY_RX_BUFFER_SIZE then
      parser.rx_buffer[parser.rx_buffer_count] = c
      parser.rx_buffer_count = parser.rx_buffer_count + 1
    end
    parser.state = parse_states.IN_FRAME
  elseif parser.state == parse_states.IN_FRAME then
    if c == FRAME_DLE then
      parser.state = parse_states.XOR -- XOR next byte
    elseif c == FRAME_HEAD then
      parser.state = parse_states.IN_FRAME
      parser.rx_buffer_count = 0
    elseif parser.rx_buffer_count < TELEMETRY_RX_BUFFER_SIZE then
      parser.rx_buffer[parser.rx_buffer_count] = c
      parser.rx_buffer_count = parser.rx_buffer_count + 1
    end
  elseif parser.state == parse_states.XOR then
    if parser.rx_buffer_count < TELEMETRY_RX_BUFFER_SIZE then
      parser.rx_buffer[parser.rx_buffer_count] = c ^ STUFF_MASK
      parser.rx_buffer_count = parser.rx_buffer_count + 1
    end
    parser.state = parse_states.IN_FRAME
  elseif parser.state == parse_states.IDLE then
    if c == FRAME_HEAD then
      parser.rx_buffer_count = 0
      parser.state = parse_states.START
    end
  end

  if parser.rx_buffer_count >= SPORT_PACKET_SIZE then
      parser.rx_buffer_count = 0
      parser.state = parse_states.IDLE
      return get_packet(packet, parser.rx_buffer);
  end
  return false
end

return sport

