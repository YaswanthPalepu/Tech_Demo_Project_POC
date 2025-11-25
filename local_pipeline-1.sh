#!/bin/bash
set -euo pipefail
trap 'echo "❌ Script failed at line $LINENO"; exit 1' ERR

echo "🚀 Starting Enhanced Pipeline - Manual + Gap-Based AI Test Flow"
echo "==================================================================="
echo ""

# 1️⃣ Set target directory backend_code pytest_fun clinic flask-high-coverage-repo food-menu 
export CURRENT_DIR="/home/sigmoid/my_name/new-tech-demo"
export TARGET_DIR="/home/sigmoid/test-repos/flask-high-coverage-repo"
export TARGET_ROOT="$TARGET_DIR"
export PYTHONPATH="$TARGET_DIR"
export PATH="$CURRENT_DIR/venv/sonar-scanner/bin:$PATH"
echo "🎯 Target Directory: $TARGET_DIR"
echo ""

# 🧹 CRITICAL: Clean all coverage artifacts before starting
echo "🧹 Cleaning previous coverage data..."
rm -f .coverage
rm -f coverage.xml
rm -rf htmlcov/
rm -rf .pytest_cache/
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$TARGET_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

echo "🗑️ Clearing all stale test caches..."

# Remove previous test folders
rm -rf "$CURRENT_DIR/tests/manual"
rm -rf "$CURRENT_DIR/tests/generated"

# Remove pytest cache
rm -rf "$CURRENT_DIR/.pytest_cache"

# Remove pyc files
find "$CURRENT_DIR" -name "*.pyc" -delete
find "$CURRENT_DIR" -name "__pycache__" -type d -exec rm -rf {} +

# Remove coverage cache
rm -f "$CURRENT_DIR/.coverage"
rm -f "$TARGET_DIR/.coverage"

# Remove old sonar cache
rm -rf "$CURRENT_DIR/.scannerwork"
rm -rf "$TARGET_DIR/.scannerwork"
rm -rf .codebase_index
rm -f \
  .pytest_combined.json \
  .pytest_generated.json \
  .pytest_manual.json \
  auto_fixer_report.json \
  coverage_gaps.json \
  iteration_report.json \
  manual_test_result.json \
  pytest_report.json

echo "Cleanup done."
echo "✅ All stale caches removed"
echo ""

# 🔧 Ensure pytest-json-report is installed for auto-fix functionality
echo "📦 Installing pytest-json-report for auto-fix feature..."
pip install -q pytest-json-report || echo "⚠️  Failed to install pytest-json-report, auto-fix may not work"
echo ""

# 2️⃣ Detect Manual Tests
echo "🔍 Running detect_manual_tests.py on target repo..."
python src/detect_manual_tests.py "$TARGET_DIR" || true

FOUND=$(python3 -c "import json; print(json.load(open('manual_test_result.json'))['manual_tests_found'])")
PATHS=$(python3 -c "import json; print(' '.join(json.load(open('manual_test_result.json'))['manual_test_paths']))")

echo ""
echo "📁 Manual Tests Found: $FOUND"
echo "📂 Test Paths: $PATHS"
echo ""

# -------------------------------------------------------------------
# CASE 1️⃣: Manual Tests Found - Run and Analyze Coverage
# -------------------------------------------------------------------
if [[ "${FOUND,,}" == "true" ]]; then
  echo "✅ Manual test cases detected. Running pytest with coverage analysis..."
  echo ""

  export JSON_FILE="manual_test_result.json"
  export TEST_PATHS=$(python3 - <<'PYCODE'
import json
with open("manual_test_result.json") as f:
    data = json.load(f)
print(" ".join(data.get("manual_test_paths", [])))
PYCODE
)
  
  # 📦 Install project dependencies if requirements.txt exists
  if [ -f "$TARGET_DIR/requirements.txt" ]; then
    echo "📦 Installing project dependencies..."
    pip install -r "$TARGET_DIR/requirements.txt"
  else
    echo "⚠️ No requirements.txt found — skipping dependency installation"
  fi
  echo ""

  echo "📂 Copying manual tests to local folder: ./tests/manual"
  rm -rf "./tests/manual"
  mkdir -p ./tests/manual

  # This prevents pytest collection errors from duplicate filenames
  python3 - <<'PYCODE'
import json
import os
import shutil

