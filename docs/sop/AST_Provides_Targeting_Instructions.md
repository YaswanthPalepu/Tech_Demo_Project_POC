# The REAL Purpose of AST: Targeting Instructions for LLM

## Your Sharp Question

**"AST maps all methods, functions, classes, routes AND we pass the entire file anyway. So what's the use of AST?"**

**Answer**: AST provides **TARGETING METADATA** that tells the LLM **WHICH specific functions to focus on**.

---

## The Critical Difference: Prompt Content

### WITHOUT AST Metadata (Blind Generation)

**Prompt Sent to LLM**:
```
Generate comprehensive tests for this Python file.

# FILE: app/main.py
import bcrypt
from database import get_db_connection

MAX_USERS = 100
DB_TIMEOUT = 30

def _connect():
    return get_db_connection()

def _hash_password(pwd):
    return bcrypt.hashpw(pwd.encode(), bcrypt.gensalt())

def create_user(username, password):
    hashed = _hash_password(password)
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO users VALUES (?, ?)", (username, hashed))
    return cursor.lastrowid

def delete_user(user_id):
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
    conn.commit()

def update_user(user_id, username):
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET username = ? WHERE id = ?", (username, user_id))
    conn.commit()

def get_user(user_id):
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    return cursor.fetchone()

def list_users():
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    return cursor.fetchall()

def validate_email(email):
    import re
    return bool(re.match(r'^[^@]+@[^@]+\.[^@]+$', email))

def send_welcome_email(user_id):
    user = get_user(user_id)
    # ... send email logic
    pass

# ... 42 more functions
```

**LLM Response**: Generates tests for **ALL 50 functions** in the file!
- Creates `test_create_user()` ✅
- Creates `test_delete_user()` ✅
- Creates `test_update_user()` ✅
- Creates `test_get_user()` ✅
- Creates `test_list_users()` ✅
- Creates `test_validate_email()` ✅
- Creates `test_send_welcome_email()` ✅
- Creates `test__connect()` ✅
- Creates `test__hash_password()` ✅
- ... and 41 more test functions!

**Result**: 50 test functions generated when you only wanted 3!

---

### WITH AST Metadata (Targeted Generation)

**Prompt Sent to LLM**:
```
Generate UNIT tests for ONLY these specific functions:

FOCUS TARGETS:
- create_user
- validate_email
- send_welcome_email

PROJECT METADATA:
{
  "functions": [
    {"name": "create_user", "file": "app/main.py", "lineno": 14, "args_count": 2},
    {"name": "validate_email", "file": "app/main.py", "lineno": 42, "args_count": 1},
    {"name": "send_welcome_email", "file": "app/main.py", "lineno": 46, "args_count": 1}
  ],
  "total_functions_in_file": 50,
  "total_classes_in_file": 0
}

INSTRUCTIONS:
The file contains 50 functions total. Generate tests ONLY for the 3 functions
listed in FOCUS TARGETS above. Do NOT generate tests for other functions like
delete_user, update_user, get_user, list_users, etc.

SOURCE CODE (for context):
# FILE: app/main.py
import bcrypt
from database import get_db_connection

MAX_USERS = 100
DB_TIMEOUT = 30

def _connect():
    return get_db_connection()

def _hash_password(pwd):
    return bcrypt.hashpw(pwd.encode(), bcrypt.gensalt())

def create_user(username, password):  # ← TARGET 1
    hashed = _hash_password(password)
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO users VALUES (?, ?)", (username, hashed))
    return cursor.lastrowid

def delete_user(user_id):  # ← NOT a target
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
    conn.commit()

def update_user(user_id, username):  # ← NOT a target
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET username = ? WHERE id = ?", (username, user_id))
    conn.commit()

def get_user(user_id):  # ← NOT a target
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    return cursor.fetchone()

def list_users():  # ← NOT a target
    conn = _connect()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    return cursor.fetchall()

def validate_email(email):  # ← TARGET 2
    import re
    return bool(re.match(r'^[^@]+@[^@]+\.[^@]+$', email))

def send_welcome_email(user_id):  # ← TARGET 3
    user = get_user(user_id)
    # ... send email logic
    pass

# ... 42 more functions
```

