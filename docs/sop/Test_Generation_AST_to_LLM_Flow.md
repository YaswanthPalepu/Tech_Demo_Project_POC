# Test Generation: How Actual Source Code is Passed to LLM

## Overview

For **TEST GENERATION**, we use AST to analyze and extract **METADATA** (function names, line numbers, file paths), then we **READ THE ACTUAL SOURCE FILES** and pass that real code to the LLM.

**Key Point**: AST is used for analysis and indexing. The actual source code is read from files and passed to LLM.

---

## Complete Test Generation Flow

### Step 1: Analyze Project with AST (Metadata Extraction)

**File**: `src/analyzer.py`

**Function**: `analyze_python_tree(root: pathlib.Path)`

```python
# Find all Python files
files = [p for p in root.rglob("*.py") if not _should_skip(p, root)]

for f in files:
    # READ source file
    code = read_text(f)  # ← Read actual file content

    # PARSE into AST
    tree = ast.parse(code)  # ← AST for analysis only

    # EXTRACT METADATA (not actual code)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            func_rec = {
                "name": node.name,           # ← Just the name
                "file": rel_path,            # ← Just the file path
                "lineno": node.lineno,       # ← Just the line number
                "end_lineno": node.end_lineno,
                "is_async": isinstance(node, ast.AsyncFunctionDef),
                # ... other metadata
            }
            out["functions"].append(func_rec)  # ← Store metadata
```

**What Gets Stored**:
```python
{
    "functions": [
        {
            "name": "predict_batch",
            "file": "app/main.py",
            "lineno": 45,
            "end_lineno": 67,
            "is_async": False
        },
        {
            "name": "validate_sentence",
            "file": "app/main.py",
            "lineno": 70,
            "end_lineno": 85,
            "is_async": False
        }
    ],
    "classes": [...],
    "methods": [...],
    "routes": [...]
}
```

**NOTE**: This is **METADATA ONLY** - no actual source code yet!

---

### Step 2: Determine Focus Targets

**File**: `src/gen/enhanced_prompt.py`

**Function**: `focus_for(compact, kind, shard_idx, total_shards)`

```python
# Get targets for this test shard
target_list = functions + classes + methods  # Metadata objects

# Extract just the names
target_names = []
for t in shard_targets:
    name = t.get("name")
    if name:
        target_names.append(name)  # ← Just names: ['predict_batch', 'validate_sentence']
```

**Result**: List of target names to generate tests for
```python
focus_names = ['predict_batch', 'validate_sentence', 'sanitize_input']
```

---

### Step 3: Gather Actual Source Code

**File**: `src/gen/enhanced_generate.py`

**Function**: `_gather_universal_context(target_root, analysis, focus_names, max_bytes)`

**THIS IS WHERE ACTUAL CODE IS READ**:

```python
def _gather_universal_context(target_root, analysis, focus_names, max_bytes=120000):
    # Build indices from metadata
    function_index = _gen__index(analysis.get("functions", []), "name")
    # function_index = {'predict_batch': ('app/main.py', 45, 67), ...}

    # Find which files contain the target functions
    relevant_files = set()
    for target_name in focus_names:
        if target_name in function_index:
            file_rel, _, _ = function_index[target_name]  # Get file path
            relevant_files.add(file_rel)  # ← 'app/main.py'

    context_parts = []

    # READ ACTUAL SOURCE CODE FROM FILES
    for file_rel in sorted(relevant_files):
        path = target_root / file_rel  # ← Full path to source file

        # READ THE ENTIRE SOURCE FILE AS STRING
        content = path.read_text(encoding="utf-8", errors="ignore")  # ← ACTUAL CODE

        # Create snippet with file path and FULL CONTENT
        snippet = (
            f"# FILE: {file_rel}\n"
            f"# FULL CONTENT FOR UNIVERSAL COMPATIBILITY\n"
            f"{content}\n\n"  # ← ACTUAL SOURCE CODE STRING
            f"{'=' * 80}\n\n"
        )

        context_parts.append(snippet)  # ← Add actual code to context

    # Combine all actual source code
    full_context = "".join(context_parts)
    return full_context  # ← Returns actual Python source code as string
```

