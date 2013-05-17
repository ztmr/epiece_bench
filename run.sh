#!/bin/sh

make -f epiece_nif.mk ; echo

echo " *** Compiled with HIPE =================="
# Like: c (epiece, [native, hipe]).
erlc +native +hipe epiece.erl
erl -eval 'epiece:main (["50"]), epiece:main (["100"]), epiece:main (["500"]), epiece:main (["1000"]), epiece:main (["10000"]), halt ().'
echo ""

echo " *** Compiled without HIPE ==============="
# Like: c (epiece).
erlc epiece.erl
erl -eval 'epiece:main (["50"]), epiece:main (["100"]), epiece:main (["500"]), epiece:main (["1000"]), epiece:main (["10000"]), halt ().'
echo ""

#echo " *** EScript ============================="
#./epiece.esc 100
#./epiece.esc 1000
#./epiece.esc 10000

