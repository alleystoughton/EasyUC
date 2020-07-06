(* ucState.ml *)

(* Global state of UC DSL tool *)

let include_dirs_ref : string list ref = ref []

let get_include_dirs() = ! include_dirs_ref

let set_include_dirs x = include_dirs_ref := x