# Load the detection results
with open("manual_test_result.json") as f:
    data = json.load(f)

test_root = data.get("test_root", "")
files_by_rel_path = data.get("files_by_relative_path", {})

if not files_by_rel_path:
    print("⚠️ No test files found in manual_test_result.json")
    exit(0)

print(f"📁 Test root: {test_root}")
print(f"📋 Copying {len(files_by_rel_path)} test files with preserved structure...")

copied_count = 0
for rel_path, full_path in files_by_rel_path.items():
    # Destination path preserves the relative directory structure
    dest_path = os.path.join("./tests/manual", rel_path)
    dest_dir = os.path.dirname(dest_path)

    # Create subdirectories if needed
    os.makedirs(dest_dir, exist_ok=True)

    # Copy the file
    try:
        shutil.copy2(full_path, dest_path)
        print(f"   ✓ {rel_path}")
        copied_count += 1
    except Exception as e:
        print(f"   ✗ Failed to copy {rel_path}: {e}")

print(f"\n✅ Copied {copied_count}/{len(files_by_rel_path)} test files")
PYCODE

  echo ""
  echo "✅ Manual test files copied to ./tests/manual"
  echo "📄 Files:"
  find ./tests/manual -type f -name 'test_*.py'
  echo ""

  # 🧹 Clean cache again after copying
  find ./tests/manual -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

  echo "🧪 Running manual tests from local directory with coverage analysis: ./tests/manual"
  echo ""

  # Run pytest and capture output
  MANUAL_TEST_EXIT_CODE=0
  pytest "$CURRENT_DIR/tests/manual" \
    --cov=$TARGET_DIR \
    --cov-config=pytest.ini \
    --cov-report=term-missing \
    --cov-report=xml \
    --cov-report=html \
    --cov-fail-under=0 \
    --json-report \
    --junitxml="$CURRENT_DIR/test-results.xml" \
    --json-report-file="$CURRENT_DIR/.pytest_manual.json" \
    -v || MANUAL_TEST_EXIT_CODE=$?

  sonar-scanner \
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    -Dproject.settings="$CURRENT_DIR/sonar-project.properties" \
    -Dsonar.projectBaseDir="$TARGET_DIR" \
    -Dsonar.sources="$TARGET_DIR" \
    -Dsonar.python.coverage.reportPaths="$CURRENT_DIR/coverage.xml"

  echo "🎉 SonarQube upload complete!"


  echo "📊 Coverage report generated"
  coverage report --show-missing

  echo ""

  # Auto-fix failing tests if any failures detected
  if [ $MANUAL_TEST_EXIT_CODE -ne 0 ]; then
    echo "⚠️  Some manual tests failed (exit code: $MANUAL_TEST_EXIT_CODE)"
    echo "🔧 Starting auto-fix for failing manual tests..."
    echo ""

    # python -m src.gen.auto_fix_tests \
    #   --test-dir "tests/manual" \
    #   --target-dir "$TARGET_DIR" \
    #   --current-dir "$CURRENT_DIR" \
    #   --max-iterations 3 || true



    # python run_auto_fixer.py \
    # --test-dir "$CURRENT_DIR/tests/generated" \
    # --project-root "$TARGET_DIR" \
    # --max-iterations 3 || true
    echo ""
  fi

  echo "✅ Pytest completed for manual tests."
  echo ""

  # Parse coverage from coverage.xml
  if [ -f coverage.xml ]; then
    COVERAGE=$(python3 -c "import xml.etree.ElementTree as ET; \
      tree = ET.parse('coverage.xml'); root = tree.getroot(); \
      print(f'{float(root.attrib.get(\"line-rate\", 0)) * 100:.2f}')")
    echo "✅ Manual Test Coverage: $COVERAGE%"

    # Show which files were covered
    echo ""
    echo "📊 Coverage Summary:"
    python3 - <<'PYCODE'
import xml.etree.ElementTree as ET
tree = ET.parse('coverage.xml')
root = tree.getroot()
for pkg in root.findall('.//package'):
    for cls in pkg.findall('.//class'):
        filename = cls.get('filename')
        line_rate = float(cls.get('line-rate', 0)) * 100
        print(f"  {filename}: {line_rate:.1f}%")
