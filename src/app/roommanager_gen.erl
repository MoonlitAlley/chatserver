%%%-------------------------------------------------------------------
%%% @author admin
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 一月 2019 17:39
%%%-------------------------------------------------------------------
-module(roommanager_gen).
-author("admin").
-define(SERVER , ?MODULE).
-behaviour(gen_server).
-export([start_roommanager/0]).
%%gen_server回调函数
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-include("records.hrl").

-record(room ,{
  id ,
  number,
  talker =[] }).

start_roommanager() ->
    gen_server:start_link( { local ,?SERVER} ,?MODULE , [],[]).

init([]) ->
    RoomList = [],
    {ok,RoomList}.

handle_info({chat , {ActionCode , RecvRoomId} ,User } , RoomList) ->
    case ActionCode of
        listRoom ->
            %所有房间的列表信息中ID，和人数提取出来，回复给客户端
            change_send(User#user.socket , RoomList,[]),
            {noreply , RoomList};
        joinRoom ->
            %如果有这个房间ID，加入，如果没有，创建；
            case lists:keyfind(RecvRoomId, #room.id , RoomList) of
                #room{number = Number , talker = TalkerList} = _Room ->
                    TempRoom = #room{id = RecvRoomId , number = Number+1 , talker = [User | TalkerList]},
                    {noreply , lists:keyreplace(RecvRoomId ,#room.id , RoomList , TempRoom)};
                false ->
                    TempRoom = #room{id = RecvRoomId , number = 1, talker = [User] },
                    {noreply , [TempRoom | RoomList] };
                _ ->
                    gen_tcp:send(User#user.socket , term_to_binary("no pattern~n")),
                    {noreply , RoomList}
            end;
        leaveRoom ->
            %是否存在这个房间
            %存在 ->玩家是否在此房间中 ->如果房间剩余人数为零，从房间列表中删除该房间
            case lists:keyfind(RecvRoomId , #room.id , RoomList) of
                #room{number = Number ,talker = TalkerList} = _Room ->
                    case lists:keyfind(User#user.id, #user.id, TalkerList) of
                        #user{} ->
                          case Number-1 of
                              0 ->
                               {noreply , lists:keydelete(RecvRoomId ,#room.id , RoomList)};
                              _ ->
                                  TalkerListTemp = lists:keydelete(User#user.id , #user.id , TalkerList),
                                  TempRoom = #room{id = RecvRoomId , number = Number -1 , talker = TalkerListTemp },
                                  {noreply , lists:keyreplace(RecvRoomId ,#room.id , RoomList , TempRoom)}
                          end;
                        _ ->
                            gen_tcp:send(User#user.socket , term_to_binary("not a member~n")),
                            {noreply , RoomList}
                    end;
                _ ->
                    gen_tcp:send(User#user.socket , term_to_binary("not a room~n")),
                    {noreply , RoomList}
            end;
        speak ->
            %是否存在这个房间
            %存在 ->玩家是否在此房间中 ->在，则广播其消息
            case lists:keyfind(RecvRoomId , #room.id , RoomList) of
                #room{talker = TalkerList} = _Room ->
                    case lists:keyfind(User#user.id, #user.id, TalkerList) of
                        #user{} ->
                            Str = User#user.username ++ " : " ++ User#user.msg,
                            %广播给除我以外的房间内所有人
                            TalkerListTemp = lists:keydelete(User#user.socket , #user.socket , TalkerList),
                            %向列表中的每个客户端发送Str
                            send_msg(Str ,TalkerListTemp),
                            {noreply , RoomList};
                        _ ->
                            gen_tcp:send(User#user.socket , term_to_binary("not a member~n")),
                            {noreply , RoomList}
                    end;
                _->
                    gen_tcp:send(User#user.socket , term_to_binary("not a room~n")),
                    {noreply , RoomList}
            end;
        _ ->
            gen_tcp:send(User#user.socket , term_to_binary("no pattern~n")),
            {noreply , RoomList}
    end.

%所有房间的列表信息中ID，和人数提取出来，回复给客户端
%从L链表中提取消息，加入ListToSend列表，当L为空时，发送
change_send(Socket ,[] ,ListToSend) ->
    gen_tcp:send(Socket , term_to_binary(ListToSend));
change_send(Socket ,[H|L] , ListToSend) ->
    change_send(Socket,L, [{H#room.id , H#room.number} | ListToSend]).

%向列表中的每个客户端发送Str
send_msg( _, []) ->
    true;
send_msg( Str,[H|T] ) ->
    Socket= H#user.socket,
    gen_tcp:send(Socket ,term_to_binary(Str)),
    send_msg(Str ,T).

handle_call(_Request,_From,State) ->
  {noreply  ,State}.
handle_cast(_Msg ,State ) ->
  {noreply , State}.
terminate(_Reason ,_State) ->
  ok.
code_change(_OldVsn , State, _Extra) ->
  {ok , State}.
