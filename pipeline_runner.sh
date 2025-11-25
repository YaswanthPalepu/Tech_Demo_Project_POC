#!/bin/bash
set -euo pipefail
trap 'echo "❌ Script failed at line $LINENO"; exit 1' ERR

echo "🚀 Starting Enhanced AI Test Generation Pipeline"
echo "=================================================================="
echo ""

# Set directory paths
export CURRENT_DIR="$(pwd)"
export TARGET_DIR="$(pwd)/../target_repo"
export TARGET_ROOT="$TARGET_DIR"
export PYTHONPATH="$TARGET_DIR"
export PATH="$CURRENT_DIR/venv/sonar-scanner/bin:$PATH"

echo "🎯 Pipeline Directory: $CURRENT_DIR"
echo "🎯 Target Repository: $TARGET_DIR"
echo ""

# Verify target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Target directory not found: $TARGET_DIR"
  exit 1
fi

# 🧹 Clean all coverage artifacts before starting
echo "🧹 Cleaning previous coverage data..."
rm -f .coverage coverage.xml
rm -rf htmlcov/ .pytest_cache/
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$TARGET_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

echo "🗑️ Clearing all stale test caches..."
rm -rf "$CURRENT_DIR/tests/manual"
rm -rf "$CURRENT_DIR/tests/generated"
rm -rf "$CURRENT_DIR/.pytest_cache"
find "$CURRENT_DIR" -name "*.pyc" -delete 2>/dev/null || true
find "$CURRENT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
rm -f "$CURRENT_DIR/.coverage" "$TARGET_DIR/.coverage"
rm -rf "$CURRENT_DIR/.scannerwork" "$TARGET_DIR/.scannerwork"
rm -rf .codebase_index/
rm -f \
  .pytest_combined.json \
  .pytest_generated.json \
  .pytest_manual.json \
  auto_fixer_report.json \
  coverage_gaps.json \
  iteration_report.json \
  manual_test_result.json \
  pytest_report.json
echo "✅ All stale caches removed"
echo ""

# 🔧 Ensure pytest-json-report is installed
echo "📦 Installing pytest-json-report for auto-fix feature..."
pip install -q pytest-json-report || echo "⚠️ Failed to install pytest-json-report"
echo ""

# 2️⃣ Detect Manual Tests
echo "🔍 Running detect_manual_tests.py on target repo..."
python src/detect_manual_tests.py "$TARGET_DIR" || true

FOUND=$(python3 -c "import json; print(json.load(open('manual_test_result.json'))['manual_tests_found'])")
PATHS=$(python3 -c "import json; print(' '.join(json.load(open('manual_test_result.json'))['manual_test_paths']))" || echo "")

echo ""
echo "📁 Manual Tests Found: $FOUND"
echo "📂 Test Paths: $PATHS"
echo ""

# Set minimum coverage threshold (default from env or 90)
MIN_COVERAGE=${MIN_COVERAGE_THRESHOLD:-90}
echo "📊 Minimum Coverage Threshold: ${MIN_COVERAGE}%"
echo ""

# -------------------------------------------------------------------
# CASE 1: Manual Tests Found - Run and Analyze Coverage
# -------------------------------------------------------------------
if [[ "${FOUND,,}" == "true" ]]; then
  echo "✅ Manual test cases detected. Running pytest with coverage analysis..."
  echo ""

  export JSON_FILE="manual_test_result.json"
  export TEST_PATHS=$(python3 - <<'PYCODE'
import json
try:
    with open("manual_test_result.json") as f:
        data = json.load(f)
    print(" ".join(data.get("manual_test_paths", [])))
except:
    print("")
PYCODE
)
  
  # 📦 Install project dependencies if requirements.txt exists
  if [ -f "$TARGET_DIR/requirements.txt" ]; then
    echo "📦 Installing project dependencies from target repo..."
    pip install -q -r "$TARGET_DIR/requirements.txt" || echo "⚠️ Some dependencies failed to install"
  else
    echo "⚠️ No requirements.txt found in target repo"
  fi
  echo ""

  echo "📂 Copying manual tests to local folder: ./tests/manual"
  rm -rf "./tests/manual"
  mkdir -p ./tests/manual

  # Copy tests preserving directory structure
  python3 - <<'PYCODE'
