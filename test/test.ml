module Time = struct
  open Foreign
  open Ctypes

  type timespec
  let timespec : timespec structure typ = structure "timespec"
  let tv_sec  = timespec *:* long
  let tv_nsec = timespec *:* long
  let () = seal timespec

  let _clock_gettime = foreign ~check_errno:true "clock_gettime" (int @-> ptr timespec @-> returning int)

  let clock_gettime clock =
    let tv = make timespec in
    ignore (_clock_gettime clock (addr tv));
    let secs = getf tv tv_sec
    and nsecs = getf tv tv_nsec in
    Signed.Long.(Pervasives.
                   (float (to_int secs) +. float (to_int nsecs) /. 1_000_000_000.))
end

open Zbar

let (>>=) = Lwt.bind

let main dev cached verb clock =
  set_verbosity verb;
  let scanner = ImageScanner.create () in
  ImageScanner.set_config scanner `None `Enable 0;
  ImageScanner.set_config scanner `Qrcode `Enable 1;
  ImageScanner.enable_cache scanner cached;
  let dev = Video.opendev ~dev () in
  let imgs = Video.stream dev in
  let ts = ref 0. in
  let imgs = Lwt_stream.map (fun img -> ts := Image.timestamp img; Image.convert img "GREY") imgs in
  let symbols = Lwt_stream.map (fun img -> ImageScanner.scan_image scanner img) imgs in
  Lwt_stream.iter (
    List.iter (fun s ->
        let now = Time.clock_gettime clock in
        Printf.printf "%s decoded in %f s\n%!" (Symbol.get_data s) (now -. !ts))) symbols
  >>= fun () ->
  Video.disable dev;
  Video.closedev dev;
  Lwt.return ()

let _ =
  let open Arg in
  let device = ref "/dev/video0" in
  let verbosity = ref 0 in
  let cache_enabled = ref true in
  let clock = ref 1 in
  let speclist = align [
      "--device", Set_string device, "<string> Path of the device to use (default: /dev/video0)";
      "-d", Set_string device, "<string> Path of the device to use (default: /dev/video0)";
      "--verbose", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "-v", Set_int verbosity, "<int> Verbosity level (default: 0)";
      "--no-cache", Clear cache_enabled, " Launch the program in non-cached mode";
      "--clock", Set_int clock, "<int> Use specified clock type (default: 1 = MONOTONIC)";
    ] in
  let usage_msg = Printf.sprintf "Usage: %s [options...]\nOptions are:" Sys.argv.(0) in
  parse speclist ignore usage_msg;
  Lwt_main.run (main !device !cache_enabled !verbosity !clock)
