#!/bin/sh -e

# Using curl instead of httpie for reduce the image size.

echo
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done

if [ -z ${HOST_HOSTNAME+x} ]; then
  echo "Environment variable 'HOST_HOSTNAME' not set, we'll use the container hostname instead"
  host_hostname=$(hostname)
else
  host_hostname=$(cat ${HOST_HOSTNAME})
fi

# Get Portainer JWT
#jwt=$(http POST "${PORTAINER_ADDR}/api/auth" Username="${PORTAINER_USER}" Password="${PORTAINER_PASS}" | jq -r .jwt)
jwt=$(curl -sf -X POST -H "Accept: application/json, */*" -H "Content-Type: application/json" --data "{\"Username\": \"${PORTAINER_USER}\", \"Password\": \"${PORTAINER_PASS}\"}" "${PORTAINER_ADDR}/api/auth"  | jq -r .jwt)

# Check if the host is already registered
# registered_hosts=$(http --auth-type=jwt --auth="${jwt}" ${PORTAINER_ADDR}/api/endpoints | jq --arg HOST "$host_hostname" -c '.[] | select(.Name == $HOST) | .Id')
registered_hosts=$(curl -sf -X GET -H "Accept: application/json, */*" -H "Content-Type: application/json" -H "Authorization: Bearer ${jwt}" ${PORTAINER_ADDR}/api/endpoints | jq --arg HOST "$host_hostname" -c '.[] | select(.Name == $HOST) | .Id')
for i in $registered_hosts
do
  echo Deleting previous found host name with id $i
  # http --auth-type=jwt --auth="${jwt}" DELETE ${PORTAINER_ADDR}/api/endpoints/$i
  curl -sf -X DELETE -H "Accept: application/json, */*" -H "Content-Type: application/json" -H "Authorization: Bearer ${jwt}" ${PORTAINER_ADDR}/api/endpoints/${i}
done

# Register current host
# http --auth-type=jwt --auth="${jwt}" POST ${PORTAINER_ADDR}/api/endpoints Name="${host_hostname}-endpoint" URL="tcp://${HOSTNAME}:2375"
curl -sf -X POST -H "Accept: application/json, */*" -H "Content-Type: application/json" -H "Authorization: Bearer ${jwt}" --data "{\"Name\": \"${host_hostname}\", \"URL\": \"tcp://${HOSTNAME}:2375\"}" ${PORTAINER_ADDR}/api/endpoints

exec "$@"
