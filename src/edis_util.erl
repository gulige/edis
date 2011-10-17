%%%-------------------------------------------------------------------
%%% @author Fernando Benavides <fernando.benavides@inakanetworks.com>
%%% @author Chad DePue <chad@inakanetworks.com>
%%% @copyright (C) 2011 InakaLabs SRL
%%% @doc edis utilities
%%% @end
%%%-------------------------------------------------------------------
-module(edis_util).
-author('Fernando Benavides <fernando.benavides@inakanetworks.com>').
-author('Chad DePue <chad@inakanetworks.com>').

-export([timestamp/0, now/0, upper/1, lower/1, binary_to_integer/1, binary_to_integer/2,
         integer_to_binary/1, binary_to_float/1, make_pairs/1, glob_to_re/1]).

-include("elog.hrl").

-define(EPOCH, 62167219200).

%% @doc Current timestamp
-spec timestamp() -> float().
timestamp() ->
  ?MODULE:now() + element(3, erlang:now()) / 1000000.

%% @doc UTC in *NIX seconds
-spec now() -> pos_integer().
now() ->
  calendar:datetime_to_gregorian_seconds(calendar:universal_time()) - ?EPOCH.

-spec upper(binary()) -> binary().
upper(Bin) ->
  upper(Bin, <<>>).

%% @private
upper(<<>>, Acc) ->
  Acc;
upper(<<C, Rest/binary>>, Acc) when $a =< C, C =< $z ->
  upper(Rest, <<Acc/binary, (C-32)>>);
upper(<<195, C, Rest/binary>>, Acc) when 160 =< C, C =< 182 -> %% A-0 with tildes plus enye
  upper(Rest, <<Acc/binary, 195, (C-32)>>);
upper(<<195, C, Rest/binary>>, Acc) when 184 =< C, C =< 190 -> %% U and Y with tilde plus greeks
  upper(Rest, <<Acc/binary, 195, (C-32)>>);
upper(<<C, Rest/binary>>, Acc) ->
  upper(Rest, <<Acc/binary, C>>).

-spec lower(binary()) -> binary().
lower(Bin) ->
  lower(Bin, <<>>).

lower(<<>>, Acc) ->
  Acc;
lower(<<C, Rest/binary>>, Acc) when $A =< C, C =< $Z ->
  lower(Rest, <<Acc/binary, (C+32)>>);
lower(<<195, C, Rest/binary>>, Acc) when 128 =< C, C =< 150 -> %% A-0 with tildes plus enye
  lower(Rest, <<Acc/binary, 195, (C+32)>>);
lower(<<195, C, Rest/binary>>, Acc) when 152 =< C, C =< 158 -> %% U and Y with tilde plus greeks
  lower(Rest, <<Acc/binary, 195, (C+32)>>);
lower(<<C, Rest/binary>>, Acc) ->
  lower(Rest, <<Acc/binary, C>>).

-spec binary_to_integer(binary()) -> integer().
binary_to_integer(Bin) ->
  try list_to_integer(binary_to_list(Bin))
  catch
    _:badarg ->
      throw(not_integer)
  end.

-spec binary_to_float(binary()) -> integer().
binary_to_float(Bin) ->
  try list_to_float(binary_to_list(Bin))
  catch
    _:badarg ->
      try 1.0 * list_to_integer(binary_to_list(Bin))
      catch
        _:badarg ->
          throw(not_float)
      end
  end.

-spec binary_to_integer(binary(), integer()) -> integer().
binary_to_integer(Bin, Default) ->
  try list_to_integer(binary_to_list(Bin))
  catch
    _:badarg ->
      ?WARN("Using ~p because we received '~s'. This behaviour was copied from redis-server~n", [Default, Bin]),
      Default
  end.

-spec integer_to_binary(binary()) -> integer().
integer_to_binary(Int) ->
  list_to_binary(integer_to_list(Int)).

-spec make_pairs([any()]) -> [{any(), any()}].
make_pairs(KVs) ->
  make_pairs(KVs, []).

make_pairs([], Acc) -> lists:reverse(Acc);
make_pairs([_], Acc) -> lists:reverse(Acc);
make_pairs([K, V | Rest], Acc) ->
  make_pairs(Rest, [{K,V} | Acc]).

-spec glob_to_re(binary()) -> binary().
glob_to_re(Pattern) ->
  binary:replace(
    binary:replace(
      binary:replace(
        binary:replace(Pattern, <<"*">>, <<".*">>, [global]),
        <<"?">>, <<".">>, [global]),
      <<"(">>, <<"\\(">>, [global]),
    <<")">>, <<"\\)">>, [global]).