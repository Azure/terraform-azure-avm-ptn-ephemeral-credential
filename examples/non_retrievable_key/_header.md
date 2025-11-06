# Non-retrievable password without rotation example

This deploys a non-retrievable ephemeral private key without TTL. Each time you read the key data, it will be regenerated, and the`value_wo_version` will only increase when private key generation settings has been changed.