PYCODE
  else
    COVERAGE=0
    echo "❌ No coverage.xml found"
  fi
  
  echo ""
  echo "=" * 80
  echo "COVERAGE ANALYSIS PHASE"
  echo "=" * 80
  
  # 3️⃣ Analyze Coverage Gaps
  echo "hello"
  echo "🔍 Analyzing coverage gaps..."
  python src/coverage_gap_analyzer.py \
    --target "$TARGET_DIR" \
    --current-dir "$CURRENT_DIR" \
    --output coverage_gaps.json || true
  
  echo ""
  
  # 4️⃣ Check if AI generation is needed based on coverage
  MIN_COVERAGE=90
  if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo "⚠️  Coverage is below ${MIN_COVERAGE}%"
    echo "🤖 Initiating Gap-Based AI Test Generation..."
    echo ""
    
    # Set environment variables for gap-focused generation
    export GAP_FOCUSED_MODE=true
    export COVERAGE_GAPS_FILE="$CURRENT_DIR/coverage_gaps.json"
    export TESTGEN_FORCE=true
    
    # Generate AI tests targeting only coverage gaps using full src/gen workflow
    echo "=" * 80
    echo "GAP-BASED AI TEST GENERATION (Using Full AI Workflow)"
    echo "=" * 80
    echo ""
    
    # Remove old generated tests
    rm -rf "./tests/generated"
    
    # Run full AI test generator with gap-focused mode enabled
    python multi_iteration_orchestrator.py \
      --target "$TARGET_DIR" \
      --iterations 3 \
      --target-coverage 90 \
      --outdir "$CURRENT_DIR/tests/generated" || true

    
    # python run_auto_fixer.py \
    #   --test-dir "$CURRENT_DIR/tests/generated" \
    #   --project-root "$TARGET_DIR" \
    #   --max-iterations 3 || true
    
    echo "=== AI Test Generation Completed ==="

    # Count generated tests
    if [ -d "./tests/generated" ]; then
      TEST_COUNT=$(find "./tests/generated" -name 'test_*.py' -type f | wc -l)
      echo "🧩 Total AI-generated test files: $TEST_COUNT"
      find "./tests/generated" -name 'test_*.py' -type f | head -10
    else
      echo "❌ No tests generated!"
      TEST_COUNT=0
    fi

    echo ""
    
    if [ $TEST_COUNT -gt 0 ]; then
      echo "✅ Gap-based AI test generation completed successfully"
      echo ""
      
      # 5️⃣ Run combined tests (manual + AI generated)
      echo "=" * 80
      echo "RUNNING COMBINED TESTS (Manual + AI Generated)"
      echo "=" * 80
      echo ""
      
      # 📦 Install project dependencies if requirements.txt exists
      if [ -f "$TARGET_DIR/requirements.txt" ]; then
        echo "📦 Installing project dependencies..."
        pip install -q -r "$TARGET_DIR/requirements.txt"
      else
        echo "⚠️ No requirements.txt found — skipping dependency installation"
      fi

      # 🧹 Clean cache for generated tests
      find ./tests/generated -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
      
      # Check if AI tests were actually generated
      if [ -d "./tests/generated" ] && [ -d "./tests/manual" ]; then
        echo "🧪 Running combined test suite..."
        COMBINED_TEST_EXIT_CODE=0
        pytest "$CURRENT_DIR/tests/manual" "$CURRENT_DIR/tests/generated" \
          --cov=$TARGET_DIR \
          --cov-config=pytest.ini \
          --cov-report=term-missing \
          --cov-report=xml \
          --cov-report=html \
          --cov-fail-under=0 \
          --json-report \
          --junitxml="$CURRENT_DIR/test-results.xml" \
          --json-report-file="$CURRENT_DIR/.pytest_combined.json" \
          -v || COMBINED_TEST_EXIT_CODE=$?

        echo ""

        # Auto-fix failing tests if any failures detected
        if [ $COMBINED_TEST_EXIT_CODE -ne 0 ]; then
          echo "⚠️  Some combined tests failed (exit code: $COMBINED_TEST_EXIT_CODE)"
          echo "🔧 Starting auto-fix for failing tests..."
          echo ""

          # Fix generated tests first (more likely to have issues)
          # python -m src.gen.auto_fix_tests \
          #   --test-dir "tests/generated" \
          #   --target-dir "$TARGET_DIR" \
          #   --current-dir "$CURRENT_DIR" \
          #   --max-iterations 3 || true
          python run_auto_fixer.py \
            --test-dir "$CURRENT_DIR/tests/generated" \
            --project-root "$TARGET_DIR" \
            --max-iterations 3 || true
          echo ""

          sonar-scanner \
            -Dsonar.host.url="$SONAR_HOST_URL" \
            -Dsonar.token="$SONAR_TOKEN" \
            -Dproject.settings="$CURRENT_DIR/sonar-project.properties" \
            -Dsonar.projectBaseDir="$TARGET_DIR" \
            -Dsonar.sources="$TARGET_DIR" \
            -Dsonar.tests="$CURRENT_DIR/tests/generated" \
            -Dsonar.python.coverage.reportPaths="$CURRENT_DIR/coverage.xml"

          echo ""
        fi

        echo "📊 Combined Coverage Analysis:"
        coverage report --show-missing
        
        # Parse combined coverage
        if [ -f coverage.xml ]; then
          COMBINED_COVERAGE=$(python3 -c "import xml.etree.ElementTree as ET; \
            tree = ET.parse('coverage.xml'); root = tree.getroot(); \
            print(f'{float(root.attrib.get(\"line-rate\", 0)) * 100:.2f}')")
          echo ""
          echo "=" * 80
          echo "FINAL RESULTS"
          echo "=" * 80
          echo "✅ Manual Test Coverage:   $COVERAGE%"
          echo "✅ Combined Line Coverage:      $COMBINED_COVERAGE%"
          echo "📈 Coverage Improvement:   $(python3 -c "print(f'{float($COMBINED_COVERAGE) - float($COVERAGE):.2f}%')")"
          echo ""
          
          if (( $(echo "$COMBINED_COVERAGE >= $MIN_COVERAGE" | bc -l) )); then
            echo "🎉 Quality Gate Passed: Coverage ${COMBINED_COVERAGE}% ≥ ${MIN_COVERAGE}%"
            echo ""
            echo "✅ Pipeline completed successfully!"
            exit 0
          else
            echo "⚠️  Quality Gate: Coverage ${COMBINED_COVERAGE}% < ${MIN_COVERAGE}%"
            echo "💡 Consider:"
            echo "   1. Review uncovered code in htmlcov/index.html"
            echo "   2. Add more manual tests for complex scenarios"
            echo "   3. Re-run gap analysis for another iteration"
            echo ""
            echo "✅ Pipeline completed with coverage improvement"
            exit 0
          fi
        fi
      else
        echo "⚠️  No AI tests were generated"
        echo "Using manual test coverage only: $COVERAGE%"
        echo ""
        echo "✅ Quality Gate Check:"
        if (( $(echo "$COVERAGE >= $MIN_COVERAGE" | bc -l) )); then
          echo "🎉 Coverage ${COVERAGE}% ≥ ${MIN_COVERAGE}% with manual tests alone!"
        else
          echo "⚠️  Coverage ${COVERAGE}% < ${MIN_COVERAGE}%"
          echo "💡 Manual tests alone don't meet threshold"
          echo "   Consider adding more manual tests for critical paths"
        fi
        exit 0
      fi
    else
      echo "❌ Gap-based AI test generation failed"
      echo "Using manual test coverage only: $COVERAGE%"
    fi
  else
    echo "🎉 Quality Gate Passed: Coverage ${COVERAGE}% ≥ ${MIN_COVERAGE}%"
    echo "✅ No AI test generation needed - manual tests provide sufficient coverage"
    echo ""
    echo "✅ Pipeline completed successfully with manual tests only!"
    exit 0
  fi

  echo ""
  echo "🎯 Enhanced Pipeline completed!"
  exit 0
