# Coverage Gap Test Generation: How Uncovered Code Gets to LLM

## Your Question
**"For uncovered part AI test generation also takes entire file to generate or how it generate?"**

## Answer: YES, Still Reads Entire Files - BUT with Critical Differences

Coverage gap test generation **STILL reads entire files** just like initial test generation, but with intelligent filtering and targeting to focus ONLY on uncovered code.

---

## 🔍 The Complete Flow

### Step 1: Coverage Analysis (Find What's Missing)

**File**: `src/coverage_gap_analyzer.py`

```python
def _parse_coverage_xml(self, coverage_data):
    for cls in package.findall(".//class"):
        for line in cls.findall(".//line"):
            line_num = int(line.attrib.get("number", 0))
            hits = int(line.attrib.get("hits", 0))

            if hits > 0:
                file_coverage["covered_lines"].add(line_num)  # ✓ Covered
            else:
                file_coverage["missing_lines"].add(line_num)  # ✗ Uncovered
```

**What It Does**:
1. Parses `coverage.xml` from manual tests
2. Identifies **exact line numbers** that are uncovered
3. Example: `app.py lines 45-52, 78-85` are uncovered

**Output**: `coverage_gaps.json`
```json
{
  "overall_coverage": 67.5,
  "uncovered_lines_by_file": {
    "app.py": [45, 46, 47, 48, 49, 50, 51, 52, 78, 79, 80, 81, 82, 83, 84, 85]
  }
}
```

---

### Step 2: AST Cross-Reference (Which Functions Are Uncovered?)

**File**: `src/coverage_gap_analyzer.py:239-290`

```python
def _identify_uncovered_elements(self, source_file, source_path, uncovered_lines):
    source_code = source_path.read_text()
    tree = ast.parse(source_code)  # ← Parse with AST

    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            func_lines = set(range(node.lineno, node.end_lineno + 1))

            # Check if function has uncovered lines
            if func_lines & uncovered_lines:
                coverage_data["uncovered_functions"].append({
                    "file": source_file,
                    "name": node.name,
                    "line_start": node.lineno,
                    "line_end": node.end_lineno,
                    "uncovered_lines": sorted(func_lines & uncovered_lines)
                })
```

**What It Does**:
- Uses AST to find all functions/classes in source files
- Cross-references with uncovered line numbers
- Identifies **which specific functions/classes** need tests

**Output**:
```json
{
  "uncovered_functions": [
    {
      "file": "app.py",
      "name": "process_payment",
      "line_start": 45,
      "line_end": 52,
      "uncovered_lines": [45, 46, 47, 48, 49, 50, 51, 52]
    },
    {
      "file": "app.py",
      "name": "validate_user",
      "line_start": 78,
      "line_end": 85,
      "uncovered_lines": [78, 79, 80, 81, 82, 83, 84, 85]
    }
  ]
}
```

---

### Step 3: Filter Analysis (Remove Already-Covered Code)

**File**: `src/gen/gap_aware_analysis.py:54-233`

```python
def filter_analysis_by_coverage_gaps(full_analysis, coverage_gaps):
    # Build lookup of uncovered functions
    uncovered_func_keys = {
        (func["file"], func["name"])
        for func in coverage_gaps["uncovered_functions"]
    }

    gap_focused_analysis = {"functions": [], "classes": [], ...}

    # ONLY include uncovered functions
    for func in full_analysis.get("functions", []):
        func_key = (func.get("file"), func.get("name"))
        if func_key in uncovered_func_keys:  # ← Filter check
            # Add coverage metadata
            func_with_gaps = func.copy()
            func_with_gaps["coverage_gaps"] = {
                "uncovered_lines": [45, 46, 47, 48, 49, 50, 51, 52]
            }
            gap_focused_analysis["functions"].append(func_with_gaps)

    return gap_focused_analysis
```

**What It Does**:
- Takes the FULL AST analysis (all 43 targets)
- Filters to ONLY uncovered targets (maybe 8 uncovered)
- Adds `coverage_gaps` metadata to each target

**Example**:
```
Full Analysis: 20 functions, 14 classes, 9 routes (43 total)
                    ↓ FILTER by coverage_gaps.json
Gap Analysis:  2 functions, 3 classes, 1 route (6 uncovered)
               ↓
               Only these 6 will be used for test generation
```

