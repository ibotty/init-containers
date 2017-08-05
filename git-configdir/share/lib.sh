#!/bin/bash 

CONFIGDIR_ENVSUBST_EXTENSION="${CONFIGDIR_ENVSUBST_EXTENSION-tmpl}"
CONFIGDIR_GIT_REF="${CONFIGDIR_GIT_REF-master}"

# shellcheck source=share/log.sh
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/log.sh"

validate_config() {
    [ -n "$CONFIGDIR_GIT_URI" ] &&
    [ -n "$CONFIGDIR_CHECKOUTDIR" ]
}

checkout_repo() {
    local repo="$CONFIGDIR_GIT_URI"
    local branch="$CONFIGDIR_GIT_REF"

    log::info "cloning repo" \$CONFIGDIR_CHECKOUTDIR \$repo \$branch
    git clone --depth 1 "$repo" --branch "$branch" "$CONFIGDIR_CHECKOUTDIR"

    case "$CONFIGDIR_GIT_PRESERVE_DOT_GIT" in
        y*|t*)
            log::info "preserving GITDIR" \$repo
            ;;
        n*|f*)
            log::notice "deleting GITDIR" \$repo
            rm -r "$CONFIGDIR_CHECKOUTDIR/.git"
            ;;
        *)
            log::error "unknown value" \$CONFIGDIR_GIT_PRESERVE_DOT_GIT
            return 1
            ;;
    esac
}

envsubst_config() {
    case "$CONFIGDIR_ENVSUBST" in
        y*|t*)
            do_envsubst_config
            ;;
        n*|f*)
            log::info "not substituting files"
            ;;
        *)
            log::error "unknown value" \$CONFIGDIR_GIT_PRESERVE_DOT_GIT
            return 1
            ;;
    esac
}

do_envsubst_config() {
    local extension="${CONFIGDIR_ENVSUBST_EXTENSION}"
    local target_file

    log::info "substituting files" \$extension

    find "$CONFIGDIR_CHECKOUTDIR" -name '*.'"$extension" -print0 | \
        while IFS= read -rd '' file ; do
            target_file="$(dirname "$file")/$(basename "$file" ".$extension")"

            if [ -f "$target_file" ]; then
                log::warn "Not substituting file" \$file \$target_file \
                    reason="target_file already exists"
            else
                log::notice "substituting file" \$file \$target_file
                envsubst < "$file" > "$target_file"
            fi
        done
}

iterate_source_secrets() {
    local checkouthost
    for dir in $CONFIGDIR_SECRETDIR/*; do
        checkouthost=$(host_from_git_uri "$CONFIGDIR_GIT_URI")
        [ -f "$dir/host" ] && checkouthost="$(<"$dir/host")"
 
        ssh_config_from_source_secret "$dir" "$checkouthost"
        netrc_from_source_secret "$dir" "$checkouthost"
    done
}

netrc_from_source_secret() {
    local dir checkouthost username password
    dir="$1"
    checkouthost="$2"

    if [ -f "$dir/username" ] && [ -f "$dir/password" ]; then
        log::info "creating netrc stanza" "secretdir=$dir"
        username="$(<"$dir/username")"
        password="$(<"$dir/password")"
        echo
        echo "machine $checkouthost"
        echo "login $username"
        echo "password $password"
    fi >> ~/.netrc
}

ssh_config_from_source_secret() {
    local dir checkouthost keyfile
    dir="$1"
    checkouthost="$2"

    if [ -f "$dir/ssh-privatekey" ]; then
        log::info "creating ssh config stanza" "secretdir=$dir"
        keyfile="$dir/ssh-privatekey"
        echo "Host $checkouthost"
        echo "  IdentityFile $keyfile"

        if [ -f "$dir/username" ]; then
            username="$(<"$dir/username")"
            echo "  User $username"
        fi
    fi >> ~/.ssh/config
}

clean_environment() {
    rm -f ~/.netrc ~/.ssh/config
}
