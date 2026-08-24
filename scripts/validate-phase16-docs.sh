#!/usr/bin/env bash

set -uo pipefail


PASSED=0
FAILED=0


pass() {
    echo "[PASS] $1"
    PASSED=$((PASSED + 1))
}


fail() {
    echo "[FAIL] $1"
    FAILED=$((FAILED + 1))
}


echo "============================================================"
echo " Phase 16 Documentation Validation"
echo "============================================================"


REQUIRED_FILES=(
    "README.md"
    "architecture-diagram.png"
    "operations-guide.md"
    "decision-log.md"
    "docs/architecture-diagram.mmd"
    "docs/demo-script.md"
)


for file in "${REQUIRED_FILES[@]}"; do

    if [ -s "$file" ]; then
        pass "$file exists and is non-empty"
    else
        fail "$file is missing or empty"
    fi

done


if file architecture-diagram.png | grep -q "PNG image data"; then
    pass "architecture-diagram.png is a valid PNG"
else
    fail "architecture-diagram.png is not a valid PNG"
fi


if grep -q "architecture-diagram.png" README.md; then
    pass "README references architecture diagram"
else
    fail "README does not reference architecture diagram"
fi


if grep -q "operations-guide.md" README.md; then
    pass "README references operations guide"
else
    fail "README does not reference operations guide"
fi


if grep -q "decision-log.md" README.md; then
    pass "README references decision log"
else
    fail "README does not reference decision log"
fi


if grep -qi "Terraform" README.md &&
   grep -qi "Ansible" README.md &&
   grep -qi "Jenkins" README.md &&
   grep -qi "Prometheus" README.md; then

    pass "README covers main DevOps technologies"

else

    fail "README is missing major technology coverage"

fi


if grep -qi "Jenkins Is Down" operations-guide.md &&
   grep -qi "SonarQube Is Not Responding" operations-guide.md &&
   grep -qi "Application Is Unavailable" operations-guide.md &&
   grep -qi "Prometheus Target Is Down" operations-guide.md &&
   grep -qi "EC2 Is Unreachable" operations-guide.md; then

    pass "Operations guide covers required incidents"

else

    fail "Operations guide is missing required incident procedures"

fi


if grep -qi "Terraform" decision-log.md &&
   grep -qi "Ansible" decision-log.md &&
   grep -qi "Jenkins" decision-log.md &&
   grep -qi "Docker" decision-log.md &&
   grep -qi "Prometheus" decision-log.md; then

    pass "Decision log covers required architectural decisions"

else

    fail "Decision log is missing key technology decisions"

fi


if grep -REn \
    'BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|AKIA[0-9A-Z]{16}' \
    README.md \
    operations-guide.md \
    decision-log.md \
    docs \
    scripts \
    >/dev/null 2>&1; then

    fail "Potential secret/private key found in documentation"

else

    pass "No obvious private keys or AWS access keys in documentation"

fi


if grep -RniE \
    --exclude='validate-phase16-docs.sh' \
    'YOUR_REAL_(TOKEN|PASSWORD|SECRET)|PASTE_SECRET_HERE' \
    README.md \
    operations-guide.md \
    decision-log.md \
    docs \
    scripts \
    >/dev/null 2>&1; then

    fail "Unsafe secret placeholder/value pattern found"

else

    pass "No unsafe secret-value placeholders found"

fi


if git diff --check; then
    pass "Git whitespace validation passes"
else
    fail "git diff --check failed"
fi


echo
echo "============================================================"
echo " Passed: ${PASSED}"
echo " Failed: ${FAILED}"
echo "============================================================"


if [ "$FAILED" -eq 0 ]; then

    echo "PHASE 16 DOCUMENTATION VALIDATION: PASS"
    exit 0

else

    echo "PHASE 16 DOCUMENTATION VALIDATION: FAIL"
    exit 1

fi
