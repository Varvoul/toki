#!/bin/bash
set -eo pipefail

status=0
if [[ $# -eq 0 ]] ; then
  php /app/docker-entrypoint.php 2>/app/startup_err.log || true
  status=$?
else
  php /app/docker-entrypoint.php "$@" 2>/app/startup_err.log || true
  status=$?
fi

[[ $status -ne 0 ]] && cat /app/startup_err.log && exit $status

exec rr serve -c .rr.yaml 2>/app/rr_err.log &
RR_PID=$!

sleep 5
if ! kill -0 $RR_PID 2>/dev/null; then
  echo "RR_DIED" > /app/startup_err.log
  cat /app/rr_err.log >> /app/startup_err.log 2>/dev/null
  exit 1
fi

wait $RR_PID