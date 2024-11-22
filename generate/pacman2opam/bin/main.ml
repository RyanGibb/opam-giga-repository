let mirror = "https://mirror.rackspace.com/archlinux"
let arch = "x86_64"
let repos = [ "core"; "extra"; "multilib" ]
let tmp_dir = "archlinux.tmp"
let out_dir = "archlinux"
let path = String.concat "/"

let mkdir_p s =
  String.split_on_char '/' s
  |> List.fold_left
       (fun acc d ->
         let p = if String.length acc > 0 then path [ acc; d ] else d in
         let () = if not (Sys.file_exists p) then Sys.mkdir p 0o755 in
         p)
       ""

let () =
  List.iter
    (fun repo ->
      let dest = mkdir_p (path [ tmp_dir; repo ]) in
      let () = Printf.printf "%s\n" dest in
      let file = repo ^ ".tar.gz" in
      let _ =
        if Sys.file_exists file then 0
        else Sys.command (Filename.quote_command "curl" [ "-L"; path [ mirror; repo; "os"; arch; repo ^ ".db.tar.gz" ]; "-o"; file ])
      in
      if Sys.command (Filename.quote_command "tar" [ "-xzf"; file; "-C"; dest ]) <> 0 then assert false)
    repos

let read_input file =
  let ic = open_in file in
  let rec loop input lines =
    try
      let line = input_line input in
      loop input (line :: lines)
    with
    | End_of_file ->
        close_in input;
        lines
  in
  loop ic [] |> List.rev

type con = {
  equality : string;
  version : string;
}

type entry = {
  name : string;
  con : con option;
}

type pac = {
  filename : string;
  name : string;
  repo : string;
  version : string;
  sha256 : string;
  deps : entry list;
  provides : entry list;
  conflicts : entry list;
}

module List = struct
  include List

  let rec split_on_element e = function
    | [] -> ([], [])
    | hd :: tl ->
        if hd = e then ([], tl)
        else
          let a, b = split_on_element e tl in
          (hd :: a, b)
end

module String = struct
  include String

  let strstr haystack needle =
    let nlen = String.length needle in
    let rec loop = function
      | i when i < 0 -> -1
      | i -> if String.sub haystack i nlen = needle then i else loop (i - 1)
    in
    loop (String.length haystack - nlen)
end

let normalise invalid s = List.fold_left (fun acc ch -> if String.contains acc ch then String.split_on_char ch acc |> String.concat "_" else acc) s invalid

let entry_of_string s =
  let name, con =
    List.fold_left
      (fun (name, cons) n ->
        let l = String.length n in
        let i = String.strstr s n in
        if name = None && i >= 0 then (Some (String.sub s 0 i), Some { equality = String.sub s i l; version = String.sub s (i + l) (String.length s - l - i) })
        else (name, cons))
      (None, None) [ ">="; "<="; "<"; ">"; "=" ]
  in
  let name = normalise [ '.' ] (Option.value ~default:s name) in
  { name; con }

let quoted_string lst = List.map (fun x -> "\"" ^ x ^ "\"") lst |> String.concat " "

let string_of_entry v =
  match v.con with
  | Some c -> quoted_string [ v.name ] ^ " {" ^ c.equality ^ " " ^ quoted_string [ c.version ] ^ "}"
  | _ -> quoted_string [ v.name ]

let rec process p = function
  | "%FILENAME%" :: filename :: tl -> process { p with filename } tl
  | "%NAME%" :: name :: tl -> process { p with name = normalise [ '.' ] name } tl
  | "%VERSION%" :: version :: tl -> process { p with version = normalise [ ':' ] version } tl
  | "%SHA256SUM%" :: sha256 :: tl -> process { p with sha256 } tl
  | "%CONFLICTS%" :: tl ->
      let conflicts, rest = List.split_on_element "" tl in
      process { p with conflicts = List.map entry_of_string conflicts } rest
  | "%PROVIDES%" :: tl ->
      let provides, rest = List.split_on_element "" tl in
      process { p with provides = List.map entry_of_string provides } rest
  | "%DEPENDS%" :: tl ->
      let deps, rest = List.split_on_element "" tl in
      process { p with deps = List.map entry_of_string deps } rest
  | _ :: tl -> process p tl
  | [] -> p

let () =
  let _ = mkdir_p out_dir in
  let oc = open_out (path [ out_dir; "/repo" ]) in
  let () = Printf.fprintf oc "opam-version: \"2.0\"\n" in
  close_out oc

let pkgs = Hashtbl.create 100_000

let () =
  List.iter
    (fun repo ->
      Sys.readdir (path [ tmp_dir; repo ])
      |> Array.to_list
      |> List.iter (fun folder ->
             let desc = path [ tmp_dir; repo; folder; "desc" ] in
             let content = if Sys.is_regular_file desc then read_input desc else [] in
             let p = process { filename = ""; name = ""; repo; version = ""; sha256 = ""; deps = []; provides = []; conflicts = [] } content in
             Hashtbl.add pkgs p.name p))
    repos

