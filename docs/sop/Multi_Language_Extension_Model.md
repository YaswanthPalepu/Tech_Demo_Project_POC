# 3.3 Multi-Language Extension Model

## Overview

The architecture is intentionally designed to scale to more languages with minimal changes through a well-defined abstraction layer. Java and JavaScript implementations demonstrate how language-specific features are unified under common interfaces.

---

## 3.3.1 Language Abstraction Layer

### BaseParser

The `BaseParser` defines the core interface for parsing source code across different languages. Each language implements this interface to handle its specific syntax and structure.

#### Core Methods

**`parse_file(file_path: str) -> AST`**
- **Purpose**: Parse a source file and generate an Abstract Syntax Tree
- **Input**: Absolute path to the source file
- **Output**: Language-specific AST representation
- **Java Implementation**: Uses JavaParser library to parse `.java` files
- **JavaScript Implementation**: Uses Babel parser (`@babel/parser`) to parse `.js` files

**`extract_functions(ast: AST) -> List[FunctionMetadata]`**
- **Purpose**: Extract all function/method definitions from the AST
- **Returns**: List containing function metadata (name, parameters, return type, line numbers)
- **Java Implementation**: Extracts methods from classes, including:
  - Method name
  - Parameter types and names
  - Return type
  - Access modifiers (public, private, protected)
  - Start and end line numbers
- **JavaScript Implementation**: Extracts:
  - Regular functions (`function foo()`)
  - Arrow functions (`const foo = () => {}`)
  - Method definitions in classes
  - Async functions
  - Generator functions

**`extract_classes(ast: AST) -> List[ClassMetadata]`**
- **Purpose**: Extract class definitions and their structure
- **Returns**: List of class metadata (name, methods, fields, inheritance)
- **Java Implementation**: Extracts:
  - Class name and package
  - Extends and implements relationships
  - Member variables (fields)
  - Constructor definitions
  - All method signatures
- **JavaScript Implementation**: Extracts:
  - ES6 class definitions
  - Constructor methods
  - Class methods (static and instance)
  - Class properties

**`extract_routes(ast: AST) -> List[RouteMetadata]`**
- **Purpose**: Identify API endpoints and route definitions
- **Returns**: List of route metadata (HTTP method, path, handler function)
- **Java Implementation**: Detects:
  - Spring Boot annotations (`@GetMapping`, `@PostMapping`, `@RequestMapping`)
  - JAX-RS annotations (`@Path`, `@GET`, `@POST`)
  - Handler method names and parameters
- **JavaScript Implementation**: Detects:
  - Express.js routes (`app.get()`, `app.post()`, `router.use()`)
  - Route paths and handler functions
  - Middleware definitions

**`normalize_ast(ast: AST) -> NormalizedAST`**
- **Purpose**: Convert language-specific AST to a common internal format
- **Returns**: Unified AST structure usable by the test generation engine
- **Implementation**: Maps language-specific nodes to common types:
  - Function declarations → `FunctionNode`
  - Class definitions → `ClassNode`
  - Import statements → `ImportNode`
  - Control flow → `ControlFlowNode`

---

### BaseTestGenerator

The `BaseTestGenerator` defines how test files are structured and generated for each language.

#### Template Structure

**Java Template Structure**
```
[Package Declaration]
[Import Statements]
  - JUnit 5 imports (org.junit.jupiter.api.*)
  - Mockito imports (org.mockito.*)
  - Class under test imports

[Test Class]
  @DisplayName("ClassName Tests")
  public class ClassNameTest {

    [Mock Dependencies]
    @Mock
    private DependencyClass dependency;

    @InjectMocks
    private ClassUnderTest classUnderTest;

    [Setup Method]
    @BeforeEach
    void setUp() {
      MockitoAnnotations.openMocks(this);
    }

    [Test Methods]
    @Test
    @DisplayName("should test specific behavior")
    void testMethodName() {
      // Arrange
      // Act
      // Assert
    }
  }
```

**JavaScript Template Structure**
```
[Import Statements]
  - Source imports (require/import)
  - Jest globals (describe, test, expect)
  - Mock imports

[Test Suite]
describe('ClassName', () => {

  [Setup/Teardown]
  beforeEach(() => {
    // Setup code
  });

  afterEach(() => {
    // Cleanup code
  });

  [Test Cases]
  test('should test specific behavior', () => {
    // Arrange
    // Act
    // Assert
  });

  [Nested Suites]
  describe('methodName', () => {
    test('should handle specific case', () => {
      // Test code
    });
  });
});
```

