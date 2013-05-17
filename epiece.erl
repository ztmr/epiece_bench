-module (epiece).
-compile (export_all).

-define (TC_AVG_REPEAT, 10).
-define (MAG, 100).  %% 1.23us -> 123 in output

%-define (BENCH (Fun), {round (tc_avg (Fun)*?MAG), dropped_result}).
-define (BENCH (Fun), (fun () -> {X,Y} = timer:tc (Fun), {X*?MAG, Y} end) ()).

epiece ([], _, _) -> []; %% No source data
epiece (_, _, []) -> []; %% No fields to extract
epiece (S, D, F) when is_list (S) ->
  %% XXX: a little hack to enforce the last piece to be grabbed
  SBin = list_to_binary (S++D),
  DBin = list_to_binary (D),
  epiece_internal (binary:split (SBin, DBin), DBin, F, []).

epiece_internal ([_S|_], _, [], Res) -> Res;
epiece_internal ([S, R], D, [Fh|Fr], Res) ->
  X = binary:split (R, D),
  epiece_internal (X, D, Fr, [{Fh, binary_to_list (S)}|Res]);
epiece_internal (_, _, _, Res) -> Res.

epiece2 ([], _, _) -> [];
epiece2 (_, _, []) -> [];
epiece2 (S, D, F) when is_list (S) ->
  xzip (F, re:split (S, resc (D), [{return, list}]), []).

%% Split by single character in-place,
%% if the delimiter is longer than 1, use NIF.
epz ([], _) -> [];
epz (S, [D]) ->
  epz_ (S, D, [], []);
epz (S, D) ->
  epiece_nif:piece (S, D).

%% D is a single character
epz_ ([], _, [], []) -> [];
epz_ ([], _, Buf, Res) ->
  lists:reverse ([lists:reverse (Buf)|Res]);
epz_ ([D|S], D, Buf, Res) ->
  epz_ (S, D, [], [lists:reverse (Buf)|Res]);
epz_ ([X|S], D, Buf, Res) ->
  epz_ (S, D, [X|Buf], Res).

%% @doc epiece_nif:piece on steroids (returns a proplist).
epn ([], _, _) -> [];
epn (_, _, []) -> [];
epn (S, D, F) when is_list (S) ->
  xzip (F, epiece_nif:piece (S, D), []).

%% @doc lists:zip for lists of unequal length.
xzip ([], _, Acc) -> Acc;
xzip (_, [], Acc) -> Acc;
xzip ([H1|T1], [H2|T2], Acc) ->
  xzip (T1, T2, [{H1, H2}|Acc]).

%% @doc regex pattern escaper.
resc ({re_pattern, _} = Pat) -> Pat;
resc ([]) -> [];
resc ([H|T]) when H >= $0, H =< $9; H >= $a, H =< $z; H >= $A, H =< $Z ->
  [H|resc (T)];
resc ([H|T]) -> [$\\, H|resc (T)].