let visited = Hashtbl.create 100000

(* Remove circular dependencies *)
let rec dfs bt (p : pac) =
  List.iter
    (fun (d : entry) ->
      if List.mem d.name bt then
        let () = Printf.printf "pkg %s: remove circular dependency on %s\n" p.name d.name in
        Hashtbl.replace pkgs p.name { p with deps = List.filter (fun (e : entry) -> e.name <> d.name) p.deps }
      else
        match Hashtbl.find_opt visited d.name with
        | Some _ -> ()
        | None -> (
            match Hashtbl.find_opt pkgs d.name with
            | None -> ()
            | Some p ->
                let () = dfs (d.name :: bt) p in
                Hashtbl.add visited p.name true))
    p.deps

let () = Hashtbl.iter (fun _ pkg -> dfs [] pkg) pkgs

(* fix version where pacman assumes 256.6 == 256.6-1 *)
let () =
  Hashtbl.iter
    (fun name pkg ->
      List.iter
        (fun (dep : entry) ->
          match dep.con with
          | None -> ()
          | Some con -> (
              match String.index_opt con.version '-' with
              | Some _ -> ()
              | None -> (
                  match Hashtbl.find_opt pkgs dep.name with
                  | None -> ()
                  | Some p ->
                      if String.length p.version > String.length con.version && String.sub p.version 0 (String.length con.version) = con.version then
                        let () = Printf.printf "pkg %s: updating dependency version of %s from %s to %s\n" name dep.name con.version p.version in
                        Hashtbl.replace pkgs name
                          {
                            pkg with
                            deps =
                              List.map
                                (fun (e : entry) -> if e.name = dep.name then { name = e.name; con = Some { con with version = p.version } } else e)
                                pkg.deps;
                          })))
        pkg.deps)
    pkgs

let () =
  Hashtbl.iter
    (fun _ d ->
      if d.name <> "opam" then
        let opam = mkdir_p (path [ out_dir; "packages"; d.name; d.name ^ "." ^ d.version ]) in
        let () = Printf.printf "Creating %s/opam\n" opam in
        let oc = open_out (path [ opam; "opam" ]) in
        let () = Printf.fprintf oc "opam-version: \"2.0\"\n" in
        let () = Printf.fprintf oc "build: [%s]\n" (quoted_string [ "/usr/bin/pacman"; "-U"; "--nodeps"; "--nodeps"; "--noconfirm"; d.filename ]) in
        let () = Printf.fprintf oc "remove: [%s]\n" (quoted_string [ "/usr/bin/pacman"; "-R"; "--noconfirm"; d.name ]) in
        let () =
          if List.length d.deps > 0 then
            let () = Printf.fprintf oc "depends: [\n" in
            let () = List.iter (fun e -> Printf.fprintf oc "  %s\n" (string_of_entry e)) d.deps in
            Printf.fprintf oc "]\n"
        in
        let () =
          if List.length d.conflicts > 0 then
            let () = Printf.fprintf oc "conflicts: [\n" in
            let () =
              List.iter
                (fun (conflict : entry) ->
                  match List.find_opt (fun (provide : entry) -> provide.name = conflict.name) d.provides with
                  | Some p when p.con != None ->
                      let c = Option.value ~default:{ equality = "!="; version = d.version } p.con in
                      Printf.fprintf oc "  %s\n" (string_of_entry { name = conflict.name; con = Some { equality = "!="; version = c.version } })
                  | Some _
                  | None ->
                      Printf.fprintf oc "  %s\n" (string_of_entry conflict))
                d.conflicts
            in
            Printf.fprintf oc "]\n"
        in
        let () = Printf.fprintf oc "extra-source \"%s\" {\n" d.filename in
        let () = Printf.fprintf oc "  src: \"%s/%s/os/%s/%s\"\n" mirror d.repo arch d.filename in
        let () = if d.sha256 <> "" then Printf.fprintf oc "  checksum: [ \"sha256=%s\" ]\n" d.sha256 in
        let () = Printf.fprintf oc "}\n" in
        let () = close_out oc in
        List.iter
          (fun p ->
            let c = Option.value ~default:{ equality = "="; version = "1" } p.con in
            let opam = mkdir_p (path [ out_dir; "packages"; p.name; p.name ^ "." ^ c.version ]) in
            let opam_file = path [ opam; "opam" ] in
            if not (Sys.file_exists opam_file) then
              let oc = open_out (path [ opam; "opam" ]) in
              let () = Printf.fprintf oc "opam-version: \"2.0\"\n" in
              let () = Printf.fprintf oc "depends: [ %s ]\n" (string_of_entry { name = d.name; con = Some { equality = "="; version = d.version } }) in
              close_out oc)
          d.provides)
    pkgs