**Example Output** (actual source code string):
```python
"""
# FILE: app/main.py
# FULL CONTENT FOR UNIVERSAL COMPATIBILITY
import re
from typing import List, Optional

MODEL = None

def load_model():
    global MODEL
    MODEL = initialize_model()
    return MODEL

def predict_batch(texts: List[str]) -> List[str]:
    \"\"\"Process multiple texts.\"\"\"
    if MODEL is None:
        load_model()

    results = []
    for text in texts:
        result = MODEL.predict(text)
        results.append(result)
    return results

def validate_sentence(text: str) -> bool:
    if not text or len(text) < 5:
        raise ValueError("Text too short")
    return True

def sanitize_input(text: str) -> str:
    return re.sub(r'[^\w\s]', '', text)

================================================================================
"""
```

---

### Step 4: Build Prompt with Actual Code

**File**: `src/gen/enhanced_generate.py` (line 677-680)

```python
# Gather actual source code
context = _gather_universal_context(target_root, filtered_analysis, focus_names)
                                    # ↑ Returns actual source code string

# Build prompt with actual code
prompt_messages = build_prompt(
    test_kind,
    compact_json,     # Metadata as JSON
    focus_label,
    file_index,
    num_files,
    compact,
    context           # ← ACTUAL SOURCE CODE STRING passed here
)
```

**File**: `src/gen/enhanced_prompt.py` (line 260-312)

```python
def build_prompt(kind, compact_json, focus_label, shard, total, compact, context=""):
    # Trim context if too large
    trimmed_context = context[:60000] if context else ""
                      # ↑ This is ACTUAL SOURCE CODE (not AST)

    # Build user prompt
    user_content = f"""
UNIVERSAL {kind.upper()} TEST GENERATION - FILE {shard + 1}/{total}

{dev_instructions}
{merged_rules}

FOCUS TARGETS: {focus_label}
PROJECT ANALYSIS: {compact_json}

ADDITIONAL CONTEXT (TRIMMED): {trimmed_context}
                              ↑↑↑
                   THIS IS ACTUAL SOURCE CODE
                   (read from files, not AST)

{UNIVERSAL_SCAFFOLD}
"""

    return [
        {"role": "system", "content": SYSTEM_MIN_LOCAL},
        {"role": "user", "content": user_content}  # ← Contains actual code
    ]
```

---

### Step 5: LLM Receives Actual Code

**File**: `src/gen/enhanced_generate.py` (line 682)

```python
# Generate tests using LLM
test_code = _generate_with_universal_retry(prompt_messages, max_attempts=3)
```

**File**: `src/gen/enhanced_generate.py` (line 222)

```python
def _generate_with_universal_retry(messages, max_attempts=3):
    # Call LLM with the messages containing actual source code
    response_content = create_chat_completion(client, deployment, messages)
                                                                # ↑
                                                    Contains actual source code

    # LLM returns generated test code
    return extracted_code
```

**What LLM Receives** (simplified):
```
User: Generate UNIT tests

FOCUS TARGETS: predict_batch, validate_sentence

PROJECT ANALYSIS: {
  "functions": [
    {"name": "predict_batch", "file": "app/main.py", "lineno": 45}
  ]
}

ADDITIONAL CONTEXT:
# FILE: app/main.py
# FULL CONTENT FOR UNIVERSAL COMPATIBILITY
import re
from typing import List, Optional

MODEL = None

def load_model():
    global MODEL
    MODEL = initialize_model()
    return MODEL

def predict_batch(texts: List[str]) -> List[str]:
    """Process multiple texts."""
    if MODEL is None:
        load_model()

    results = []
    for text in texts:
        result = MODEL.predict(text)
        results.append(result)
    return results

def validate_sentence(text: str) -> bool:
    if not text or len(text) < 5:
        raise ValueError("Text too short")
    return True

...
```

---

## Key Differences from Auto-Fixer

