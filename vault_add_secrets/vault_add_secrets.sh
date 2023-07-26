#!/bin/bash

new_secrets=$( jo $SECRET_KEY=$SECRET_VALUE )
echo $new_secrets > new_secrets.json

# Check if the Vault SECRET_PATH exists

if vault kv get -address="$VAULT_URL" "$SECRET_PATH" ; then
    # Vault SECRET_PATH exists, read existing secrets and merge them with new secret
    existing_secrets=$(vault kv get -address="$VAULT_URL" -format=json "$SECRET_PATH")
    jq -n "$existing_secrets.data.data" > existing_secrets.json
    jq -n '([inputs] | add)' new_secrets.json existing_secrets.json > merged_secrets.json
    vault kv put -address="$VAULT_URL" "$SECRET_PATH" @merged_secrets.json
    echo "Merged secret SECRET_KEY: $SECRET_KEY with SECRET_VALUE: $SECRET_VALUE in SECRET_PATH: $SECRET_PATH"
else
    vault kv put -address="$VAULT_URL" "$SECRET_PATH" "$SECRET_KEY=$SECRET_VALUE"
    echo "Created new secret SECRET_PATH: $SECRET_PATH with SECRET_KEY: $SECRET_KEY"
fi
