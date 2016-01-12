local skynet = require "skynet"
local cluster = require "cluster"
local socket = require "socket"

require "client"
require "clientcmd"
require "clientbag"

_ENV = CMD
-----------------------------------------------------------------

function start(conf)
	local fd    = conf.client
	local gate = conf.gate

	_G.dog = conf.watchdog

	local client = cclient:new()
	client.fd = fd
	client.agentid = conf.id
	client.ip = conf.ip

	aidclients[conf.id] = client
	fdclients[fd] = client

	skynet.call(gate, "lua", "forward", fd,fd)
end

function disconnect(fd)
	local client = fdclients[fd]

	if not client then
		return
	end

	client:ondisconnect()

	--unlink
	fdclients[fd] = nil
	aidclients[client.agentid] = nil
end

function newday(dayid)
	for _,client in pairs(fdclients) do
		client:onnewday(dayid)
	end

	return NONE
end

function broadcast(msg,data)
	for _,client in pairs(fdclients) do
		client:send(msg,data)
	end

	return NONE
end