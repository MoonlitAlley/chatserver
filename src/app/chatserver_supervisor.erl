%%%-------------------------------------------------------------------
%%% @author song saifei
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 一月 2019 14:17
%%%-------------------------------------------------------------------
-module(chatserver_supervisor).
-author("song saifei").
%% API
-behaviour(supervisor).
-export([start/0,start_in_shell_for_testing/0,start_link/1,init/1]).
-import(listen_gen ,[start_link/0]).

start() ->
  spawn( fun() -> supervisor:start_link({local , ?MODULE} , ?MODULE ,_Arg = [] ) end).

start_in_shell_for_testing() ->
  {ok , Pid} = supervisor:start_link({local , ?MODULE} , ?MODULE  ,_Arg = []),
  unlink(Pid).

start_link(Args) ->
  supervisor:start_link({local , ?MODULE} , ?MODULE , Args).

init([]) ->

  %警报处理待完成
  %gen_event:swap_handler(alarm_handler, {alarm_handler , swap }, {my_alarm_handler,xyz}),

  %%安装我们自己的错误处理器
  {ok , { { one_for_one , 3 , 10 },
    [ { tag1 , {listen_gen , start_link , [] } ,
      permanent,
      10000,
      worker,
      [listen_gen]}
    ]}}.


