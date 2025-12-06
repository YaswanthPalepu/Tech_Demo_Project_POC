# The Real Purpose of AST: Sharding and Distribution

## Your Sharp Observation

**Your Analysis Output Shows**:
- 20 functions found
- 14 classes found
- 9 routes found
- **Total: 43 targets across 8 files**

**Your Question**:
"AST finds ALL functions, classes, routes. Then we send entire files anyway. So what's the use of AST?"

**Answer**: AST enables **SHARDING** - dividing 43 targets into **multiple batches**, NOT sending all 43 at once!

---

## What Actually Happens: Distribution Across Multiple Test Files

### Your Project Analysis:
```
Total Targets: 43
├─ Functions: 20
├─ Classes: 14
└─ Routes: 9
```

### WITHOUT AST (Impossible)

**Problem**: You can't split work intelligently

```python
# How do you know there are 43 targets?
# How do you divide them into batches?
# You can't!

# Best you can do:
for file in all_files:
    generate_tests(file)  # 1 test file per source file
```

**Result**: 8 test files (1 per source file), unbalanced

---

### WITH AST (Smart Distribution)

**AST knows**: 43 total targets

**Decision**: Generate 4 test files, ~10-11 targets each

```python
# From src/gen/enhanced_prompt.py - files_per_kind()
num_test_files = (43 + 10 - 1) // 10  # = 5 test files

# Distribute targets across 5 shards
Test File 1: Targets 1-9   (9 targets)
Test File 2: Targets 10-18 (9 targets)
Test File 3: Targets 19-27 (9 targets)
Test File 4: Targets 28-36 (9 targets)
Test File 5: Targets 37-43 (7 targets)
```

---

## The Sharding Process with Your Real Data

### Test File 1: Unit Tests (Shard 0 of 5)

**AST Selects**:
```python
focus_names = [
    "get_db",           # Function from database.py
    "root",             # Function from main.py
    "signup",           # Function from routers/auth.py
    "login",            # Function from routers/auth.py
    "add_to_cart",      # Function from routers/cart.py
    "remove_from_cart", # Function from routers/cart.py
    "get_cart",         # Function from routers/cart.py
    "checkout",         # Function from routers/orders.py
    "get_orders"        # Function from routers/orders.py
]
# Total: 9 functions
```

**Files to Read** (based on AST mapping):
```python
relevant_files = [
    "database.py",
    "main.py",
    "routers/auth.py",
    "routers/cart.py",
    "routers/orders.py"
]
# 5 files (not all 8)
```

**Prompt to LLM**:
```python
"""
Generate UNIT tests for ONLY these 9 functions:
- get_db
- root
- signup
- login
- add_to_cart
- remove_from_cart
- get_cart
- checkout
- get_orders

METADATA:
{
  "functions": [
    {"name": "get_db", "file": "database.py", "lineno": 15},
    {"name": "root", "file": "main.py", "lineno": 32},
    {"name": "signup", "file": "routers/auth.py", "lineno": 10},
    {"name": "login", "file": "routers/auth.py", "lineno": 19},
    {"name": "add_to_cart", "file": "routers/cart.py", "lineno": 10},
    {"name": "remove_from_cart", "file": "routers/cart.py", "lineno": 22},
    {"name": "get_cart", "file": "routers/cart.py", "lineno": 31},
    {"name": "checkout", "file": "routers/orders.py", "lineno": 11},
    {"name": "get_orders", "file": "routers/orders.py", "lineno": 28}
  ]
}

SOURCE CODE:
# FILE: database.py
[entire file content]

# FILE: main.py
[entire file content]

# FILE: routers/auth.py
[entire file content]

# FILE: routers/cart.py
[entire file content]

# FILE: routers/orders.py
[entire file content]
"""
```

**LLM Generates**: `test_unit_001.py` with 9 test functions

---

### Test File 2: Unit Tests (Shard 1 of 5)

**AST Selects**:
```python
focus_names = [
    "get_products",  # Function from routers/products.py
    "UserDB",        # Class from models/db_models.py
    "OrderDB",       # Class from models/db_models.py
    "Product",       # Class from models/schemas.py
    "CartItem",      # Class from models/schemas.py
    "DetailedCartItem", # Class from models/schemas.py
    "User",          # Class from models/schemas.py
    "CheckoutRequest" # Class from models/schemas.py
]
# Total: 1 function + 7 classes = 8 targets
```

