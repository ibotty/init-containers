# Init Containers

This repository includes various init containers.
These are containers that run before the (potentially long-running) main container starts up.
They set up config dirs, populate shared state from backups, etc.

## git-configdir

This container will check out a git directory and optionally `envsubst` configuration files.
