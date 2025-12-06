# How AST Actually Finds Target Functions, Routes, and Classes

## The Core Question

**"How can AST find target functions, routes, or classes from the analysis?"**

**Answer**: AST **walks through the code tree** and identifies patterns using **node types**.

---

## The AST Walking Process

### Step 1: Parse Source Code into Tree

**File**: `src/analyzer.py` (line 195-196)

```python
# Read the source file
code = read_text(f)  # Read as string

# Parse into AST tree
tree = ast.parse(code)  # ← Creates Abstract Syntax Tree
```

**What `ast.parse()` does**:
- Converts Python code (string) into a tree structure
- Each code element becomes a **node** with a specific **type**

---

## Understanding AST Nodes

### Example Source Code:

```python
# source.py
import requests

class User:
    def __init__(self, name):
        self.name = name

def process_user(user):
    return user.name.upper()

@app.get("/users")
def get_users():
    return {"users": []}
```

### AST Tree Structure:

```
Module
├── Import (name='requests')
├── ClassDef (name='User')
│   └── FunctionDef (name='__init__')
│       └── arguments (args=[self, name])
├── FunctionDef (name='process_user')
│   └── arguments (args=[user])
└── FunctionDef (name='get_users')
    ├── decorator_list
    │   └── Call
    │       └── Attribute (attr='get')
    └── arguments (args=[])
```

Each element has a **node type**:
- `ast.Import` - Import statement
- `ast.ClassDef` - Class definition
- `ast.FunctionDef` - Function definition
- `ast.Call` - Function call
- `ast.Attribute` - Attribute access (like `app.get`)

---

## How AST Finds Functions

### The Code: `src/analyzer.py` (lines 231-256)

```python
# Walk through ALL nodes in the tree
for node in ast.walk(tree):

    # Check if this node is a function definition
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):

        # Extract metadata from the function node
        func_rec = {
            "name": node.name,                    # ← Function name
            "file": rel_path,                     # ← File path
            "lineno": getattr(node, "lineno", 1), # ← Start line
            "end_lineno": getattr(node, "end_lineno", 1),  # ← End line
            "is_async": isinstance(node, ast.AsyncFunctionDef),
            "is_top_level": node.name in top_level_names,
            "args_count": len(node.args.args) if hasattr(node, 'args') else 0,
        }

        # Store the function metadata
        out["functions"].append(func_rec)
```

### Visual Example:

**Input Code**:
```python
def process_user(user):
    return user.name.upper()
```

**AST Node**:
```python
FunctionDef(
    name='process_user',           # ← Extract this
    args=arguments(
        args=[arg(arg='user')]     # ← Count arguments
    ),
    lineno=8,                      # ← Extract this
    end_lineno=9,                  # ← Extract this
    body=[...]
)
```

**Extracted Metadata**:
```python
{
    "name": "process_user",
    "file": "source.py",
    "lineno": 8,
    "end_lineno": 9,
    "is_async": False,
    "args_count": 1
}
```

---

## How AST Finds Classes

### The Code: `src/analyzer.py` (lines 276-298)

```python
for node in ast.walk(tree):

    # Check if this node is a class definition
    elif isinstance(node, ast.ClassDef):

        # Extract class metadata
        class_rec = {
            "name": node.name,                # ← Class name
            "file": rel_path,
            "lineno": getattr(node, "lineno", 1),
            "end_lineno": getattr(node, "end_lineno", 1),
            "bases": [                        # ← Parent classes
                b.id if isinstance(b, ast.Name) else
                getattr(b, 'attr', str(b))
                for b in node.bases
            ],
            "method_count": len([             # ← Count methods
                n for n in node.body
                if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
            ]),
        }

        out["classes"].append(class_rec)

        # Extract ALL methods from the class
        methods = _analyze_class_methods(node, rel_path)
        out["methods"].extend(methods)
```

### Visual Example:

**Input Code**:
```python
class User:
    def __init__(self, name):
        self.name = name

    def get_name(self):
        return self.name
```

**AST Node**:
```python
ClassDef(
    name='User',              # ← Extract this
    bases=[],                 # ← Parent classes
    body=[
        FunctionDef(name='__init__', ...),
        FunctionDef(name='get_name', ...)
    ],
    lineno=3,
    end_lineno=8
)
```

**Extracted Metadata**:
```python
{
    "name": "User",
    "file": "source.py",
    "lineno": 3,
    "end_lineno": 8,
    "bases": [],
    "method_count": 2
}
```

---

## How AST Finds Routes (API Endpoints)

### The Code: `src/analyzer.py` (lines 257-269)