#### Prompt Generation Rules

**Common Prompt Structure**
1. **Context Block**: Source code being tested
2. **Instruction Block**: Testing requirements and coverage targets
3. **Constraints Block**: Language-specific testing patterns
4. **Example Block**: Sample test format for the language

**Java Prompt Rules**
- Include package context and class hierarchy
- Specify JUnit 5 and Mockito usage
- Request proper annotations (`@Test`, `@DisplayName`, `@ExtendWith`)
- Emphasize mock injection for dependencies
- Request assertion library (AssertJ or JUnit assertions)

**JavaScript Prompt Rules**
- Include module type (CommonJS vs ES6 modules)
- Specify Jest testing framework
- Request proper describe/test nesting
- Emphasize mock functions (`jest.fn()`, `jest.mock()`)
- Request async/await handling for promises

#### File Writing Rules

**Java File Writing**
- **File Location**: `src/test/java/{package_path}/{ClassName}Test.java`
- **Naming Convention**: `{ClassName}Test.java`
- **Package Alignment**: Must match source package structure
- **Import Organization**: Organize imports by groups (JUnit, Mockito, project imports)

**JavaScript File Writing**
- **File Location**: `tests/{relative_path}/{filename}.test.js`
- **Naming Convention**: `{filename}.test.js` or `{filename}.spec.js`
- **Module Format**: Match source file format (CommonJS or ES6)
- **Mock Location**: Co-locate mocks with tests or in `__mocks__/` directory

---

### BaseCoverageHandler

The `BaseCoverageHandler` manages test execution and coverage collection for each language.

#### How Tests Are Executed

**Java Execution**
```bash
mvn test -Dtest=ClassNameTest
# or
gradle test --tests ClassNameTest
```
- Uses Maven Surefire or Gradle test runner
- Executes tests in isolated JVM instances
- Collects results in XML format (Surefire reports)

**JavaScript Execution**
```bash
jest path/to/test.test.js --coverage
# or
npm test -- --coverage
```
- Uses Jest test runner
- Executes tests in Node.js environment
- Can run tests in parallel by default

#### How Coverage Is Collected

**Java Coverage Collection**
- **Tool**: JaCoCo (Java Code Coverage)
- **Execution**: JaCoCo agent instruments bytecode during test execution
- **Output Formats**:
  - XML: `target/site/jacoco/jacoco.xml`
  - HTML: `target/site/jacoco/index.html`
  - CSV: `target/site/jacoco/jacoco.csv`
- **Metrics Collected**:
  - Line coverage (instructions executed)
  - Branch coverage (decision points)
  - Method coverage
  - Class coverage
  - Complexity coverage

**JavaScript Coverage Collection**
- **Tool**: Istanbul/nyc (built into Jest)
- **Execution**: Instruments code at runtime using AST transformation
- **Output Formats**:
  - JSON: `coverage/coverage-final.json`
  - LCOV: `coverage/lcov.info`
  - HTML: `coverage/lcov-report/index.html`
- **Metrics Collected**:
  - Statement coverage
  - Branch coverage
  - Function coverage
  - Line coverage

#### How Uncovered Lines Are Mapped

**Java Mapping Process**
1. Parse JaCoCo XML report
2. Extract `<sourcefile>` elements for each class
3. Identify `<line>` elements with attributes:
   - `nr`: Line number
   - `ci`: Covered instructions
   - `mi`: Missed instructions
4. Lines where `mi > 0` are uncovered
5. Map line numbers to source file using:
   ```java
   {
     "sourceFile": "src/main/java/com/example/UserService.java",
     "className": "com.example.UserService",
     "uncoveredLines": [45, 46, 52, 67]
   }
   ```

**JavaScript Mapping Process**
1. Parse coverage JSON or LCOV file
2. Extract file coverage data:
   ```javascript
   {
     "path/to/file.js": {
       "statementMap": {...},
       "fnMap": {...},
       "branchMap": {...},
       "s": { "1": 0, "2": 5, ... },  // Statement hit counts
       "f": { "1": 0, "2": 3, ... },  // Function hit counts
       "b": { "1": [0, 0], ... }      // Branch hit counts
     }
   }
   ```
