open Zbar

let (>>=) = Lwt.bind

let main () =
  let open Video in
  let dev = opendev () in
  let s = stream dev in
  Lwt_stream.iter_s (fun i -> Image.destroy i; Lwt_io.printf "Image received!\n") s >>= fun () ->
  disable dev;
  closedev dev;
  Lwt.return ()

let _ = Lwt_main.run (main ())
