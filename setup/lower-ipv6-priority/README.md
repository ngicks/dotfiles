# Lower IPv6 address priority

Use this on Linux hosts where DNS returns IPv6 addresses but the network has
no working IPv6 route. It keeps IPv6 enabled while making glibc prefer IPv4
when both address families are available.

Apply the resolver policy:

```sh
sudo ./apply.sh
```

The script idempotently adds this rule to `/etc/gai.conf`:

```text
precedence ::ffff:0:0/96  100
```

New processes use the policy immediately. Confirm that Python now lists IPv4
before IPv6:

```sh
python -c 'import socket; print([x[0].name for x in socket.getaddrinfo("huggingface.co", 443, type=socket.SOCK_STREAM)])'
```

`AF_INET` should appear before `AF_INET6`. This affects address selection for
glibc applications; it does not disable IPv6 or change DNS records.

To undo it, remove the added comment and `precedence` line from
`/etc/gai.conf`.