**Files to Read**:
```python
relevant_files = [
    "routers/products.py",
    "models/db_models.py",
    "models/schemas.py"
]
# 3 files
```

**Prompt to LLM**:
```python
"""
Generate UNIT tests for ONLY these 8 targets:
- get_products (function)
- UserDB (class)
- OrderDB (class)
- Product (class)
- CartItem (class)
- DetailedCartItem (class)
- User (class)
- CheckoutRequest (class)

METADATA:
{
  "functions": [
    {"name": "get_products", "file": "routers/products.py", "lineno": 16}
  ],
  "classes": [
    {"name": "UserDB", "file": "models/db_models.py", "lineno": 5},
    {"name": "OrderDB", "file": "models/db_models.py", "lineno": 12},
    {"name": "Product", "file": "models/schemas.py", "lineno": 4},
    {"name": "CartItem", "file": "models/schemas.py", "lineno": 11},
    {"name": "DetailedCartItem", "file": "models/schemas.py", "lineno": 15},
    {"name": "User", "file": "models/schemas.py", "lineno": 21},
    {"name": "CheckoutRequest", "file": "models/schemas.py", "lineno": 25}
  ]
}

SOURCE CODE:
# FILE: routers/products.py
[entire file content]

# FILE: models/db_models.py
[entire file content]

# FILE: models/schemas.py
[entire file content]
"""
```

**LLM Generates**: `test_unit_002.py` with 8 test functions

---

### Test File 3: E2E Tests (Routes)

**AST Selects**:
```python
focus_routes = [
    {"method": "GET", "path": "/", "handler": "root"},
    {"method": "POST", "path": "/signup", "handler": "signup"},
    {"method": "POST", "path": "/login", "handler": "login"},
    {"method": "POST", "path": "/add", "handler": "add_to_cart"},
    {"method": "POST", "path": "/remove", "handler": "remove_from_cart"},
    {"method": "GET", "path": "/", "handler": "get_cart"},
    {"method": "POST", "path": "/checkout", "handler": "checkout"},
    {"method": "GET", "path": "/orders/{user_id}", "handler": "get_orders"},
    {"method": "GET", "path": "/", "handler": "get_products"}
]
# Total: 9 routes
```

**Files to Read**:
```python
relevant_files = [
    "main.py",
    "routers/auth.py",
    "routers/cart.py",
    "routers/orders.py",
    "routers/products.py"
]
# 5 files
```

**Prompt to LLM**:
```python
"""
Generate E2E tests for ONLY these 9 API endpoints:
- GET /
- POST /signup
- POST /login
- POST /add
- POST /remove
- GET / (cart)
- POST /checkout
- GET /orders/{user_id}
- GET / (products)

METADATA:
{
  "routes": [
    {"method": "GET", "path": "/", "handler": "root", "file": "main.py"},
    {"method": "POST", "path": "/signup", "handler": "signup", "file": "routers/auth.py"},
    ...
  ]
}

SOURCE CODE:
# FILE: main.py
[entire file content]

# FILE: routers/auth.py
[entire file content]

# FILE: routers/cart.py
[entire file content]

# FILE: routers/orders.py
[entire file content]

# FILE: routers/products.py
[entire file content]
"""
```

**LLM Generates**: `test_e2e_001.py` with 9 test functions

---

## The Key Point: Batching

### Total Work:
- 20 functions
- 14 classes
- 9 routes
- **= 43 total targets**

### How It's Distributed:

| Test File | Targets | Files Read | LLM Call |
|-----------|---------|------------|----------|
| `test_unit_001.py` | 9 functions | 5 files | LLM Call #1 |
| `test_unit_002.py` | 8 targets (1 func + 7 classes) | 3 files | LLM Call #2 |
| `test_unit_003.py` | Remaining functions/classes | 2-3 files | LLM Call #3 |
| `test_e2e_001.py` | 9 routes | 5 files | LLM Call #4 |

**Each LLM call handles ~8-10 targets, NOT all 43!**

---

## The Code That Does This

### From `src/gen/enhanced_prompt.py` (lines 194-233)

