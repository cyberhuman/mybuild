open Printf
open Ocamlbuild_plugin

let bracket res destroy k =
  match k res with
  | exception e -> destroy res; raise e
  | x -> destroy res; x

let cmd cmd = bracket (Unix.open_process_in cmd) (fun ch -> ignore @@ Unix.close_process_in ch) input_line

module Version = struct

let git_describe () =
  let version = cmd "git describe --long --always --dirty=+\"$(git config user.name)@$(hostname)\"" in
  let version = String.map (function ' ' -> '.' | c -> c) version in
  match cmd "git symbolic-ref -q --short HEAD" with
  | exception End_of_file -> version
  | "" | "master" -> version
  | branch -> version^"-"^branch

let save outfile =
  bracket (open_out outfile) close_out begin fun out ->
    let revision = try git_describe () with _ -> "<unknown>" in
    Printf.fprintf out "let id = %S\n" revision
  end

end

module Atdgen = struct

let setup_ c =
  let ml = sprintf "_%c.ml" c in
  let prod = "%" ^ ml in
  rule ("atdgen: .atd -> " ^ ml) ~dep:"%.atd" ~prods:[prod; prod^"i"] begin fun env _ ->
    Cmd (S (
      [ P "atdgen"; T (tags_of_pathname (env prod) ++ "atdgen");
        A (sprintf "-%c" c)
      ] @
      (if c = 'j' then [A "-j-std"] else []) @ (* better use _tags? *)
      [A (env "%.atd"); ]
    ))
  end

let setup () =
  setup_ 't';
  setup_ 'b';
  setup_ 'j';
  setup_ 'v';
  pflag ["atdgen"] "atdgen" (fun s -> S [A s]);
  ()

end

module Extprot = struct

let setup () =
  rule ("extprot: proto -> ml") ~dep:"%.proto" ~prod:"%.ml" begin fun env _ ->
    let dep = env "%.proto" and prod = env "%.ml" in
    Cmd (S[ P"extprotc";
      T(tags_of_pathname prod ++ "extprot");
      A "-w"; A "200";
      A dep;
      A"-o"; A prod;
    ])
  end

end

module Ragel = struct

let setup () =
  rule ("ragel: .ml.rl -> .ml") ~dep:"%.ml.rl" ~prod:"%.ml" begin fun env _ ->
    let dep = env "%.ml.rl" and prod = env "%.ml" in
    Cmd (S[ P"ragel";
      T(tags_of_pathname prod ++ "ragel");
      A "-O";
      A "-F1";
      A dep;
      A"-o"; A prod;
    ])
  end;
  rule ("ragel: .c.rl -> .c") ~dep:"%.c.rl" ~prod:"%.c" begin fun env _ ->
    let dep = env "%.c.rl" and prod = env "%.c" in
    Cmd (S[ P"ragel";
      T(tags_of_pathname prod ++ "ragel");
      A "-C";
      A "-G2";
      A dep;
      A"-o"; A prod;
    ])
  end

end

(** common tags for ocaml compiler *)
module OCaml = struct

let setup () =
  flag ["ocaml";"compile";"native";"asm"] & S [A "-S"];
  flag ["ocaml"; "link"; "toplevel"] & A"-linkpkg";
  pflag ["ocaml";"link";"native"] "inline" (fun s -> S [A "-inline"; A s]);
  ()

end

module Full = struct

let setup () =
  OCaml.setup ();
  Atdgen.setup ();
  Extprot.setup ();
  Ragel.setup ();
  ()

end