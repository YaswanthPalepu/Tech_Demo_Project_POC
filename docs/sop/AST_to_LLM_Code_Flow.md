# How AST is Used to Extract and Pass Actual Code to LLM

## Overview

You're correct - we **DO NOT pass the AST output directly to the LLM**. Instead, we use the AST to **identify and extract the actual source code**, then pass that source code to the LLM. This is a critical distinction.

---

## The Complete Flow: AST → Code Extraction → LLM

### Step 1: Parse Test File with AST

**File**: `src/auto_fixer/ast_context_extractor.py`

**Method**: `extract_context()`

```python
# Read the test file
with open(test_file_path, 'r') as f:
    test_content = f.read()

# Parse test file into AST
tree = ast.parse(test_content)  # ← AST is created here
```

**Purpose**: Create an Abstract Syntax Tree to analyze the test file structure

---

### Step 2: Extract Imports from AST

**Method**: `_extract_imports(tree: ast.AST) → Dict[str, str]`

**What the AST Finds**:
```python
# AST walks through the tree and finds:
for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        # import app.main as app_main
        # Extracts: name='app_main', module='app.main'

    elif isinstance(node, ast.ImportFrom):
        # from app.main import predict_batch
        # Extracts: name='predict_batch', module='app.main'
```

**Result**: Dictionary mapping import names to module paths
```python
{
    'app_main': 'app.main',
    'predict_batch': 'app.main',
    'User': 'models.user'
}
```

---

### Step 3: Extract Test Function Code (Actual Code, Not AST)

**Method**: `_extract_test_function(tree: ast.AST, func_name: str) → str`

**What Happens**:
```python
for node in ast.walk(tree):
    if isinstance(node, ast.FunctionDef) and node.name == func_name:
        # Found the test function node in AST
        # NOW CONVERT AST BACK TO ACTUAL SOURCE CODE
        return ast.unparse(node)  # ← RETURNS ACTUAL CODE STRING
```

**Example Output** (actual Python code string):
```python
"""
def test_predict_batch():
    result = predict_batch(['hello', 'world'])
    assert result is not None
"""
```

---

### Step 4: Resolve Imports to Source Files

**Method**: `_resolve_imports_to_files(imports: Set[str]) → List[str]`

**What Happens**:
```python
# Input: imports = {'app.main', 'models.user'}

# Convert module paths to file paths
# 'app.main' → 'app/main.py'
# 'models.user' → 'models/user.py'

# Returns: ['app/main.py', 'models/user.py']
```

**Key Function**: `_module_to_file(module_path: str)`
- Tries multiple variations (app.main → app/main.py, main.py, app.py, etc.)
- Checks which file actually exists
- Returns the actual file path

---

### Step 5: Build Source Map from Source File

**Method**: `_build_source_map(source_file: str) → Dict[str, Dict]`

**What Happens**:
```python
# Read the actual source file (NOT test file)
with open(source_file, 'r') as f:
    content = f.read()  # ← ACTUAL SOURCE CODE

# Parse source file into AST
tree = ast.parse(content)

# Walk through AST to index all definitions
source_map = {}
for node in tree.body:
    if isinstance(node, ast.FunctionDef):
        name = node.name  # e.g., 'predict_batch'

        # IMPORTANT: Extract the ACTUAL CODE for this function
        code = ast.unparse(node)  # ← ACTUAL FUNCTION CODE

        source_map[name] = {
            'node': node,           # AST node (for further analysis)
            'line_start': node.lineno,
            'line_end': node.end_lineno,
            'code': code            # ← ACTUAL SOURCE CODE STRING
        }
```

**Example Source Map**:
```python
{
    'predict_batch': {
        'node': <ast.FunctionDef object>,
        'line_start': 45,
        'line_end': 67,
        'code': """def predict_batch(texts):
    \"\"\"Process multiple texts.\"\"\"
    results = []
    for text in texts:
        result = MODEL.predict(text)
        results.append(result)
    return results"""
    },
    'validate_sentence': {
        'node': <ast.FunctionDef object>,
        'line_start': 70,
        'line_end': 85,
        'code': """def validate_sentence(text):
    if not text or len(text) < 5:
        raise ValueError("Text too short")
    return True"""
    }
}
```

---

### Step 6: Extract Relevant Code (Actual Code Based on AST Analysis)

**Method**: `_extract_relevant_code_targeted()`

**What Happens**:

1. **Identify Target Functions** (using AST analysis):
```python
# From test imports: ['predict_batch', 'validate_sentence']
# From error traceback: ['predict_batch', 'sanitize_input']
# Combined targets: {'predict_batch', 'validate_sentence', 'sanitize_input'}
```

2. **Find Dependencies** (using AST):
```python
def _find_dependencies(node: ast.AST, source_map: Dict) → Set[str]:
    dependencies = set()

    # Walk through function AST to find what it calls
    for child in ast.walk(node):
        if isinstance(child, ast.Name):
            name = child.id  # e.g., 'MODEL'
            if name in source_map:
                dependencies.add(name)  # Found dependency!

    return dependencies
```

