module Image : sig
  type t
  val destroy : t -> unit
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
