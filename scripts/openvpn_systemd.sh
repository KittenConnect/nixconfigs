
set -eu -o pipefail


conf=$1
svc="openvpn-$conf"

_service_infos() {
    systemctl status $svc -l --no-pager

    iface="$(cut -c-15 <<< ${conf})"

    for v in 4 6; do
    echo "# IPv$v"
    ip -$v -color address show $iface
    
    echo "# Routes v$v"
    ip -$v -color route show dev $iface
    done
}

_service_status() {
    systemctl show $svc -p StatusText | cut -d= -f2-
}

if [[ "${2:-start}" == "--stop" ]]; then
    ACTION=stop
    if ! systemctl is-active $svc -q; then
    code=$?
    echo "OpenVPN $conf already stopped"
    exit $code
    fi
else
    ACTION=start
    if systemctl is-active $svc -q; then
        svcstatus="$(_service_status)"
        if [[ "$svcstatus" == "Initialization Sequence Completed" ]]; then
            echo "OpenVPN $conf already running"
            _service_infos
            exit 0
        else
            echo "OpenVPN service is running in a strange state: $svcstatus, restarting"
            sudo systemctl stop $svc
        fi
    fi
fi

sudo systemctl $ACTION $svc

if [[ "$ACTION" == "start" ]]; then
    echo "Waiting for OpenVPN $conf to start"
    while [[ $(_service_status) != "Initialization Sequence Completed" ]]; do 
    if [[ $(systemd-tty-ask-password-agent --list | wc -l) -eq 1 ]]; then
        sudo systemd-tty-ask-password-agent --query
    else
        echo -n .
        sleep 1
    fi
    done

    _service_infos
else
    systemctl status $svc -l --no-pager
fi
