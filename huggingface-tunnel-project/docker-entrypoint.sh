#!/bin/sh
# This wrapper script runs as root.

set -e

# 1. Generate SSH host keys
/usr/bin/ssh-keygen -A

# 2. Switch to the "user" and execute the main entrypoint script.
# su-exec is a lightweight sudo/gosu alternative common in Alpine.
exec su-exec user /entrypoint.sh