%% @doc Stdlib string:tokens hack.
%% https://github.com/erlang/otp/blob/maint/lib/stdlib/src/string.erl#L216
%%
%% NOTE: unlike other functions in this benchmark,
%% `Seps' argument is not a string delimiter, but
%% a list of multiple single-character delimiters.
tokens (S, Seps) ->
  tokens1 (S, Seps, []).

tokens1 ([C], Seps, Toks) ->
  %io:format ("tokens1: C=~p, Seps=~p, Toks=~p~n", [C, Seps, Toks]),
  case lists:member (C, Seps) of
    true -> tokens1 ([], Seps, [[]|Toks]);
    false -> tokens2 ([], Seps, Toks, [C])
  end;
tokens1 ([C, C |S], Seps, Toks) ->
  %io:format ("tokens1: C=~p, C=~p, S=~p, Seps=~p, Toks=~p~n", [C, C, S, Seps, Toks]),
  case lists:member (C, Seps) of
    true -> tokens1 ([C|S], Seps, [[]|Toks]);
    false -> tokens2 ([C|S], Seps, Toks, [C])
  end;
tokens1 ([C|S], Seps, []) ->
  %io:format ("tokens1: C=~p, S=~p, Seps=~p, Toks=~p~n", [C, S, Seps, []]),
  case lists:member (C, Seps) of
    true -> tokens1 (S, Seps, [[]]);
    false -> tokens2 (S, Seps, [], [C])
  end;
tokens1 ([C|S], Seps, Toks) ->
  %io:format ("tokens1: C=~p, S=~p, Seps=~p, Toks=~p~n", [C, S, Seps, Toks]),
  case lists:member (C, Seps) of
    true -> tokens1 (S, Seps, Toks);
    false -> tokens2 (S, Seps, Toks, [C])
  end;
tokens1 ([], _Seps, Toks) ->
  %io:format ("tokens1: C/S=[], Seps=~p, Toks=~p~n", [_Seps, Toks]),
  lists:reverse (Toks).

tokens2 ([C], Seps, Toks, Cs) ->
  %io:format ("tokens2: C=~p, Seps=~p, Toks=~p, Cs=~p~n", [C, Seps, Toks, Cs]),
  case lists:member (C, Seps) of
    true -> tokens1 ([], Seps, [[], lists:reverse (Cs)|Toks]);
    false -> tokens2 ([], Seps, Toks, [C|Cs])
  end;
tokens2 ([C, C |S], Seps, Toks, Cs) ->
  %io:format ("tokens2: C=~p, C=~p, S=~p, Seps=~p, Toks=~p, Cs=~p~n", [C, C, S, Seps, Toks, Cs]),
  case lists:member (C, Seps) of
    true -> tokens1 ([C|S], Seps, [[], lists:reverse (Cs)|Toks]);
    false -> tokens2 ([C|S], Seps, Toks, [C|Cs])
  end;
tokens2 ([C|S], Seps, [], Cs) ->
  %io:format ("tokens2: C=~p, S=~p, Seps=~p, Toks=~p, Cs=~p~n", [C, S, Seps, [], Cs]),
  case lists:member (C, Seps) of
    true -> tokens1 (S, Seps, [lists:reverse (Cs)|[]]);
    false -> tokens2 (S, Seps, [], [C|Cs])
  end;
tokens2 ([C|S], Seps, Toks, Cs) ->
  %io:format ("tokens2: C=~p, S=~p, Seps=~p, Toks=~p, Cs=~p~n", [C, S, Seps, Toks, Cs]),
  case lists:member (C, Seps) of
    true -> tokens1 (S, Seps, [lists:reverse (Cs)|Toks]);
    false -> tokens2 (S, Seps, Toks, [C|Cs])
  end;
tokens2 ([], _Seps, Toks, Cs) ->
  %io:format ("tokens2: C/S=[], Seps=~p, Toks=~p, Cs=~p~n", [_Seps, Toks, Cs]),
  lists:reverse ([lists:reverse (Cs)|Toks]).

%% Got from EGTM's EUnit utility module.
tc_avg (Fun) -> tc_avg (Fun, ?TC_AVG_REPEAT).
tc_avg (Fun, Count) when is_function (Fun, 0) ->
  tc_avg_internal (Fun, Count, 0).
tc_avg_internal (_, 0, Avg) -> Avg;
tc_avg_internal (Fun, Count, Avg) ->
  {T,_} = timer:tc (Fun),
  NewAvg = case Avg =:= 0 of
    true  -> T;
    false -> (Avg+T)/2
  end,
  tc_avg_internal (Fun, Count-1, NewAvg).

main ([X]) -> main (list_to_integer (X));
main (Max) when is_integer (Max) ->
  Delim = "|",
  Seq = lists:seq (0, Max),
  Mst = fun () -> {_, _, Ms} = now (), Ms end,
  Str = [ $  + (random:uniform (Max) + Mst () + I) rem ($~-$ )
          || I <- Seq ],
  io:format ("Max=~b, Delim=~p~n", [Max, Delim]),

  %timer:tc (fun epiece/3, [Str, Delim, Seq]).
  {Tim0, Res} = ?BENCH (fun () -> epiece (Str, Delim, Seq) end),
  io:format (" * epiece ........................ ~7.6b~n", [Tim0]),

  {Tim1, _} = ?BENCH (fun () -> string:tokens (Str, Delim) end),
  io:format (" * string:tokens ................. ~7.6b~n", [Tim1]),

  {Tim2, _} = ?BENCH (fun () -> re:split (Str, resc (Delim), [{return, list}]) end),
  io:format (" * re:split ...................... ~7.6b~n", [Tim2]),

  {Tim2x, _} = ?BENCH (fun () -> re:split (Str, resc (Delim), [{return, list}]) end),
  io:format (" * re:split again (cached?) ...... ~7.6b~n", [Tim2x]),

  {Tim3, Res} = ?BENCH (fun () -> epiece2 (Str, Delim, Seq) end),
  io:format (" * epiece2 (re:split; cached?) ... ~7.6b~n", [Tim3]),

  {Tim4, _} = ?BENCH (fun () -> tokens (Str, Delim) end),
  io:format (" * string:tokens hack ............ ~7.6b~n", [Tim4]),

  %% Warm up `epiece_nif' (let it load the shared library first)
  %% ...unlike others [i.e. re:split], only the first run is slower
  %% independently on its input arguments!
  epiece_nif:piece ("a,b,c", ","),

  {Tim5, _} = ?BENCH (fun () -> epiece_nif:piece (Str, Delim) end),
  io:format (" * epiece_nif:piece .............. ~7.6b~n", [Tim5]),

  {Tim6, _} = ?BENCH (fun () -> epn (Str, Delim, Seq) end),
  io:format (" * epiece_nif + xzip ............. ~7.6b~n", [Tim6]),

  {Tim7, _} = ?BENCH (fun () -> epz (Str, Delim) end),
  io:format (" * epz ........................... ~7.6b~n", [Tim7]),

  timer:sleep (500),

  %io:format ("foo: ~p~n", [tokens ("aaa:bbb:::ccc:ddd::", ":")]),
  ok.
