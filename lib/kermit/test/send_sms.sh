#!/bin/bash

expect_failure='false'

#sleep 1
case ${expect_failure} in
  'false')
    echo "OK"
    ;;
  *)
    echo "ERROR"
    exit 1
    ;;
esac
#sleep 5
exit 0
