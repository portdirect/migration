#!/bin/bash

MAINTAINER='MAINTAINER Pete Birley <petebirley@gmail.com>'
RES=0

for dockerfile in "$@"; do
    if ! grep -q "$MAINTAINER" "$dockerfile"; then
        echo "ERROR: $dockerfile has incorrect MAINTAINER" >&2
        RES=1
    fi
done

exit $RES
