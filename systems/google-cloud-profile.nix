{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/virtualisation/google-compute-image.nix")];

  config = {
    virtualisation.vmVariant = {
      virtualisation.graphics = false;

      services.getty.autologinUser = "root";
      boot.consoleLogLevel = 7;
      boot.kernelParams = [
        "systemd.journald.forward_to_console=1"
        "systemd.log_level=info"
      ];
    };

    kittenModules.nixConfig.nixosFolder = null;

    # Bootloader.
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.enable = true;

    # boot.kernelParams = [ "systemd.mask=google-guest-agent.service" ];
    nix.settings.trusted-users = ["@google-sudoers"];
    services.nscd.enableNsncd = false;

    systemd.services.google-startup-scripts.serviceConfig.TimeoutStartSec = 90;
    systemd.services.google-shutdown-scripts.serviceConfig.TimeoutStartSec = 90;
    systemd.services.google-guest-agent.serviceConfig.TimeoutStartSec = 90;

    networking.interfaces.eth0.useDHCP = true;
    networking.useNetworkd = true;
    systemd.network.enable = true;

    virtualisation.googleComputeImage.efi = true;

    system.build.deployImageScript = config.system.build.googleDeployImage;
    system.build.googleDeployImage = let
      image = config.system.build.googleComputeImage;
      toplevelHash = builtins.head (
        lib.splitString "-" (
          builtins.baseNameOf (builtins.unsafeDiscardStringContext config.system.build.toplevel)
        )
      );
      toplevelVersion = (builtins.parseDrvName config.system.build.toplevel.name).version;
      imageName =
        lib.replaceStrings ["_" "."] ["-" "-"]
        "nixos-${toplevelHash}-${config.networking.hostName}";
    in
      pkgs.writeShellApplication {
        name = "deploy-${image.name}";
        # version = toplevelVersion;

        runtimeInputs = with pkgs; [google-cloud-sdk];
        text = let
          metadata =
            (lib.optional config.systemd.services."serial-getty@ttyS0".enable "serial-port-enable=true")
            ++ (lib.optional config.security.googleOsLogin.enable "enable-oslogin=TRUE");
        in ''
          metadata="${lib.concatStringsSep "," metadata}"
          now="$(date +%Y%m%d-%H%M%S)"

          GCP_PROJECT="kittenconnect"
          GCP_BUCKET="kitten-tmp-images"

          IMAGE_SOURCE="${config.system.build.googleComputeImage}/${config.image.filePath}"
          IMAGE_NAME="${imageName}"
          IMAGE_URI="gs://$GCP_BUCKET/$IMAGE_NAME.raw.tar.gz"

          pushImage() {
            gcloud storage cp "$IMAGE_SOURCE" "$IMAGE_URI"
          }

          createImage() {
            gcloud compute images create "$IMAGE_NAME" \
              --project="$GCP_PROJECT" \
              --storage-location europe-west9 \
              --guest-os-features=UEFI_COMPATIBLE \
              --source-uri="$IMAGE_URI"
          }

          createVM () {
            imageRef="projects/$GCP_PROJECT/global/images/$IMAGE_NAME"
            gcloud beta compute instances create "$1-$now" \
              --project="$GCP_PROJECT" \
              --zone=europe-west9-b \
              --description="Kitten VM $IMAGE_NAME - created at $now" \
              --machine-type=e2-micro \
              --network-interface=ipv6-network-tier=PREMIUM,network-tier=PREMIUM,stack-type=IPV4_IPV6,subnet=kitten-subnet \
              --metadata="$metadata" \
              --can-ip-forward \
              --no-restart-on-failure \
              --maintenance-policy=TERMINATE \
              --provisioning-model=SPOT \
              --instance-termination-action=STOP \
              --service-account=721518634971-compute@developer.gserviceaccount.com \
              --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
              --tags=http-server,https-server \
              --create-disk="auto-delete=yes,boot=yes,device-name=$1-$now,image=$imageRef,mode=rw,size=10,type=pd-standard" \
              --no-shielded-secure-boot \
              --shielded-vtpm \
              --shielded-integrity-monitoring \
              --labels=goog-ec-src=vm_add-gcloud \
              --reservation-affinity=none \
              --deletion-protection
          }

          set -x

          imageStatus() {
            gcloud compute images describe --project=kittenconnect "$IMAGE_NAME" --format='value(status)'
          }

          if ! gcloud compute images describe --project=kittenconnect "$IMAGE_NAME"; then
            if ! gcloud storage ls "$IMAGE_URI"; then
              pushImage || exit $?
            fi

            createImage || exit $?
          fi

          echo "Waiting for $IMAGE_NAME to be ready" >&2
          while :; do
            case $(imageStatus) in
              READY)
                break
                ;;
              PENDING)
                echo -n .
                sleep 1
                ;;
              *)
                echo "$STATUS"
                exit 1
            esac
          done

          createVM ${config.networking.hostName}
        '';
      };
  };
}