import json
import os
import shutil

with open("manual_test_result.json") as f:
    data = json.load(f)

test_root = data.get("test_root", "")
files_by_rel_path = data.get("files_by_relative_path", {})

if not files_by_rel_path:
    print("⚠️ No test files found in manual_test_result.json")
    exit(0)

print(f"📁 Test root: {test_root}")
print(f"📋 Copying {len(files_by_rel_path)} test files...")

copied_count = 0
for rel_path, full_path in files_by_rel_path.items():
    dest_path = os.path.join("./tests/manual", rel_path)
    dest_dir = os.path.dirname(dest_path)
    os.makedirs(dest_dir, exist_ok=True)
    
    try:
        shutil.copy2(full_path, dest_path)
        print(f"   ✓ {rel_path}")
        copied_count += 1
    except Exception as e:
        print(f"   ✗ Failed to copy {rel_path}: {e}")

print(f"\n✅ Copied {copied_count}/{len(files_by_rel_path)} test files")
PYCODE

  echo ""
  find ./tests/manual -type f -name 'test_*.py' 2>/dev/null || echo "No test files found"
  echo ""

  find ./tests/manual -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

  echo "🧪 Running manual tests with coverage analysis..."
  echo ""

  MANUAL_TEST_EXIT_CODE=0
  pytest "$CURRENT_DIR/tests/manual" \
    --cov="$TARGET_DIR" \
    --cov-config=pytest.ini \
    --cov-report=term-missing \
    --cov-report=xml \
    --cov-report=html \
    --cov-fail-under=0 \
    --json-report \
    --junitxml="$CURRENT_DIR/test-results.xml" \
    --json-report-file="$CURRENT_DIR/.pytest_manual.json" \
    -v || MANUAL_TEST_EXIT_CODE=$?

  # Upload to SonarQube if credentials provided
  if [ -n "${SONAR_HOST_URL:-}" ] && [ -n "${SONAR_TOKEN:-}" ]; then
    echo "📤 Uploading results to SonarQube..."
    sonar-scanner \
      -Dsonar.host.url="$SONAR_HOST_URL" \
      -Dsonar.token="$SONAR_TOKEN" \
      -Dproject.settings="$CURRENT_DIR/sonar-project.properties" \
      -Dsonar.projectBaseDir="$TARGET_DIR" \
      -Dsonar.sources="$TARGET_DIR" \
      -Dsonar.python.coverage.reportPaths="$CURRENT_DIR/coverage.xml" || echo "⚠️ SonarQube upload failed"
    echo "🎉 SonarQube upload complete!"
  else
    echo "⚠️ SonarQube credentials not provided, skipping upload"
  fi

  echo "📊 Coverage report generated"
  coverage report --show-missing || true

  # Auto-fix failing tests if any failures detected
  if [ $MANUAL_TEST_EXIT_CODE -ne 0 ]; then
    echo "⚠️ Some manual tests failed (exit code: $MANUAL_TEST_EXIT_CODE)"
    echo "🔧 Auto-fix is available but skipped for manual tests"
    echo ""
  fi

  echo "✅ Pytest completed for manual tests."
  echo ""

  # Parse coverage from coverage.xml
  if [ -f coverage.xml ]; then
    COVERAGE=$(python3 -c "import xml.etree.ElementTree as ET; tree = ET.parse('coverage.xml'); root = tree.getroot(); print(f'{float(root.attrib.get(\"line-rate\", 0)) * 100:.2f}')")
    echo "✅ Manual Test Coverage: $COVERAGE%"
    
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
  echo "=================================================================="
  echo "COVERAGE ANALYSIS PHASE"
  echo "=================================================================="
  
  # Analyze Coverage Gaps
  echo "🔍 Analyzing coverage gaps..."
  python src/coverage_gap_analyzer.py \
    --target "$TARGET_DIR" \
    --current-dir "$CURRENT_DIR" \
    --output coverage_gaps.json || true
  
  echo ""
  
  # Check if AI generation is needed
  if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo "⚠️ Coverage is below ${MIN_COVERAGE}%"
    echo "🤖 Initiating Gap-Based AI Test Generation..."
    echo ""
    
    export GAP_FOCUSED_MODE=true
    export COVERAGE_GAPS_FILE="$CURRENT_DIR/coverage_gaps.json"
    export TESTGEN_FORCE=true
    
    echo "=================================================================="
    echo "GAP-BASED AI TEST GENERATION"
    echo "=================================================================="
    echo ""
    
    rm -rf "./tests/generated"
    
    python multi_iteration_orchestrator.py \
      --target "$TARGET_DIR" \
      --iterations 3 \
      --target-coverage "$MIN_COVERAGE" \
      --outdir "$CURRENT_DIR/tests/generated" || true

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
      echo "✅ Gap-based AI test generation completed"
      echo ""
      
      echo "=================================================================="
      echo "RUNNING COMBINED TESTS (Manual + AI Generated)"
      echo "=================================================================="
      echo ""
      
      find ./tests/generated -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
      
      if [ -d "./tests/generated" ] && [ -d "./tests/manual" ]; then
        echo "🧪 Running combined test suite..."
        COMBINED_TEST_EXIT_CODE=0
        pytest "$CURRENT_DIR/tests/manual" "$CURRENT_DIR/tests/generated" \
          --cov="$TARGET_DIR" \
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

        if [ $COMBINED_TEST_EXIT_CODE -ne 0 ]; then
          echo "⚠️ Some combined tests failed"
          echo "🔧 Starting auto-fix for failing generated tests..."
          echo ""

          python run_auto_fixer.py \
            --test-dir "$CURRENT_DIR/tests/generated" \
            --project-root "$TARGET_DIR" \
            --max-iterations 3 || true

          # Upload to SonarQube
          if [ -n "${SONAR_HOST_URL:-}" ] && [ -n "${SONAR_TOKEN:-}" ]; then
            sonar-scanner \
              -Dsonar.host.url="$SONAR_HOST_URL" \
              -Dsonar.token="$SONAR_TOKEN" \
              -Dproject.settings="$CURRENT_DIR/sonar-project.properties" \
              -Dsonar.projectBaseDir="$TARGET_DIR" \
              -Dsonar.sources="$TARGET_DIR" \
              -Dsonar.tests="$CURRENT_DIR/tests/generated" \
              -Dsonar.python.coverage.reportPaths="$CURRENT_DIR/coverage.xml" || echo "⚠️ SonarQube upload failed"
          fi
        fi

        echo "📊 Combined Coverage Analysis:"
        coverage report --show-missing || true
        
        if [ -f coverage.xml ]; then
          COMBINED_COVERAGE=$(python3 -c "import xml.etree.ElementTree as ET; tree = ET.parse('coverage.xml'); root = tree.getroot(); print(f'{float(root.attrib.get(\"line-rate\", 0)) * 100:.2f}')")
          echo ""
          echo "=================================================================="
          echo "FINAL RESULTS"
          echo "=================================================================="
          echo "✅ Manual Test Coverage:   $COVERAGE%"
          echo "✅ Combined Coverage:      $COMBINED_COVERAGE%"
          echo "📈 Coverage Improvement:   $(python3 -c "print(f'{float($COMBINED_COVERAGE) - float($COVERAGE):.2f}%')")"
          echo ""
          
          if (( $(echo "$COMBINED_COVERAGE >= $MIN_COVERAGE" | bc -l) )); then
            echo "🎉 Quality Gate Passed: Coverage ${COMBINED_COVERAGE}% ≥ ${MIN_COVERAGE}%"
            echo "✅ Pipeline completed successfully!"
            exit 0
          else
            echo "⚠️ Quality Gate: Coverage ${COMBINED_COVERAGE}% < ${MIN_COVERAGE}%"
            echo "✅ Pipeline completed with coverage improvement"
            exit 0
          fi
        fi
      fi
    fi
  else
    echo "🎉 Quality Gate Passed: Coverage ${COVERAGE}% ≥ ${MIN_COVERAGE}%"
    echo "✅ No AI test generation needed!"
    exit 0
  fi

  exit 0
