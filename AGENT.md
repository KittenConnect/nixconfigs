# kittenNix

NixOS-based machine configurations for KittenConnect network infrastructure.

## Tech Stack

- **NixOS** - Operating system
- **Colmena** - Fleet deployment
- **Bird2** - BGP routing
- **WireGuard** - VPN tunnels
- **SOPS + age** - Secrets management
- **Disko** - Disk partitioning

## Directory Structure

| Path | Description |
|------|-------------|
| `/systems/` | Machine configs (routers, clients, servers, stonkmembers) |
| `/modules/` | Reusable NixOS modules |
| `/modules/system/kitten/connect/` | KittenConnect modules (bird2, disko, wireguard, firewall) |
| `/lib/` | Custom library functions (network, peers) |
| `/ci/` | GitHub Actions, Colmena configs |
| `/.secrets/` | SOPS-encrypted secrets per host |
| `/npins/` | Dependency pins (nixpkgs, colmena) |

## Key Commands

```bash
nix develop                    # Enter dev shell
colmena deploy --on $HOST      # Deploy to host
```

## Validation

To verify all Nix files parse correctly:
```bash
find . -type f -name '*.nix' -exec nix-instantiate --parse {} \; >/dev/null
```

To verify machine evaluation:
```bash
nix eval --show-trace --json -f ./default.nix outputs.nixosConfigurations --apply 'input: map (x: builtins.attrNames input.${x}.config.system.build.toplevel) (builtins.attrNames input)'
```

## Secrets

Files in `/.secrets/*.yaml` are SOPS-encrypted. Use `sops` CLI to edit:
```bash
sops .secrets/hostname.yaml
```
Never commit decrypted secrets.

## Conventions

- Uses **default.nix** with `outputs` attribute for the entrypoint (NOT a flake)
- Uses **npins** (not flakes) for dependency management
- Never run `nix flake *` commands - this repo does NOT use flakes
- **Always use `kittenLib`** (not `lib.kitten`) to access custom library functions
- Secrets use per-host age keys (see `.sops.yaml`)
- Modules follow standard NixOS module conventions
- **Never use `mkEnableOption` or `mkEnabledOption`** - use explicit `mkOption` with `type` and `default`:
  ```nix
  enable = mkOption {
    type = types.bool;
    default = true;  # or false - always explicit
    description = "description";
  };
  ```

## Guidelines for Agents

- **Append all new conventions to this file** - Any patterns, refactorings, or guidelines discovered during tasks should be documented here for future reference.