**LLM Response**: Generates tests for **ONLY 3 functions**:
- Creates `test_create_user()` ✅
- Creates `test_validate_email()` ✅
- Creates `test_send_welcome_email()` ✅
- Skips all other 47 functions ✅

**Result**: Exactly 3 test functions as requested!

---

## The Comparison

| Aspect | Without AST Metadata | With AST Metadata |
|--------|---------------------|-------------------|
| **Prompt** | "Test this file" | "Test ONLY these 3 functions: [list]" |
| **LLM Understanding** | Test everything in file | Test specific targets only |
| **Tests Generated** | 50 test functions | 3 test functions |
| **Token Usage** | High (50 test functions) | Low (3 test functions) |
| **Cost** | ~$2.00 | ~$0.15 |
| **Precision** | 0% (tests everything) | 100% (tests exact targets) |

---

## Where AST Metadata Appears in the Prompt

### From Your Code: `src/gen/enhanced_prompt.py` (lines 281-312)

```python
def build_prompt(kind, compact_json, focus_label, shard, total, compact, context=""):

    user_content = f"""
UNIVERSAL {kind.upper()} TEST GENERATION - FILE {shard + 1}/{total}

{dev_instructions}
{merged_rules}

FOCUS TARGETS: {focus_label}
               ↑↑↑
       AST METADATA: Tells LLM WHAT to focus on

PROJECT ANALYSIS: {compact_json}
                  ↑↑↑
       AST METADATA: Function names, line numbers, file paths

ADDITIONAL CONTEXT (TRIMMED): {trimmed_context}
                              ↑↑↑
                   Entire file content (for dependencies)

{UNIVERSAL_SCAFFOLD}
"""
```

**The Key Parts**:
1. `FOCUS TARGETS` - From AST: "create_user, validate_email, send_welcome_email"
2. `PROJECT ANALYSIS` - From AST: JSON with function metadata
3. `ADDITIONAL CONTEXT` - File content: Complete source code

---

## Real Example from Your Codebase

### AST Analysis Output (Metadata):

```python
# From src/analyzer.py after analyzing app/main.py
{
    "functions": [
        {"name": "_connect", "file": "app/main.py", "lineno": 7},
        {"name": "_hash_password", "file": "app/main.py", "lineno": 10},
        {"name": "create_user", "file": "app/main.py", "lineno": 14},
        {"name": "delete_user", "file": "app/main.py", "lineno": 21},
        {"name": "update_user", "file": "app/main.py", "lineno": 27},
        {"name": "get_user", "file": "app/main.py", "lineno": 33},
        {"name": "list_users", "file": "app/main.py", "lineno": 39},
        {"name": "validate_email", "file": "app/main.py", "lineno": 44},
        {"name": "send_welcome_email", "file": "app/main.py", "lineno": 49},
        # ... 41 more functions
    ]
}
```

### Focus Selection (Smart Targeting):

```python
# From src/gen/enhanced_prompt.py - focus_for()
# Choose 3 functions for this test file shard
focus_names = ['create_user', 'validate_email', 'send_welcome_email']
```

### Prompt Building (Metadata + Content):

```python
# From src/gen/enhanced_prompt.py - build_prompt()
prompt = f"""
FOCUS TARGETS: {', '.join(focus_names)}
               ↑ Tells LLM: "Only test these 3"

PROJECT METADATA:
{json.dumps(compact)}
↑ Provides function details (line numbers, args)

SOURCE CODE:
{context}
↑ Entire file (for context/dependencies)
"""
```

---

## Why We Still Pass Entire Files

**Question**: If we only want 3 functions, why not send ONLY those 3 functions?

**Answer**: **Dependencies!**

```python
# If we only send this:
def create_user(username, password):
    hashed = _hash_password(password)  # ← What is _hash_password?
    conn = _connect()                  # ← What is _connect?
    # uses MAX_USERS                   # ← What is MAX_USERS?
```

