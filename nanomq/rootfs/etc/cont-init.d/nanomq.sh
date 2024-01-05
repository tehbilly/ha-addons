#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configures NanoMQ
# ==============================================================================

declare discovery_password
declare service_password

# Read or create system account credentials
if ! bashio::fs.file_exists /data/system_user.json; then
  discovery_password="$(pwgen 64 1)"
  service_password="$(pwgen 64 1)"

  # Store it for future use
  bashio::var.json \
    homeassistant "^$(bashio::var.json password "${discovery_password}")" \
    addons "^$(bashio::var.json password "${service_password}")" \
    > /data/system_user.json
else
  # Read the existing values
  discovery_password=$(bashio::jq /data/system_user.json ".homeassistant.password")
  service_password=$(bashio::jq /data/system_user.json ".addons.password")
fi

# Set up authentication
echo "homeassistant:${discovery_password}" >> /etc/nanomq_pwd.conf
echo "addons:${service_password}" >> /etc/nanomq_pwd.conf

# Add any configured credentials
for login in $(bashio::config 'logins|keys'); do
  bashio::config.require.username "logins[${login}].username"
  bashio::config.require.password "logins[${login}].password"

  username=$(bashio::config "logins[${login}].username")
  password=$(bashio::config "logins[${login}].password")

  bashio::log.info "Setting up user ${username}"
  echo "${username}:${password}" >> /etc/nanomq_pwd.conf
done

# Generate ACL conf
echo '{}' | tempio -template /usr/share/tempio/nanomq_acl.conf -out /etc/nanomq_acl.conf

# Generate NanoMQ conf
bashio::var.json \
  allow_anonymous "^$(bashio::config 'allow_anonymous')" \
  listen_websocket "^$(bashio::config 'listen_websocket')" \
  | tempio -template /usr/share/tempio/nanomq.conf -out /etc/nanomq.conf
