# pingh

_pingh_ checks the system for specific conditions, and reports back to an HTTP endpoint as a "heartbeat" mechanism. It is intended to be compatible with [Better Stack](https://betterstack.com/) and other services that support simple GET requests.

## Examples
 
- Simple heartbeat: **pingh -m:2 "https://example.org"**
- Running process check: **pingh -m:2 -p:java "https://example.org"**
- Open TCP port check on localhost (works dual-stack): **pingh -m:2 -t:8080 "https://example.org"**
- Open TCP port check on another host (slower, works dual-stack): **pingh -m:2 -s:"example.com" -t:443 "https://example.org"**

**Other flags:** _--debug (-d)_, _--help (-h)_, _--version (-v)_

## Running on Linux

1. Edit the pingh.service file to the settings you wish to use.
2. Copy the provided pingh.service file to **/etc/systemd/system/**
3. **systemctl enable pingh.service && systemctl start pingh.service**

## Running on Windows

- Task Scheduler can work, but may not be stable. Modify the included XML file, and import to Task Scheduler to try this.
- You may have better luck using [nssm](https://nssm.cc/); on a Windows 11 host, it can be installed via winget. "nssm install" -> provide it a name (ex: PINGH), the location of the EXE, the parameters, and a friendly service name (ex: Pingh Heartbeat Monitor). Then start it from the Services window.

## Changelog

- 2025.06.02.2 -> Used Claude Sonnet 4 to validate code & rebuild check logic; added a "debug" option & made the output less verbose by default; ping URL check now has a 10 second timeout.
- 2025.03.22.2 -> Added test for open TCP socket & minor fixes.
- 2025.03.22.1 -> Added test for running process.
- 2025.03.21.1 -> Initial Release
