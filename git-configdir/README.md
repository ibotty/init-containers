# git-configdir

Check out a Git repository prior to starting a container.
Meant to be used as init container.

## USAGE

Configure `git-configdir` via environment variables.

 * `CONFIGDIR_GIT_URI`, the git url to check out,
 * `CONFIGDIR_CHECKOUTDIR`, the dir in which to check it out,
 * `CONFIGDIR_GIT_PRESERVE_DOT_GIT`, whether to keep the gitdir (optional, default no),
 * `CONFIGDIR_GIT_REF`, the reference to check out (optional, defaults to master), currently only implemented for branches
 * `CONFIGDIR_GIT_CONTEXTDIR`, the sub dir to check out (optional), not implemented yet


