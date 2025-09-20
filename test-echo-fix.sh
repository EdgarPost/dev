#!/bin/bash

# Test the echo vs printf fix
echo "Testing printf vs echo -e..."

# Old way (problematic with some shells)
echo -e "   \033[0;31m❌\033[0m Old echo method"

# New way (should work everywhere)
printf "   \033[0;32m✓\033[0m %s\n" "New printf method"

echo "Done testing."