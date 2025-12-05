# Standard Operating Procedure (SOP) - Java

## Document Information
- **Version**: 1.0
- **Last Updated**: December 2025
- **Purpose**: Standard Operating Procedure for Java Development and Testing

---

## Table of Contents
1. [Overview](#overview)
2. [Environment Setup](#environment-setup)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing Procedures](#testing-procedures)
7. [Build and Deployment](#build-and-deployment)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## 1. Overview

### 1.1 Scope
This SOP covers the complete development lifecycle for Java applications, including:
- Environment configuration
- Code development and testing
- Build and packaging
- Deployment procedures

### 1.2 Audience
- Java Developers
- Backend Engineers
- QA Engineers
- DevOps Engineers

### 1.3 Prerequisites
- Java Development Kit (JDK 17 or higher)
- Maven or Gradle build tool
- Git version control
- IDE (IntelliJ IDEA or Eclipse recommended)

---

## 2. Environment Setup

### 2.1 Install Java Development Kit

#### Step 1: Download and Install JDK
```bash
# Verify installation
java -version
javac -version
```

#### Step 2: Set JAVA_HOME Environment Variable
```bash
# Linux/Mac
export JAVA_HOME=/path/to/jdk
export PATH=$JAVA_HOME/bin:$PATH

# Windows
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%
```

### 2.2 Install Build Tools

#### Maven Installation
```bash
# Verify Maven installation
mvn --version
```

#### Gradle Installation
```bash
# Verify Gradle installation
gradle --version
```

### 2.3 Project Initialization

#### Using Maven
```bash
# Create new Maven project
mvn archetype:generate \
  -DgroupId=com.company.app \
  -DartifactId=my-app \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

cd my-app
```

#### Using Gradle
```bash
# Create new Gradle project
gradle init --type java-application

# Or using Spring Initializr for Spring Boot
curl https://start.spring.io/starter.zip \
  -d dependencies=web,data-jpa \
  -d name=my-app \
  -d packageName=com.company.app \
  -o my-app.zip

unzip my-app.zip
cd my-app
```

### 2.4 Configuration Files

#### Maven - pom.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.company.app</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <!-- JUnit 5 for testing -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>5.10.0</version>
            <scope>test</scope>
        </dependency>

        <!-- Mockito for mocking -->
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <version>5.5.0</version>
            <scope>test</scope>
        </dependency>

        <!-- SLF4J for logging -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
            <version>2.0.9</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.1.2</version>
            </plugin>
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.10</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

#### Checkstyle Configuration (checkstyle.xml)
```xml
<?xml version="1.0"?>
<!DOCTYPE module PUBLIC
    "-//Checkstyle//DTD Checkstyle Configuration 1.3//EN"
    "https://checkstyle.org/dtds/configuration_1_3.dtd">

<module name="Checker">
    <module name="TreeWalker">
        <module name="JavadocMethod"/>
        <module name="JavadocType"/>
        <module name="ConstantName"/>
        <module name="LocalFinalVariableName"/>
        <module name="LocalVariableName"/>
        <module name="MemberName"/>
        <module name="MethodName"/>
        <module name="PackageName"/>
        <module name="ParameterName"/>
        <module name="StaticVariableName"/>
        <module name="TypeName"/>
        <module name="LineLength">
            <property name="max" value="120"/>
        </module>
        <module name="MethodLength"/>
        <module name="ParameterNumber"/>
    </module>
</module>
```

---

## 3. Project Structure

### 3.1 Standard Maven Project Layout
```
my-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── company/
│   │   │           └── app/
│   │   │               ├── controller/
│   │   │               ├── service/
│   │   │               ├── repository/
│   │   │               ├── model/
│   │   │               ├── dto/
│   │   │               ├── util/
│   │   │               └── Application.java
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── application.yml
│   │       └── logback.xml
│   └── test/
│       ├── java/
│       │   └── com/
│       │       └── company/
│       │           └── app/
│       │               ├── controller/
│       │               ├── service/
│       │               └── repository/
│       └── resources/
│           └── application-test.properties
├── target/
├── .gitignore
├── checkstyle.xml
├── pom.xml
└── README.md
```

### 3.2 Package Organization
- **controller**: REST API endpoints and web controllers
- **service**: Business logic layer
- **repository**: Data access layer (DAO)
- **model/entity**: Domain models and JPA entities
- **dto**: Data Transfer Objects
- **config**: Configuration classes
- **exception**: Custom exceptions
- **util**: Utility classes

### 3.3 Naming Conventions
- **Classes**: PascalCase (e.g., `UserService`, `OrderController`)
- **Methods**: camelCase (e.g., `getUserById`, `processOrder`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)
- **Packages**: lowercase (e.g., `com.company.app.service`)
- **Test Classes**: append `Test` suffix (e.g., `UserServiceTest`)

---

## 4. Development Workflow

### 4.1 Starting Development

#### Step 1: Pull Latest Code
```bash
git pull origin main
```

#### Step 2: Create Feature Branch
```bash
git checkout -b feature/user-authentication
```

#### Step 3: Build Project
```bash
# Maven
mvn clean install

# Gradle
gradle clean build
```

#### Step 4: Run Application
```bash
# Maven
mvn spring-boot:run

# Gradle
gradle bootRun

# Or run JAR directly
java -jar target/my-app-1.0.0.jar
```

### 4.2 Code Development Process

#### Step 1: Create Model Class
```java
package com.company.app.model;

import javax.persistence.*;
import java.time.LocalDateTime;

/**
 * User entity representing a system user.
 */
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false)
    private String email;

    private LocalDateTime createdAt;

    // Constructors
    public User() {
        this.createdAt = LocalDateTime.now();
    }

    public User(String username, String email) {
        this();
        this.username = username;
        this.email = email;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
```

#### Step 2: Create Repository Interface
```java
package com.company.app.repository;

import com.company.app.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository interface for User entity operations.
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Find user by username.
     *
     * @param username the username to search for
     * @return Optional containing the user if found
     */
    Optional<User> findByUsername(String username);

    /**
     * Check if username exists.
     *
     * @param username the username to check
     * @return true if username exists
     */
    boolean existsByUsername(String username);
}
```

#### Step 3: Create Service Class
```java
package com.company.app.service;

import com.company.app.exception.UserNotFoundException;
import com.company.app.model.User;
import com.company.app.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service class for user-related business logic.
 */
@Service
@Transactional
public class UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Retrieve all users.
     *
     * @return list of all users
     */
    public List<User> getAllUsers() {
        logger.debug("Fetching all users");
        return userRepository.findAll();
    }

    /**
     * Get user by ID.
     *
     * @param id the user ID
     * @return the user
     * @throws UserNotFoundException if user not found
     */
    public User getUserById(Long id) {
        logger.debug("Fetching user with id: {}", id);
        return userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));
    }

    /**
     * Create new user.
     *
     * @param user the user to create
     * @return the created user
     */
    public User createUser(User user) {
        logger.info("Creating user: {}", user.getUsername());
        return userRepository.save(user);
    }

    /**
     * Update existing user.
     *
     * @param id the user ID
     * @param userDetails the updated user details
     * @return the updated user
     */
    public User updateUser(Long id, User userDetails) {
        User user = getUserById(id);
        user.setUsername(userDetails.getUsername());
        user.setEmail(userDetails.getEmail());
        logger.info("Updating user with id: {}", id);
        return userRepository.save(user);
    }

    /**
     * Delete user.
     *
     * @param id the user ID
     */
    public void deleteUser(Long id) {
        User user = getUserById(id);
        logger.info("Deleting user with id: {}", id);
        userRepository.delete(user);
    }
}
```

#### Step 4: Create Controller
```java
package com.company.app.controller;

import com.company.app.model.User;
import com.company.app.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * REST controller for user operations.
 */
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @PostMapping
    public ResponseEntity<User> createUser(@Valid @RequestBody User user) {
        User createdUser = userService.createUser(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdUser);
    }

    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody User userDetails) {
        return ResponseEntity.ok(userService.updateUser(id, userDetails));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
```

### 4.3 Version Control

#### Step 1: Check Status
```bash
git status
```

#### Step 2: Stage Changes
```bash
git add .
```

#### Step 3: Commit with Message
```bash
git commit -m "feat: implement user CRUD operations"
```

**Commit Message Conventions:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation updates
- `refactor:` Code refactoring
- `test:` Test additions/updates
- `perf:` Performance improvements
- `chore:` Build/dependency updates

#### Step 4: Push to Remote
```bash
git push origin feature/user-authentication
```

---

## 5. Coding Standards

### 5.1 Code Formatting
- Indentation: 4 spaces (no tabs)
- Line length: Maximum 120 characters
- Braces: K&R style (opening brace on same line)

### 5.2 Javadoc Comments
```java
/**
 * Calculates the total price including tax.
 * <p>
 * This method applies the specified tax rate to the base price
 * and returns the total amount.
 *
 * @param price the base price (must be positive)
 * @param taxRate the tax rate as decimal (e.g., 0.08 for 8%)
 * @return the total price including tax
 * @throws IllegalArgumentException if price is negative
 */
public double calculateTotalPrice(double price, double taxRate) {
    if (price < 0) {
        throw new IllegalArgumentException("Price cannot be negative");
    }
    return price * (1 + taxRate);
}
```

### 5.3 Exception Handling
```java
// Custom exception
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}

// Proper exception handling
public User processUser(Long userId) {
    try {
        User user = getUserById(userId);
        // Process user
        return user;
    } catch (UserNotFoundException e) {
        logger.error("User not found: {}", userId, e);
        throw e;
    } catch (Exception e) {
        logger.error("Unexpected error processing user: {}", userId, e);
        throw new RuntimeException("Failed to process user", e);
    }
}
```

### 5.4 Resource Management
```java
// Use try-with-resources for auto-closing
try (BufferedReader reader = new BufferedReader(new FileReader("file.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        // Process line
    }
} catch (IOException e) {
    logger.error("Error reading file", e);
}
```

### 5.5 Design Patterns

#### Singleton Pattern
```java
public class ConfigurationManager {
    private static ConfigurationManager instance;

    private ConfigurationManager() {}

    public static synchronized ConfigurationManager getInstance() {
        if (instance == null) {
            instance = new ConfigurationManager();
        }
        return instance;
    }
}
```

#### Builder Pattern
```java
public class User {
    private final String username;
    private final String email;
    private final String phone;

    private User(Builder builder) {
        this.username = builder.username;
        this.email = builder.email;
        this.phone = builder.phone;
    }

    public static class Builder {
        private String username;
        private String email;
        private String phone;

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder email(String email) {
            this.email = email;
            return this;
        }

        public Builder phone(String phone) {
            this.phone = phone;
            return this;
        }

        public User build() {
            return new User(this);
        }
    }
}

// Usage
User user = new User.Builder()
    .username("john")
    .email("john@example.com")
    .build();
```

---

## 6. Testing Procedures

### 6.1 Unit Testing with JUnit 5

#### Step 1: Create Test Class
```java
package com.company.app.service;

import com.company.app.exception.UserNotFoundException;
import com.company.app.model.User;
import com.company.app.repository.UserRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserService Tests")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User("testuser", "test@example.com");
        testUser.setId(1L);
    }

    @Test
    @DisplayName("Should return user when valid ID is provided")
    void testGetUserById_Success() {
        // Arrange
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        // Act
        User result = userService.getUserById(1L);

        // Assert
        assertNotNull(result);
        assertEquals("testuser", result.getUsername());
        verify(userRepository, times(1)).findById(1L);
    }

    @Test
    @DisplayName("Should throw exception when user not found")
    void testGetUserById_NotFound() {
        // Arrange
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(UserNotFoundException.class, () -> {
            userService.getUserById(999L);
        });
        verify(userRepository, times(1)).findById(999L);
    }

    @Test
    @DisplayName("Should create user successfully")
    void testCreateUser_Success() {
        // Arrange
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // Act
        User result = userService.createUser(testUser);

        // Assert
        assertNotNull(result);
        assertEquals("testuser", result.getUsername());
        verify(userRepository, times(1)).save(testUser);
    }

    @Nested
    @DisplayName("Update User Tests")
    class UpdateUserTests {

        @Test
        @DisplayName("Should update user successfully")
        void testUpdateUser_Success() {
            // Arrange
            User updatedUser = new User("updateduser", "updated@example.com");
            when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));
            when(userRepository.save(any(User.class))).thenReturn(updatedUser);

            // Act
            User result = userService.updateUser(1L, updatedUser);

            // Assert
            assertNotNull(result);
            verify(userRepository).save(any(User.class));
        }
    }
}
```

### 6.2 Integration Testing
```java
package com.company.app.controller;

import com.company.app.model.User;
import com.company.app.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testCreateUser() throws Exception {
        User user = new User("testuser", "test@example.com");

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.username").value("testuser"))
                .andExpect(jsonPath("$.email").value("test@example.com"));
    }

    @Test
    void testGetUser() throws Exception {
        User user = userRepository.save(new User("testuser", "test@example.com"));

        mockMvc.perform(get("/api/users/" + user.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("testuser"));
    }
}
```

### 6.3 Running Tests

```bash
# Run all tests with Maven
mvn test

# Run specific test class
mvn test -Dtest=UserServiceTest

# Run tests with coverage
mvn clean test jacoco:report

# View coverage report
open target/site/jacoco/index.html
```

### 6.4 Test Coverage Requirements
- **Minimum Coverage**: 80%
- **Line Coverage**: ≥ 80%
- **Branch Coverage**: ≥ 75%
- **Method Coverage**: ≥ 85%

---

## 7. Build and Deployment

### 7.1 Build Process

#### Maven Build
```bash
# Clean and package
mvn clean package

# Skip tests (not recommended for production)
mvn package -DskipTests

# Create executable JAR
mvn clean package spring-boot:repackage
```

#### Gradle Build
```bash
# Build project
gradle build

# Create executable JAR
gradle bootJar
```

### 7.2 Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Code coverage ≥ 80%
- [ ] No checkstyle violations
- [ ] Dependencies updated and secure
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Logging configured properly
- [ ] Security configurations reviewed

### 7.3 Deployment Steps

#### Step 1: Build Production JAR
```bash
mvn clean package -Pprod
```

#### Step 2: Run Application
```bash
# Run JAR
java -jar target/my-app-1.0.0.jar

# With specific profile
java -jar -Dspring.profiles.active=prod target/my-app-1.0.0.jar

# With JVM options
java -Xmx512m -Xms256m -jar target/my-app-1.0.0.jar
```

#### Step 3: Docker Deployment
```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/my-app-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
# Build Docker image
docker build -t my-app:1.0.0 .

# Run container
docker run -p 8080:8080 my-app:1.0.0
```

### 7.4 Environment Configuration

#### application.properties
```properties
# Server Configuration
server.port=8080
server.servlet.context-path=/api

# Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}

# JPA Configuration
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=true

# Logging
logging.level.root=INFO
logging.level.com.company.app=DEBUG
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### Issue 1: OutOfMemoryError
**Problem**: `java.lang.OutOfMemoryError: Java heap space`

**Solution**:
```bash
# Increase heap size
java -Xmx2g -Xms1g -jar app.jar
```

#### Issue 2: Port Already in Use
**Problem**: `Port 8080 is already in use`

**Solution**:
```bash
# Find process using port
lsof -i :8080
# Or on Windows
netstat -ano | findstr :8080

# Kill process or use different port
server.port=8081
```

#### Issue 3: Dependency Conflicts
**Problem**: `NoSuchMethodError` or `ClassNotFoundException`

**Solution**:
```bash
# View dependency tree
mvn dependency:tree

# Exclude conflicting dependency in pom.xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>library</artifactId>
    <exclusions>
        <exclusion>
            <groupId>conflicting.group</groupId>
            <artifactId>conflicting-artifact</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

### 8.2 Debugging

#### Enable Debug Mode
```bash
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -jar app.jar
```

#### View Logs
```bash
# Tail application logs
tail -f logs/application.log

# Search for errors
grep ERROR logs/application.log
```

---

## 9. Best Practices

### 9.1 Code Quality
- Follow SOLID principles
- Use dependency injection
- Write clean, self-documenting code
- Keep methods small and focused
- Use meaningful names

### 9.2 Performance
- Use connection pooling
- Implement caching (Redis, Caffeine)
- Optimize database queries
- Use lazy loading appropriately
- Profile and monitor performance

### 9.3 Security
- Validate all input
- Use parameterized queries (prevent SQL injection)
- Implement proper authentication/authorization
- Never log sensitive data
- Keep dependencies updated
- Use HTTPS in production
- Implement rate limiting

### 9.4 Logging Best Practices
```java
// Use appropriate log levels
logger.trace("Detailed trace information");
logger.debug("Debug information");
logger.info("Informational messages");
logger.warn("Warning messages");
logger.error("Error messages", exception);

// Use parameterized logging (better performance)
logger.info("User {} logged in at {}", username, timestamp);

// Don't log sensitive data
// ❌ logger.info("User password: {}", password);
// ✅ logger.info("User authenticated: {}", username);
```

---

## 10. References

### 10.1 Documentation
- [Oracle Java Documentation](https://docs.oracle.com/en/java/)
- [Spring Framework Documentation](https://docs.spring.io/spring-framework/reference/)
- [Maven Documentation](https://maven.apache.org/guides/)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)

### 10.2 Tools
- **Build Tools**: Maven, Gradle
- **Testing**: JUnit 5, Mockito, TestContainers
- **Code Quality**: Checkstyle, PMD, SonarQube
- **IDEs**: IntelliJ IDEA, Eclipse, VS Code

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2025 | Development Team | Initial SOP creation |

---

**Document Owner**: Development Team
**Review Frequency**: Quarterly
**Next Review Date**: March 2026
