open Zbar

let (>>=) = Lwt.bind

let main () =
  set_verbosity 0;
  let scanner = ImageScanner.create () in
  ImageScanner.set_config scanner `None `Enable 0;
  ImageScanner.set_config scanner `Qrcode `Enable 1;
  ImageScanner.enable_cache scanner true;
  let dev = Video.opendev () in
  let imgs = Video.stream dev in
  let imgs = Lwt_stream.map (fun img -> Image.convert img "GREY") imgs in
  let symbols = Lwt_stream.map (fun img -> ImageScanner.scan_image scanner img) imgs in
  Lwt_stream.iter_s
    (fun syms -> Lwt_stream.iter_s
        (fun s -> Lwt_io.printf "%s\n" (Symbol.get_data s)) syms) symbols >>= fun () ->
  Video.disable dev;
  Video.closedev dev;
  Lwt.return ()

let _ = Lwt_main.run (main ())
