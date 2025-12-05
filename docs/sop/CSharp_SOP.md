# Standard Operating Procedure (SOP) - C# (.NET)

## Document Information
- **Version**: 1.0
- **Last Updated**: December 2025
- **Purpose**: Standard Operating Procedure for C# .NET Development and Testing

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
This SOP covers the complete development lifecycle for C# .NET applications, including:
- Environment configuration
- Code development and testing
- Build and packaging
- Deployment procedures

### 1.2 Audience
- C# Developers
- .NET Engineers
- QA Engineers
- DevOps Engineers

### 1.3 Prerequisites
- .NET SDK 8.0 or higher
- Visual Studio 2022 or VS Code with C# extension
- Git version control
- SQL Server or PostgreSQL (for database projects)

---

## 2. Environment Setup

### 2.1 Install .NET SDK

#### Step 1: Download and Install .NET SDK
```bash
# Verify installation
dotnet --version
dotnet --list-sdks
```

#### Step 2: Install Visual Studio or VS Code
- **Visual Studio 2022**: Download from [visualstudio.microsoft.com](https://visualstudio.microsoft.com/)
- **VS Code**: Install C# extension from marketplace

### 2.2 Project Initialization

#### Create Console Application
```bash
dotnet new console -n MyApp
cd MyApp
```

#### Create Web API Application
```bash
dotnet new webapi -n MyWebApi
cd MyWebApi
```

#### Create ASP.NET Core MVC Application
```bash
dotnet new mvc -n MyMvcApp
cd MyMvcApp
```

#### Create Class Library
```bash
dotnet new classlib -n MyLibrary
cd MyLibrary
```

### 2.3 Solution Structure

#### Create Solution and Add Projects
```bash
# Create solution
dotnet new sln -n MySolution

# Create projects
dotnet new webapi -n MyApi
dotnet new classlib -n MyApi.Core
dotnet new classlib -n MyApi.Infrastructure
dotnet new xunit -n MyApi.Tests

# Add projects to solution
dotnet sln add MyApi/MyApi.csproj
dotnet sln add MyApi.Core/MyApi.Core.csproj
dotnet sln add MyApi.Infrastructure/MyApi.Infrastructure.csproj
dotnet sln add MyApi.Tests/MyApi.Tests.csproj

# Add project references
dotnet add MyApi/MyApi.csproj reference MyApi.Core/MyApi.Core.csproj
dotnet add MyApi/MyApi.csproj reference MyApi.Infrastructure/MyApi.Infrastructure.csproj
dotnet add MyApi.Tests/MyApi.Tests.csproj reference MyApi/MyApi.csproj
```

### 2.4 Install Common Packages

```bash
# Entity Framework Core
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools

# Logging
dotnet add package Serilog.AspNetCore

# Testing
dotnet add package xunit
dotnet add package Moq
dotnet add package FluentAssertions

# API Documentation
dotnet add package Swashbuckle.AspNetCore

# Authentication
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

### 2.5 Configuration Files

#### .editorconfig
```ini
root = true

[*]
charset = utf-8
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true

[*.cs]
# Code style rules
csharp_prefer_braces = true:warning
csharp_prefer_simple_using_statement = true:suggestion
csharp_style_namespace_declarations = file_scoped:warning

# Naming conventions
dotnet_naming_rule.interfaces_should_be_pascal_case.severity = warning
dotnet_naming_rule.interfaces_should_be_pascal_case.symbols = interface
dotnet_naming_rule.interfaces_should_be_pascal_case.style = begins_with_i

[*.{csproj,props,targets}]
indent_size = 2
```

---

## 3. Project Structure

### 3.1 Clean Architecture Solution Structure
```
MySolution/
├── src/
│   ├── MyApi/
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   └── MyApi.csproj
│   ├── MyApi.Core/
│   │   ├── Entities/
│   │   ├── Interfaces/
│   │   ├── Services/
│   │   ├── DTOs/
│   │   ├── Exceptions/
│   │   └── MyApi.Core.csproj
│   └── MyApi.Infrastructure/
│       ├── Data/
│       ├── Repositories/
│       ├── Configurations/
│       └── MyApi.Infrastructure.csproj
├── tests/
│   ├── MyApi.Tests/
│   │   ├── Controllers/
│   │   ├── Services/
│   │   └── MyApi.Tests.csproj
│   └── MyApi.IntegrationTests/
│       └── MyApi.IntegrationTests.csproj
├── .editorconfig
├── .gitignore
├── MySolution.sln
└── README.md
```

### 3.2 Folder Organization
- **Controllers**: API endpoints and MVC controllers
- **Services**: Business logic layer
- **Repositories**: Data access layer
- **Entities/Models**: Domain models
- **DTOs**: Data Transfer Objects
- **Interfaces**: Abstractions and contracts
- **Middleware**: Custom middleware components
- **Extensions**: Extension methods

### 3.3 Naming Conventions
- **Classes**: PascalCase (e.g., `UserService`, `OrderController`)
- **Methods**: PascalCase (e.g., `GetUserById`, `ProcessOrder`)
- **Properties**: PascalCase (e.g., `FirstName`, `TotalAmount`)
- **Private fields**: _camelCase with underscore (e.g., `_userRepository`)
- **Interfaces**: PascalCase with 'I' prefix (e.g., `IUserService`)
- **Constants**: PascalCase or UPPER_SNAKE_CASE
- **Async methods**: Append `Async` suffix (e.g., `GetUserByIdAsync`)

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

#### Step 3: Restore Packages
```bash
dotnet restore
```

#### Step 4: Build Solution
```bash
dotnet build
```

#### Step 5: Run Application
```bash
dotnet run --project MyApi/MyApi.csproj

# Or with watch (auto-reload)
dotnet watch run --project MyApi/MyApi.csproj
```

### 4.2 Code Development Process

#### Step 1: Create Entity
```csharp
namespace MyApi.Core.Entities;

/// <summary>
/// Represents a user in the system.
/// </summary>
public class User
{
    /// <summary>
    /// Gets or sets the user identifier.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Gets or sets the username.
    /// </summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the email address.
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the creation timestamp.
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Gets or sets a value indicating whether the user is active.
    /// </summary>
    public bool IsActive { get; set; } = true;
}
```

#### Step 2: Create Repository Interface
```csharp
namespace MyApi.Core.Interfaces;

using MyApi.Core.Entities;

/// <summary>
/// Repository interface for User entity operations.
/// </summary>
public interface IUserRepository
{
    /// <summary>
    /// Gets all users asynchronously.
    /// </summary>
    /// <returns>A collection of users.</returns>
    Task<IEnumerable<User>> GetAllAsync();

    /// <summary>
    /// Gets a user by identifier.
    /// </summary>
    /// <param name="id">The user identifier.</param>
    /// <returns>The user if found; otherwise, null.</returns>
    Task<User?> GetByIdAsync(int id);

    /// <summary>
    /// Creates a new user.
    /// </summary>
    /// <param name="user">The user to create.</param>
    /// <returns>The created user.</returns>
    Task<User> CreateAsync(User user);

    /// <summary>
    /// Updates an existing user.
    /// </summary>
    /// <param name="user">The user to update.</param>
    /// <returns>The updated user.</returns>
    Task<User> UpdateAsync(User user);

    /// <summary>
    /// Deletes a user.
    /// </summary>
    /// <param name="id">The user identifier.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task DeleteAsync(int id);
}
```

#### Step 3: Implement Repository
```csharp
namespace MyApi.Infrastructure.Repositories;

using Microsoft.EntityFrameworkCore;
using MyApi.Core.Entities;
using MyApi.Core.Interfaces;
using MyApi.Infrastructure.Data;

/// <summary>
/// Repository implementation for User entity.
/// </summary>
public class UserRepository : IUserRepository
{
    private readonly ApplicationDbContext _context;

    public UserRepository(ApplicationDbContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
    }

    public async Task<IEnumerable<User>> GetAllAsync()
    {
        return await _context.Users
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<User?> GetByIdAsync(int id)
    {
        return await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<User> CreateAsync(User user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task<User> UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task DeleteAsync(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user != null)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
        }
    }
}
```

#### Step 4: Create Service
```csharp
namespace MyApi.Core.Services;

using MyApi.Core.Entities;
using MyApi.Core.Exceptions;
using MyApi.Core.Interfaces;
using Microsoft.Extensions.Logging;

/// <summary>
/// Service for user-related business logic.
/// </summary>
public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<UserService> _logger;

    public UserService(
        IUserRepository userRepository,
        ILogger<UserService> logger)
    {
        _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<IEnumerable<User>> GetAllUsersAsync()
    {
        _logger.LogDebug("Fetching all users");
        return await _userRepository.GetAllAsync();
    }

    public async Task<User> GetUserByIdAsync(int id)
    {
        _logger.LogDebug("Fetching user with ID: {UserId}", id);

        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
        {
            throw new NotFoundException($"User with ID {id} not found");
        }

        return user;
    }

    public async Task<User> CreateUserAsync(User user)
    {
        _logger.LogInformation("Creating user: {Username}", user.Username);

        // Validation logic here
        if (string.IsNullOrWhiteSpace(user.Username))
        {
            throw new ValidationException("Username is required");
        }

        return await _userRepository.CreateAsync(user);
    }

    public async Task<User> UpdateUserAsync(int id, User userUpdate)
    {
        _logger.LogInformation("Updating user with ID: {UserId}", id);

        var existingUser = await GetUserByIdAsync(id);

        existingUser.Username = userUpdate.Username;
        existingUser.Email = userUpdate.Email;

        return await _userRepository.UpdateAsync(existingUser);
    }

    public async Task DeleteUserAsync(int id)
    {
        _logger.LogInformation("Deleting user with ID: {UserId}", id);

        var user = await GetUserByIdAsync(id);
        await _userRepository.DeleteAsync(id);
    }
}
```

#### Step 5: Create Controller
```csharp
namespace MyApi.Controllers;

using Microsoft.AspNetCore.Mvc;
using MyApi.Core.Entities;
using MyApi.Core.Interfaces;

/// <summary>
/// Controller for user operations.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UsersController> _logger;

    public UsersController(
        IUserService userService,
        ILogger<UsersController> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    /// <summary>
    /// Gets all users.
    /// </summary>
    /// <returns>A list of users.</returns>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<User>>> GetAllUsers()
    {
        var users = await _userService.GetAllUsersAsync();
        return Ok(users);
    }

    /// <summary>
    /// Gets a user by ID.
    /// </summary>
    /// <param name="id">The user ID.</param>
    /// <returns>The user.</returns>
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<User>> GetUserById(int id)
    {
        var user = await _userService.GetUserByIdAsync(id);
        return Ok(user);
    }

    /// <summary>
    /// Creates a new user.
    /// </summary>
    /// <param name="user">The user to create.</param>
    /// <returns>The created user.</returns>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<User>> CreateUser([FromBody] User user)
    {
        var createdUser = await _userService.CreateUserAsync(user);
        return CreatedAtAction(nameof(GetUserById), new { id = createdUser.Id }, createdUser);
    }

    /// <summary>
    /// Updates an existing user.
    /// </summary>
    /// <param name="id">The user ID.</param>
    /// <param name="user">The updated user data.</param>
    /// <returns>The updated user.</returns>
    [HttpPut("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<User>> UpdateUser(int id, [FromBody] User user)
    {
        var updatedUser = await _userService.UpdateUserAsync(id, user);
        return Ok(updatedUser);
    }

    /// <summary>
    /// Deletes a user.
    /// </summary>
    /// <param name="id">The user ID.</param>
    /// <returns>No content.</returns>
    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteUser(int id)
    {
        await _userService.DeleteUserAsync(id);
        return NoContent();
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

### 5.1 General Guidelines
- Follow Microsoft's C# Coding Conventions
- Use meaningful names (no abbreviations)
- Keep methods small and focused
- Use async/await for I/O operations
- Leverage LINQ for collections
- Use nullable reference types

### 5.2 Code Formatting
```csharp
// Use file-scoped namespaces (C# 10+)
namespace MyApi.Services;

// Use primary constructors or expression-bodied members
public class Calculator
{
    // Properties
    public int Value { get; set; }

    // Expression-bodied method
    public int Add(int a, int b) => a + b;

    // Regular method
    public int Multiply(int a, int b)
    {
        return a * b;
    }
}

// Use pattern matching
public string GetUserType(User user) => user switch
{
    { IsAdmin: true } => "Administrator",
    { IsActive: true } => "Active User",
    _ => "Inactive User"
};

// Use records for DTOs (C# 9+)
public record UserDto(int Id, string Username, string Email);

// Use init-only setters
public class Product
{
    public int Id { get; init; }
    public string Name { get; init; } = string.Empty;
}
```

### 5.3 Exception Handling
```csharp
// Custom exceptions
namespace MyApi.Core.Exceptions;

public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message)
    {
    }
}

public class ValidationException : Exception
{
    public ValidationException(string message) : base(message)
    {
    }
}

// Exception handling in services
public async Task<User> ProcessUserAsync(int userId)
{
    try
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
        {
            throw new NotFoundException($"User {userId} not found");
        }

        // Process user
        return user;
    }
    catch (NotFoundException)
    {
        _logger.LogWarning("User {UserId} not found", userId);
        throw;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error processing user {UserId}", userId);
        throw new InvalidOperationException("Failed to process user", ex);
    }
}
```

### 5.4 Dependency Injection
```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Register services
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();

// Register DbContext
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();
```

### 5.5 LINQ Best Practices
```csharp
// Use method syntax for complex queries
var activeUsers = await _context.Users
    .Where(u => u.IsActive)
    .OrderBy(u => u.Username)
    .Select(u => new UserDto(u.Id, u.Username, u.Email))
    .ToListAsync();

// Use query syntax for multiple from clauses
var userOrders = from user in _context.Users
                 from order in user.Orders
                 where user.IsActive
                 select new { user.Username, order.Total };
```

---

## 6. Testing Procedures

### 6.1 Unit Testing with xUnit

#### Step 1: Create Test Class
```csharp
namespace MyApi.Tests.Services;

using Moq;
using Xunit;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using MyApi.Core.Entities;
using MyApi.Core.Interfaces;
using MyApi.Core.Services;
using MyApi.Core.Exceptions;

public class UserServiceTests
{
    private readonly Mock<IUserRepository> _mockRepository;
    private readonly Mock<ILogger<UserService>> _mockLogger;
    private readonly UserService _userService;

    public UserServiceTests()
    {
        _mockRepository = new Mock<IUserRepository>();
        _mockLogger = new Mock<ILogger<UserService>>();
        _userService = new UserService(_mockRepository.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetUserByIdAsync_WithValidId_ReturnsUser()
    {
        // Arrange
        var userId = 1;
        var expectedUser = new User
        {
            Id = userId,
            Username = "testuser",
            Email = "test@example.com"
        };

        _mockRepository
            .Setup(r => r.GetByIdAsync(userId))
            .ReturnsAsync(expectedUser);

        // Act
        var result = await _userService.GetUserByIdAsync(userId);

        // Assert
        result.Should().NotBeNull();
        result.Should().BeEquivalentTo(expectedUser);
        _mockRepository.Verify(r => r.GetByIdAsync(userId), Times.Once);
    }

    [Fact]
    public async Task GetUserByIdAsync_WithInvalidId_ThrowsNotFoundException()
    {
        // Arrange
        var userId = 999;
        _mockRepository
            .Setup(r => r.GetByIdAsync(userId))
            .ReturnsAsync((User?)null);

        // Act
        Func<Task> act = async () => await _userService.GetUserByIdAsync(userId);

        // Assert
        await act.Should().ThrowAsync<NotFoundException>()
            .WithMessage($"User with ID {userId} not found");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public async Task CreateUserAsync_WithInvalidUsername_ThrowsValidationException(string username)
    {
        // Arrange
        var user = new User { Username = username, Email = "test@example.com" };

        // Act
        Func<Task> act = async () => await _userService.CreateUserAsync(user);

        // Assert
        await act.Should().ThrowAsync<ValidationException>()
            .WithMessage("Username is required");
    }

    [Fact]
    public async Task CreateUserAsync_WithValidData_ReturnsCreatedUser()
    {
        // Arrange
        var user = new User { Username = "testuser", Email = "test@example.com" };
        var createdUser = new User
        {
            Id = 1,
            Username = user.Username,
            Email = user.Email
        };

        _mockRepository
            .Setup(r => r.CreateAsync(It.IsAny<User>()))
            .ReturnsAsync(createdUser);

        // Act
        var result = await _userService.CreateUserAsync(user);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(1);
        result.Username.Should().Be("testuser");
    }
}
```

### 6.2 Integration Testing
```csharp
namespace MyApi.IntegrationTests;

using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Json;
using Xunit;
using FluentAssertions;

public class UsersControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UsersControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetAllUsers_ReturnsSuccessStatusCode()
    {
        // Act
        var response = await _client.GetAsync("/api/users");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task CreateUser_WithValidData_ReturnsCreatedUser()
    {
        // Arrange
        var newUser = new { Username = "testuser", Email = "test@example.com" };

        // Act
        var response = await _client.PostAsJsonAsync("/api/users", newUser);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var createdUser = await response.Content.ReadFromJsonAsync<User>();
        createdUser.Should().NotBeNull();
        createdUser!.Username.Should().Be("testuser");
    }
}
```

### 6.3 Running Tests

```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura

# Run specific test
dotnet test --filter FullyQualifiedName~UserServiceTests

# Run tests in parallel
dotnet test --parallel

# Run with detailed output
dotnet test --logger "console;verbosity=detailed"
```

### 6.4 Test Coverage Requirements
- **Minimum Coverage**: 80%
- **Line Coverage**: ≥ 80%
- **Branch Coverage**: ≥ 75%
- **Method Coverage**: ≥ 85%

---

## 7. Build and Deployment

### 7.1 Build Process

```bash
# Clean solution
dotnet clean

# Restore packages
dotnet restore

# Build solution
dotnet build --configuration Release

# Publish application
dotnet publish -c Release -o ./publish

# Create self-contained deployment
dotnet publish -c Release -r win-x64 --self-contained true
```

### 7.2 Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Code coverage ≥ 80%
- [ ] No compiler warnings
- [ ] Dependencies reviewed and updated
- [ ] Connection strings configured
- [ ] Environment variables set
- [ ] Migrations applied
- [ ] Logging configured

### 7.3 Deployment Configuration

#### appsettings.json
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyDb;User Id=sa;Password=YourPassword;"
  },
  "AllowedHosts": "*",
  "JwtSettings": {
    "SecretKey": "${JWT_SECRET}",
    "Issuer": "MyApi",
    "Audience": "MyApiUsers",
    "ExpirationMinutes": 60
  }
}
```

#### appsettings.Production.json
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "${DATABASE_CONNECTION_STRING}"
  }
}
```

### 7.4 Docker Deployment

#### Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyApi/MyApi.csproj", "MyApi/"]
RUN dotnet restore "MyApi/MyApi.csproj"
COPY . .
WORKDIR "/src/MyApi"
RUN dotnet build "MyApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MyApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApi.dll"]
```

```bash
# Build Docker image
docker build -t myapi:1.0.0 .

# Run container
docker run -p 8080:80 -e ASPNETCORE_ENVIRONMENT=Production myapi:1.0.0
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### Issue 1: NuGet Package Restore Fails
**Solution**:
```bash
dotnet nuget locals all --clear
dotnet restore
```

#### Issue 2: EF Core Migration Issues
**Solution**:
```bash
# List migrations
dotnet ef migrations list

# Remove last migration
dotnet ef migrations remove

# Update database
dotnet ef database update
```

#### Issue 3: Port Already in Use
**Solution**:
```bash
# Change port in launchSettings.json or use:
dotnet run --urls "http://localhost:5001"
```

### 8.2 Debugging

```bash
# Enable detailed logging
export ASPNETCORE_ENVIRONMENT=Development

# Attach debugger
dotnet run --no-build

# View logs
dotnet run --verbosity detailed
```

---

## 9. Best Practices

### 9.1 Code Quality
- Follow SOLID principles
- Use dependency injection
- Implement proper error handling
- Use async/await consistently
- Leverage nullable reference types

### 9.2 Performance
- Use async I/O operations
- Implement caching (IMemoryCache, IDistributedCache)
- Use compiled queries for EF Core
- Implement pagination for large datasets
- Use response compression

### 9.3 Security
- Validate all input
- Use parameterized queries
- Implement authentication and authorization
- Use HTTPS in production
- Store secrets in Azure Key Vault or environment variables
- Enable CORS selectively

### 9.4 Logging
```csharp
// Structured logging
_logger.LogInformation(
    "User {UserId} logged in at {Timestamp}",
    userId,
    DateTime.UtcNow);

// Log levels
_logger.LogTrace("Trace message");
_logger.LogDebug("Debug message");
_logger.LogInformation("Info message");
_logger.LogWarning("Warning message");
_logger.LogError(exception, "Error message");
_logger.LogCritical("Critical message");
```

---

## 10. References

### 10.1 Documentation
- [.NET Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/en-us/aspnet/core/)
- [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)
- [C# Programming Guide](https://docs.microsoft.com/en-us/dotnet/csharp/)

### 10.2 Tools
- **IDE**: Visual Studio, VS Code, Rider
- **Testing**: xUnit, NUnit, MSTest, Moq
- **Code Quality**: SonarQube, ReSharper
- **Build**: .NET CLI, MSBuild

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2025 | Development Team | Initial SOP creation |

---

**Document Owner**: Development Team
**Review Frequency**: Quarterly
**Next Review Date**: March 2026