fi

# -------------------------------------------------------------------
# CASE 2️⃣: No Manual Tests Found → Generate Full AI Tests
# -------------------------------------------------------------------
echo "⚠️ No manual tests found. Proceeding with full AI Test Generation..."
echo ""

echo "=== Starting full AI test generation ==="
export TESTGEN_FORCE=true
echo "Force regeneration: $TESTGEN_FORCE"

# Remove previous test cases
rm -rf "./tests/generated"

# Run AI test generator (full generation mode)
python -m src.gen --target "$TARGET_DIR" --outdir "$CURRENT_DIR/tests/generated" --force

echo "=== AI Test Generation Completed ==="

# Count generated tests
if [ -d "./tests/generated" ]; then
  TEST_COUNT=$(find "./tests/generated" -name 'test_*.py' -type f | wc -l)
  echo "🧩 Total AI-generated test files: $TEST_COUNT"
  find "./tests/generated" -name 'test_*.py' -type f | head -10
else
  echo "❌ No tests generated!"
  TEST_COUNT=0
fi

echo ""

# 📦 Install project dependencies if requirements.txt exists
if [ -f "$TARGET_DIR/requirements.txt" ]; then
  echo "📦 Installing project dependencies..."
  pip install -r "$TARGET_DIR/requirements.txt"
