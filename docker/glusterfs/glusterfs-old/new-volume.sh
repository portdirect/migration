#!/bin/sh
set -e

BRICK_NAME=${BRICK_NAME-''}
VOL_NAME=${VOL_NAME-${BRICK_NAME}}
HOSTS=""
CREATE_OPTIONS="redundancy=1"
VOL_OPTIONS="nfs.disable=yes"

start_volume=0

create_vol() {
    bricks=""
    create_opts=${${CREATE_OPTIONS//,/ }//=/ }
    for host in $HOSTS; do
        bricks="$bricks $host:/bricks/$BRICK_NAME/b"
    done

    echo "creating volume $VOL_NAME with opts $opts and bricks $bricks"
    eval gluster volume create $VOL_NAME $opts $bricks

    echo "setting volume $VOL_NAME options $VOL_OPTIONS"
    for opt in $VOL_OPTIONS; do
        eval gluster volume set $VOL_NAME ${opt/=/ }
    done
}

usage() {
    cat <<EOF
$0 [-b BRICK_NAME] [-s] [-c key=value,key=value] [-o key=value,key=value] \
   [-n VOL_NAME] host1 [host2 ...]
where
 * BRICK_NAME is the name of the brick to add to the volume on each host,
 * VOL_NAME is the name of the volume to create, defaults to BRICK_NAME,
 * -s specifies to start the volume, defaults, not to start,
 * -c options to set when creating volume, defaults to "redundancy=1",
 * -o options to set with 'gluster volume set', defaults to "nfs.disable=True".
BRICK_NAME and VOL_NAME can be specified by environment variables.
EOF
}

main() {
    while getopts "n:b:c:s" flag
    do
        case "$flag" in
        n)
            if [ -z ${OPTARG} ]; then
                err "Missing argument VOL_NAME for -v"
                exit 1
            fi
            VOL_NAME=$OPTARG
            ;;
        c)
            if [ -z ${OPTARG} ]; then
                err "Missing argument CREATE_OPTIONS for -c"
                exit 1
            fi
            CREATE_OPTIONS=$OPTARG
            ;;
        o)
            if [ -z ${OPTARG} ]; then
                err "Missing argument VOL_OPTIONS for -o"
                exit 1
            fi
            VOL_OPTIONS=$OPTARG
            ;;
        b)
            if [ -z ${OPTARG} ]; then
                err "Missing argument BRICK_NAME for -s"
                exit 1
            fi
            BRICK_NAME=$OPTARG
            ;;
        s)
            start_volume=1
            ;;
        *)
            err "invalid option: $flag"
            usage
            exit 1
        esac
    done
    shift $(( OPTIND - 1 ));

    if [ $# -eq 0 ] ; then
        err "Missing arguments: host"
        exit 1
    fi
    HOSTS=$*

    create_vol
}

main
