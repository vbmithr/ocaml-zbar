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

let (|>) x f = f x
