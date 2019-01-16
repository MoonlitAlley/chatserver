%%%-------------------------------------------------------------------
%%% @author admin
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 一月 2019 14:28
%%%-------------------------------------------------------------------
-module(chatserver_app).
-author("song saifei").

%% API
-export([start/2 , stop/1]).
-import(chatserver_supervisor,[start_link/1]).

start(_Type , StartArgs) ->
  chatserver_supervisor:start_link(StartArgs).

stop(_State) ->
  ok.