3. Identify statements/branches with hit count = 0
4. Map statement IDs to line numbers using `statementMap`
5. Return uncovered line numbers:
   ```javascript
   {
     "filePath": "src/services/userService.js",
     "uncoveredLines": [34, 35, 41, 58],
     "uncoveredBranches": [
       { "line": 42, "type": "if", "branch": "else" }
     ]
   }
   ```

---

### BaseFailureParser

The `BaseFailureParser` analyzes test failures and extracts actionable information for debugging and auto-fixing.

#### How Test Errors Are Classified

**Common Error Categories**

1. **Assertion Failures**
   - **Description**: Expected vs actual value mismatch
   - **Java Indicators**: `AssertionError`, `AssertionFailedError`
   - **JavaScript Indicators**: `expect(...).toBe()` failures, assertion errors

2. **Timeout Errors**
   - **Description**: Test exceeded maximum execution time
   - **Java Indicators**: `TestTimedOutException`
   - **JavaScript Indicators**: `Timeout - Async callback was not invoked`

3. **Null/Undefined Errors**
   - **Description**: Accessing null or undefined values
   - **Java Indicators**: `NullPointerException`
   - **JavaScript Indicators**: `TypeError: Cannot read property of undefined`

4. **Mock/Stub Errors**
   - **Description**: Issues with test doubles
   - **Java Indicators**: `UnnecessaryStubbingException`, `WantedButNotInvoked`
   - **JavaScript Indicators**: `expect(jest.fn()).toHaveBeenCalled()` failures

5. **Import/Dependency Errors**
   - **Description**: Missing or incorrect imports
   - **Java Indicators**: `ClassNotFoundException`, `NoClassDefFoundError`
   - **JavaScript Indicators**: `Cannot find module`, `MODULE_NOT_FOUND`

6. **Setup/Teardown Errors**
   - **Description**: Failures in test lifecycle methods
   - **Java Indicators**: Errors in `@BeforeEach`, `@AfterEach` methods
   - **JavaScript Indicators**: Errors in `beforeEach()`, `afterEach()` hooks

**Java Error Classification Logic**
```java
Classification classifyError(TestFailure failure) {
  String exceptionType = failure.getExceptionType();
  String message = failure.getMessage();

  if (exceptionType.contains("AssertionError")) {
    return Classification.ASSERTION_FAILURE;
  } else if (exceptionType.contains("NullPointerException")) {
    return Classification.NULL_ERROR;
  } else if (exceptionType.contains("ClassNotFoundException")) {
    return Classification.IMPORT_ERROR;
  } else if (message.contains("WantedButNotInvoked")) {
    return Classification.MOCK_ERROR;
  } else if (exceptionType.contains("TestTimedOutException")) {
    return Classification.TIMEOUT;
  }

  return Classification.UNKNOWN;
}
```

**JavaScript Error Classification Logic**
```javascript
function classifyError(failure) {
  const { type, message, stack } = failure;

  if (message.includes('expect(') && message.includes('toBe')) {
    return 'ASSERTION_FAILURE';
  } else if (message.includes('Cannot read property') ||
             message.includes('is not defined')) {
    return 'NULL_UNDEFINED_ERROR';
  } else if (message.includes('Cannot find module') ||
             message.includes('MODULE_NOT_FOUND')) {
    return 'IMPORT_ERROR';
  } else if (message.includes('toHaveBeenCalled') ||
             message.includes('jest.fn()')) {
    return 'MOCK_ERROR';
  } else if (message.includes('Timeout') ||
             message.includes('Async callback')) {
    return 'TIMEOUT';
  }

  return 'UNKNOWN';
}
```

#### How Stack Traces Are Parsed

**Java Stack Trace Parsing**

**Input Format**:
```
org.opentest4j.AssertionFailedError: expected: <200> but was: <404>
    at com.example.UserServiceTest.testGetUser(UserServiceTest.java:45)
    at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    at com.example.UserService.getUser(UserService.java:78)
    at com.example.UserController.handleRequest(UserController.java:34)
```

**Parsing Logic**:
1. **Extract Exception Type**: First line before colon
   - Result: `org.opentest4j.AssertionFailedError`

2. **Extract Error Message**: First line after colon
   - Result: `expected: <200> but was: <404>`

3. **Parse Stack Frames**: Each line starting with "at"
   ```java
   StackFrame {
     className: "com.example.UserServiceTest",
     methodName: "testGetUser",
     fileName: "UserServiceTest.java",
     lineNumber: 45,
     isTestCode: true  // matches test file pattern
   }
   ```

