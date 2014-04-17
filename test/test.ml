open Zbar

let (>>=) = Lwt.bind

let rec display_speed_info nb_read ival =
  nb_read := 0;
  Lwt_unix.sleep ival >>= fun () ->
  Printf.printf "%d QR/s\n%!" !nb_read;
  display_speed_info nb_read ival

let main dev cached verb bench =
  let nb_read = ref 0 in
  if bench then Lwt.async (fun () -> display_speed_info nb_read 1.);
  set_verbosity verb;
  let scanner = ImageScanner.create () in
  ImageScanner.set_config scanner `None `Enable 0;
  ImageScanner.set_config scanner `Qrcode `Enable 1;
  ImageScanner.enable_cache scanner cached;
  let dev = Video.opendev ~dev () in
  let imgs = Video.stream dev in
  let imgs = Lwt_stream.map (fun img -> Image.convert img "GREY") imgs in
  let symbols = Lwt_stream.map (fun img -> ImageScanner.scan_image scanner img) imgs in
  Lwt_stream.iter (fun syms ->
      if List.length syms > 0 then
        (incr nb_read;
         if bench then Printf.printf ".%!");
      if not bench then List.iter (fun s -> Printf.printf "%s\n%!" (Symbol.get_data s)) syms
    )
    symbols
  >>= fun () ->
  Video.disable dev;
  Video.closedev dev;
  Lwt.return ()

let _ =
  let open Arg in
  let device = ref "/dev/video0" in
  let verbosity = ref 0 in
  let cache_enabled = ref false in
  let bench = ref false in
  let speclist = align [
      "--bench", Set bench, " Enable benchmark mode";
      "--verbose", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "-v", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "--enable-cache", Set cache_enabled, " Enable QR-code cache to suppress doublons";
    ] in
  let usage_msg = "Usage: " ^ Sys.argv.(0) ^ " [options] [/dev/video?]\nOptions are:" in
  parse speclist ignore usage_msg;
  if Array.length Sys.argv > 1 then
    device := Sys.argv.(1);
  Lwt_main.run (main !device !cache_enabled !verbosity !bench)
