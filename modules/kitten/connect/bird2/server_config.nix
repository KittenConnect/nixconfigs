{ lib, ... }:
let inherit (lib) mkOrder mkMerge;
in {
  service.bird2.config = mkMerge [
    (mkOrder 25 ''

      # The Kernel protocol is not a real routing protocol. Instead of communicating
      # with other routers in the network, it performs synchronization of BIRD
      # routing tables with the OS kernel. One instance per table.
      protocol kernel KERNEL4 {
      	ipv4 {                  # Connect protocol to IPv4 table by channel
      #             table master4;    # Default IPv4 table is master4
      #             import all;       # Import to table, default is import all
      #             export all;       # Export to protocol. default is export none
      	      export filter {
      		  if  ( is_valid4_network() || source ~ [RTS_STATIC]
            ${
              let sep = "|| proto =";
              in optionalString (rrs != [ ]) sep
              + (concatMapStringsSep sep quoteString rrs)
            }
            ) then {
                ${
                  optionalString (lo4 != null) ''

                      if source ~ [RTS_BGP] || net ~ [ 0.0.0.0/0 ] then {
                    krt_prefsrc=${lo4};
                      }
                  ''
                }
      		     accept;
      		  } else reject;
      	      };
      	};
        merge paths on;
      #       learn;                  # Learn alien routes from the kernel
      #       kernel table 10;        # Kernel table to synchronize with (default: main)
      }

      # Another instance for IPv6, skipping default options
      protocol kernel KERNEL6 {
      #       ipv6 { export all; };
      	ipv6 {
      	     export filter {

             if  ( is_valid6_network() || source ~ [RTS_STATIC]
            ${
              let sep = "|| proto =";
              in optionalString (rrs != [ ]) sep
              + (concatMapStringsSep sep quoteString rrs)
            }
            ) then {
                         ${
                           optionalString (lo6 != null) ''

                                  if source ~ [RTS_BGP] || net ~ [ ::/0 ] then {
                             	 krt_prefsrc=${lo6};
                                  }
                           ''
                         }
      		       accept;
      		 } else reject;
      	     };
      	};

        merge paths on;
      }
    ''

    )
  ];
}
