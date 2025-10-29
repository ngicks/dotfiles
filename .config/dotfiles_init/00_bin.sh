#!/bin/bash

case ":${PATH}:" in
    *:"$HOME/bin":*)
        ;;
    *)
        export PATH="$HOME/bin:$PATH"
        ;;
esac

case ":${PATH}:" in
    *:"$HOME/.local/bin":*)
        ;;
    *)
        # Prepending path in case a system-installed binary needs to be overridden
        export PATH="$HOME/.local/bin:$PATH"
        ;;
esac
