%%%-------------------------------------------------------------------
%%% @author song saifei
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 一月 2019 14:27
%%%-------------------------------------------------------------------
-module(listen_gen).
-behaviour(gen_server).
-define(SERVER , ?MODULE).
%% API
-export([start_link/0]).
%%gen_server回调函数
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-import(userdata_gen,[start_broadcast/0]).
-import(accept_gen, [start_accept/2]).
-import(roommanager_gen,[start_roommanager/0]).

-record(state, {
    listen,
    broadcastPid,
    roomManagerPid
}).
start_link() ->
    gen_server:start_link( { local ,?SERVER} ,?MODULE , [],[]).

init([]) ->
    {ok,Listen} =  gen_tcp:listen( 6789 , [ binary ,{packet , 4} ,{active , true}]),
    io:format("Start Listen , Port : 6789~n"),
    %广播服务器 ->用户登录校验
    {ok,BroadCastPid} = userdata_gen:start_broadcast(),
    %房间管理 ->聊天室列表、聊天室内在线成员
    {ok , RoomManagerPid} = roommanager_gen:start_roommanager(),
    self() ! accept,
    {ok,#state{listen = Listen,broadcastPid = BroadCastPid,roomManagerPid = RoomManagerPid}}.

handle_info(accept, #state{listen = Listen,broadcastPid = BroadCastPid,roomManagerPid = RoomManagerPid}= State) ->
    io:format("Start Listen ,  handle_info,broadcast servering:~p~n",[BroadCastPid]),

    {ok , AcceptPid} = accept_gen:start_accept(BroadCastPid ,RoomManagerPid),
    {ok , Socket} = gen_tcp:accept(Listen),
    gen_tcp:controlling_process(Socket,AcceptPid),
    io:format("controlling_process(~p,~p)~n",[Socket,AcceptPid]),
    %开始循环
    self() ! accept ,
    {noreply ,State}.

handle_call(_Request,_From,Circulation) -> {noreply , Circulation}.
handle_cast(_Msg ,Circulation ) -> {noreply , Circulation}.
terminate(_Reason ,_Circulation) -> ok.
code_change(_OldVsn , Circulation, _Extra) -> {ok , Circulation}.
