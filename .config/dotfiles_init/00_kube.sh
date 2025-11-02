kube_config_loc=${XDG_CONFIG_HOME:-$HOME/.config}/kube/config
case ":${KUBECONFIG}:" in
    *:"${kube_config_loc}":*)
        ;;
    *)
        if [[ -z ${KUBECONFIG} ]]; then
            export KUBECONFIG="${kube_config_loc}"
        else
            export KUBECONFIG="${KUBECONFIG}:${kube_config_loc}"
        fi
        ;;
esac

