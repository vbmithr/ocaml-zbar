(** Binding to the ZBar library to decode QR-codes from images and videos. *)

val set_verbosity : int -> unit
(** [set_verbosity level] sets ZBar's verbosity level to [level]. *)

val increase_verbosity : unit -> unit
(** [increase_verbosity ()] increments ZBar's verbosity by one. *)

module Symbol : sig
  type t
  (** Type of a symbol structure ([zbar_symbol_t *]). *)

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
  (** Type of symbols recognized by ZBar. *)

  val get_data : t -> string
  (** [get_data s] is the string encoded in [s]. *)

  val get_type : t -> symbology
  (** [get_type s] is the encoding used in [s]. *)
end

module Image : sig
  type t
  (** Type of a ZBar image ([zbar_image_t *]). *)

  val destroy : t -> unit
  (** [destroy i] frees the memory used by [i]. *)

  val convert : t -> string -> t
  (** [convert i fmt] converts [i] to the pixel format described by
      [fmt], using the fourcc notation ([http://www.fourcc.org]). Use
      "GREY" to obtain an image from which ZBar can decode symbols. *)
end

module ImageScanner : sig
  type t
  (** Type of an image scanner ([zbar_image_scanner_t *]). *)

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
  (** Type of the argument for the function [set_config]. *)

  val create : unit -> t
  val destroy : t -> unit

  val set_config : t -> Symbol.symbology -> config -> int -> unit
  (** Wrapper to [zbar_image_scanner_set_config]. Please consult
      ZBar documentation. *)

  val enable_cache : t -> bool -> unit
  (** [enable_cache s b] enables caching in [s] according to the value
      of [b]. When caching is enabled, more computing power is used,
      but the same symbols observed in subsequent frames are only
      returned once by [scan_image]. *)

  val scan_image : t -> Image.t -> Symbol.t list
  (** [scan_image s i] is the list of symbols found in [i]. *)
end

module Video : sig
  type t
  (** Type of a video device (encapsulate the C type [zbar_video_t *]). *)

  (** {2 Initialisation} *)

  (** {3 Low level interface} *)

  val create : unit -> t
  (** Create the video device structure. *)

  val request_size : t -> int -> int -> unit
  (** Request a preferred size for the video image from the
      device. Must be called before [open_]. *)

  val request_interface : t -> int -> unit
  (** Request a preferred driver interface version for
      debug/testing. Must be called before [open_]. *)

  val request_iomode : t -> int -> unit
  (** Request a preferred I/O mode for debug/testing. Must be called
      before [open_]. *)

  val open_ : t -> string -> unit
  (** [open_ h dev] opens the video device [dev]. *)

  (** {3 High level interface} *)

  val opendev : ?dev:string -> unit -> t
  (** [opendev ~dev ()] creates a video device reading its frames from
      [~dev] (default [/dev/video0]) and opens it with the default
      settings. It is equivalent to call [create], then [open_]. *)

  (** {2 Using the video device} *)

  val closedev : t -> unit

  val stream : t -> Image.t Lwt_stream.t
  (** [stream d] starts the video capture and returns the stream of
      images from the video device structure [d]. *)

  val disable : t -> unit
  (** [disable d] stops the video capture on device structure [d]. *)
end