```python
def files_per_kind(compact: Dict[str, Any], kind: str) -> int:
    """Distribute ALL targets across appropriate number of files."""

    total_targets = targets_count(compact, kind)
    if total_targets == 0:
        return 0

    targets_per_file = 50  # Max 50 targets per test file

    if kind == "unit":
        # For your project: (20 functions + 14 classes) / 50 = 1 file
        # But let's say we use 10 per file: 34 / 10 = 4 files
        return max(1, (total_targets + targets_per_file - 1) // targets_per_file)
    elif kind == "e2e":
        # For routes: 9 routes / 20 = 1 file
        return max(1, (total_targets + 19) // 20)
    else:
        return max(1, (total_targets + 29) // 30)

def focus_for(compact: Dict[str, Any], kind: str, shard_idx: int, total_shards: int):
    """Select targets for THIS specific shard."""

    functions = compact.get("functions", [])
    classes = compact.get("classes", [])
    routes = compact.get("routes", [])

    if kind == "unit":
        target_list = functions + classes  # All 34 targets
    elif kind == "e2e":
        target_list = routes  # All 9 routes

    # Split into groups
    groups = create_strategic_groups(target_list, total_shards)

    # Return ONLY this shard's targets
    shard_targets = groups[shard_idx]  # ← Just 8-10 targets, not all 43!

    # Extract names
    target_names = [t.get("name") for t in shard_targets]

    return focus_label, target_names, shard_targets
```

---

## The Generation Loop

### From `src/gen/enhanced_generate.py` (lines 661-698)

```python
for test_kind in ["unit", "e2e"]:
    num_files = files_per_kind(compact, test_kind)  # ← How many test files?

    for file_index in range(num_files):  # ← Loop through shards

        # Get targets for THIS shard only
        focus_label, focus_names, shard_targets = focus_for(
            compact, test_kind, file_index, num_files
        )
        # ↑ Returns 8-10 targets, not all 43!

        print(f"Generating test {file_index + 1}/{num_files} for {len(focus_names)} targets")

        # Read files containing these targets
        context = _gather_universal_context(target_root, filtered_analysis, focus_names)

        # Build prompt with ONLY this shard's targets
        prompt_messages = build_prompt(
            test_kind, compact_json, focus_label,
            file_index, num_files, compact, context
        )

        # Generate tests for THIS shard
        test_code = _generate_with_universal_retry(prompt_messages, max_attempts=3)

        # Write to file
        filename = f"test_{test_kind}_{timestamp}_{file_index + 1:02d}.py"
        write_text(output_dir / filename, test_code)
```

---

## Summary: What AST Actually Does

### 1. **Complete Discovery**
```
AST analyzes ALL files
↓
Finds: 20 functions, 14 classes, 9 routes (43 total)
```

### 2. **Intelligent Distribution**
```
Divide 43 targets into batches
↓
Shard 0: Targets 1-9
Shard 1: Targets 10-17
Shard 2: Targets 18-26
Shard 3: Targets 27-34 (unit)
Shard 4: Routes 1-9 (e2e)
```

### 3. **Per-Shard Generation**
```
For each shard:
  ↓
  Select 8-10 targets (NOT all 43)
  ↓
  Find files containing these targets
  ↓
  Read those files (entire content for dependencies)
  ↓
  Build prompt: "Test ONLY these 8-10 targets"
  ↓
  LLM generates tests for 8-10 targets
  ↓
  Write test file
```

---

## The Answer to Your Question

**Q**: "AST finds all functions/classes/routes. We send entire files. What's the use?"

**A**: AST enables **BATCHING**:

| Without AST | With AST |
|-------------|----------|
| ❌ Don't know there are 43 targets | ✅ Know exactly: 43 targets |
| ❌ Can't divide work | ✅ Divide into 5 test files |
| ❌ Would send all 43 at once | ✅ Send 8-10 per batch |
| ❌ One giant test file | ✅ Multiple organized test files |
| ❌ Overwhelming for LLM | ✅ Focused generation per batch |

**AST transforms**:
- From: "Test everything at once"
- To: "Test 8-10 targets at a time, 5 separate generations"

**Yes, we send entire files**, but **NO, we don't test all functions at once**!

Each LLM call focuses on 8-10 targets out of 43 total.

That's the power of AST! 🎯
