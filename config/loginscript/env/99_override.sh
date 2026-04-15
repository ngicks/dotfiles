case ":${PATH}:" in
    *:"$HOME/.local/bin/override":*)
        ;;
    *)
        export PATH="$HOME/.local/bin/override:$PATH"
        ;;
esac
