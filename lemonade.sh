#!/bin/bash

if [ "$1" = "bash" ] || [ "$1" = "/bin/bash" ]; then
    exec "$@"
fi
if [ $# -eq 0 ]; then
    exec /usr/bin/lemond --host :: --port 13305
fi

exec "$@"
