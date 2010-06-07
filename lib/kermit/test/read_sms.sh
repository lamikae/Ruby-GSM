#!/bin/bash
# simuloi sms-viestin lukemista laitteelta.
# ottaa samat parametrit kuin read_sms.ksc

if [ "${SMS_INVALID}" == "true" ]; then
  cat "resp/read_error_321"
  exit 0
fi

msgnr=$1

# print a static message for testing
if [ $msgnr -eq 0 ]; then
  cat "resp/read_sms_test"
  exit 0
fi

# sleep 1

if [ $(grep '^[0-9]*$' <<< $msgnr) ]; then
  file="resp/read_${1}"
  if [ -e $file ]; then
    cat $file
  else
    cat "resp/read_error_321"
  fi
else
  echo "ERROR"
  exit 1
fi

#sleep 5
exit 0


