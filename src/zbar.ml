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

let i_int (i:int) = ignore i

let wrap_int f success error =
  match f () with
  | -1 -> failwith (error ())
  | oth -> success oth

let verb = ref 0
external set_verbosity :
  int -> unit = "stub_set_verbosity" [@@noalloc]
external increase_verbosity :
  unit -> unit = "stub_increase_verbosity" [@@noalloc]

let set_verbosity v =
  verb := v;
  set_verbosity v

let increase_verbosity () =
  incr verb;
  increase_verbosity ()

module Symbol = struct
  type symbology =
    | None
    | Partial
    | Ean2
    | Ean5
    | Ean8
    | Upce
    | Isbn10
    | Upca
    | Ean13
    | Composite
    | I25
    | Databar
    | Databar_exp
    | Codabar
    | Code39
    | Pdf417
    | Qrcode
    | Code93
    | Code128

  let int_of_symbology = function
    | None -> 0
    | Partial -> 1
    | Ean2 -> 2
    | Ean5 -> 5
    | Ean8 -> 8
    | Upce -> 9
    | Isbn10 -> 10
    | Upca -> 12
    | Ean13 -> 13
    | Composite -> 14
    | I25 -> 15
    | Databar -> 25
    | Databar_exp -> 34
    | Codabar -> 35
    | Code39 -> 39
    | Pdf417 -> 57
    | Qrcode -> 64
    | Code93 -> 93
    | Code128 -> 128

  let symbology_of_int = function
    | 0   -> Some None
    | 1   -> Some Partial
    | 2   -> Some Ean2
    | 3   -> Some Ean5
    | 8   -> Some Ean8
    | 9   -> Some Upce
    | 10  -> Some Isbn10
    | 12  -> Some Upca
    | 13  -> Some Ean13
    | 14  -> Some Composite
    | 15  -> Some I25
    | 25  -> Some Databar
    | 34  -> Some Databar_exp
    | 39  -> Some Code39
    | 57  -> Some Pdf417
    | 64  -> Some Qrcode
    | 93  -> Some Code93
    | 128 -> Some Code128
    | _   -> None

  type t

  external next : t -> t option = "stub_symbol_next"
  external get_type : t -> int = "stub_symbol_get_type" [@@noalloc]
  external get_data : t -> string = "stub_symbol_get_data"

  let get_type h =
    symbology_of_int (get_type h)
end

module SymbolSet = struct
  type t

  external first_symbol : t -> Symbol.t option = "stub_symbol_set_first_symbol"

  let to_list h =
    let rec inner acc = function
      | Some s -> inner (s::acc) (Symbol.next s)
      | None -> acc
    in
    List.rev (inner [] (first_symbol h))
end

module Image = struct
  type t

  external convert : t -> string -> t option = "stub_image_convert"

  let convert i fmt =
    if String.length fmt <> 4 then
      invalid_arg "Image.convert: format should be a string of length 4" ;
    convert i fmt
end

module ImageScanner = struct
  type t

  type config =
    | Enable
    | Add_check
    | Emit_check
    | Ascii
    | Num
    | Min_len
    | Max_len
    | Uncertainty
    | Position
    | X_density
    | Y_density

  let int_of_config = function
    | Enable -> 0
    | Add_check -> 1
    | Emit_check -> 2
    | Ascii -> 3
    | Num -> 4
    | Min_len -> 0x20
    | Max_len -> 0x21
    | Uncertainty -> 0x40
    | Position -> 0x80
    | X_density -> 0x100
    | Y_density -> 0x101

  external create : unit -> t = "stub_image_scanner_create"
  external set_config : t -> int -> int -> int -> int =
    "stub_image_scanner_set_config" [@@noalloc]

  let set_config h symbology config value = wrap_int
      (fun () ->
         set_config h (Symbol.int_of_symbology symbology)
           (int_of_config config) value)
      i_int
      (fun () -> "ImageScanner.set_config")

  external scan_image : t -> Image.t -> int =
    "stub_scan_image" [@@noalloc]

  external get_results : t -> SymbolSet.t = "stub_image_scanner_get_results"
  external enable_cache : t -> bool -> unit = "stub_image_scanner_enable_cache"

  let disable_cache h = enable_cache h false
  let enable_cache h = enable_cache h true

  let scan_image h i =
    let res = scan_image h i in
    match res with
    | 0 -> []
    | n when n < 0 -> raise (Failure (Printf.sprintf "ImageScanner.scan_image returns code %d" n))
    | _ -> SymbolSet.to_list (get_results h)
end

module Video = struct
  type t

  external create : unit -> t = "stub_video_create"
  external opendev :
    t -> string -> int = "stub_video_open" [@@noalloc]
  external get_fd :
    t -> Unix.file_descr option = "stub_video_get_fd"
  external request_size :
    t -> int -> int -> int = "stub_video_request_size" [@@noalloc]
  external request_interface :
    t -> int -> int = "stub_video_request_interface" [@@noalloc]
  external request_iomode :
    t -> int -> int = "stub_video_request_iomode" [@@noalloc]
  external get_width :
    t -> int = "stub_video_get_width" [@@noalloc]
  external get_height :
    t -> int = "stub_video_get_height" [@@noalloc]
  (* external init : t -> int -> int = "stub_video_init" [@@noalloc] *)
  external enable : t -> bool -> int = "stub_video_enable" [@@noalloc]

  external next_image : t -> Image.t option = "stub_video_next_image"
  external error_string : t -> int -> string = "stub_video_error_string"

  let opendev ?size ?interface ?iomode dev =
    let t = create () in
    wrap_int (fun () -> opendev t dev)
      (fun _ ->
        (match size with
         | None -> ()
         | Some (w, h) -> ignore (request_size t w h)) ;
        (match interface with
         | None -> ()
         | Some v -> ignore (request_interface t v)) ;
        (match iomode with
         | None -> ()
         | Some v -> ignore (request_iomode t v)) ;
        t)
      (fun () -> error_string t !verb)

  let get_fd h =
    match get_fd h with
    | Some fd -> Ok fd
    | None -> Error (error_string h !verb)

  let disable h = wrap_int
      (fun () -> enable h false)
      i_int
      (fun () -> error_string h !verb)

  let enable h = wrap_int
      (fun () -> enable h true)
      i_int
      (fun () -> error_string h !verb)
end
