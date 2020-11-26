ROOT="${HOME}/scripts/dropbear"

exec "${HOME}/apps/software/dropbear/2020.80/sbin/dropbear" -r "${ROOT}/dropbear_dss_host_key" \
-r "${ROOT}/dropbear_ecdsa_host_key" -r "${ROOT}/dropbear_ed25519_host_key" \
-r "${ROOT}/dropbear_rsa_host_key" -FE -p 41017
