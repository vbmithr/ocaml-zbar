open Zbar

let (>>=) = Lwt.bind

let main () =
  let open Video in
  let dev = opendev () in
  let s = stream dev in
  Lwt_stream.iter_s
    (fun img ->
       let sym_stream = Image.stream img in
       Lwt_stream.iter_s
         ( fun s ->
           Lwt_io.printf "Decoded symbol: %s\n" (Symbol.get_data s)
         )
         sym_stream >>= fun () ->
       Image.destroy img; Lwt_io.printf ".") s >>= fun () ->
  disable dev;
  closedev dev;
  Lwt.return ()

let _ = Lwt_main.run (main ())
