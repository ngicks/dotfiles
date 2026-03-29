export MOON_HOME=$HOME/.local/share/moonbit

case ":${PATH}:" in
    *:"$MOON_HOME/bin":*)
        ;;
    *)
        export PATH="$MOON_HOME/bin:$PATH"
        ;;
esac

if [ ! -d "$MOON_HOME" ]; then
  mkdir -p "${MOON_HOME}"
fi