else
  echo "⚠️ No requirements.txt found — skipping dependency installation"
fi

# 🧹 Clean cache for generated tests
find ./tests/generated -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Run pytest on AI-generated tests
if [ "$TEST_COUNT" -gt 0 ]; then
  echo "🧪 Running pytest on AI-generated tests..."
  AI_TEST_EXIT_CODE=0
  pytest "$CURRENT_DIR/tests/generated" \
    --cov=$TARGET_DIR \
    --cov-config=pytest.ini \
    --cov-report=term-missing \
    --cov-report=xml \
    --cov-report=html \
    --cov-fail-under=0 \
    --json-report \
    --junitxml="$CURRENT_DIR/test-results.xml" \
    --json-report-file="$CURRENT_DIR/.pytest_generated.json" \
    -v || AI_TEST_EXIT_CODE=$?

  echo ""

  # Auto-fix failing tests if any failures detected
  if [ $AI_TEST_EXIT_CODE -ne 0 ]; then
    echo "⚠️  Some AI-generated tests failed (exit code: $AI_TEST_EXIT_CODE)"
    echo "🔧 Starting auto-fix for failing AI-generated tests..."
    echo ""

    python run_auto_fixer.py \
        --test-dir "$CURRENT_DIR/tests/generated" \
        --project-root "$TARGET_DIR" \
        --max-iterations 3 || true

    pytest "$CURRENT_DIR/tests/generated" \
      --cov=$TARGET_DIR \
      --cov-config=pytest.ini \
      --cov-report=term-missing \
      --cov-report=xml \
      --cov-report=html \
      --cov-fail-under=0 \
      --json-report \
      --junitxml="$CURRENT_DIR/test-results.xml" \
      --json-report-file="$CURRENT_DIR/.pytest_generated.json" \
      -v || true

    sonar-scanner \
      -Dsonar.host.url="$SONAR_HOST_URL" \
      -Dsonar.token="$SONAR_TOKEN" \
      -Dproject.settings="$CURRENT_DIR/sonar-project.properties" \
      -Dsonar.projectBaseDir="$TARGET_DIR" \
      -Dsonar.sources="$TARGET_DIR" \
      -Dsonar.python.coverage.reportPaths="$CURRENT_DIR/coverage.xml"    

    echo ""
  fi

  echo "✅ Pytest completed for AI-generated tests."
  echo ""

  # Parse coverage
  if [ -f coverage.xml ]; then
    COVERAGE=$(python3 -c "import xml.etree.ElementTree as ET; \
      tree = ET.parse('coverage.xml'); root = tree.getroot(); \
      print(f'{float(root.attrib.get(\"line-rate\", 0)) * 100:.2f}')")
    echo "✅ AI Test Coverage: $COVERAGE%"

     # Show which files were covered
    echo ""
    echo "📊 Coverage Summary:"
    python3 - <<'PYCODE'
import xml.etree.ElementTree as ET
tree = ET.parse('coverage.xml')
root = tree.getroot()
for pkg in root.findall('.//package'):
    for cls in pkg.findall('.//class'):
        filename = cls.get('filename')
        line_rate = float(cls.get('line-rate', 0)) * 100
        print(f"  {filename}: {line_rate:.1f}%")
PYCODE
  else
    COVERAGE=0
    echo "❌ No coverage.xml found"
  fi

  MIN_COVERAGE=70
  if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo "❌ Quality Gate Failed: Coverage below ${MIN_COVERAGE}%"
    exit 1
  else
    echo "✅ Quality Gate Passed: Coverage ${COVERAGE}% ≥ ${MIN_COVERAGE}%"
  fi

  echo ""
  echo "🎯 Enhanced Pipeline completed successfully with AI-generated tests!"
  exit 0
else
  echo "❌ No AI-generated tests found. Pipeline cannot proceed."
  exit 1
fi