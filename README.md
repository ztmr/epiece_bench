Erlang string splitting experiments
===================================
The goal is to find the fastest possible way of
string splitting/tokenization with string delimiter.
Inspiration comes from ANSI/ISO MUMPS `$P[iece]` function.

Assumption is that `string:split` does not exist
(even if it was proposed
[multiple times](http://erlang.org/pipermail/erlang-questions/2008-October/038892.html))
and we don't want to implement it as BIF/NIF native
calls.

This project contains several string splitting methods
which we're trying to test and optimize until we find
the fastest one.

The resulting function may be generalization of multiple
methods so that it will decide which method to use.
(Input text length, delimiter length, etc.)

An ideal candidate will look like:
```Erlang
  epiece ("hello:world::zoo::joe", ":") ->
    [{1, "hello"}, {2, "world"}, {3, []}, {4, "zoo"}, {5, []}, {6, "joe"}].
  epiece ("hello:world::zoo::joe", ":", [foo, bar, x, x, x, ex]) ->
    [{foo, "hello"}, {bar, "world"}, {x, []}, {ex, "joe"}].
```


The NIF way
===========
Well, we're not lazy, so the NIF library was added too.
It is pretty fast and may be even faster.

The next step would be to change the NIF module
to work with binaries instead of lists/strings.

Another thing is to make `epiece:epn` function
completely native -- for sure, it will be faster
to make `xzip` and `epiece_nif:piece` within a
single iteration loop in the NIF itself.

