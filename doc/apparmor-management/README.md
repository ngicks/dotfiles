# AppArmor management

Host-specific AppArmor profiles live here. Install them into
`/etc/apparmor.d/`; AppArmor does not load profiles directly from this
repository.

## Nix-managed skopeo

Ubuntu restricts unprivileged user namespaces by default. `skopeo` needs a
user namespace for some container-image operations, but a Nix installation
resolves to a versioned `/nix/store` path and is not covered by Ubuntu's
distribution profiles.

The [`nix-skopeo`](./nix-skopeo) profile matches the versioned Nix store path,
leaves `skopeo` otherwise unconfined, and grants only the AppArmor `userns`
permission needed to opt it out of that restriction.

Install or update the profile and load it:

```sh
sudo install -m 0644 doc/apparmor-management/nix-skopeo \
  /etc/apparmor.d/nix-skopeo
sudo apparmor_parser -r /etc/apparmor.d/nix-skopeo
```

Confirm that the resolved executable is covered by the attachment pattern:

```sh
readlink -f "$(command -v skopeo)"
```

The result must have the form
`/nix/store/<hash>-skopeo-<version>/bin/skopeo`. If Nix changes that package
name or layout, update the attachment pattern before loading the profile.

This is an allowance profile, not a confinement policy: `default_allow`
preserves normal `skopeo` behavior while the explicit `userns` rule permits
user-namespace creation. Do not disable
`kernel.apparmor_restrict_unprivileged_userns` system-wide for this use case.
