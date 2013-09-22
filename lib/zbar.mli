module Video : sig
  type t
  val opendev : ?dev:string -> unit -> t
  val closedev : t -> unit
  val get_fd : t -> Unix.file_descr
  val request_size : t -> int -> int -> unit
  val request_interface : t -> int -> unit
  val request_iomode : t -> int -> unit
  val enable : t -> unit
  val disable : t -> unit
end
