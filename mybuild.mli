(** Collection of ocamlbuild plugins *)

(** Extract version information from VCS *)
module Version :
sig
val git_describe : unit -> string

(** Save extracted version into specified OCaml source file, as [let id = <detected version>]
  @param default substitute for version if VCS information is not available, defaults to ["<unknown>"]
*)
val save : ?default:string -> string -> unit
end

(** Rules for {{:https://github.com/mjambon/atdgen}atdgen} JSON (and biniou) serialization code generator *)
module Atdgen :
sig
(** Add rules [.atd -> _t.ml _t.mli _j.ml _j.mli _v.ml _v.mli _b.ml _b.mli] *)
val setup : unit -> unit
end

(** Rules for {{:https://github.com/mfp/extprot}extprot} extensible binary protocol code generator *)
module Extprot :
sig
(** Add rule [.proto -> .ml] *)
val setup : unit -> unit
end

(** Rules for {{:https://www.colm.net/open-source/ragel/}ragel} state machine compiler *)
module Ragel :
sig
(** Add rules [.c.rl -> .c] and [.ml.rl -> .ml] *)
val setup : unit -> unit
end

(** Implementation of "standard" tags for the older OCaml versions *)
module OCaml :
sig
(** Add tags [inline], [asm], [runtime_variant], [warn] (if not implemented by ocamlbuild) *)
val setup : unit -> unit
end

(** All in one *)
module Full :
sig
(** Enable all of the above plugins *)
val setup : unit -> unit
end