#!/bin/bash

export XDG_RUNTIME_DIR=/lemonade-server/.cache/lemonade/

if [ "$1" = "bash" ] || [ "$1" = "/bin/bash" ]; then
    exec "$@"
fi
if [ $# -eq 0 ]; then
    exec /usr/bin/lemond --host :: --port 13305
fi

exec "$@"
