
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
--资源
redis_userdetail = 
{
	name = "tbluserdetail",
	fields = {"userid","nickname","gold","diamond","energy","version","star"},
	--默认值
	defaults = {gold=500,diamond=0,energy=100,version=0,star=0},
	--建立的索引
	index = {"userid"}
}
--英雄
redis_userheros = 
{
	name = "tbluserheros",
	fields = {"userid","heros","version"},
	--默认值
	defaults = {version=0},
	--建立的索引
	index = {"userid"}
}
--关卡
redis_userrounds = 
{
	name = "tbluserrounds",
	fields = {"userid","rounds","version"},
	--默认值
	defaults = {version=0},
	--建立的索引
	index = {"userid"}
}
--时间
redis_usertime = 
{
	name = "tblusertime",
	fields = {"userid","energytime","version"},
	--默认值
	defaults = {energytime=0,version=0},
	--建立的索引
	index = {"userid"}
}
















