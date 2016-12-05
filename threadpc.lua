--[[
Cross-thread procedure call
Created by buckle2000
http://github.com/buckle2000/
No Copyright (CC0) or WTFPL (http://wtfpl.net/)
]]

local OP_UNSET = 0
local OP_SET = 1
local OP_CALL = 2

local rpc_mt = {}

-- get local value or get rpc function
function rpc_mt.__index(t, key)
	local value = rawget(t, "values")[key]
	if value == nil then
		local chn_out = rawget(t, "chn_out")
		return function (...)
			chn_out:push({OP_CALL, key, ...})
		end
	else
		return value
	end
end

-- set callback or set remote value
function rpc_mt.__newindex(t, key, value)
	local v_type = type(value)
	if v_type == "number" or v_type == "string" or v_type == "boolean" then
		rawget(t, "chn_out"):push({OP_SET, key, value})
	elseif v_type == "function" then
		rawget(t, "callbacks")[key] = value
	elseif value == nil then
		rawget(t, "callbacks")[key] = nil
		rawget(t, "chn_out"):push({OP_UNSET, key})
	end
end

local function update_local(chn_in, values, callbacks)
	local event = chn_in:pop()
	while event ~= nil do
		local op = event[1]
		local key = event[2]
		if op == OP_UNSET then
			values[key] = nil
		elseif op == OP_SET then
			values[key] = event[3]
		elseif op == OP_CALL then
			local cb = callbacks[key]
			if cb then
				cb(unpack(event, 3))
			else
				error("No callback '" .. key .. "' registered.")
			end
		else
			error(("Invalid op code %d."):format(op))
		end
		event = chn_in:pop()
	end
end

-- update values, call callbacks
function rpc_mt.__call(t)
	local chn_in = rawget(t, "chn_in")
	-- update_local(chn_in, rawget(t, "values"), rawget(t, "callbacks"))  -- process anything including ones sent during processing
	chn_in:performAtomic(update_local, rawget(t, "values"), rawget(t, "callbacks"))
end

local function is_channel(x)
	return type(x) == "userdata" and x:typeOf("Channel")
end

local function new_rpc_proxy(chn_in, chn_out)
	local proxy = {}
	if type(chn_in) == "string" then
		chn_in = love.thread.getChannel(chn_in)
	end
	if type(chn_out) == "string" then
		chn_out = love.thread.getChannel(chn_out)
	end
	assert(is_channel(chn_in) and is_channel(chn_out), "Please specify channel name or pass in Channel object.")
	proxy.chn_in = chn_in
	proxy.chn_out = chn_out
	proxy.values = {}
	proxy.callbacks = {}
	return setmetatable(proxy, rpc_mt)
end

return new_rpc_proxy
