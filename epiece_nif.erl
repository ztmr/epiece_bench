-module (epiece_nif).

-export ([piece/2]).
-on_load (nif_init/0).

nif_init () ->
  erlang:load_nif ("./epiece_nif", 0).

piece (_, _) -> not_loaded (?LINE).

not_loaded (Line) ->
  exit ({not_loaded, [{module, ?MODULE}, {line, Line}]}).

%% vim: fdm=syntax:fdn=3:tw=74:ts=2:syn=erlang
