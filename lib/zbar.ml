open Ctypes
open Foreign

type color =
  [
  | `Space
  | `Bar
  ]

let int_of_color = function
  | `Space -> 0
  | `Bar -> 1

type symbol =
  [
  | `None
  | `Partial
  | `Ean2
  | `Ean5
  | `Ean8
  | `Upce
  | `Isbn10
  | `Upca
  | `Ean13
  | `Composite
  | `I25
  | `Databar
  | `Databar_exp
  | `Codabar
  | `Code39
  | `Pdf417
  | `Qrcode
  | `Code93
  | `Code128
  ]

let int_of_symbol = function
  | `None -> 0
  | `Partial -> 1
  | `Ean2 -> 2
  | `Ean5 -> 5
  | `Ean8 -> 8
  | `Upce -> 9
  | `Isbn10 -> 10
  | `Upca -> 12
  | `Ean13 -> 13
  | `Composite -> 14
  | `I25 -> 15
  | `Databar -> 25
  | `Databar_exp -> 34
  | `Codabar -> 35
  | `Code39 -> 39
  | `Pdf417 -> 57
  | `Qrcode -> 64
  | `Code93 -> 93
  | `Code128 -> 128

type orientation =
  [
  | `Unknown
  | `Up
  | `Right
  | `Down
  | `Left
  ]

let i_int (i:int) = ignore i

let wrap_int f success error =
  match f () with
  | -1 -> failwith (error ())
  | oth -> success oth

let verb = ref 0
let set_verb level = verb := level

let from = Dl.(dlopen ~filename:"libzbar.so" ~flags:[RTLD_LAZY])

module Image = struct
  type t
  let t : t structure typ = structure "zbar_image_s"
end

module Video = struct
  type _t
  let t : _t structure typ = structure "zbar_video_s"

  type t = _t structure ptr

  let create = foreign ~from "zbar_video_create" (void @-> returning (ptr t))
  let destroy = foreign ~from "zbar_video_destroy" (ptr t @-> returning void)
  let _open = foreign ~from "zbar_video_open" (ptr t @-> string @-> returning int)
  let _get_fd = foreign ~from "zbar_video_get_fd" (ptr t @-> returning int)
  let _request_size = foreign ~from "zbar_video_request_size" (ptr t @-> uint @-> uint @-> returning int)
  let _request_interface = foreign ~from "zbar_video_request_interface" (ptr t @-> int @-> returning int)
  let _request_iomode = foreign ~from "zbar_video_request_iomode" (ptr t @-> int @-> returning int)
  let _get_width = foreign ~from "zbar_video_get_width" (ptr t @-> returning int)
  let _get_height = foreign ~from "zbar_video_get_height" (ptr t @-> returning int)
  let _init = foreign ~from "zbar_video_init" (ptr t @-> ulong @-> returning int)
  let _enable = foreign ~from "zbar_video_enable" (ptr t @-> int @-> returning int)
  let next_image = foreign ~from "zbar_video_next_image" (ptr t @-> returning (ptr_opt Image.t))
  let error_string = foreign ~from "_zbar_error_string" (ptr t @-> int @-> returning string)

  let opendev ?(dev="/dev/video0") () =
    let h = create () in
    wrap_int
      (fun () -> _open h dev)
      (fun i -> i_int i; h)
      (fun () -> error_string h !verb)

  let closedev = destroy

  let get_fd h : Unix.file_descr = wrap_int
      (fun () -> _get_fd h)
      Obj.magic
      (fun () -> error_string h !verb)

  let request_size h width height =
    let open Unsigned.UInt in
    let width = of_int width in
    let height = of_int height in
    wrap_int
      (fun () -> _request_size h width height)
      i_int
      (fun () -> error_string h !verb)

  let request_interface h version = wrap_int
      (fun () -> _request_interface h version)
      i_int
      (fun () -> error_string h !verb)

  let request_iomode h mode = wrap_int
      (fun () -> _request_iomode h mode)
      i_int
      (fun () -> error_string h !verb)

  let enable h = wrap_int
      (fun () -> _enable h 1)
      i_int
      (fun () -> error_string h !verb)

  let disable h = wrap_int
    (fun () -> _enable h 0)
    i_int
    (fun () -> error_string h !verb)
end
