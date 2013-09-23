val set_verbosity : int -> unit
val increase_verbosity : unit -> unit

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

module Symbol : sig
  type t
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

  val get_data : t -> string
  val get_type : t -> symbology
end

module Image : sig
  type t
  val destroy : t -> unit
  val convert : t -> string -> t
end

module ImageScanner : sig
  type t
  val create : unit -> t
  val destroy : t -> unit
  val set_config : t -> Symbol.symbology -> config -> int -> unit
  val enable_cache : t -> bool -> unit
  val scan_image : t -> Image.t -> Symbol.t Lwt_stream.t
end

module Video : sig
  type t
  val opendev : ?dev:string -> unit -> t
  val closedev : t -> unit
  val request_size : t -> int -> int -> unit
  val request_interface : t -> int -> unit
  val request_iomode : t -> int -> unit
  val stream : t -> Image.t Lwt_stream.t
  val disable : t -> unit
end