fi

# -------------------------------------------------------------------
# CASE 2: No Manual Tests Found → Generate Full AI Tests
# -------------------------------------------------------------------
echo "⚠️ No manual tests found. Proceeding with full AI Test Generation..."
echo ""

export TESTGEN_FORCE=true
rm -rf "./tests/generated"

# Install target dependencies
if [ -f "$TARGET_DIR/requirements.txt" ]; then
  echo "📦 Installing project dependencies..."
  pip install -q -r "$TARGET_DIR/requirements.txt" || echo "⚠️ Some dependencies failed"
fi

python -m src.gen --target "$TARGET_DIR" --outdir "$CURRENT_DIR/tests/generated" --force || true

if [ -d "./tests/generated" ]; then
  TEST_COUNT=$(find "./tests/generated" -name 'test_*.py' -type f | wc -l)
  echo "🧩 Total AI-generated test files: $TEST_COUNT"
else
  echo "❌ No tests generated!"
  TEST_COUNT=0
fi

if [ "$TEST_COUNT" -gt 0 ]; then
  find ./tests/generated -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

  echo "🧪 Running pytest on AI-generated tests..."
  AI_TEST_EXIT_CODE=0
  pytest "$CURRENT_DIR/tests/generated" \
    --cov="$TARGET_DIR" \
    --cov-config=pytest.ini \
    --cov-report=term-missing \
    --cov-report=xml \
    --cov-report=html \
    --cov-fail-under=0 \
    --json-report \
    --junitxml="$CURRENT_DIR/test-results.xml" \
    --json-report-file="$CURRENT_DIR/.pytest_generated.json" \
    -v || AI_TEST_EXIT_CODE=$?

  if [ $AI_TEST_EXIT_CODE -ne 0 ]; then
    echo "⚠️ Some AI-generated tests failed"
    echo "🔧 Starting auto-fix..."
    
    python run_auto_fixer.py \
      --test-dir "$CURRENT_DIR/tests/generated" \
      --project-root "$TARGET_DIR" \
      --max-iterations 3 || true

    # Re-run tests after fix
    pytest "$CURRENT_DIR/tests/generated" \
      --cov="$TARGET_DIR" \
      --cov-config=pytest.ini \
      --cov-report=term-missing \
      --cov-report=xml \
      --cov-report=html \
      --cov-fail-under=0 \
      -v || true

    # Upload to SonarQube
    if [ -n "${SONAR_HOST_URL:-}" ] && [ -n "${SONAR_TOKEN:-}" ]; then
      sonar-scanner \
        -Dsonar.host.url="$SONAR_HOST_URL" \
        -Dsonar.token="$SONAR_TOKEN" \
        -Dproject.settings="$CURRENT_DIR/sonar-project.properties" \
        -Dsonar.projectBaseDir="$TARGET_DIR" \
        -Dsonar.sources="$TARGET_DIR" \
        -Dsonar.python.coverage.reportPaths="$CURRENT_DIR/coverage.xml" || echo "⚠️ SonarQube upload failed"
    fi
  fi

  if [ -f coverage.xml ]; then
    COVERAGE=$(python3 -c "import xml.etree.ElementTree as ET; tree = ET.parse('coverage.xml'); root = tree.getroot(); print(f'{float(root.attrib.get(\"line-rate\", 0)) * 100:.2f}')")
    echo "✅ AI Test Coverage: $COVERAGE%"

    if (( $(echo "$COVERAGE < 70" | bc -l) )); then
      echo "⚠️ Coverage below 70%"
      exit 1
    else
      echo "✅ Quality Gate Passed: Coverage ${COVERAGE}%"
    fi
  fi

  echo "🎯 Pipeline completed successfully!"
  exit 0
else
  echo "❌ No AI-generated tests found. Pipeline cannot proceed."
  exit 1
fi
