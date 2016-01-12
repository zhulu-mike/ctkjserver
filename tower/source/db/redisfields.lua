
--定义redis表里的字段
redis_user = 
{
	--在redis中记录的名称
	name = "tbluser",
	--存储的键值
	fields = {"id","username","qudao","state","binduname","serverid","registtime","lastlogintime","logintimes","lastdeviceid","lastip"},
	defaults = {},
	--建立的索引
	index = {"username_qudao_serverid","binduname_qudao_serverid","id"}
}

redis_userdetail = 
{
	name = "tbluserdetail",
	fields = {"userid","nickname","gold","diamond","energy"},
	--默认值
	defaults = {gold=0,diamond=0,energy=0},
	--建立的索引
	index = {"userid"}
}

redis_usertime = 
{
	name = "tblusertime",
	fields = {"userid","energytime"},
	--默认值
	defaults = {energytime=0},
	--建立的索引
	index = {"userid"}
}
















