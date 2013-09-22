open Zbar

let _ =
  let open Video in
  let dev = opendev () in
  let _ = ignore (get_fd dev) in
  closedev dev
