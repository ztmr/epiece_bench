-module (epiece).
-compile (export_all).

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

tokens1 ([C, C |S], Seps, Toks) ->
  case lists:member (C, Seps) of
    true -> tokens1 ([C|S], Seps, [[]|Toks]);
    false -> tokens2 ([C|S], Seps, Toks, [C])
  end;
tokens1 ([C|S], Seps, Toks) ->
  case lists:member (C, Seps) of
    true -> tokens1 (S, Seps, Toks);
    false -> tokens2 (S, Seps, Toks, [C])
  end;
tokens1 ([], _Seps, Toks) ->
  lists:reverse (Toks).

tokens2 ([C, C |S], Seps, Toks, Cs) ->
  case lists:member (C, Seps) of
    true -> tokens1 ([C|S], Seps, [[], lists:reverse (Cs)|Toks]);
    false -> tokens2 ([C|S], Seps, Toks, [C|Cs])
  end;
tokens2 ([C|S], Seps, Toks, Cs) ->
  case lists:member (C, Seps) of
    true -> tokens1 (S, Seps, [lists:reverse (Cs)|Toks]);
    false -> tokens2 (S, Seps, Toks, [C|Cs])
  end;
tokens2 ([], _Seps, Toks, Cs) ->
  lists:reverse ([lists:reverse (Cs)|Toks]).

main ([X]) -> main (list_to_integer (X));
main (Max) when is_integer (Max) ->
  Delim = "\\",
  Seq = lists:seq (0, Max),
  Mst = fun () -> {_, _, Ms} = now (), Ms end,
  Str = [ $  + (random:uniform (Max) + Mst () + I) rem ($~-$ )
          || I <- Seq ],
  io:format ("Max=~b, Delim=~p~n", [Max, Delim]),

  %timer:tc (fun epiece/3, [Str, Delim, Seq]).
  {Tim0, Res} = timer:tc (fun () -> epiece (Str, Delim, Seq) end),
  io:format (" * epiece ........................ ~7.6b~n", [Tim0]),

  {Tim1, _} = timer:tc (fun () -> string:tokens (Str, Delim) end),
  io:format (" * string:tokens ................. ~7.6b~n", [Tim1]),

  {Tim2, _} = timer:tc (fun () -> re:split (Str, resc (Delim), [{return, list}]) end),
  io:format (" * re:split ...................... ~7.6b~n", [Tim2]),

  {Tim2x, _} = timer:tc (fun () -> re:split (Str, resc (Delim), [{return, list}]) end),
  io:format (" * re:split again (cached?) ...... ~7.6b~n", [Tim2x]),

  {Tim3, Res} = timer:tc (fun () -> epiece2 (Str, Delim, Seq) end),
  io:format (" * epiece2 (re:split; cached?) ... ~7.6b~n", [Tim3]),

  {Tim4, _} = timer:tc (fun () -> tokens (Str, Delim) end),
  io:format (" * string:tokens hack ............ ~7.6b~n", [Tim4]),

  %io:format ("foo: ~p~n", [tokens ("aaa:bbb:::ccc:ddd::", ":")]),
  ok.
