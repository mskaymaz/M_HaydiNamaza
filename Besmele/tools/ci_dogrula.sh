#!/usr/bin/env sh
# ci_dogrula: CI veya yerelde Besmele yapisini tek komutla dogrular.
set -eu
python "Besmele/tools/validate_besmele.py"