4. **Identify Failure Location**: First stack frame in test code
   ```java
   FailureLocation {
     file: "UserServiceTest.java",
     line: 45,
     method: "testGetUser",
     class: "com.example.UserServiceTest"
   }
   ```

5. **Extract Source Trace**: Stack frames from source code (non-JDK)
   ```java
   SourceTrace [
     { class: "UserService", method: "getUser", line: 78 },
     { class: "UserController", method: "handleRequest", line: 34 }
   ]
   ```

**JavaScript Stack Trace Parsing**

**Input Format**:
```
Error: expect(received).toBe(expected)

Expected: 200
Received: 404

    at Object.<anonymous> (/project/tests/userService.test.js:34:18)
    at processTicksAndRejections (internal/process/task_queues.js:95:5)
    at getUserById (/project/src/services/userService.js:67:15)
    at fetchUserData (/project/src/controllers/userController.js:23:10)
```

**Parsing Logic**:
1. **Extract Error Type**: First word of first line
   - Result: `Error`

2. **Extract Error Message**: Multi-line message (until stack trace)
   ```javascript
   message: "expect(received).toBe(expected)\n\nExpected: 200\nReceived: 404"
   ```

3. **Parse Stack Frames**: Lines with "at" followed by file paths
   ```javascript
   StackFrame {
     functionName: "Object.<anonymous>",
     fileName: "/project/tests/userService.test.js",
     lineNumber: 34,
     columnNumber: 18,
     isTestCode: true  // matches test file pattern
   }
   ```

4. **Identify Failure Location**: First frame in test file
   ```javascript
   FailureLocation {
     file: "tests/userService.test.js",
     line: 34,
     column: 18,
     function: "Object.<anonymous>"
   }
   ```

5. **Extract Source Trace**: Frames from source code (excluding node_modules, internal)
   ```javascript
   SourceTrace [
     { function: "getUserById", file: "src/services/userService.js", line: 67 },
     { function: "fetchUserData", file: "src/controllers/userController.js", line: 23 }
   ]
   ```

**Advanced Stack Trace Analysis**

**Java: Identify Root Cause**
```java
RootCause analyzeStackTrace(List<StackFrame> frames) {
  // Filter to project code only (exclude JDK, frameworks)
  List<StackFrame> projectFrames = frames.stream()
    .filter(f -> f.getClassName().startsWith("com.example"))
    .collect(Collectors.toList());

  // Last project frame is usually the root cause
  StackFrame rootFrame = projectFrames.get(projectFrames.size() - 1);

  return new RootCause(
    rootFrame.getFileName(),
    rootFrame.getLineNumber(),
    rootFrame.getMethodName()
  );
}
```

**JavaScript: Async Stack Trace Handling**
```javascript
function parseAsyncStackTrace(stack) {
  const frames = stack.split('\n')
    .filter(line => line.trim().startsWith('at'))
    .map(line => parseStackFrame(line));

  // Identify async boundaries
  const asyncBoundaries = frames
    .filter(f => f.functionName.includes('processTicksAndRejections') ||
                 f.functionName.includes('async'))
    .map(f => frames.indexOf(f));

  // Extract frames between async boundaries (actual code path)
  const relevantFrames = frames.filter((f, index) =>
    !asyncBoundaries.includes(index) &&
    !f.fileName.includes('node_modules')
  );

  return relevantFrames;
}
```

---

## Implementation Summary

| Component | Java | JavaScript |
|-----------|------|------------|
| **BaseParser** | JavaParser library | Babel parser |
| **AST Node Types** | CompilationUnit, ClassOrInterfaceDeclaration, MethodDeclaration | Program, FunctionDeclaration, ArrowFunctionExpression |
| **TestGenerator** | JUnit 5 + Mockito templates | Jest templates |
| **Coverage Tool** | JaCoCo | Istanbul (Jest built-in) |
| **Coverage Format** | XML (jacoco.xml) | JSON + LCOV |
| **Test Runner** | Maven Surefire / Gradle | Jest CLI |
| **Failure Format** | Surefire XML reports | Jest JSON output |
| **Stack Trace Format** | Java standard (class.method.file:line) | V8 format (function (file:line:col)) |

---

**Key Design Principle**: Each language implements the same abstract interface, allowing the core test generation engine to remain language-agnostic while supporting language-specific features and conventions.
