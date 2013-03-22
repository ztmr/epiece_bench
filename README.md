Erlang string splitting experiments
===================================
The goal is to find the fastest possible way of
string splitting/tokenization with string delimiter.
Inspiration comes from ANSI/ISO MUMPS $P[iece] function.

Assumption is that string:split does not exists
and we don't want to implement it as BIF/NIF native
calls.

This project contains several string splitting methods
which we're trying to test and optimize until we find
the fastest one.

The resulting function may be generalization of multiple
methods so that it will decide which method to use.
(Input text length, delimiter length, etc.)

An ideal candidate will look like:

  epiece ("hello:world::zoo::joe", ":") ->
    [{1, "hello"}, {2, "world"}, {3, []}, {4, "zoo"}, {5, []}, {6, "joe"}].
  epiece ("hello:world::zoo::joe", ":", [foo, bar, x, x, x, ex]) ->
    [{foo, "hello"}, {bar, "world"}, {x, []}, {ex, "joe"}].