3. **Extract Actual Code** (NOT AST):
```python
extracted = []

# Priority 1: Target functions (ACTUAL CODE)
for target in target_names:
    if target in source_map:
        code = source_map[target]['code']  # ← ACTUAL CODE STRING
        extracted.append(code)

# Priority 2: Dependencies (ACTUAL CODE)
for dep in dependencies:
    if dep in source_map:
        code = source_map[dep]['code']  # ← ACTUAL CODE STRING
        extracted.append(code)

# Combine all extracted code
result = "\n\n".join(extracted)
```

**Example Result** (actual Python code):
```python
"""
# function: predict_batch (line 45)
def predict_batch(texts):
    \"\"\"Process multiple texts.\"\"\"
    results = []
    for text in texts:
        result = MODEL.predict(text)
        results.append(result)
    return results

# function: validate_sentence (line 70)
def validate_sentence(text):
    if not text or len(text) < 5:
        raise ValueError("Text too short")
    return True

# constant: MODEL (line 15)
MODEL = None
"""
```

---

### Step 7: Build Prompt with Actual Code

**File**: `src/gen/enhanced_prompt.py`

**Method**: `build_prompt(kind, compact_json, focus_label, shard, total, compact, context)`

**What Gets Passed**:

```python
def build_prompt(..., context: str):
    # context parameter contains ACTUAL SOURCE CODE (not AST)
    # This code was extracted in Step 6

    trimmed_context = context[:60000]  # Limit to 60k chars

    user_content = f"""
UNIVERSAL {kind.upper()} TEST GENERATION - FILE {shard + 1}/{total}

{dev_instructions}
{merged_rules}

FOCUS TARGETS: {focus_label}
PROJECT ANALYSIS: {compact_json}

ADDITIONAL CONTEXT (TRIMMED): {trimmed_context}
                              ↑↑↑
                   THIS IS ACTUAL SOURCE CODE
                   extracted using AST analysis

{UNIVERSAL_SCAFFOLD}
"""

    return [
        {"role": "system", "content": SYSTEM_MIN_LOCAL},
        {"role": "user", "content": user_content}  # ← SENT TO LLM
    ]
```

---

## Complete Example Flow

### Input Test File:
```python
# tests/test_app.py
from app.main import predict_batch

def test_predict_batch():
    result = predict_batch(['hello'])
    assert result is not None
```

### Step-by-Step Processing:

**1. AST Parses Test File**
- Finds import: `from app.main import predict_batch`
- Finds test function: `test_predict_batch`

**2. Resolve Import to File**
- `app.main` → `app/main.py`

**3. AST Parses Source File (`app/main.py`)**
```python
# app/main.py (actual file)
MODEL = None

def load_model():
    global MODEL
    MODEL = "loaded"

def predict_batch(texts):
    if MODEL is None:
        load_model()
    results = []
    for text in texts:
        results.append(f"result:{text}")
    return results
```

**4. Build Source Map**
```python
{
    'MODEL': {
        'code': 'MODEL = None',
        'line_start': 1
    },
    'load_model': {
        'code': 'def load_model():\n    global MODEL\n    MODEL = "loaded"',
        'line_start': 3
    },
    'predict_batch': {
        'code': 'def predict_batch(texts):\n    if MODEL is None:\n...',
        'line_start': 8
    }
}
```

**5. Extract Relevant Code**
- Target: `predict_batch` (from imports)
- Dependencies: `MODEL`, `load_model` (from AST analysis)

**6. Actual Code Sent to LLM**:
```python
"""
# constant: MODEL (line 1)
MODEL = None

# function: load_model (line 3)
def load_model():
    global MODEL
    MODEL = "loaded"

# function: predict_batch (line 8)
def predict_batch(texts):
    if MODEL is None:
        load_model()
    results = []
    for text in texts:
        results.append(f"result:{text}")
    return results
"""
```

---

## Key Points

### 1. AST is Used for ANALYSIS, Not as Final Output
- ✅ AST identifies structure (imports, functions, dependencies)
- ✅ AST locates where code is defined (line numbers)
- ❌ AST output is NOT sent to LLM

### 2. Actual Code is Extracted Using AST
- `ast.unparse(node)` converts AST node back to source code
- File is read using `open(file).read()`
- Source code strings are extracted and combined

### 3. LLM Receives Real Python Code
- Input: Actual function/class source code (strings)
- Format: Valid Python code with comments
- No AST representation in the prompt

### 4. The Role of Each Component

| Component | Input | Output |
|-----------|-------|--------|
| **AST Parser** | Source file string | AST tree (for analysis) |
| **Import Extractor** | AST tree | Module paths `{'app.main': ...}` |
| **File Resolver** | Module paths | File paths `['app/main.py']` |
| **Source Map Builder** | Source file | `{func_name: {code: "actual code"}}` |
| **Code Extractor** | Source map | Actual source code string |
| **Prompt Builder** | Actual code | Prompt for LLM |
| **LLM** | Prompt with code | Generated tests |

---

## Summary

**Question**: "After AST, how do we pass actual code to LLM?"

**Answer**:
1. AST **analyzes** the test file to find imports and dependencies
2. AST **parses** the source file to build a map of all definitions
3. **`ast.unparse()`** converts AST nodes back to **actual source code**
4. Code extraction logic **selects relevant functions** based on AST analysis
5. **Actual source code strings** are combined and passed to LLM in the prompt

**We use AST as a tool to find and extract code, then pass the actual code (not AST) to the LLM.**
