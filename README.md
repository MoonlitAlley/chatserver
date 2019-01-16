
启动方式：

服务端：
	以应用程序方式启动监控器、记录器 和 错误处理器（未完整实现）：
	（日志文件生成位置："F:/ewVersion/chatserver/ebin" ，最大支持：10MB）
	（注意切换目录 ，elog3 位于：chatserver\src\app , application 位于 chatserver\ebin
	$ erl -boot start_sasl -config elog3
	1>application:load(chatserver).
	2>application:start(chatserver).
	
	shell启动带有监控器和错误处理器（未完整实现）：
	chatserver_app:start( normal , [] ).
	
	运行启动：
	listen_gen:start_link().

客户端：
	PID = client:start_client().
	之后可以使用send异步发送消息(Msg格式见下方）
	client:send( PID , Msg).


消息协议：
client ->>->> server
username 在重新登陆之后生效

注册：	{register , userID , userName , ""}
登录：	{login , userID , userName , ""}
登出：	{logout , UserID , "" , ""}
以下消息仅支持登陆后发送（否则提示“please login at first”）
列出房间：	{chat , ListRoom , "" ,""}
加入房间：	{chat , joinRoom , roomID , ""}
离开房间：	{chat , leaveRoom , roomID ,""}
房间发言：	{chat , speak ,roomID , Msg}
(发言昵称已本地登录昵称为准）


