#!/bin/bash
# Force homebrew go/gopls ahead of any asdf shim or repo-local go wrapper
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/go/bin:$PATH"
export GOTOOLCHAIN=local
exec /opt/homebrew/bin/gopls "$@"
