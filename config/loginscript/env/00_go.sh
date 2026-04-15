# I'm not using ~/.cache/go since it is somehow populated
export_unless_container_override GOPATH "${XDG_DATA_HOME:-$HOME/.local/share}/go"
export_unless_container_override GOBIN "${XDG_DATA_HOME:-$HOME/.local/share}/go/bin"
case ":${PATH}:" in
    *:"$GOBIN":*)
        ;;
    *)
        export PATH="$GOBIN:$PATH"
        ;;
esac
