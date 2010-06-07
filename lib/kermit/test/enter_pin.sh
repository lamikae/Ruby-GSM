#!/bin/bash
expect_failure=${WRONG_PIN:-false}

#sleep 1
case ${expect_failure} in
  'true')
    cat resp/enter_pin_incorrect
    ;;
  'false')
    cat resp/enter_pin_correct
    ;;
  *)
    echo "ERROR"
    exit 1
    ;;
esac
#sleep 5

exit 0
