let int_to_protocol = function
  | 1  -> Some `ICMP
  | 6  -> Some `TCP
  | 17 -> Some `UDP
  | _  -> None

type t = {
  src     : Ipaddr.V4.t;
  dst     : Ipaddr.V4.t;
  proto   : Cstruct.uint8;
  options : Cstruct.t option;
  payload : Cstruct.t option;
}

let parse_ipv4_header buf =
  let open Rresult in
  let open Ipv4_wire in
  let length_of_hlen_version n = (n land 0x0f) * 4 in
  let get_header_length buf =
    try
      Result.Ok (get_ipv4_hlen_version buf |> length_of_hlen_version)
    with
    | Invalid_argument s -> Result.Error s
  in
  let check_header_len buf options_end =
    if options_end < 20 then Result.Error "IPv4 header claimed to have size < 20"
    else Result.Ok (options_end - sizeof_ipv4)
  in
  let parse buf options_len =
    try
      let src = Ipaddr.V4.of_int32 (get_ipv4_src buf) in
      let dst = Ipaddr.V4.of_int32 (get_ipv4_dst buf) in
      let proto = get_ipv4_proto buf in
      let options =
        if options_len > 0 then Some (Cstruct.sub buf sizeof_ipv4 options_len)
        else None
      in
      let payload_len = (get_ipv4_len buf) - sizeof_ipv4 - options_len in
      if payload_len = 0 then
        Ok {src; dst; proto; options; payload=None }
      else begin
        let payload = Some (Cstruct.sub buf (sizeof_ipv4 + options_len) payload_len) in
        Ok {src; dst; proto; options; payload}
      end
    with
    | Invalid_argument s -> Result.Error s
  in
  get_header_length buf >>= check_header_len buf >>= parse buf