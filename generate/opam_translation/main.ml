
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
          | Some `Alpine -> Some (OpamPackage.Name.of_string ("apk-" ^ pkg_name))
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

let translate_pkg_name_string pkg_name =
  "opam-" ^ pkg_name

let translate_pkg_name pkg_name =
  OpamPackage.Name.to_string pkg_name |>
  translate_pkg_name_string |>
  OpamPackage.Name.of_string

let rename_depends (depends : OpamTypes.filtered_formula) : OpamTypes.filtered_formula =
  OpamFormula.map (fun (name, condition) ->
    (* TODO do we need to package names in conditions? *)
    OpamTypes.Atom (translate_pkg_name name, condition)
  ) depends

let translate_opam_file in_filepath out_filepath =
  let opam_file =
    let opam_filename = OpamFilename.raw in_filepath in
    OpamFile.make opam_filename
  in
  let opam = OpamFile.OPAM.read opam_file in
  let depext_depends = translate_depexts opam.depexts in
  let opam = OpamFile.OPAM.with_depexts [] opam in
  let depends_renamed = rename_depends opam.depends in
  let depends = OpamFormula.And (depends_renamed, depext_depends) in
  let opam = OpamFile.OPAM.with_depends depends opam in
  let opam = OpamFile.OPAM.with_name_opt (Option.map translate_pkg_name opam.name) opam in
  let out_opam_file =
    let opam_filename = OpamFilename.raw out_filepath in
    OpamFile.make opam_filename
  in
  OpamFile.OPAM.write_with_preserved_format ~format_from:opam_file out_opam_file opam

let () =
  if Array.length Sys.argv < 3 then (
    Printf.eprintf "Usage: %s <input repository directory> <output repository directory>\n" Sys.argv.(0);
    exit 1);
  let repo_dir = Sys.argv.(1) in
  let out_dir = Sys.argv.(2) in
  let package_dirs = Sys.readdir repo_dir in
  Array.iter (fun package_dirname ->
    let package_dir = Filename.concat repo_dir package_dirname in
    if Sys.is_directory package_dir then (
      let version_dirs = Sys.readdir package_dir in
      Array.iter (fun version_dirname ->
        let in_filepath =
          let version_dir = Filename.concat package_dir version_dirname in
          Filename.concat version_dir "opam"
        in
        let out_filepath =
          let out_package_dir = Filename.concat out_dir (translate_pkg_name_string package_dirname) in
          let out_version_dir = Filename.concat out_package_dir (translate_pkg_name_string version_dirname) in
          Filename.concat out_version_dir "opam"
        in
        translate_opam_file in_filepath out_filepath
      ) version_dirs
    )
  ) package_dirs;