| Aspect | Test Generation | Auto-Fixer |
|--------|----------------|-----------|
| **Purpose** | Generate new tests | Fix failing tests |
| **Input** | Entire project analysis | Specific test file + error |
| **AST Usage** | Extract metadata (names, locations) | Extract imports + dependencies |
| **Code Extraction** | Read entire source files | Extract specific functions via `ast.unparse()` |
| **Scope** | Multiple files | Targeted functions only |
| **Method** | `path.read_text()` | `ast.unparse(node)` |

---

## Summary: Test Generation Flow

1. **Analyzer** uses AST to extract **METADATA** (function names, file paths, line numbers)
   - Input: Source files
   - Output: JSON with metadata
   - Does NOT extract actual code

2. **Focus Selection** identifies which functions to test
   - Input: Metadata JSON
   - Output: List of target names

3. **Context Gatherer** reads **ACTUAL SOURCE FILES**
   - Input: Target names + file paths (from metadata)
   - Method: `path.read_text()` - reads entire file
   - Output: Actual Python source code as string

4. **Prompt Builder** includes actual source code
   - Input: Metadata JSON + actual source code string
   - Output: Prompt for LLM

5. **LLM** receives actual source code and generates tests
   - Input: Prompt with actual code
   - Output: Generated test code

---

## Code Examples from Your Implementation

### Reading Metadata (AST analysis)
```python
# src/analyzer.py:236
func_rec = {
    "name": node.name,           # Just metadata
    "file": rel_path,
    "lineno": getattr(node, "lineno", 1),
}
out["functions"].append(func_rec)
```

### Reading Actual Code (File reading)
```python
# src/gen/enhanced_generate.py:466
content = _gen__read_text_safe(path)  # ← Reads ENTIRE file as string

# src/gen/enhanced_generate.py:469-473
snippet = (
    f"# FILE: {file_rel}\n"
    f"# FULL CONTENT FOR UNIVERSAL COMPATIBILITY\n"
    f"{content}\n\n"  # ← ACTUAL SOURCE CODE
)
```

### Passing to LLM
```python
# src/gen/enhanced_generate.py:677
context = _gather_universal_context(target_root, filtered_analysis, focus_names)
                                    # ↑ Returns actual source code

# src/gen/enhanced_generate.py:679-680
prompt_messages = build_prompt(test_kind, compact_json, focus_label,
                              file_index, num_files, compact, context)
                              #                                 ↑
                              #                   Actual source code passed here

# src/gen/enhanced_prompt.py:304
ADDITIONAL CONTEXT (TRIMMED): {trimmed_context}
                              # ↑ Actual source code in prompt
```

---

## Visual Flow Diagram

```
┌─────────────────────────────────────────────┐
│ Step 1: Analyze with AST                   │
│                                             │
│ Input:  Source files (*.py)                 │
│ Method: ast.parse(code)                     │
│ Output: Metadata JSON                       │
│   {                                         │
│     "functions": [                          │
│       {"name": "func1", "file": "a.py"},    │
│     ]                                       │
│   }                                         │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ Step 2: Select Focus Targets                │
│                                             │
│ Input:  Metadata JSON                       │
│ Output: ['func1', 'func2', 'func3']         │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ Step 3: Read Actual Source Files           │
│                                             │
│ for each file in relevant_files:            │
│   content = file.read_text()  ← ACTUAL CODE │
│   context += content                        │
│                                             │
│ Output: String with actual source code      │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ Step 4: Build Prompt                        │
│                                             │
│ prompt = f"""                               │
│   Generate tests for: {targets}            │
│   Metadata: {metadata_json}                 │
│   Source Code: {actual_code}  ← ACTUAL CODE │
│ """                                         │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ Step 5: LLM Generates Tests                │
│                                             │
│ Input:  Prompt with actual source code      │
│ Output: Generated test code                 │
└─────────────────────────────────────────────┘
```

---

## Bottom Line

**For Test Generation**:
- ❌ We DO NOT pass AST to LLM
- ✅ We USE AST to find file locations and function names
- ✅ We READ actual source files using `file.read_text()`
- ✅ We PASS actual Python source code (as strings) to LLM

**The LLM sees real Python code, not AST representations!**
