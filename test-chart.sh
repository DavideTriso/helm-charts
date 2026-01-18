#!/bin/bash
# Test script for WordPress Helm chart

set -e

echo "==================================="
echo "WordPress Helm Chart Test Suite"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

test_passed() {
    echo -e "${GREEN}✓ $1${NC}"
}

test_failed() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Test 1: Helm lint
echo "Test 1: Running helm lint..."
if helm lint wordpress; then
    test_passed "Helm lint passed"
else
    test_failed "Helm lint failed"
fi
echo ""

# Test 2: Template rendering
echo "Test 2: Testing template rendering..."
if helm template test wordpress --dry-run > /dev/null 2>&1; then
    test_passed "Template rendering successful"
else
    test_failed "Template rendering failed"
fi
echo ""

# Test 3: Count generated resources
echo "Test 3: Verifying resource count..."
RESOURCE_COUNT=$(helm template test wordpress 2>/dev/null | grep -c "^kind:")
if [ "$RESOURCE_COUNT" -eq 12 ]; then
    test_passed "Correct number of resources generated (12)"
else
    test_failed "Expected 12 resources, got $RESOURCE_COUNT"
fi
echo ""

# Test 4: Check required resources exist
echo "Test 4: Checking required resources..."
RESOURCES=$(helm template test wordpress 2>/dev/null | grep "^kind:" | sort | uniq)
REQUIRED_RESOURCES=(
    "kind: ConfigMap"
    "kind: Deployment"
    "kind: Ingress"
    "kind: PersistentVolumeClaim"
    "kind: Secret"
    "kind: Service"
    "kind: ServiceAccount"
    "kind: StatefulSet"
)

for req in "${REQUIRED_RESOURCES[@]}"; do
    if echo "$RESOURCES" | grep -q "$req"; then
        test_passed "Found $req"
    else
        test_failed "Missing $req"
    fi
done
echo ""

# Test 5: Test with MySQL disabled
echo "Test 5: Testing with external database (MySQL disabled)..."
if helm template test wordpress --set mysql.enabled=false > /dev/null 2>&1; then
    test_passed "External database configuration works"
else
    test_failed "External database configuration failed"
fi
echo ""

# Test 6: Test with autoscaling enabled
echo "Test 6: Testing with autoscaling enabled..."
OUTPUT=$(helm template test wordpress --set autoscaling.enabled=true 2>/dev/null)
if echo "$OUTPUT" | grep -q "kind: HorizontalPodAutoscaler"; then
    test_passed "HPA generated when autoscaling enabled"
else
    test_failed "HPA not generated when autoscaling enabled"
fi
echo ""

# Test 7: Test with ingress disabled
echo "Test 7: Testing with ingress disabled..."
OUTPUT=$(helm template test wordpress --set ingress.enabled=false 2>/dev/null)
if echo "$OUTPUT" | grep -q "kind: Ingress"; then
    test_failed "Ingress should not be generated when disabled"
else
    test_passed "Ingress not generated when disabled"
fi
echo ""

# Test 8: Validate values files
echo "Test 8: Validating example values files..."
for values_file in wordpress/values-*.yaml; do
    if [ -f "$values_file" ]; then
        if helm template test wordpress -f "$values_file" > /dev/null 2>&1; then
            test_passed "$(basename $values_file) is valid"
        else
            test_failed "$(basename $values_file) is invalid"
        fi
    fi
done
echo ""

# Test 9: Check security contexts
echo "Test 9: Checking security contexts..."
OUTPUT=$(helm template test wordpress 2>/dev/null)
if echo "$OUTPUT" | grep -q "runAsNonRoot: true"; then
    test_passed "Non-root security context configured"
else
    test_failed "Non-root security context missing"
fi
echo ""

# Test 10: Check resource limits
echo "Test 10: Checking resource limits..."
OUTPUT=$(helm template test wordpress 2>/dev/null)
if echo "$OUTPUT" | grep -q "limits:" && echo "$OUTPUT" | grep -q "requests:"; then
    test_passed "Resource limits and requests configured"
else
    test_failed "Resource limits or requests missing"
fi
echo ""

echo "==================================="
echo -e "${GREEN}All tests passed! ✓${NC}"
echo "==================================="
