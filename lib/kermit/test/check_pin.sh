#!/bin/bash

expect_failure=${PIN_FAILURE:-false}

#sleep 1
case ${expect_failure} in
  'true')
    cat resp/check_pin_waiting
    ;;
  'false')
    cat resp/check_pin_ok
    ;;
  *)
    echo "ERROR"
    exit 1
    ;;
esac
#sleep 5
exit 0
