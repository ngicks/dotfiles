# FHS binary compatibility: Set library paths for mounted binaries
# Only needed if binaries require libraries not in their RPATH
if [[ "${IN_CONTAINER:-}" == "1" ]]; then
    NIX_PROFILE_LIB="$HOME/.nix-profile/lib"
    if [[ -d "$NIX_PROFILE_LIB" ]]; then
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$NIX_PROFILE_LIB"
    fi
fi
