_c_bin=${HOME}/.local/containers/bin
_c_lib=${HOME}/.local/containers/lib/podman
_c_libexec=${HOME}/.local/containers/libexec/podman

case ":${PATH}:" in
    *:"$_c_bin":*)
        ;;
    *)
        export PATH="$_c_bin:$PATH"
        ;;
esac


case ":${PATH}:" in
    *:"$_c_lib":*)
        ;;
    *)
        export PATH="$_c_lib:$PATH"
        ;;
esac

case ":${PATH}:" in
    *:"$_c_libexec":*)
        ;;
    *)
        export PATH="$_c_libexec:$PATH"
        ;;
esac
