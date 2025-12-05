# Standard Operating Procedure (SOP) - JavaScript

## Document Information
- **Version**: 1.0
- **Last Updated**: December 2025
- **Purpose**: Standard Operating Procedure for JavaScript Development and Testing

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
This SOP covers the complete development lifecycle for JavaScript applications, including:
- Environment configuration
- Code development and testing
- Build processes
- Deployment procedures

### 1.2 Audience
- Frontend Developers
- Full-Stack Engineers
- QA Engineers
- DevOps Engineers

### 1.3 Prerequisites
- Node.js (v18.x or higher)
- npm or yarn package manager
- Git version control
- Code editor (VS Code recommended)

---

## 2. Environment Setup

### 2.1 Install Node.js and npm

#### Step 1: Download and Install Node.js
```bash
# Verify installation
node --version
npm --version
```

#### Step 2: Update npm to Latest Version
```bash
npm install -g npm@latest
```

### 2.2 Project Initialization

#### Step 1: Create New Project
```bash
# Create project directory
mkdir my-javascript-project
cd my-javascript-project

# Initialize npm project
npm init -y
```

#### Step 2: Install Essential Dependencies
```bash
# Production dependencies
npm install express axios dotenv

# Development dependencies
npm install --save-dev \
  jest \
  eslint \
  prettier \
  nodemon \
  @babel/core \
  @babel/preset-env
```

### 2.3 Configuration Files

#### Step 1: Create `.eslintrc.json`
```json
{
  "env": {
    "node": true,
    "es2021": true,
    "jest": true
  },
  "extends": ["eslint:recommended"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "indent": ["error", 2],
    "quotes": ["error", "single"],
    "semi": ["error", "always"]
  }
}
```

#### Step 2: Create `.prettierrc`
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
```

#### Step 3: Create `jest.config.js`
```javascript
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.test.js'
  ],
  testMatch: [
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ]
};
```

---

## 3. Project Structure

### 3.1 Recommended Directory Layout
```
my-javascript-project/
├── src/
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── utils/
│   └── index.js
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── config/
│   └── config.js
├── public/
│   ├── css/
│   ├── js/
│   └── images/
├── .env.example
├── .eslintrc.json
├── .gitignore
├── .prettierrc
├── jest.config.js
├── package.json
└── README.md
```

### 3.2 File Naming Conventions
- **Source files**: Use camelCase (e.g., `userService.js`)
- **Test files**: Use `.test.js` or `.spec.js` suffix (e.g., `userService.test.js`)
- **Constants**: Use UPPER_SNAKE_CASE (e.g., `API_CONSTANTS.js`)
- **Classes**: Use PascalCase (e.g., `UserController.js`)

---

## 4. Development Workflow

### 4.1 Starting Development

#### Step 1: Pull Latest Code
```bash
git pull origin main
```

#### Step 2: Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

#### Step 3: Install Dependencies
```bash
npm install
```

#### Step 4: Start Development Server
```bash
npm run dev
```

### 4.2 Code Development Process

#### Step 1: Write Code
- Follow coding standards (see Section 5)
- Write modular, reusable functions
- Add JSDoc comments for functions

Example:
```javascript
/**
 * Calculates the total price with tax
 * @param {number} price - The base price
 * @param {number} taxRate - The tax rate (e.g., 0.08 for 8%)
 * @returns {number} The total price including tax
 */
function calculateTotal(price, taxRate) {
  return price * (1 + taxRate);
}
```

#### Step 2: Run Linter
```bash
npm run lint
```

#### Step 3: Format Code
```bash
npm run format
```

### 4.3 Version Control

#### Step 1: Stage Changes
```bash
git add .
```

#### Step 2: Commit with Descriptive Message
```bash
git commit -m "feat: add user authentication service"
```

**Commit Message Convention:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

#### Step 3: Push to Remote
```bash
git push origin feature/your-feature-name
```

---

## 5. Coding Standards

### 5.1 General Guidelines
- Use ES6+ syntax (arrow functions, destructuring, template literals)
- Keep functions small and focused (Single Responsibility Principle)
- Use meaningful variable and function names
- Avoid nested callbacks (use async/await)

### 5.2 Variable Declarations
```javascript
// Use const by default
const MAX_USERS = 100;

// Use let for variables that will be reassigned
let counter = 0;

// Avoid var
// ❌ var oldStyle = 'avoid';
```

### 5.3 Functions
```javascript
// Arrow functions for simple operations
const add = (a, b) => a + b;

// Named functions for complex logic
function processUserData(userData) {
  // implementation
}

// Async/await for asynchronous operations
async function fetchUserData(userId) {
  try {
    const response = await fetch(`/api/users/${userId}`);
    return await response.json();
  } catch (error) {
    console.error('Error fetching user:', error);
    throw error;
  }
}
```

### 5.4 Error Handling
```javascript
// Always use try-catch for async operations
async function saveUser(user) {
  try {
    const result = await db.users.insert(user);
    return result;
  } catch (error) {
    logger.error('Failed to save user:', error);
    throw new Error('User save operation failed');
  }
}

// Use custom error classes
class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
  }
}
```

### 5.5 Module Structure
```javascript
// Import statements at the top
import express from 'express';
import { getUserById, createUser } from './userService.js';

// Constants
const PORT = process.env.PORT || 3000;

// Main logic
const app = express();

// Export at the bottom
export default app;
export { PORT };
```

---

## 6. Testing Procedures

### 6.1 Test Setup

#### Step 1: Create Test File
```bash
# For src/services/userService.js
# Create tests/unit/userService.test.js
```

#### Step 2: Write Unit Tests
```javascript
// tests/unit/userService.test.js
import { getUserById, createUser } from '../../src/services/userService';

