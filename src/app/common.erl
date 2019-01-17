%%%-------------------------------------------------------------------
%%% @author song saifei
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 一月 2019 10:51
%%%-------------------------------------------------------------------
-module(common).

%% API
-export([get_message/1,set_message/1]).
-define(register ,1).
-define(login , 2).
-define(logout , 3).
-define(chat , 4).

-define(listRoom , 1 ).
-define(joinRoom , 2 ).
-define(leaveRoom,3).
-define(speak , 4).



%打包 ->客户端使用
set_message({RequestCode , UserID , UserName}) ->
  UserNameBinary = list_to_binary(UserName),
  UserNamebit = <<UserNameBinary/binary>>,
  Size = byte_size(UserNamebit),
  Length = 4+4+Size,
  case RequestCode of
    register->
      <<Length:32 , ?register:32 , UserID:32 , UserNamebit:Size/binary>>;
    login ->
      <<Length:32 , ?login:32 , UserID:32 , UserNamebit:Size/binary>>;
    logout ->
      <<Length:32 , ?logout:32 , UserID:32 , UserNamebit:Size/binary>>
  end;
set_message({chat ,ActionCode , RoomID , Msg}) ->
  MsgBinary = list_to_binary(Msg),
  Msgbit = <<MsgBinary/binary>>,
  Size = byte_size(Msgbit),
  Length = 4+4+4+Size,
  case ActionCode of
    listRoom ->
      <<Length:32 , ?chat:32 , ?listRoom:32 , RoomID:32 , Msgbit:Size/binary>>;
    joinRoom ->
      <<Length:32 , ?chat:32 ,?joinRoom:32 , RoomID:32 , Msgbit:Size/binary>>;
    leaveRoom ->
      <<Length:32 , ?chat:32 , ?leaveRoom:32 , RoomID:32 , Msgbit:Size/binary>>;
    speak ->
      <<Length:32 , ?chat:32 , ?speak:32 , RoomID:32 , Msgbit:Size/binary>>
  end.



%解包 ->服务端使用
get_message(Binary) ->
  Count = byte_size(Binary),
  Lend = Count -4,
  <<Length:32 ,  Residue:Lend/binary>> = Binary,

  case Length =< Count of
    true ->
      LendTemp = Count -8,
      <<RequestCode:32 ,Last:LendTemp/binary>> = Residue,
      case RequestCode  of
        ?register ->
          get_result(RequestCode,Count,Length,Last);
        ?login ->
          get_result(RequestCode,Count,Length,Last);
        ?logout ->
          get_result(RequestCode,Count,Length,Last);
        ?chat ->
          MsgLength = Length - 4 -4 -4,
          ResidueLength = Count -4 -Length,
          <<ActionCode:32 , RoomID:32 , Msg:MsgLength/binary , Other:ResidueLength/binary>> = Last,
          { {RequestCode , ActionCode , RoomID , Msg} , Other};
        _ ->
          {false,<<>>}
      end;
    _ ->
      {false,<<>>}
  end.

get_result(RequestCode ,Count , Length , Last) ->
  UserNameLength = Length - 4 -4,
  ResidueLength = Count - 4 - Length,
  <<UserID:32 , UserNameBin:UserNameLength/binary , Other:ResidueLength/binary>> = Last,
  UserName = binary_to_list(UserNameBin),

  {{RequestCode , UserID , UserName} , Other}.
