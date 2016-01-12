local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local protobuf = require "protobuf"

--客户端的2个映射
fdclients = {}			--socket->client
aidclients = {}			--agent id->client

CMD = {}
setmetatable(CMD,{__index = _G})

require "agentcmd"
require "protofiles"
require "msghandler"

function encode(msgid,msgname,data)
	local msgdata = protobuf.encode(msgname, data)
	local size = #msgdata + 2
	local package = string.pack(">h", size) .. string.pack(">h", msgid)  .. msgdata
	return package
end

function sendpackage(fd,code,data)
	local msg = MSG[code]
	
	if msg == nil then
		dprint("unknown msg: not registered",code)
		return
	end
	if LOG_LEVEL > 0 then
		print("send resp：" .. msg.proto .. "," .. table.serialize(data))
	end
	socket.write(fd, encode(code,msg.proto,data))
end
--注册新的消息类型，用与C/S通信
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	
	unpack = function (msg, sz)
		local netdata = skynet.tostring(msg,sz)
		local v1,v2  = string.unpack(">h",netdata)
		local stringbuffer = string.sub(netdata,v2, -1)

		local msg = MSG[v1]

		if msg == nil then
			return
		end
		--解包
		local result,error = protobuf.decode(msg.proto, stringbuffer)

		if  error then
			dprint("failed to decode proto:",msg.proto)
			return
    		end

		return v1,result
	end,
	--对各协议的处理
	dispatch = function (_, fd, code, ...)
		local msg = MSG[code]

		if msg == nil then
			return
		end
		if LOG_LEVEL > 0 then
			local receive = ...
			print("received res：" .. msg.proto .. "," .. table.serialize(receive))
		end
		local client = fdclients[fd]

		if not client then
			return
		end

		if msg.on then
			if code == 100 then
				msg.on(client,...)
			else
				if not client.uid then
					return
				end
				
				msg.on(client,...)
			end
		end
	end
}

function returnwarp(r,...)
	if r ~= NONE then
		skynet.ret(skynet.pack(r,...))
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command,command2,...)
		local f = CMD[command]

		if f then
			returnwarp(f(command2,...))
		else
			--command is agentid
			local client = aidclients[command]

			if not client then
				return -1
			end

			f = client[command2]

			if f then
				returnwarp(f(client,...))
			else
				dprint("invalid call",command2)
			end
		end
	end)

	skynet.fork(function()
		local interval = 500 + math.random(0,100)

		while true do
			for _,client in pairs(fdclients) do
				pcall(client.update,client,5)
			end

			skynet.sleep(interval)
		end
	end)
	--注册协议
	for _,file in ipairs(protofiles) do
		local fullPath = "../../protocol/" .. file
		protobuf.register_file(fullPath)
	end

	db = skynet.localname(".db")
	world = skynet.localname(".world")
	gateid= skynet.getenv("gateid")
end)