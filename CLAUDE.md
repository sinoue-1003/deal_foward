# CLAUDE.md — AI Assistant Guide for deal_foward

> This file provides context for AI assistants (Claude, Copilot, etc.) working on
> this repository. It describes the project, codebase structure, development
> workflows, and conventions to follow.

## Project Overview

**deal_foward** is a new repository currently in its initial setup phase. No
application code, configuration files, or CI/CD pipelines have been added yet.
This document should be updated as the project evolves.

**Repository:** `sinoue-1003/deal_foward`

## Repository Status

- **Current state:** Empty — no source code, dependencies, or build tooling
  configured yet.
- **Primary branch:** To be established (main or master) once initial code is
  committed.
- **Development branches:** Follow the pattern `claude/<description>-<session-id>`
  for AI-assisted work.

## Directory Structure

```
deal_foward/
├── CLAUDE.md          # This file — AI assistant context and conventions
└── (empty)            # Awaiting initial project scaffolding
```

As the project grows, update this section to reflect the actual structure
(e.g., `src/`, `tests/`, `docs/`, config files, etc.).

## Development Workflow

### Getting Started

_No setup steps defined yet._ Once the project is scaffolded, document:

1. Prerequisites (runtime versions, system dependencies)
2. Installation steps (e.g., `npm install`, `pip install -r requirements.txt`)
3. Environment configuration (`.env` files, secrets)
4. How to run the project locally

### Common Commands

_No commands defined yet._ Once tooling is in place, list commands such as:

| Command | Description |
|---------|-------------|
| `<build>` | Build the project |
| `<dev>` | Start development server |
| `<test>` | Run the test suite |
| `<lint>` | Run linting checks |
| `<format>` | Auto-format code |

### Testing

_No test framework configured yet._ Document the following when tests are added:

- Test framework and runner
- How to run all tests vs. a single test
- Where test files live and naming conventions
- Minimum coverage requirements (if any)

### Linting & Formatting

_No linting or formatting tools configured yet._ When added, document:

- Tools used (ESLint, Prettier, Ruff, Black, etc.)
- How to run lint checks and auto-fix
- Editor integration notes

## Git Conventions

### Branch Naming

- Feature branches: `feature/<short-description>`
- Bug fixes: `fix/<short-description>`
- AI-assisted branches: `claude/<description>-<session-id>`

### Commit Messages

Follow clear, descriptive commit messages:

- Use the imperative mood ("Add feature" not "Added feature")
- Keep the subject line under 72 characters
- Include a body for non-trivial changes explaining the "why"

### Pull Requests

- Keep PRs focused on a single concern
- Include a summary and test plan in the PR description
- Ensure all checks pass before requesting review

## Code Conventions

_To be defined once the tech stack is chosen._ When established, document:

- Programming language(s) and version(s)
- Frameworks and key libraries
- Code style guide or standard being followed
- Naming conventions (files, variables, functions, classes)
- Import ordering rules
- Error handling patterns
- Logging conventions

## Architecture

_No architecture defined yet._ When the project takes shape, document:

- High-level architecture diagram or description
- Key components and their responsibilities
- Data flow between components
- External services and integrations
- Database schema or data model overview

## Environment & Configuration

_No environment configuration yet._ When added, document:

- Required environment variables
- Configuration file locations and formats
- Secrets management approach
- Differences between dev, staging, and production environments

## AI Assistant Guidelines

When working on this repository, AI assistants should:

1. **Read this file first** for project context before making changes.
2. **Check for updates** — this file should be the source of truth for project
   conventions and may change as the project evolves.
3. **Follow existing patterns** — match the style of surrounding code rather than
   introducing new conventions.
4. **Run tests and linting** before committing, once those tools are configured.
5. **Keep changes focused** — avoid unrelated refactors or scope creep.
6. **Update this file** when adding new tooling, changing conventions, or
   modifying project structure.
7. **Never commit secrets** — no API keys, passwords, or tokens in code.
8. **Prefer editing over creating** — modify existing files rather than creating
   new ones when possible.

## Updating This File

This CLAUDE.md should be treated as a living document. Update it when:

- The tech stack is chosen and scaffolded
- Build/test/lint commands are established
- Architectural decisions are made
- New conventions or patterns are adopted
- Directory structure changes significantly
