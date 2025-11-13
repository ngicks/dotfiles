_kube_config_loc=${XDG_CONFIG_HOME:-$HOME/.config}/kube/config
case ":${KUBECONFIG}:" in
    *:"${_kube_config_loc}":*)
        ;;
    *)
        if [[ -z ${KUBECONFIG} ]]; then
            export KUBECONFIG="${_kube_config_loc}"
        else
            export KUBECONFIG="${KUBECONFIG}:${_kube_config_loc}"
        fi
        ;;
esac

