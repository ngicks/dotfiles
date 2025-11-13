c_bin=$HOME/.local/containers/bin:$PATH
c_lib=$HOME/.local/containers/lib/podman:$PATH

case ":${PATH}:" in
    *:"c_bin":*)
        ;;
    *)
        export PATH="c_bin:$PATH"
        ;;
esac


case ":${PATH}:" in
    *:"c_lib":*)
        ;;
    *)
        export PATH="c_lib:$PATH"
        ;;
esac
