{ lib, pkgs, peer, ... }:
let
  inherit (lib) optionalString;
  inherit (builtins) concatStringsSep toJSON;

  withType = types: x: lib.toFunction types.${builtins.typeOf x} x;
in with peer; ''


  ${optionalString (bgpMED != null)
  "define bgpMED_${toString peerName} = ${toString bgpMED};"}
  ${optionalString (template == "kittunderlay") ''


    filter filter4_IN_BGP_${toString peerName} {
      if is_valid4_network() then {
        if defined( bgp_med ) then
          bgp_med = bgp_med + bgpMED_${toString peerName};
        else {
          bgp_med = bgpMED_${toString peerName};
        }
        accept;
      } else reject;
    }

    filter filter6_IN_BGP_${toString peerName} {
      if is_valid6_network() then {
        if defined( bgp_med ) then
          bgp_med = bgp_med + bgpMED_${toString peerName};
        else {
          bgp_med = bgpMED_${toString peerName};
        }
        accept;
      } else reject;
    }
  ''}

  # L: AS${toString localAS} | R: AS${toString peerAS}
  protocol bgp ${toString peerName} ${
    optionalString (template != "") "from ${toString template}"
  } {
    local ${optionalString (localIP != "") (toString localIP)} as ${
      toString localAS
    }; # localIP: "${toString localIP}"
    neighbor ${toString peerIP} as ${toString peerAS};
    ${optionalString (interface != null) ''interface "${interface}";''}
    ${
      if multihop == 0 then
        "direct;"
      else
        "multihop ${
          optionalString (multihop != -1) toString
          (if multihop < -1 then -1 * multihop else multihop)
        };"
    } # multihop: ${toString multihop}

    ${
      optionalString (password != "") ''

        password "${
          assert lib.asserts.assertMsg (passwordRef == "")
            "U defined a passwordRef, why do you still want to leak password ?";
          toString (lib.warn
            "bird2 peers password is insecure consider using passwordRef with a bird_secrets file"
            password)
        }"; # Not-Secured cleartext access for @everyone''
    }
    ${
      optionalString (passwordRef != "") "password secretPassword_${
        toString passwordRef
      }; # Defined in secrets file"
    }

    ${
      optionalString (ipv6 != { }) ''


        ipv6 {
          ${
            optionalString
            (ipv6 ? imports && ipv6.imports != "" && ipv6.imports != [ ]) (let
              myType = withType {
                string = x: "  import ${x};";
                null = x: "  import none;";
                lambda = f: myType (f peerName);
                list = x: ''


                  # ${toJSON x}
                      import filter {
                        if ( net ~ [ ${concatStringsSep ", " x} ] ) then {
                          accept;
                        }
                        reject;
                      };
                '';
              };
            in myType ipv6.imports)
          }
          ${
            optionalString
            (ipv6 ? exports && ipv6.exports != "" && ipv6.exports != [ ]) (let
              myType = withType {
                string = x: "  export ${x};";
                null = x: "  export none;";
                lambda = f: myType (f peerName);
                list = x: ''


                  # ${toJSON x}
                      export filter {
                        if ( net ~ [ ${concatStringsSep ", " x} ] ) then {
                          accept;
                        }
                        reject;
                      };
                '';
              };
            in myType ipv6.exports)
          }
          };
      ''
    }

  }
''
