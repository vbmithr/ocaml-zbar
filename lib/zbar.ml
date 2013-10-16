#if ocaml_version < (4,1)
let (@@) f x = f x
let (|>) x f = f x
#endif

module Opt = struct
  type 'a t = 'a option

  let return x = Some x

  let (>>=) x f = match x with
    | Some x -> f x
    | None -> None

  let (>|=) x f = match x with
    | Some x -> Some (f x)
    | None -> None

  let run = function
    | Some x -> x
    | None -> failwith "Opt.run"

  let default d = function
    | Some x -> x
    | None -> d
end

let i_int (i:int) = ignore i

let wrap_int f success error =
  match f () with
  | -1 -> failwith (error ())
  | oth -> success oth

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


type orientation =
  [
    | `Unknown
    | `Up
    | `Right
    | `Down
    | `Left
  ]

type config =
  [
    | `Enable
    | `Add_check
    | `Emit_check
    | `Ascii
    | `Num
    | `Min_len
    | `Max_len
    | `Uncertainty
    | `Position
    | `X_density
    | `Y_density
  ]

let int_of_config = function
  | `Enable -> 0
  | `Add_check -> 1
  | `Emit_check -> 2
  | `Ascii -> 3
  | `Num -> 4
  | `Min_len -> 0x20
  | `Max_len -> 0x21
  | `Uncertainty -> 0x40
  | `Position -> 0x80
  | `X_density -> 0x100
  | `Y_density -> 0x101

let config_of_int = function
  | 0 -> `Enable
  | 1 -> `Add_check
  | 2 -> `Emit_check
  | 3 -> `Ascii
  | 4 -> `Num
  | 0x20 -> `Min_len
  | 0x21 -> `Max_len
  | 0x40 -> `Uncertainty
  | 0x80 -> `Postition
  | 0x100 -> `X_density
  | 0x101 -> `Y_density
  | _ -> raise (Invalid_argument "config_of_int")

let from = Dl.(dlopen ~filename:"libzbar.so" ~flags:[RTLD_LAZY])

let verb = ref 0
let _set_verbosity = foreign ~from "zbar_set_verbosity" (int @-> returning void)
let _increase_verbosity = foreign ~from "zbar_increase_verbosity" (void @-> returning void)

let set_verbosity v =
  verb := v;
  _set_verbosity v

let increase_verbosity () =
  incr verb;
  _increase_verbosity ()

module Symbol = struct
  type symbology =
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

  let int_of_symbology = function
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

  let symbology_of_int = function
    | 0 -> `None
    | 1 -> `Partial
    | 2 -> `Ean2
    | 3 -> `Ean5
    | 8 -> `Ean8
    | 9 -> `Upce
    | 10 -> `Isbn10
    | 12 -> `Upca
    | 13 -> `Ean13
    | 14 -> `Composite
    | 15 -> `I25
    | 25 -> `Databar
    | 34 -> `Databar_exp
    | 39 -> `Code39
    | 57 -> `Pdf417
    | 64 -> `Qrcode
    | 93 -> `Code93
    | 128 -> `Code128
    | _ -> raise (Invalid_argument "symbol_of_int")

  type _t
  let t : _t structure typ = structure "zbar_symbol_s"
  type t = _t structure ptr


  let next = foreign ~from "zbar_symbol_next" (ptr t @-> returning (ptr_opt t))
  let _get_type = foreign ~from "zbar_symbol_get_type" (ptr t @-> returning int)
  let get_data = foreign ~from "zbar_symbol_get_data" (ptr t @-> returning string)

  let get_type h =
    symbology_of_int (_get_type h)
end

module SymbolSet = struct
  type _t
  let t : _t structure typ = structure "zbar_symbol_set_s"
  type t = _t structure ptr

  let length = foreign ~from "zbar_symbol_set_get_size" (ptr t @-> returning int)
  let first_symbol = foreign ~from "zbar_symbol_set_first_symbol" (ptr t @-> returning (ptr_opt Symbol.t))

  let to_stream h =
    let sym = ref (first_symbol h) in
    Lwt_stream.from_direct
      (fun () -> let cur = !sym in sym := Opt.(!sym >>= fun s -> Symbol.next s); cur)
end

module Image = struct
  type _t
  let t : _t structure typ = structure "zbar_image_s"

  type t = _t structure ptr

  let destroy = foreign ~from "zbar_image_destroy" (ptr t @-> returning void)
  let get_symbols = foreign ~from "zbar_image_get_symbols" (ptr t @-> returning (ptr_opt SymbolSet.t))
  let first_symbol = foreign ~from "zbar_image_first_symbol" (ptr t @-> returning (ptr_opt Symbol.t))
  let _convert = foreign ~from "zbar_image_convert" (ptr t @-> uint32_t @-> returning (ptr t))

  let convert i fmt =
    if String.length fmt <> 4 then
      raise (Invalid_argument "Image.convert: format should be a string of length 4")
    else
      let open Unsigned.UInt32 in
      let a, b, c, d = Char.(code fmt.[0], code fmt.[1], code fmt.[2], code fmt.[3]) in
      let fmt = of_int a in
      let fmt = logor fmt (shift_left (of_int b) 8) in
      let fmt = logor fmt (shift_left (of_int c) 16) in
      let fmt = logor fmt (shift_left (of_int d) 24) in
      let converted = _convert i fmt in
      destroy i;
      converted
end

module ImageScanner = struct
  type _t
  let t : _t structure typ = structure "zbar_image_scanner_s"
  type t = _t structure ptr

  let create = foreign ~from "zbar_image_scanner_create" (void @-> returning (ptr t))
  let destroy = foreign ~from "zbar_image_scanner_destroy" (ptr t @-> returning void)
  let _set_config = foreign ~from "zbar_image_scanner_set_config" (ptr t @-> int @-> int @-> int @-> returning int)

  let set_config h symbology config value = wrap_int
      (fun () -> _set_config h Symbol.(int_of_symbology symbology) (int_of_config config) value)
      i_int
      (fun () -> "ImageScanner.set_config")

  let _scan_image = foreign ~from "zbar_scan_image" (ptr t @-> ptr Image.t @-> returning int)
  let _get_results = foreign ~from "zbar_image_scanner_get_results" (ptr t @-> returning (ptr SymbolSet.t))
  let _enable_cache = foreign ~from "zbar_image_scanner_enable_cache" (ptr t @-> int @-> returning void)

  let enable_cache h v = _enable_cache h (if v then 1 else 0)

  let scan_image h i =
    let res = _scan_image h i in
    Image.destroy i;
    match res with
    | 0 -> Lwt_stream.from_direct (fun () -> None)
    | n when n < 0 -> failwith (Printf.sprintf "ImageScanner.scan_image returns code %d" n)
    | n -> SymbolSet.to_stream (_get_results h)
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

  let stream h =
    enable h;
    Lwt_stream.from (fun () ->
        Lwt_unix.(wrap_syscall
                    Read
                    (of_unix_file_descr (get_fd h))
                    (fun () -> next_image h)))

end
