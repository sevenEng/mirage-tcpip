open Ethif_wire

type t = {
  source : Macaddr.t;
  destination : Macaddr.t;
  ethertype : Ethif_wire.ethertype;
  payload : Cstruct.t; (* bare ethernet frames not allowed *)
}

let parse_ethernet_header frame =
  if Cstruct.len frame >= sizeof_ethernet then
    match get_ethernet_ethertype frame |> int_to_ethertype with
    | None -> Result.Error "unknown ethertype in frame"
    | Some ethertype ->
      let payload = Cstruct.shift frame sizeof_ethernet
      and source = Macaddr.of_bytes_exn (copy_ethernet_src frame)
      and destination = Macaddr.of_bytes_exn (copy_ethernet_dst frame)
      in
      Result.Ok { destination; source; ethertype; payload }
  else
    Result.Error "frame too small to contain a valid ethernet header"