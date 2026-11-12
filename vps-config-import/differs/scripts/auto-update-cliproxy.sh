#!/bin/sh
# Compatibility entrypoint: the user service owns CAPI; never sync a source config.
exec /home/dev/.local/libexec/capi-update.py "$@"
