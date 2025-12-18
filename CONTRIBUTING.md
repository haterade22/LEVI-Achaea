# Contributing to LEVI-Achaea

First off, thank you for considering contributing to LEVI! It's people like you that make LEVI such a great tool for the Achaea community.

## Code of Conduct

This project and everyone participating in it is governed by a code of respect and professionalism. By participating, you are expected to uphold this standard. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (commands, triggers, configuration)
- **Describe the behavior you observed** and what you expected
- **Include screenshots or logs** if applicable
- **Note your environment**: Mudlet version, operating system, Achaea class

**Bug Report Template**:
```markdown
## Description
A clear description of the bug.

## Steps to Reproduce
1. Start system with '...'
2. Execute command '...'
3. Observe behavior '...'

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- Mudlet Version: 
- OS: 
- LEVI Version: 
- Achaea Class: 
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most LEVI users
- **List examples** of how the enhancement would be used
- **Note any potential drawbacks** or implementation challenges

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the code style guidelines
3. **Add tests** if you've added functionality
4. **Ensure tests pass** by running the test suite
5. **Update documentation** to reflect your changes
6. **Write a clear commit message** describing your changes

## Development Process

### Setting Up Development Environment

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/LEVI-Achaea.git
   cd LEVI-Achaea
   ```

2. Install development dependencies:
   ```bash
   # Install Lua linter (luacheck)
   luarocks install luacheck
   ```

3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Code Style Guidelines

#### Lua Style

- **Indentation**: 2 spaces (no tabs)
- **Line Length**: Maximum 100 characters
- **Naming Conventions**:
  - Variables and functions: `snake_case`
  - Constants: `UPPER_SNAKE_CASE`
  - Modules: `PascalCase` for tables, `snake_case` for files
  - Private functions: prefix with underscore `_private_function`

- **Comments**:
  ```lua
  -- Single line comment
  
  --[[
    Multi-line comment for complex logic
    or function documentation
  ]]--
  
  --- LDoc style documentation
  -- @param affliction The affliction to cure
  -- @return true if cure was successful
  function cure_affliction(affliction)
    -- Implementation
  end
  ```

- **Function Declarations**:
  ```lua
  -- Good
  local function calculate_priority(affliction)
    return affliction.priority or 0
  end
  
  -- Avoid
  function calculatePriority(aff)
    return aff.priority or 0
  end
  ```

- **Table Declarations**:
  ```lua
  -- Good: Multi-line for complex structures
  local config = {
    enabled = true,
    priority = 5,
    methods = {
      "herb",
      "salve"
    }
  }
  
  -- Good: Single line for simple structures
  local point = {x = 10, y = 20}
  ```

#### Module Structure

Each module file should follow this structure:

```lua
--- Module description
-- @module module_name

local module_name = {}

-- Module-level constants
local CONSTANT_VALUE = 100

-- Private functions
local function _private_helper()
  -- Implementation
end

-- Public functions
--- Public function description
-- @param param1 Description
-- @return Description
function module_name.public_function(param1)
  -- Implementation
end

-- Initialization
function module_name.init()
  -- Setup code
end

return module_name
```

### Testing Guidelines

1. **Unit Tests**: Test individual functions in isolation
   ```lua
   -- tests/test_curing.lua
   local curing = require("curing.logic")
   
   function test_priority_calculation()
     local aff = {name = "asthma", priority = 10}
     assert(curing.get_priority(aff) == 10)
   end
   ```

2. **Integration Tests**: Test module interactions
3. **Run tests before submitting**:
   ```bash
   lua tests/run_tests.lua
   ```

### Linting

Before submitting, run the linter:

```bash
luacheck core/ tracking/ curing/ offense/ ui/ config/
```

Fix any warnings or errors reported.

### Documentation

- **Update README.md** if you change functionality
- **Update ARCHITECTURE.md** for structural changes
- **Update CHANGELOG.md** with your changes
- **Add inline comments** for complex logic
- **Write clear commit messages**

### Commit Message Guidelines

Follow the conventional commits specification:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(curing): add support for focus curing
fix(tracking): correct affliction detection for asthma
docs(readme): update installation instructions
```

## Project Structure

Please maintain the existing structure:

```
LEVI-Achaea/
├── core/          # Core system (init, events, utilities)
├── tracking/      # State tracking (afflictions, balances)
├── curing/        # Curing system (priorities, logic)
├── offense/       # Offense system (abilities, queuing)
├── ui/            # User interface (displays, gauges)
├── config/        # Configuration files
├── docs/          # Additional documentation
├── tests/         # Test suite
└── .github/       # GitHub templates and workflows
```

## Review Process

1. **Automated checks**: GitHub Actions will run linting
2. **Code review**: Maintainers will review your code
3. **Testing**: Changes will be tested in-game
4. **Discussion**: We may suggest changes or improvements
5. **Merge**: Once approved, your PR will be merged

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- The contributor graph

## Questions?

Don't hesitate to ask questions by:
- Opening an issue with the `question` label
- Reaching out to maintainers
- Joining our community discussions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to LEVI! Your efforts help make combat in Achaea more accessible and enjoyable for everyone.
