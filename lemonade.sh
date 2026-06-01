#!/bin/bash
exec /usr/bin/lemond
exec strace -tt -s1024 -f /usr/bin/lemond
