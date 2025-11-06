# Non-retrievable password with rotation example

This deploys a non-retrievable ephemeral password with a 1 hour TTL.

Changing time-rotation or password generation settings will cause regeneration of the value_wo_version, which leads to an update of the downstream resources.
