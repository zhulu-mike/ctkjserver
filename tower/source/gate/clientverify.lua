--auth connection and return secret

local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local crypt = require "crypt"

local socket_error = {}

local function assert_socket(service, v, fd)
	if v then
		return v
	else
		--skynet.error(string.format("%s failed: socket (fd = %d) closed", service, fd))
		error(socket_error)
	end
end

local function write(service, fd, text)
	assert_socket(service, socket.write(fd, text), fd)
end

local function auth(fd, addr)
	fd = assert(tonumber(fd))
	socket.start(fd)

	-- set socket buffer limit (8K)
	-- If the attacker send large package, close the socket
	socket.limit(fd, 8192)

	local challenge = crypt.randomkey()
	write("auth", fd, crypt.base64encode(challenge).."\n")

	local handshake = assert_socket("auth", socket.readline(fd), fd)
	local clientkey = crypt.base64decode(handshake)

	if #clientkey ~= 8 then
		error "Invalid client key"
	end

	local serverkey = crypt.randomkey()
	write("auth", fd, crypt.base64encode(crypt.dhexchange(serverkey)).."\n")

	local secret = crypt.dhsecret(clientkey, serverkey)
	local response = assert_socket("auth", socket.readline(fd), fd)
	local hmac = crypt.hmac64(challenge, secret)

	if hmac ~= crypt.base64decode(response) then
		write("auth", fd, "400 Bad Request\n")
		error "challenge failed"
	end

	--local etoken = assert_socket("auth", socket.readline(fd),fd)
	--local token = crypt.desdecode(secret, crypt.base64decode(etoken))
	--local ok, server, uid =  pcall(auth_handler,token)

	socket.abandon(fd)
	return true, secret
end

local function ret_pack(ok, err, ...)
	if ok then
		--verified
		skynet.ret(skynet.pack(err, ...))
	else
		if err == socket_error then
			skynet.ret(skynet.pack(nil, "socket error"))
		else
			skynet.ret(skynet.pack(false, err))
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, fd,addr)
		ret_pack(pcall(auth,fd,addr))
	end)
end)