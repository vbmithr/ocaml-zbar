open Zbar

let (>>=) = Lwt.bind

let main dev cached verb =
  set_verbosity verb;
  let scanner = ImageScanner.create () in
  ImageScanner.set_config scanner `None `Enable 0;
  ImageScanner.set_config scanner `Qrcode `Enable 1;
  ImageScanner.enable_cache scanner cached;
  let dev = Video.opendev ~dev () in
  let imgs = Video.stream dev in
  let imgs = Lwt_stream.map (fun img -> Image.convert img "GREY") imgs in
  let symbols = Lwt_stream.map (fun img -> ImageScanner.scan_image scanner img) imgs in
  Lwt_stream.iter_s
    (fun syms -> Lwt_stream.iter_s
        (fun s -> Printf.printf "%s\n%!" (Symbol.get_data s) |> Lwt.return) syms) symbols
  >>= fun () ->
  Video.disable dev;
  Video.closedev dev;
  Lwt.return ()

let _ =
  let open Arg in
  let device = ref "/dev/video0" in
  let verbosity = ref 0 in
  let cache_enabled = ref true in
  let speclist = align [
      "--device", Set_string device, "<string> Path of the device to use (default: /dev/video0)";
      "-d", Set_string device, "<string> Path of the device to use (default: /dev/video0)";
      "--verbose", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "-v", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "--no-cache", Clear cache_enabled, " Launch the program in non-cached mode";
    ] in
  let usage_msg = "Usage: " ^ Sys.argv.(0) ^ " [options...]\nOptions are:" in
  parse speclist ignore usage_msg;
  Lwt_main.run (main !device !cache_enabled !verbosity)
