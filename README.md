# pingh

_pingh_ checks the system for specific conditions, and reports back to an HTTP endpoint as a "heartbeat" mechanism. It is intended to be compatible with [Better Stack](https://betterstack.com/) and other services that support simple GET requests.

**Example usage (simple heartbeat):** pingh -m:2 "https://example.org"

**Example usage (running process check):** pingh -m:2 -p:java "https://example.org"

**Other flags:** _--help (-h)_, _--version (-v)_

## Changelog

- 2025.03.21.1 -> Initial Release
- 2025.03.22.1 -> Added test for running process

## TODO

- Example systemd script for Linux use.
