%%%-------------------------------------------------------------------
%%% @author song saifei
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 一月 2019 15:59
%%%-------------------------------------------------------------------
-module(client).
-author("song saifei").

%% API
-export([start_client/0,send/2]).

%%% 首先使用start_client得到与服务端建立连接的进程的Pid，
%%% 然后通过send发送消息。可以重复发送
send(TargetPid , Str) ->
  TargetPid ! {send , Str}.


start_client() ->
  Pid = spawn(fun() -> loop(undefined) end ),
  Pid ! {start},
  Pid.

loop(Socket) ->
  io:format("Ready recv~n"),

  receive
    {tcp , Socket , Bin} ->
      Val = binary_to_term(Bin),
      io:format("Client Recv : ~p~n" , [Val]),
      %gen_tcp:close(Socket);
      loop(Socket);
    {send,Str} ->
      ok = gen_tcp:send(Socket ,term_to_binary(Str)),
      io:format("Msg sended : ~p~n" , [Str]),
      loop(Socket);
    {start} ->
      {ok , Socket1} = gen_tcp:connect("localhost" , 6789 , [binary ,{packet , 4}]),
      loop(Socket1);
      _ ->
      io:format("Client Recv : nothing ~n" ),
      loop(Socket)

  end.