```python
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):

        # Check for route decorators
        for d in getattr(node, "decorator_list", []):

            # Extract route information from decorator
            route_info = _extract_route_info(d)

            if route_info and route_info.get("path"):
                out["routes"].append({
                    "handler": node.name,          # ← Handler function name
                    "file": rel_path,
                    "method": route_info.get("method"),  # ← HTTP method
                    "path": route_info.get("path"),      # ← URL path
                    "lineno": func_rec["lineno"],
                    "end_lineno": func_rec["end_lineno"],
                })
```

### The Decorator Extraction: `src/analyzer.py` (lines 59-98)

```python
def _extract_route_info(dec) -> Dict[str, Any]:
    """Extract route information from decorators."""
    info = {}

    # Handle @router.get("/path") style (FastAPI)
    if hasattr(dec, 'func'):
        func = dec.func
        if hasattr(func, 'attr'):
            # Check if it's a route method (get, post, put, etc.)
            if func.attr in {"get", "post", "put", "patch", "delete"}:
                info["method"] = func.attr  # ← Extract HTTP method

                # Extract path from first argument
                if hasattr(dec, "args") and dec.args:
                    arg0 = dec.args[0]
                    if isinstance(arg0, ast.Constant):
                        info["path"] = arg0.value  # ← Extract URL path

    return info
```

### Visual Example:

**Input Code**:
```python
@app.get("/users")
def get_users():
    return {"users": []}

@app.post("/users")
async def create_user(user: User):
    return {"id": 1}
```

**AST Structure**:
```python
FunctionDef(
    name='get_users',
    decorator_list=[
        Call(                        # @app.get("/users")
            func=Attribute(
                value=Name(id='app'),
                attr='get'           # ← HTTP method
            ),
            args=[
                Constant(value='/users')  # ← URL path
            ]
        )
    ],
    lineno=1
)
```

**Extracted Route Metadata**:
```python
{
    "handler": "get_users",
    "file": "source.py",
    "method": "get",        # ← From decorator
    "path": "/users",       # ← From decorator argument
    "lineno": 1,
    "end_lineno": 3
}
```

---

## The Complete Discovery Process

### Real Example with Actual Code

**Source File**: `app/main.py`
```python
from fastapi import FastAPI
import bcrypt

app = FastAPI()

# Constant
MAX_USERS = 100

# Helper function
def _hash_password(pwd: str) -> str:
    return bcrypt.hashpw(pwd.encode(), bcrypt.gensalt()).decode()

# Target function 1
def validate_email(email: str) -> bool:
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

# Target class
class User:
    def __init__(self, username: str, email: str):
        self.username = username
        self.email = email

    def to_dict(self):
        return {"username": self.username, "email": self.email}

# Route 1
@app.get("/users")
def get_users():
    return {"users": []}

# Route 2
@app.post("/users")
async def create_user(username: str, email: str):
    if not validate_email(email):
        raise ValueError("Invalid email")
    return {"id": 1}
```

### Step-by-Step AST Analysis

#### Step 1: Parse File
```python
code = read_text("app/main.py")
tree = ast.parse(code)
```

#### Step 2: Walk Tree and Identify Nodes
```python
for node in ast.walk(tree):
    # Process each node...
```

#### Step 3: Extract Functions
```python
# Found: _hash_password (line 10)
{
    "name": "_hash_password",
    "file": "app/main.py",
    "lineno": 10,
    "end_lineno": 11,
    "is_async": False,
    "args_count": 1
}

# Found: validate_email (line 14)
{
    "name": "validate_email",
    "file": "app/main.py",
    "lineno": 14,
    "end_lineno": 17,
    "is_async": False,
    "args_count": 1
}

# Found: get_users (line 30)
{
    "name": "get_users",
    "file": "app/main.py",
    "lineno": 30,
    "end_lineno": 32,
    "is_async": False,
    "args_count": 0
}

# Found: create_user (line 35)
{
    "name": "create_user",
    "file": "app/main.py",
    "lineno": 35,
    "end_lineno": 38,
    "is_async": True,
    "args_count": 2
}
```

#### Step 4: Extract Classes
```python
# Found: User (line 20)
{
    "name": "User",
    "file": "app/main.py",
    "lineno": 20,
    "end_lineno": 26,
    "bases": [],
    "method_count": 2
}
```

#### Step 5: Extract Methods
```python
# From class User:

# Found: __init__ (line 21)
{
    "name": "__init__",
    "class": "User",
    "file": "app/main.py",
    "lineno": 21,
    "end_lineno": 23,
    "is_async": False
}

# Found: to_dict (line 25)
{
    "name": "to_dict",
    "class": "User",
    "file": "app/main.py",
    "lineno": 25,
    "end_lineno": 26,
    "is_async": False
}
```