---

### Step 4: Read Files (YES, Still Entire Files)

**File**: `src/gen/enhanced_generate.py:464-486`

```python
def _gather_universal_context(target_root, analysis, focus_names, max_bytes=120000):
    relevant_files = set()

    # Collect files containing uncovered targets
    for target_name in focus_names:  # ← Only uncovered targets
        for idx in (function_index, class_index, method_index):
            if target_name in idx:
                file_rel, _, _ = idx[target_name]
                relevant_files.add(file_rel)

    # Read ENTIRE file content
    for file_rel in sorted(relevant_files):
        path = target_root / file_rel
        content = path.read_text()  # ← READS ENTIRE FILE
        snippet = f"# FILE: {file_rel}\n{content}\n"
        context_parts.append(snippet)
```

**What It Does**:
- ✅ STILL reads **entire files** as strings
- ❌ Does NOT extract only uncovered lines
- ✓ BUT only reads files that contain uncovered targets

**Why Read Entire Files?**
Same reasons as initial test generation:
1. LLM needs context (imports, dependencies, related functions)
2. Can't test `process_payment()` without seeing what it calls
3. Easier for LLM to understand full file structure

---

### Step 5: Add Coverage Instructions to Prompt

**File**: `src/gen/gap_aware_analysis.py:236-302`

```python
def enhance_prompt_with_coverage_context(coverage_gaps):
    context_lines = []

    context_lines.append("CRITICAL: GAP-FOCUSED TEST GENERATION MODE")
    context_lines.append(f"Current Coverage: {coverage_gaps['overall_coverage']:.2f}%")
    context_lines.append(f"Target: 90%+")
    context_lines.append("")

    context_lines.append("CRITICAL INSTRUCTIONS:")
    context_lines.append("1. Generate tests ONLY for uncovered code sections below")
    context_lines.append("2. DO NOT generate tests for already-covered code")
    context_lines.append("3. Focus tests on hitting specific uncovered line numbers")
    context_lines.append("")

    # List specific uncovered functions
    for func in coverage_gaps["uncovered_functions"]:
        context_lines.append(f"🔧 {func['file']}::{func['name']} (lines {func['line_start']}-{func['line_end']})")
        context_lines.append(f"   Uncovered Lines: {', '.join(map(str, func['uncovered_lines']))}")
```

**What It Does**:
- Builds **explicit instructions** for the LLM
- Lists specific uncovered functions with line numbers
- Added to the beginning of the prompt

---

### Step 6: Final Prompt to LLM

```
================================================================================
CRITICAL: GAP-FOCUSED TEST GENERATION MODE
================================================================================

CURRENT SITUATION:
- Existing manual test coverage: 67.50%
- Target coverage: 90%+
- Gap to fill: 22.50%
- Uncovered statements: 85

CRITICAL INSTRUCTIONS:
1. Generate tests ONLY for uncovered code sections specified below
2. DO NOT generate tests for already-covered code
3. Focus tests on hitting specific uncovered line numbers

UNCOVERED FUNCTIONS (Must Test):
--------------------------------------------------------------------------------
🔧 app.py::process_payment (lines 45-52)
   Uncovered Lines: 45, 46, 47, 48, 49, 50, 51, 52

🔧 app.py::validate_user (lines 78-85)
   Uncovered Lines: 78, 79, 80, 81, 82, 83, 84, 85

================================================================================

# UNIVERSAL PROJECT STRUCTURE
# Root: /project
# Relevant Files: 2

# FILE: app.py
# FULL CONTENT FOR UNIVERSAL COMPATIBILITY
def calculate_total(items):
    return sum(item.price for item in items)

def process_payment(amount, method):  # ← Lines 45-52 UNCOVERED
    if method == "credit":
        charge_credit_card(amount)
    elif method == "cash":
        process_cash(amount)
    return True

def validate_user(username, password):  # ← Lines 78-85 UNCOVERED
    if len(password) < 8:
        return False
    # ... more code
    return True
```

---

## 🎯 Key Differences from Initial Test Generation