describe('UserService', () => {
  describe('getUserById', () => {
    it('should return user when valid ID is provided', async () => {
      const userId = '123';
      const user = await getUserById(userId);

      expect(user).toBeDefined();
      expect(user.id).toBe(userId);
    });

    it('should throw error when user not found', async () => {
      const invalidId = 'invalid';

      await expect(getUserById(invalidId))
        .rejects
        .toThrow('User not found');
    });
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com'
      };

      const user = await createUser(userData);

      expect(user).toHaveProperty('id');
      expect(user.name).toBe(userData.name);
      expect(user.email).toBe(userData.email);
    });
  });
});
```

### 6.2 Running Tests

#### Step 1: Run All Tests
```bash
npm test
```

#### Step 2: Run Specific Test File
```bash
npm test -- userService.test.js
```

#### Step 3: Run Tests with Coverage
```bash
npm test -- --coverage
```

#### Step 4: Run Tests in Watch Mode
```bash
npm test -- --watch
```

### 6.3 Test Coverage Requirements
- **Minimum Coverage**: 80% for all metrics
- **Unit Tests**: Test individual functions and methods
- **Integration Tests**: Test component interactions
- **E2E Tests**: Test complete user workflows

### 6.4 Mocking
```javascript
// Mock external dependencies
jest.mock('../../src/services/database');
import { database } from '../../src/services/database';

describe('UserService with mocks', () => {
  beforeEach(() => {
    database.findOne.mockClear();
  });

  it('should call database with correct parameters', async () => {
    database.findOne.mockResolvedValue({ id: '123', name: 'John' });

    await getUserById('123');

    expect(database.findOne).toHaveBeenCalledWith({ id: '123' });
  });
});
```

---

## 7. Build and Deployment

### 7.1 Build Process

#### Step 1: Update package.json Scripts
```json
{
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "build": "babel src -d dist",
    "test": "jest",
    "lint": "eslint src/**/*.js",
    "format": "prettier --write \"src/**/*.js\"",
    "pretest": "npm run lint"
  }
}
```

#### Step 2: Run Production Build
```bash
npm run build
```

### 7.2 Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Code coverage meets requirements (≥80%)
- [ ] Linter reports no errors
- [ ] Environment variables documented
- [ ] Dependencies updated and audited
- [ ] Security vulnerabilities addressed

### 7.3 Deployment Steps

#### Step 1: Security Audit
```bash
npm audit
npm audit fix
```

#### Step 2: Build Application
```bash
npm run build
```

#### Step 3: Test Production Build
```bash
NODE_ENV=production npm start
```

#### Step 4: Deploy to Server
```bash
# Example: Deploy to server
scp -r dist/ user@server:/path/to/app/
ssh user@server 'cd /path/to/app && npm install --production && pm2 restart app'
```

### 7.4 Environment Variables
```bash
# .env.example
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://localhost:5432/mydb
API_KEY=your_api_key_here
JWT_SECRET=your_jwt_secret
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### Issue 1: Module Not Found
**Problem**: `Error: Cannot find module 'xyz'`

**Solution**:
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### Issue 2: Port Already in Use
**Problem**: `Error: listen EADDRINUSE: address already in use :::3000`

**Solution**:
```bash
# Find and kill process using the port
lsof -ti:3000 | xargs kill -9

# Or use different port
PORT=3001 npm start
```

#### Issue 3: Test Failures
**Problem**: Tests fail randomly or inconsistently

**Solution**:
```bash
# Clear Jest cache
jest --clearCache

# Run tests in band (no parallel execution)
npm test -- --runInBand
```

### 8.2 Debugging

#### Enable Debug Logging
```bash
DEBUG=* npm start
```

#### Use Chrome DevTools
```bash
node --inspect src/index.js
```

Then open `chrome://inspect` in Chrome browser.

---

## 9. Best Practices

### 9.1 Code Quality
- Use ESLint and Prettier for consistent code style
- Write self-documenting code with clear variable names
- Keep functions pure when possible (no side effects)
- Use TypeScript for large projects (optional but recommended)

### 9.2 Performance
- Use lazy loading for large modules
- Implement caching where appropriate
- Avoid synchronous operations in production
- Use connection pooling for database connections
- Implement rate limiting for APIs

### 9.3 Security
- Never commit sensitive data (use .gitignore)
- Validate and sanitize all user input
- Use environment variables for configuration
- Keep dependencies updated
- Use HTTPS in production
- Implement proper authentication and authorization
- Use security headers (helmet.js)

### 9.4 Documentation
- Write clear README.md files
- Document API endpoints (use Swagger/OpenAPI)
- Add JSDoc comments for public APIs
- Keep changelog updated
- Document environment variables

### 9.5 Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] No security vulnerabilities introduced
- [ ] Error handling is appropriate
- [ ] Code is well-documented
- [ ] No console.log statements in production code
- [ ] Performance implications considered
- [ ] Backward compatibility maintained

---

## 10. References

### 10.1 Documentation
- [Node.js Documentation](https://nodejs.org/docs/)
- [MDN JavaScript Reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [ESLint Rules](https://eslint.org/docs/rules/)

### 10.2 Tools
- **Node Version Manager**: nvm
- **Package Manager**: npm, yarn, pnpm
- **Test Framework**: Jest, Mocha, Jasmine
- **Build Tools**: Webpack, Rollup, Vite
- **Linter**: ESLint
- **Formatter**: Prettier

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2025 | Development Team | Initial SOP creation |

---

**Document Owner**: Development Team
**Review Frequency**: Quarterly
**Next Review Date**: March 2026
