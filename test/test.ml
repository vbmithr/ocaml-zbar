open Zbar

let (>>=) = Lwt.bind

let main () =
  let dev = Video.opendev () in
  let img_stream = Video.stream dev in
  Lwt_stream.iter_s (fun img ->
       Image.destroy img; Lwt_io.printf ".") img_stream >>= fun () ->
  Video.disable dev;
  Video.closedev dev;
  Lwt.return ()

let _ = Lwt_main.run (main ())
