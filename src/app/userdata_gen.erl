%%%-------------------------------------------------------------------
%%% @author song saifei
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 一月 2019 14:28
%%%-------------------------------------------------------------------
-module(userdata_gen).
-author("song saifei").

-define(SERVER , ?MODULE).
%% API
-export([start_broadcast/0]).
%%gen_server回调函数
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-record(user,{
  id, username, socket,
  msg_type, msg}).

start_broadcast() ->
    gen_server:start_link( { local ,?SERVER} ,?MODULE , [],[]).

init([]) ->
    dets:open_file(usermap , [{type , set},{keypos , #user.id}]),
    io:format("start_broadcast:init-dets:open_file: true~n"),
    UserList = [],
    {ok,UserList}.

handle_call({register , #user{id = RecvId } = User} ,_From , UserList) ->
    case dets:lookup(usermap, RecvId) of
        [#user{}] ->
            Reason = "someone registered",
            {reply , {faile , Reason} , UserList};
        [] ->
            dets:insert(usermap , User),
            {reply , {success , "register successed"} , UserList};
        _ ->
            {reply , {faile , "no pattern"} , UserList}
    end;
handle_call({login , #user{id = RecvId} = User}, _From ,UserList) ->
    case dets:lookup(usermap , RecvId) of
        [#user{}] ->
            {reply , {success, "login success"} , [User|UserList]};
        {error , Reason} ->
            {reply , {faile , Reason } ,UserList};
        _ ->
            {reply , {faile , "no pattern" } ,UserList}
    end;
handle_call({logout , #user{id = RecvId } =_User} ,_From , UserList) ->
    {reply , {success , "logout success"} , lists:keydelete(RecvId , #user.id , UserList) }.


handle_info(_Info , State ) -> {noreply , State}.
handle_cast(_Msg ,State ) -> {noreply , State}.
terminate(_Reason ,_State) ->
    %关闭打开的用户信息文件
    dets:close(usermap),
    ok.
code_change(_OldVsn , State, _Extra) ->
  {ok , State}.