open Lwt.Infix
open Zbar

let rec display_speed_info nb_read ival =
  nb_read := 0;
  Lwt_unix.sleep ival >>= fun () ->
  Printf.printf "%d QR/s\n%!" !nb_read;
  display_speed_info nb_read ival

let main dev dim cached verb bench =
  let nb_read = ref 0 in
  if bench then Lwt.async (fun () -> display_speed_info nb_read 1.);
  set_verbosity verb;
  let scanner = ImageScanner.create () in
  ImageScanner.set_config scanner None Enable 0;
  ImageScanner.set_config scanner Qrcode Enable 1;
  ImageScanner.enable_cache scanner cached;
  let dev = Video.opendev ~dev () in
  (match dim with
  | Some (x, y) -> Video.request_size dev x y
  | _ -> ());
  match Zbar_lwt.video_stream dev with
  | Error msg ->
    Lwt.fail_with msg
  | Ok imgs ->
    let imgs = Lwt_stream.map
        (fun img -> Image.convert img "GREY") imgs in
    let symbols = Lwt_stream.map
        (fun img -> ImageScanner.scan_image scanner img) imgs in
    Lwt_stream.iter begin fun syms ->
      if List.length syms > 0 then begin
        incr nb_read;
        if bench then Printf.printf ".%!"
        end ;
      if not bench then
        List.iter begin fun s ->
          Printf.printf "%s\n" (Symbol.get_data s)
        end syms
    end symbols

let _ =
  let open Arg in
  let device = ref "/dev/video0" in
  let dim = ref None in
  let verbosity = ref 0 in
  let cache_enabled = ref false in
  let bench = ref false in
  let speclist = align [
      "--dim", String
        (fun d -> let set_dim x y = dim := Some (x, y) in Scanf.sscanf d "%dx%d" set_dim),
      "<int>x<int> Specify video capture size, e.g. 640x480";
      "--enable-cache", Set cache_enabled, " Enable QR-code cache to suppress doublons";
      "--bench", Set bench, " Enable benchmark mode";
      "--verbose", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "-v", Set_int verbosity, "<int> Verbosity level (default: 0)";
    ] in
  let usage_msg = "Usage: " ^ Sys.argv.(0) ^ " [options] [/dev/video?]\nOptions are:" in
  let set_device d = device := d in
  parse speclist set_device usage_msg;
  Lwt_main.run (main !device !dim !cache_enabled !verbosity !bench)
