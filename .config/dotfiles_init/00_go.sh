# I'm not using ~/.cache/go since it is somehow populated
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export GOBIN="${XDG_DATA_HOME:-$HOME/.local/share}/go/bin" 
case ":${PATH}:" in
    *:"$GOBIN":*)
        ;;
    *)
        export PATH="$GOBIN:$PATH"
        ;;
esac
