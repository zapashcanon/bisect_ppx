module Bisect_visit___object___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160u@" in
      let `Staged cb =
        Bisect.Runtime.register_file "object.ml" ~point_count:1
          ~point_definitions in
      cb
  end
open Bisect_visit___object___ml
let _ = object method foo = ___bisect_visit___ 0; () end
