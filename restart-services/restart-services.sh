#!/bin/bash

# shellcheck disable=SC1091
source .env

# shellcheck disable=SC1091
source /etc/apache2/envvars

email_alert() {
	curl -X POST "${EMAIL_SERVICE}" \
		--data-binary "{\"token\":\"${MAIL_TOKEN}\",\"subject\":\"Service down ${1}\",\"from_name\":\"${MAIL_TITLE}\",\"to\":\"${TO_MAIL}\",\"to_name\":\"${TO_NAME}\",\"message\":\"${2}\"}"
}
for SERVICE in $ALL_SERVICES; do
	if ! pgrep "$SERVICE" >/dev/null; then
		echo "$SERVICE service is down"
		service "$SERVICE" start
		SERVICE_STATUS_OUTPUT=$(service "${SERVICE}" status)
		CURL_OUTPUT=$(curl -s -I "${CURL_CHECK}")
		MESSAGE=$(echo -e "Service ${SERVICE} was down, and now is started again.\n\nService status: \n${SERVICE_STATUS_OUTPUT}\n\nCurl output after service start:\n${CURL_OUTPUT}")
		MESSAGE_BASE64=$(echo "${MESSAGE}" | base64 -w0 | sed 's/^/base64:/')

		email_alert "${SERVICE}" "${MESSAGE_BASE64}"
	fi
done
