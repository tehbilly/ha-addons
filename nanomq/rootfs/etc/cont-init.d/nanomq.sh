#!/usr/bin/with-contenv bashio
# ==============================================================================
# Configures NanoMQ
# ==============================================================================

readonly CONF_FILE="/etc/nanomq.conf"
readonly PWD_FILE="/etc/nanomq_pwd.conf"
readonly SYSTEM_USER="/data/system_user.json"

declare discovery_password
declare service_password

# Read or create system account credentials
if ! bashio::fs.file_exists "${SYSTEM_USER}"; then
  discovery_password="$(pwgen 64 1)"
  service_password="$(pwgen 64 1)"

  # Store it for future use
  bashio::var.json \
    homeassistant "^$(bashio::var.json password "${discovery_password})" \
    addons "^$(bashio::var.json password "${service_password}"})" \
    > "${SYSTEM_USER}"
else
  # Read the existing values
  discovery_password=$(bashio::jq "${SYSTEM_USER}" ".homeassistant.password")
  service_password=$(bashio::jq "${SYSTEM_USER}" ".addons.password")
fi

# Set up authentication
echo "homeassistant:${discovery_password}" >> "${PWD_FILE}"
echo "addons:${service_password}" >> "${PWD_FILE}"

# Add any configured credentials
for login in $(bashio::config 'logins|keys'); do
  bashio::config.require.username "logins[${login}].username"
  bashio::config.require.password "logins[${login}].password"

  username=$(bashio::config "logins[${login}].username")
  password=$(bashio::config "logins[${login}].password")

  bashio::log.info "Setting up user ${username}"
  echo "${username}:${password}" >> "${PWD_FILE}"
done

# Generate ACL conf
bashio::var.json | tempio -template /usr/share/tempio/nanomq_acl.conf -out /etc/nanomq_acl.conf

# Generate NanoMQ conf
bashio::var.json \
  allow_anonymous "^$(bashio::config 'allow_anonymous')" \
  listen_websocket "^$(bashio::config 'listen_websocket')" \
  | tempio -template /usr/share/tempio/nanomq.conf -out /etc/nanomq.conf
