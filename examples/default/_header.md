# Non-retrievable password without rotation example

This deploys a non-retrievable ephemeral password without TTL. Each time you read the password, it will be regenerated, and the`value_wo_version` will only increase when password generation settings has been changed.