| Aspect | Initial Test Generation | Coverage Gap Generation |
|--------|------------------------|------------------------|
| **AST Filtering** | All functions/classes/routes | **ONLY uncovered** functions/classes |
| **File Reading** | Entire files with targets | Entire files with **uncovered** targets |
| **Number of Files** | All relevant files (maybe 10) | Only files with gaps (maybe 3) |
| **Prompt Instructions** | "Generate comprehensive tests" | **"ONLY test lines 45-52, 78-85"** |
| **Target Count** | 43 targets → 5 test files | 6 uncovered → 1 test file |
| **LLM Focus** | Test everything | **Focus on specific line numbers** |

---

## 📊 Real Example with Your Data

### Scenario
```
Initial Analysis: 20 functions, 14 classes, 9 routes (43 total)
Manual Test Coverage: 67.5% (29 targets covered, 14 uncovered)
```

### Coverage Gap Flow

**1. Coverage Analysis identifies:**
```json
{
  "overall_coverage": 67.5,
  "uncovered_functions": [
    {"file": "app.py", "name": "process_payment", "uncovered_lines": [45-52]},
    {"file": "app.py", "name": "validate_user", "uncovered_lines": [78-85]},
    {"file": "utils.py", "name": "format_date", "uncovered_lines": [12-18]}
  ],
  "uncovered_classes": [
    {"file": "models.py", "name": "User", "uncovered_methods": ["validate", "save"]}
  ]
}
```

**2. Filter Analysis:**
```
Original: 43 targets
    ↓ Filter to uncovered only
Gap-Focused: 6 targets (3 functions, 1 class with 2 methods, 1 route)
    ↓ 85.7% reduction
```

**3. Read Files:**
```python
# Reads ENTIRE FILES but ONLY these 2:
- app.py (contains process_payment, validate_user)
- models.py (contains User class)

# Does NOT read these 8 files (100% covered):
- auth.py ✓
- database.py ✓
- routes.py ✓
- ... (5 more covered files)
```

**4. LLM receives:**
```
PROMPT:
"Test ONLY these 6 uncovered targets:
- app.py::process_payment (lines 45-52)
- app.py::validate_user (lines 78-85)
- utils.py::format_date (lines 12-18)
- models.py::User.validate (lines 34-42)
- models.py::User.save (lines 50-58)
- routes.py::update_profile (lines 120-135)"

CONTEXT:
[Entire content of app.py, models.py, utils.py, routes.py]
```

---

## 💡 Summary: Does It Read Entire Files?

### ✅ YES - Still Reads Entire Files
- Same file reading mechanism as initial generation
- Passes complete file content as strings to LLM
- LLM sees all code, not just uncovered lines

### 🎯 BUT - With Critical Targeting
1. **Filtered targets**: Only uncovered functions/classes in analysis
2. **Fewer files**: Only files containing gaps
3. **Explicit instructions**: "ONLY test lines 45-52, 78-85"
4. **Coverage metadata**: Each target has `uncovered_lines` field
5. **No waste**: LLM knows which code to ignore

### 🔑 Why This Approach Works

**Without entire files:**
```python
# LLM only sees:
def process_payment(amount, method):
    if method == "credit":
        charge_credit_card(amount)  # ← What is charge_credit_card?
```

**With entire files:**
```python
# LLM sees full context:
from payment_processor import charge_credit_card  # ← Ah, imported function
from cash_handler import process_cash

def process_payment(amount, method):
    if method == "credit":
        charge_credit_card(amount)  # ← Now LLM can test this properly
```

---

## 📁 Related Files

- **Coverage Analysis**: `src/coverage_gap_analyzer.py`
- **Gap Filtering**: `src/gen/gap_aware_analysis.py`
- **File Reading**: `src/gen/enhanced_generate.py:404-508` (`_gather_universal_context`)
- **Prompt Building**: `src/gen/gap_aware_analysis.py:236-302` (`enhance_prompt_with_coverage_context`)

---

## 🔗 See Also

- [Test_Generation_AST_to_LLM_Flow.md](./Test_Generation_AST_to_LLM_Flow.md) - Initial test generation flow
- [AST_Sharding_Distribution.md](./AST_Sharding_Distribution.md) - How targets are batched
- [AST_Provides_Targeting_Instructions.md](./AST_Provides_Targeting_Instructions.md) - How AST affects prompts
