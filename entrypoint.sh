#!/bin/bash
set -e

case "${HAPI_MODE}" in
  all)
    # Start server in background, runner in foreground
    hapi server &
    sleep 3
    exec hapi runner start-sync
    ;;
  server)
    exec hapi server
    ;;
  *)
    # Default: runner only
    exec hapi runner start-sync
    ;;
esac
