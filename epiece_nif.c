
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "erl_nif.h"

#define EPIECE$MAXINPUT           (1024*1024)
#define EPIECE$MAXDELIM           128
#define EPIECE$MAXITEMS           ((EPIECE$MAXINPUT)/2)

#define NIFARGS \
  ErlNifEnv * env, int argc, const ERL_NIF_TERM argv []
#define NIF(name) \
  ERL_NIF_TERM (name) (NIFARGS)

static int load_internal (ErlNifEnv * env, void ** priv, void ** old_priv,
                          ERL_NIF_TERM load_info, bool upgrade) { return 0; }

static int load (ErlNifEnv * env, void ** priv,
                 ERL_NIF_TERM load_info) {

  return load_internal (env, priv, NULL, load_info, false);
}

static int upgrade (ErlNifEnv * env, void ** priv, void ** old_priv,
                    ERL_NIF_TERM load_info) {

  return load_internal (env, priv, old_priv, load_info, true);
}

static int reload (ErlNifEnv * env, void ** priv,
                   ERL_NIF_TERM load_info) { return 0; }

static void unload (ErlNifEnv * env, void * priv) { }

NIF (piece) {

  if (argc != 2) return enif_make_badarg (env);

  char input [EPIECE$MAXINPUT];
  char delim [EPIECE$MAXDELIM];
  ERL_NIF_TERM result [EPIECE$MAXITEMS];
  int i;
  unsigned itemCnt;

  if (enif_get_string (env, argv [0], input, EPIECE$MAXINPUT, ERL_NIF_LATIN1) < 0)
    return enif_make_badarg (env);

  if (enif_get_string (env, argv [1], delim, EPIECE$MAXDELIM, ERL_NIF_LATIN1) < 0)
    return enif_make_badarg (env);

  char * pos_ptr,
       * start_ptr = input,
       * token;
  for (i = 1, itemCnt = 0;
       itemCnt < EPIECE$MAXITEMS &&
       pos_ptr < input+EPIECE$MAXINPUT; start_ptr = NULL) {
    token = strtok_r (start_ptr, delim, &pos_ptr);
    if (token == NULL) break;
    result [itemCnt++] = enif_make_string (env, token, ERL_NIF_LATIN1);
  }

  return enif_make_list_from_array (env, result, itemCnt);
}

static ErlNifFunc nif_funcs [] = {
  {"piece", 2, piece}
};

ERL_NIF_INIT (epiece_nif, nif_funcs, &load, &reload, &upgrade, &unload);

// vim: fdm=syntax:fdn=1:tw=74:ts=2:syn=c
