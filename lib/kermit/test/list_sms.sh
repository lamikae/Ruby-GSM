#!/bin/bash
# simuloi sms-viestien lukemista laitteelta.
# ottaa samat parametrit kuin list_sms.ksc

no_unread=${NO_UNREAD_MESSAGES:-false}

#sleep 1
case ${1} in
  'ALL')
    cat resp/list_sms_all
    ;;
  'REC UNREAD')
    if [ $no_unread == 'true' ]; then
      cat resp/list_sms_unread_none
    else
      cat resp/list_sms_unread
    fi
    ;;
  *)
    echo "ERROR"
    exit 1
    ;;
esac
#sleep 5
exit 0
