# GIT-BASED SMART TEST GENERATION APPROACH
## Intelligent Test Generation with Change Detection

---

## 🎯 **OBJECTIVE**

Create a smart system that:
1. ✅ **Detects code changes** via git diff
2. ✅ **Updates existing tests** when code is modified (not regenerate everything)
3. ✅ **Generates new tests** for new code
4. ✅ **Uses coverage gaps** to find uncovered lines in both old and new code
5. ✅ **Removes stale tests** when code is deleted

---

## 🏗️ **ARCHITECTURE**

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: GIT CHANGE DETECTION                               │
│  - Compare current commit with last test generation commit  │
│  - Identify: Modified files, New files, Deleted files       │
│  - Parse AST to detect function-level changes               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: TEST-CODE MAPPING                                  │
│  - Load metadata from .test_metadata.json                   │
│  - Map which tests cover which code                         │
│  - Identify orphaned tests (code deleted)                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: RUN EXISTING TESTS & ANALYZE COVERAGE             │
│  - Run manual + existing AI tests                          │
│  - Generate coverage report                                 │
│  - Identify uncovered lines in ALL code (old + new)        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: SMART TEST UPDATE/GENERATION                      │
│                                                             │
│  For MODIFIED code:                                         │
│    → LLM updates existing test (context-aware)             │
│    → Keeps test structure, updates assertions               │
│                                                             │
│  For NEW code:                                              │
│    → Generate new tests                                     │
│                                                             │
│  For UNCOVERED lines (via coverage):                        │
│    → Generate tests for specific uncovered lines           │
│    → Even in "tested" functions                            │
│                                                             │
│  For DELETED code:                                          │
│    → Remove corresponding tests                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: UPDATE METADATA                                    │
│  - Save test-to-code mappings                               │
│  - Save current commit hash                                 │
│  - Save coverage information                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 **COMPONENTS TO BUILD**

### 1. **Git Change Detector** (`src/git_change_detector.py`)

**Purpose**: Detect what changed since last test generation

**Features**:
- Compare current commit with last test generation commit
- Detect modified/new/deleted files
- Parse AST to detect function-level changes
- Classify changes: MODIFIED, NEW, DELETED

**Input**:
- Current commit hash
- Last test generation commit (from metadata)

**Output**:
```json
{
  "last_commit": "abc123",
  "current_commit": "def456",
  "changes": {
    "modified": [
      {
        "file": "calculator.py",
        "functions": {
          "add": "modified",
          "subtract": "unchanged"
        }
      }
    ],
    "new": [
      {
        "file": "advanced_calc.py",
        "functions": ["multiply", "divide"]
      }
    ],
    "deleted": [
      {
        "file": "old_calc.py",
        "functions": ["deprecated_func"]
      }
    ]
  }
}
```

---

### 2. **Test-Code Mapper** (`src/test_code_mapper.py`)

**Purpose**: Track which tests cover which code

**Metadata Format** (`.test_metadata.json`):
```json
{
  "generated_at": "2025-12-11T10:30:00Z",
  "last_commit": "abc123",
  "test_mappings": {
    "target_repo/calculator.py": {
      "code_hash": "hash123",
      "functions": {
        "add": {
          "covered_by": ["tests/generated/test_calculator.py::test_add"],
          "coverage": 100,
          "uncovered_lines": []
        },
        "subtract": {
          "covered_by": ["tests/generated/test_calculator.py::test_subtract"],
          "coverage": 80,
          "uncovered_lines": [15, 16, 17]
        }
      }
    }
  }
}
```

**Features**:
- Load/save metadata
- Map tests to code
- Identify orphaned tests
- Track coverage per function

---

### 3. **Coverage Gap Analyzer (Enhanced)**

**Purpose**: Find uncovered lines even in "tested" code

**Current**: Finds uncovered files/functions
**Enhanced**: Finds uncovered lines in SPECIFIC functions

**Example**:
```python
def add(a, b):
    """Add two numbers"""
    if a < 0:           # Line 10 - COVERED
        raise ValueError
    if b < 0:           # Line 12 - UNCOVERED ❌
        raise ValueError
    return a + b        # Line 14 - COVERED
```

**Output**:
```json
{
  "calculator.py::add": {
    "total_lines": 5,
    "covered_lines": [10, 14],
    "uncovered_lines": [12, 13],
    "coverage_percentage": 60
  }
}
```

---

### 4. **Smart Test Updater** (`src/smart_test_updater.py`)

**Purpose**: Update existing tests when code changes (instead of regenerating)

**How it works**:

For MODIFIED code:
```python
# OLD CODE:
def add(a, b):
    return a + b

# EXISTING TEST:
def test_add():
    assert add(2, 3) == 5

# NEW CODE (modified):
def add(a, b):
    if a < 0 or b < 0:
        raise ValueError("No negatives")
    return a + b

# LLM UPDATES TEST (preserves structure):
def test_add():
    assert add(2, 3) == 5
    # NEW: Added test for validation
    with pytest.raises(ValueError):
        add(-1, 2)
```

**LLM Prompt**:
```
You are updating an existing test because the source code changed.

OLD CODE:
{old_code}

NEW CODE:
{new_code}

EXISTING TEST:
{existing_test}

CHANGES DETECTED:
- Added validation for negative numbers

Task: Update the test to cover the new code behavior.
Rules:
1. KEEP the existing test structure
2. ADD new test cases for new behavior
3. UPDATE assertions if logic changed
4. DO NOT remove existing valid tests
```

---

### 5. **Gap-Based Test Generator** (existing, enhanced)

**Purpose**: Generate tests for:
- NEW functions
- UNCOVERED lines in existing functions

