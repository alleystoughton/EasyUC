(* ucState.mli *)

(* Global state of UC DSL tool *)

val get_include_dirs : unit -> string list

val set_include_dirs : string list -> unit
