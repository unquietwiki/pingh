# pingh

_pingh_ checks the system for specific conditions, and reports back to an HTTP endpoint as a "heartbeat" mechanism. It is intended to be compatible with [Better Stack](https://betterstack.com/) and other services that support simple GET requests.

## Examples
 
- Simple heartbeat: **pingh -m:2 "https://example.org"**
- Running process check: **pingh -m:2 -p:java "https://example.org"**
- Open TCP port check on localhost (works dual-stack): **pingh -m:2 -t:8080 "https://example.org"**
- Open TCP port check on another host (slower, works dual-stack): **pingh -m:2 -s:"example.com" -t:443 "https://example.org"**

**Other flags:** _--help (-h)_, _--version (-v)_

## Changelog

- 2025.03.21.1 -> Initial Release
- 2025.03.22.1 -> Added test for running process
- 2025.03.22.2 -> Added test for open TCP socket & minor fixes

## TODO

- Example systemd script for Linux use.