**Integration**:
```python
# For NEW function
generate_test_for_function(function_name, function_code)

# For UNCOVERED lines in existing function
generate_test_for_uncovered_lines(
    function_name,
    function_code,
    uncovered_lines=[12, 13]
)
```

---

## 🔄 **COMPLETE WORKFLOW**

### **Day 1: Initial Run**

```bash
# No metadata exists → Full generation
1. Detect: No .test_metadata.json
2. Generate tests for ALL code
3. Save metadata with commit hash
4. Result: 100% coverage
```

---

### **Day 2: Developer Modifies `add()` Function**

```bash
Git changes:
  - calculator.py::add → MODIFIED
  - calculator.py::subtract → UNCHANGED

1. Git Change Detector:
   → Detects add() modified

2. Load Metadata:
   → add() covered by test_calculator.py::test_add

3. Run Existing Tests:
   → test_add FAILS (code changed)
   → Coverage for add() = 60% (new validation uncovered)

4. Smart Test Updater:
   → LLM reads: old code, new code, existing test
   → Updates test_add to include new validation cases
   → Runs updated test → PASSES ✅

5. Coverage Gap Analyzer:
   → Still finds uncovered lines 12-13 in add()

6. Gap-Based Generator:
   → Generates ADDITIONAL test for lines 12-13
   → Adds test_add_edge_cases()

7. Update Metadata:
   → add() covered by: test_add, test_add_edge_cases
   → Coverage: 100%
   → Save commit hash
```

---

### **Day 3: Developer Adds `multiply()` Function**

```bash
Git changes:
  - calculator.py::multiply → NEW

1. Git Change Detector:
   → Detects multiply() is new

2. Gap-Based Generator:
   → Generates test_multiply()

3. Run Tests:
   → All pass, coverage 100%

4. Update Metadata:
   → multiply() covered by: test_multiply
```

---

### **Day 4: Developer Deletes `deprecated_calc.py`**

```bash
Git changes:
  - deprecated_calc.py → DELETED

1. Git Change Detector:
   → File deleted

2. Test-Code Mapper:
   → Finds tests/generated/test_deprecated_calc.py

3. Cleanup:
   → Removes test_deprecated_calc.py

4. Update Metadata:
   → Remove deprecated_calc.py entries
```

---

## 🎯 **WHY THIS IS BETTER**

| Aspect | Current (Full Regen) | Smart Detection |
|--------|---------------------|-----------------|
| **Speed** | Regenerates ALL tests | Only updates changed code |
| **Test Quality** | Loses context | Preserves test structure |
| **Duplicates** | Can create duplicates | No duplicates |
| **Coverage** | Gap-based only | Gap-based + smart updates |
| **Efficiency** | Slow for large codebases | Fast, incremental |

---

## 🔧 **IMPLEMENTATION FILES**

```
src/
├── git_change_detector.py         ← NEW: Detect code changes
├── test_code_mapper.py             ← NEW: Track test-code mappings
├── smart_test_updater.py           ← NEW: Update existing tests
├── coverage_gap_analyzer.py        ← ENHANCE: Find uncovered lines
├── gap_based_generator.py          ← ENHANCE: Generate for gaps
└── smart_test_orchestrator.py      ← NEW: Coordinate all components

pipeline_runner.sh                  ← UPDATE: Use smart orchestrator
.test_metadata.json                 ← NEW: Track mappings
```

---

## 📋 **UNCOVERED LINES USE CASE**

**Question**: "What's the use of uncovered lines test generation?"

**Answer**: Even "tested" functions can have uncovered edge cases!

**Example**:

```python
def process_payment(amount, currency="USD"):
    """Process payment"""
    if amount <= 0:                    # Line 10
        raise ValueError("Invalid")

    if currency == "USD":              # Line 13 - COVERED
        return amount * 1.0
    elif currency == "EUR":            # Line 15 - UNCOVERED ❌
        return amount * 0.85
    elif currency == "GBP":            # Line 17 - UNCOVERED ❌
        return amount * 0.73

    return amount                      # Line 19 - COVERED
```

**Existing Test**:
```python
def test_process_payment():
    assert process_payment(100, "USD") == 100.0
    # Only covers USD path!
```

**Coverage Report**:
- Function: process_payment ✅ (has test)
- Coverage: 40% (lines 15, 17 uncovered)

**Smart System**:
1. Detects function is tested but has gaps
2. Generates ADDITIONAL test for uncovered lines:
```python
def test_process_payment_currency_conversion():
    # Cover line 15
    assert process_payment(100, "EUR") == 85.0
    # Cover line 17
    assert process_payment(100, "GBP") == 73.0
```

**Result**: 100% coverage for process_payment()

---

## ✅ **BENEFITS SUMMARY**

1. ✅ **Smart Updates**: Modifies tests instead of regenerating
2. ✅ **Faster**: Only processes changed code
3. ✅ **Better Tests**: Preserves test structure and context
4. ✅ **Complete Coverage**: Finds gaps even in "tested" code
5. ✅ **No Duplicates**: Tracks what's tested
6. ✅ **Clean Codebase**: Removes stale tests automatically

---

## 🚀 **NEXT STEPS**

If approved, I will implement:

1. ✅ `git_change_detector.py` - Detect code changes
2. ✅ `test_code_mapper.py` - Track test mappings
3. ✅ `smart_test_updater.py` - Update existing tests
4. ✅ Enhance `coverage_gap_analyzer.py` - Find uncovered lines
5. ✅ `smart_test_orchestrator.py` - Coordinate everything
6. ✅ Update `pipeline_runner.sh` - Integrate smart system

**Do you approve this approach?**