#### Step 6: Extract Routes
```python
# Found route with @app.get decorator:
{
    "handler": "get_users",
    "file": "app/main.py",
    "method": "get",
    "path": "/users",
    "lineno": 30,
    "end_lineno": 32
}

# Found route with @app.post decorator:
{
    "handler": "create_user",
    "file": "app/main.py",
    "method": "post",
    "path": "/users",
    "lineno": 35,
    "end_lineno": 38
}
```

---

## The Complete Analysis Output

```python
{
    "functions": [
        {"name": "_hash_password", "file": "app/main.py", "lineno": 10},
        {"name": "validate_email", "file": "app/main.py", "lineno": 14},
        {"name": "get_users", "file": "app/main.py", "lineno": 30},
        {"name": "create_user", "file": "app/main.py", "lineno": 35}
    ],
    "classes": [
        {"name": "User", "file": "app/main.py", "lineno": 20, "method_count": 2}
    ],
    "methods": [
        {"name": "__init__", "class": "User", "file": "app/main.py", "lineno": 21},
        {"name": "to_dict", "class": "User", "file": "app/main.py", "lineno": 25}
    ],
    "routes": [
        {"handler": "get_users", "method": "get", "path": "/users", "lineno": 30},
        {"handler": "create_user", "method": "post", "path": "/users", "lineno": 35}
    ]
}
```

---

## How AST Identifies Different Node Types

### Pattern Recognition

| Python Code | AST Node Type | How to Identify |
|-------------|---------------|-----------------|
| `def func():` | `ast.FunctionDef` | `isinstance(node, ast.FunctionDef)` |
| `async def func():` | `ast.AsyncFunctionDef` | `isinstance(node, ast.AsyncFunctionDef)` |
| `class MyClass:` | `ast.ClassDef` | `isinstance(node, ast.ClassDef)` |
| `@decorator` | `decorator_list` | `node.decorator_list` |
| `@app.get("/path")` | `ast.Call` with `ast.Attribute` | Check `func.attr == 'get'` |
| `import module` | `ast.Import` | `isinstance(node, ast.Import)` |
| `from x import y` | `ast.ImportFrom` | `isinstance(node, ast.ImportFrom)` |

---

## Key Attributes Extracted

### For Functions (`ast.FunctionDef`)
```python
node.name           # Function name
node.lineno         # Start line number
node.end_lineno     # End line number
node.args.args      # List of arguments
node.decorator_list # List of decorators
node.body           # Function body (statements)
```

### For Classes (`ast.ClassDef`)
```python
node.name           # Class name
node.bases          # Parent classes
node.body           # Class body (methods, attributes)
node.decorator_list # Class decorators
```

### For Decorators (`ast.Call`)
```python
node.func.attr      # Decorator method (get, post, etc.)
node.args[0].value  # First argument (URL path)
```

---

## The Magic of `ast.walk()`

**What it does**: Recursively visits every node in the tree

```python
# Example tree
Module
├── FunctionDef (name='outer')
│   └── FunctionDef (name='inner')  # Nested function
└── ClassDef (name='MyClass')
    └── FunctionDef (name='method')

# ast.walk() visits in order:
1. Module
2. FunctionDef (outer)
3. FunctionDef (inner)  ← Finds nested functions too!
4. ClassDef (MyClass)
5. FunctionDef (method) ← Finds methods inside classes!
```

**This is why AST finds EVERYTHING** - it walks the entire tree recursively!

---

## Summary: How AST Finds Targets

### The Process:

1. **Parse**: Convert Python code string → AST tree
2. **Walk**: Visit every node in the tree using `ast.walk()`
3. **Identify**: Check node type using `isinstance()`
4. **Extract**: Get metadata from node attributes (`.name`, `.lineno`, etc.)
5. **Store**: Save metadata in structured format

### What Gets Found:

- ✅ **Functions**: By checking `isinstance(node, ast.FunctionDef)`
- ✅ **Classes**: By checking `isinstance(node, ast.ClassDef)`
- ✅ **Methods**: By walking class body nodes
- ✅ **Routes**: By checking decorator patterns on functions
- ✅ **Nested Functions**: Because `ast.walk()` is recursive
- ✅ **Line Numbers**: From `node.lineno` and `node.end_lineno`

### The Output:

Structured metadata that tells us:
- **What** exists (function/class/route names)
- **Where** it is (file path, line numbers)
- **Type** of element (function, async function, class, etc.)

This metadata is then used to:
- Target specific functions for test generation
- Organize tests by type
- Map functions to files
- Identify coverage gaps
- Distribute work across test files

---

## Bottom Line

**AST finds targets by**:
1. Walking through the code tree
2. Checking each node's type
3. Extracting metadata from matching nodes
4. Building a structured inventory

**It's like a code scanner** that reads every line and identifies "this is a function", "this is a class", "this is a route", then records where they are!
