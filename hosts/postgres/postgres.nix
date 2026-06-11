{ lib, ... }: {
  services.postgresql = { 
    enable = lib.mkDefault true;
    # ... conf ...

    ensureDatabases = [ "netbox" ];

    ensureUsers = [
      {
          name = "superkitten";
          ensureClauses = {
              # superuser = true;
              createrole = true;
              createdb = true;
              login = true;
          };
      }
      {
          name = "netbox";
          ensureDBOwnership = true;
          ensureClauses = {
              login = true;
          };
      }
    ];

    enableTCPIP = lib.mkDefault true;

#    settings = {
#      listen_addresses = "";
#    };
  };
}
