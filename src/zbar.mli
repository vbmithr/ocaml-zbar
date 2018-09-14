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

(** Binding to the ZBar library to decode QR-codes from images and videos. *)

val set_verbosity : int -> unit
(** [set_verbosity level] sets ZBar's verbosity level to [level]. *)

val increase_verbosity : unit -> unit
(** [increase_verbosity ()] increments ZBar's verbosity by one. *)

module Symbol : sig
  type t
  (** Type of a symbol structure ([zbar_symbol_t *]). *)

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
    (** Type of symbols recognized by ZBar. *)

  val get_data : t -> string
  (** [get_data s] is the string encoded in [s]. *)

  val get_type : t -> symbology option
  (** [get_type s] is the encoding used in [s]. *)
end

module Image : sig
  type t
  (** Type of a ZBar image ([zbar_image_t *]). *)

  val convert : t -> string -> t option
  (** [convert i fmt] converts [i] to the pixel format described by
      [fmt], using the fourcc notation ([http://www.fourcc.org]). Use
      "GREY" to obtain an image from which ZBar can decode symbols. *)
end

module ImageScanner : sig
  type t
  (** Type of an image scanner ([zbar_image_scanner_t *]). *)

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
    (** Type of the argument for the function [set_config]. *)

  val create : unit -> t

  val set_config : t -> Symbol.symbology -> config -> int -> unit
  (** Wrapper to [zbar_image_scanner_set_config]. Please consult
      ZBar documentation. *)

  val enable_cache : t -> unit
  (** [enable_cache s b] enables caching in [s] according to the value
      of [b]. When caching is enabled, more computing power is used,
      but the same symbols observed in subsequent frames are only
      returned once by [scan_image]. *)

  val disable_cache : t -> unit

  val scan_image : t -> Image.t -> Symbol.t list
  (** [scan_image s i] is the list of symbols found in [i]. *)
end

module Video : sig
  type t
  (** Type of a video device (encapsulate the C type [zbar_video_t *]). *)

  val opendev :
    ?size:int * int ->
    ?interface:int ->
    ?iomode:int ->
    string -> t
  (** [opendev dev] creates a video device reading its frames from
      [dev]. *)

  val get_width : t -> int
  val get_height : t -> int

  val get_fd : t -> (Unix.file_descr, string) result
  (** [get_fd t] is [t]'s underlying file descriptor. *)

  val next_image : t -> Image.t option
  (** [next_image t] retrieve next captured image from [t]. Blocks
     until an image is available. *)

  val enable : t -> unit
  val disable : t -> unit
  (** [disable d] stops the video capture on device structure [d]. *)
end
