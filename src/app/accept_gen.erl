%%%-------------------------------------------------------------------
%%% @author song saifei
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 一月 2019 14:36
%%%-------------------------------------------------------------------
-module(accept_gen).
-author("song saifei").

-define(SERVER , ?MODULE).
-export([start_accept/2]).
%%gen_server回调函数
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-import(common ,[get_message/1]).
-include("records.hrl").
-define( false ,false).
-define(true , true).
-define(register ,1).
-define(login , 2).
-define(logout , 3).
-define(chat , 4).

-define(listRoom , 1 ).
-define(joinRoom , 2 ).
-define(leaveRoom,3).
-define(speak , 4).

-record(client, {
    socket, broadcastPid,
    roomManagerPid,
    id, username,
    %是否登陆成功, 之后的操作仅需检验该值
    is_login = false}).


start_accept(BroadCastPid,RoomManagerPid ) ->
    gen_server:start_link(?MODULE , [BroadCastPid,RoomManagerPid],[] ).

init([BroadCastPid,RoomManagerPid]) ->
    io:format("start_accept:init~n"),
    {ok,#client{broadcastPid = BroadCastPid,roomManagerPid = RoomManagerPid}}.

handle_info({tcp, Socket ,Bin} , #client{is_login = LoginState} = Client) when LoginState == ?false ->

    case get_message(Bin) of
        {?register , RecvId, RecvUN}->
            User = #user{id = RecvId , username = RecvUN , socket = Socket},
            %注册该账号，并检查返回结果，将结果通过Socket回复给客户端
            case gen_server:call(broadcast_gen,{register , User}) of
                {success , Des} ->
                    gen_tcp:send(Socket , term_to_binary({success , Des})),
                    {noreply ,Client};
                {faile , Why } ->
                    gen_tcp:send(Socket , term_to_binary({faile , Why })),
                    {noreply ,Client};
                _ ->
                    io:format("no pattern in accept_gen handle_info:register~n"),
                    {noreply ,Client}
            end;
        {?login, RecvId , RecvUN} ->
            User = #user{id = RecvId , username = RecvUN , socket = Socket},
            case gen_server:call(broadcast_gen, {login, User}) of
                {success ,Des} ->
                    %将本连接中的User状态修改为在线状态，后续发送消息无验证
                    gen_tcp:send(Socket , term_to_binary({success , Des})),
                    {noreply , Client#client{socket = Socket , id = RecvId , username = RecvUN , is_login = true}};
                {faile,Reason} ->
                    gen_tcp:send(Socket , term_to_binary({faile , Reason})),
                    {noreply,Client};
                _ ->
                    {noreply , Client}
            end;
        _ ->
            {noreply ,Client}
    end;

handle_info({tcp, Socket ,Bin} ,  #client{is_login = LoginState} = Client) when LoginState == ?true ->

    case get_message(Bin) of
        {?logout,RecvId ,RecvUN} ->
            User = #user{id = RecvId , username = RecvUN , socket = Socket},
            case gen_server:call(broadcast_gen, {logout, User}) of
                {success , Des}  ->
                    gen_tcp:send(Socket , term_to_binary(Des)),
                    {noreply , Client#client{is_login = false}};
                _ ->
                    {noreply , Client}
            end;
        {?chat , ActionCode , RoomId , Msg}  ->
            %此处需要进行消息转化：按照消息协议，服务端接收消息内容为 { chat ，二级命令，房间ID， MSG } ，用户信息使用本进程的记录内数据
            case Client#client.is_login of
                true ->
                    UserTemp = #user{id = Client#client.id , socket = Client#client.socket , username = Client#client.username, msg = Msg},
                    Client#client.roomManagerPid ! {chat , {ActionCode , RoomId} ,UserTemp },
                    {noreply , Client};
                _ ->
                    gen_tcp:send(Socket , term_to_binary("please login at first")),
                    {noreply , Client}
            end;
        _ ->
            {noreply ,Client}
    end;


handle_info({tcp_closed, Socket} , Client ) ->
    case gen_server:call(broadcast_gen, {logout, #user{id = Client#client.id }}) of
        {success , Des}  ->
            gen_tcp:send(Socket , term_to_binary(Des)),
            {noreply , Client#client{is_login = false}};
        _ ->
            {noreply , Client}
    end.

%断开连接的处理
handle_call(_Request,_From,State) -> {noreply , State}.
handle_cast(_Msg ,State ) -> {noreply , State}.
terminate(_Reason ,_State) -> ok.
code_change(_OldVsn , State, _Extra) -> {ok , State}.

%%handle_info({tcp, Socket ,Bin} , #client{is_login = LoginState} = Client) when LoginState == ?false ->
%%
%%    {RecvType ,RecvId , RecvUN,RecvMsg} = binary_to_term(Bin),
%%    io:format("it is ~p:~p:~p:~p~n",[RecvType ,RecvId , RecvUN,RecvMsg]),
%%    User = #user{id = RecvId , username = RecvUN , socket = Socket,msg_type = RecvType,msg = RecvMsg},
%%case RecvType of
%%register->
%%%注册该账号，并检查返回结果，将结果通过Socket回复给客户端
%%case gen_server:call(broadcast_gen,{register , User}) of
%%{success , Des} ->
%%gen_tcp:send(Socket , term_to_binary({success , Des})),
%%{noreply ,Client};
%%{faile , Why } ->
%%gen_tcp:send(Socket , term_to_binary({faile , Why })),
%%{noreply ,Client};
%%_ ->
%%io:format("no pattern in accept_gen handle_info:register~n"),
%%{noreply ,Client}
%%end;
%%login->
%%case gen_server:call(broadcast_gen, {login, User}) of
%%{success ,Des} ->
%%%将本连接中的User状态修改为在线状态，后续发送消息无验证
%%gen_tcp:send(Socket , term_to_binary({success , Des})),
%%{noreply , Client#client{socket = Socket , id = RecvId , username = RecvUN , is_login = true}};
%%{faile,Reason} ->
%%gen_tcp:send(Socket , term_to_binary({faile , Reason})),
%%{noreply,Client};
%%_ ->
%%{noreply , Client}
%%end;
%%_ ->
%%{noreply ,Client}
%%end;

%%handle_info({tcp, Socket ,Bin} ,  #client{is_login = LoginState} = Client) when LoginState == ?true ->
%%
%%    {RecvType ,RecvId , RecvUN,RecvMsg} = binary_to_term(Bin),
%%    io:format("it is ~p:~p:~p:~p~n",[RecvType ,RecvId , RecvUN,RecvMsg]),
%%    User = #user{id = RecvId , username = RecvUN , socket = Socket,msg_type = RecvType,msg = RecvMsg},
%%
%%    case RecvType of
%%        logout->
%%            case gen_server:call(broadcast_gen, {logout, User}) of
%%                {success , Des}  ->
%%                    gen_tcp:send(Socket , term_to_binary(Des)),
%%                    {noreply , Client#client{is_login = false}};
%%                _ ->
%%                    {noreply , Client}
%%            end;
%%        chat ->
%%            %此处需要进行消息转化：按照消息协议，服务端接收消息内容为 { chat ，二级命令，房间ID， MSG } ，用户信息使用本进程的记录内数据
%%            case Client#client.is_login of
%%                true ->
%%                    UserTemp = #user{id = Client#client.id , socket = Client#client.socket , username = Client#client.username, msg = RecvMsg},
%%                    Client#client.roomManagerPid ! {chat , {RecvId , RecvUN} ,UserTemp },
%%                    {noreply , Client};
%%                _ ->
%%                    gen_tcp:send(Socket , term_to_binary("please login at first")),
%%                    {noreply , Client}
%%            end;
%%        _ ->
%%            {noreply ,Client}
%%    end;
