#!/bin/bash

# Test script for mayr_events package
# This script runs all tests, formatting, and analysis checks

set -e

echo "🔍 Running Dart analysis..."
dart analyze --fatal-warnings .

echo ""
echo "✨ Checking code formatting..."
dart format --set-exit-if-changed .

echo ""
echo "🧪 Running tests..."
flutter test --coverage

echo ""
echo "✅ All checks passed!"
echo ""
echo "📊 Coverage report generated in: coverage/lcov.info"
echo "   View HTML coverage: genhtml coverage/lcov.info -o coverage/html"
