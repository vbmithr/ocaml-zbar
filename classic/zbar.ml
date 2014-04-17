(*
 * Copyright (c) 2013 Vincent Bernardoff <vb@luminar.eu.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

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

let (>>=) = Lwt.(>>=)

let i_int (i:int) = ignore i

let wrap_int f success error =
  match f () with
  | -1 -> failwith (error ())
  | oth -> success oth

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

let verb = ref 0
external _set_verbosity : int -> unit = "stub_set_verbosity"
external _increase_verbosity : unit -> unit = "stub_increase_verbosity"

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

  type t

  external next : t -> t option = "stub_symbol_next"
  external _get_type : t -> int = "stub_symbol_get_type"
  external get_data : t -> string = "stub_symbol_get_data"

  let get_type h =
    symbology_of_int (_get_type h)
end

module SymbolSet = struct
  type t

  external length : t -> int = "stub_symbol_set_get_size"
  external first_symbol : t -> Symbol.t option = "stub_symbol_set_first_symbol"

  let to_stream h =
    let sym = ref (first_symbol h) in
    Lwt_stream.from_direct
      (fun () -> let cur = !sym in sym := Opt.(!sym >>= fun s -> Symbol.next s); cur)

  let to_list h =
    let rec inner acc = function
      | Some s -> inner (s::acc) (Symbol.next s)
      | None -> acc
    in
    List.rev (inner [] (first_symbol h))
end

module Image = struct
  type t

  external destroy : t -> unit = "stub_image_destroy"
  external get_symbols : t -> SymbolSet.t option = "stub_image_get_symbols"
  external first_symbol : t -> Symbol.t option = "stub_image_first_symbol"
  external _convert : t -> int32 -> t = "stub_image_convert"

  let convert i fmt =
    if String.length fmt <> 4 then
      raise (Invalid_argument "Image.convert: format should be a string of length 4")
    else
      let open Int32 in
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
  type t

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

  external create : unit -> t = "stub_image_scanner_create"
  external destroy : t -> unit = "stub_image_scanner_destroy"
  external _set_config : t -> int -> int -> int -> int = "stub_image_scanner_set_config"

  let set_config h symbology config value = wrap_int
      (fun () -> _set_config h Symbol.(int_of_symbology symbology) (int_of_config config) value)
      i_int
      (fun () -> "ImageScanner.set_config")

  external _scan_image : t -> Image.t -> int = "stub_scan_image"
  external _get_results : t -> SymbolSet.t = "stub_image_scanner_get_results"
  external _enable_cache : t -> int -> unit = "stub_image_scanner_enable_cache"

  let enable_cache h v = _enable_cache h (if v then 1 else 0)

  let scan_image h i =
    let res = _scan_image h i in
    Image.destroy i;
    match res with
    | 0 -> []
    | n when n < 0 -> raise (Failure (Printf.sprintf "ImageScanner.scan_image returns code %d" n))
    | n -> SymbolSet.to_list (_get_results h)
end

module Video = struct
  type t

  external create : unit -> t = "stub_video_create"
  external destroy : t -> unit = "stub_video_destroy"
  external _open : t -> string -> int = "stub_video_open"
  external _get_fd : t -> int = "stub_video_get_fd"
  external _request_size : t -> int -> int -> int = "stub_video_request_size"
  external _request_interface : t -> int -> int = "stub_video_request_interface"
  external _request_iomode : t -> int -> int = "stub_video_request_iomode"
  external _get_width : t -> int = "stub_video_get_width"
  external _get_height : t -> int = "stub_video_get_height"
  external _init : t -> int32 -> int = "stub_video_init"
  external _enable : t -> int -> int = "stub_video_enable"
  external next_image : t -> Image.t option = "stub_video_next_image"
  external error_string : t -> int -> string = "_stub_error_string"

  let open_ h dev =
    wrap_int
      (fun () -> _open h dev)
      (fun i -> i_int i)
      (fun () -> error_string h !verb)

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