**LLM can't generate tests** - missing dependencies!

**But if we send the entire file**:
```python
MAX_USERS = 100  # ← LLM sees this

def _connect():  # ← LLM sees this
    return get_db_connection()

def _hash_password(pwd):  # ← LLM sees this
    return bcrypt.hashpw(pwd.encode(), bcrypt.gensalt())

def create_user(username, password):  # ← TARGET
    hashed = _hash_password(password)  # ✅ LLM knows what this is
    conn = _connect()                  # ✅ LLM knows what this is
```

**LLM can generate proper tests** with mocking!

---

## The Two Roles of AST

### Role 1: Discovery (Which files to read)

Without AST:
```python
# Read all 100 files in project
for file in all_files:
    send_to_llm(file.read_text())
```

With AST:
```python
# AST tells us: "create_user is in app/main.py"
# Only read that 1 file
send_to_llm(Path("app/main.py").read_text())
```

### Role 2: Targeting (Which functions to test)

Without AST metadata:
```python
prompt = f"Test this file: {file_content}"
# LLM tests EVERYTHING
```

With AST metadata:
```python
prompt = f"""
Test ONLY these functions: {focus_names}
File content: {file_content}
"""
# LLM tests ONLY specified functions
```

---

## The Complete Flow

```
1. AST Analyzes Project
   ↓
   Found: 250 functions across 20 files

2. Select Targets (for this test shard)
   ↓
   Focus: 3 functions from 1 file

3. Read Relevant File(s)
   ↓
   Read: app/main.py (contains all 50 functions)

4. Build Prompt with Metadata + Content
   ↓
   FOCUS: ["create_user", "validate_email", "send_welcome_email"]
   METADATA: [function details from AST]
   CONTENT: [entire file for dependencies]

5. LLM Generates Targeted Tests
   ↓
   Output: Tests for ONLY the 3 target functions
   (LLM ignores the other 47 functions because of metadata)
```

---

## What Happens in Multi-File Projects

### Project with 100 files, 1000 functions

**Without AST**:
```python
# How do you know which files to read?
# How do you tell LLM what to focus on?
# You'd have to read all 100 files and hope for the best
```

**With AST**:
```python
# Iteration 1: Test file 1
AST → Focus: 10 functions from files A, B
Read: A.py, B.py (2 files)
Prompt: "Test ONLY these 10 functions: [...metadata...]"
Result: test_unit_001.py (10 test functions)

# Iteration 2: Test file 2
AST → Focus: 10 different functions from files C, D
Read: C.py, D.py (2 files)
Prompt: "Test ONLY these 10 functions: [...metadata...]"
Result: test_unit_002.py (10 test functions)

# ... 100 iterations
# Total: 100 test files, each testing 10 specific functions
```

---

## Summary: AST Provides TARGETING

### What AST Does:

1. ✅ **Discovery**: "These 250 functions exist"
2. ✅ **Organization**: "Split into 10 test files, 25 functions each"
3. ✅ **Mapping**: "Functions X, Y, Z are in file A"
4. ✅ **Targeting**: "Tell LLM to test ONLY functions X, Y, Z"
5. ✅ **Optimization**: "Read 3 files instead of 100"

### What Entire File Provides:

1. ✅ **Context**: Dependencies, helpers, constants
2. ✅ **Complete Picture**: LLM sees all related code
3. ✅ **Proper Mocking**: LLM knows what to mock

---

## Bottom Line

**AST = GPS Instructions**
- "Drive to 123 Main Street" (target functions)
- Without GPS: You drive around blindly
- With GPS: You know exactly where to go

**Entire File = The Map**
- Shows all roads, landmarks, connections
- Helps you understand the context
- Lets you plan the route

**Both are needed**:
- AST tells LLM **WHAT** to focus on
- File content gives LLM **HOW** to test it (context)

**The key is**: AST metadata in the prompt acts as **targeting instructions** that tell the LLM to ignore 47 functions and focus on only 3!
