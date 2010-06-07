#!/bin/bash
expect_failure=${NO_CARRIER:-false}

#sleep 1
case ${expect_failure} in
  'true')
    cat resp/carrier_none
    ;;
  'false')
    cat resp/carrier
    ;;
  *)
    echo "ERROR"
    exit 1
    ;;
esac
#sleep 5
exit 0
