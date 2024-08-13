
let find_backend_from_filter filter =
  OpamFilter.fold_down_left (fun acc filter ->
    match filter with
    | OpamTypes.FOp (OpamTypes.FIdent ([],variable,None), `Eq, FString value) ->
        (* Printf.printf "%s\n" @@ OpamFilter.to_string filter; *)
        let variable_name = OpamVariable.to_string variable in
        (match variable_name with
        | "os-family" | "os-distribution" ->
            (match value with
            | "debian" ->
                (* Printf.printf "debian\n"; *)
                Some `Debian
            | "alpine" ->
                (* Printf.printf "alpine\n"; *)
                Some `Alpine
            | _ -> acc)
        | _ -> acc)
    | _ -> acc
  ) None filter

let translate_depexts depexts =
  let conditions : OpamTypes.filtered_formula =
    List.fold_left (fun acc depext ->
      let sys_pkgs, filter = depext in
      OpamSysPkg.Set.fold (fun sys_pkg acc ->
        let pkg_name = OpamSysPkg.to_string sys_pkg in
        let pkg_name = Str.global_replace (Str.regexp_string ".") "-" pkg_name in
        let pkg_name = Str.global_replace (Str.regexp_string "@") "-" pkg_name in
        let backend = find_backend_from_filter filter in
        let repository_pkg_name = match backend with
          | Some `Debian -> Some (OpamPackage.Name.of_string ("deb-" ^ pkg_name))
          | Some `Alpine -> Some (OpamPackage.Name.of_string ("apkg-" ^ pkg_name))
          | None -> None
        in
        match repository_pkg_name with
        | Some name ->
          let depend = OpamTypes.Atom (name, OpamTypes.Atom (OpamTypes.Filter filter)) in
          OpamTypes.And (acc, depend)
        | None -> acc
      ) sys_pkgs acc
    ) OpamTypes.Empty depexts
  in
  conditions

let translate_opam_file opam_file_path =
  let opam_file =
    let opam_filename = OpamFilename.raw opam_file_path in
    OpamFile.make opam_filename
  in
  let opam = OpamFile.OPAM.read opam_file in
  let transformed = translate_depexts opam.depexts in
  let opam = OpamFile.OPAM.with_depexts [] opam in
  let depends = OpamFormula.And (opam.depends, transformed) in
  let opam = OpamFile.OPAM.with_depends depends opam in
  OpamFile.OPAM.write_with_preserved_format opam_file opam

let () =
  if Array.length Sys.argv < 2 then (
    Printf.eprintf "Usage: %s <repository directory>\n" Sys.argv.(0);
    exit 1);
  let dir_path = Sys.argv.(1) in
  let package_dirs = Sys.readdir dir_path in
  Array.iter (fun package_dir ->
    let package_dir = Filename.concat dir_path package_dir in
    if Sys.is_directory package_dir then (
      let version_dirs = Sys.readdir package_dir in
      Array.iter (fun version_dir ->
        let version_dir = Filename.concat package_dir version_dir in
        let opam_file_path = Filename.concat version_dir "opam" in
        translate_opam_file opam_file_path
      ) version_dirs
    )
  ) package_dirs;

