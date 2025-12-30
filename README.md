# DBLite

**A lightweight PowerShell database inspection and querying tool with a WinForms UI.**

---

## Table of Contents

- [Overview](#overview)
- [Purpose](#purpose)
- [Requirements](#requirements)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Supported Databases](#supported-databases)
- [Usage & Examples](#usage--examples)
- [Logging & Debugging](#logging--debugging)
- [Contributing](#contributing)
- [Project Structure & Architecture](#project-structure--architecture)
- [Sources](#sources)

---

## Overview

**DBLite** is a PowerShell module designed to provide a lightweight, GUI-based interface for browsing, managing, and querying relational databases.
It aims to provide fast database access, structured views of tables, indexes, and query history, and easy integration with multiple database providers, all from within PowerShell.

---

## Purpose

This module is used for managing and exploring relational databases without needing full-featured database management tools.
Target users include database administrators, developers, and IT professionals who work with multiple database types.
Typical scenarios include browsing table structures, inspecting indexes, running queries, tracking query history, and performing lightweight database maintenance tasks.

---

## Requirements

- Windows
- PowerShell 7+
- .NET Desktop Runtime (for WinForms)
- Database-specific client libraries:
  - SQL Server client library:
    - `System.Data.SqlClient`
    - `Microsoft.Data.SqlClient`

---

## Features

- WinForms GUI
- Pluggable database provider architecture
- Query editor with execution support
- Query history tracking
- Saved queries for reusable snippets
- Database connection string aliases
- Schema browser
- Export tables to JSON and/or CSV
- Backup creation
- Backup history
- Index inspection
- User listing
- Performance-oriented views backed by database metadata and Dynamic Management Views (DMVs)
- Executed query performance view
- Centralized logging with daily log rotation
- JSON-based configuration files
- Test coverage using Pester
- Designed for future expansion to additional database engines

---

## Installation

### Manual / Local Installation

1. Clone or download the repository
2. Ensure the folder structure is preserved
3. Import the module directly from a PowerShell terminal:

```powershell
Import-Module "<path>\DBLite.psm1" -Force
```

4. Launch DBLite to initialize the config folder and contents. This will generate a warning and some errors but is the easiest way to generate all necessary config:

```powershell
Start-DBLite <any random string>
```

5. Add your connection string aliases to the generated `config\aliases.json` then start DBLite again

```json
"alias": "connection_string"
```

```powershell
Start-DBLite <any random string>
```

### PowerShell Gallery (Planned)

1. Once published, DBLite will be installable via:

```powershell
Install-Module -Name DBLite -Scope CurrentUser
```

2. Launch DBLite to initialize the config folder and contents. This will generate a warning and some errors but is the easiest way to generate all necessary config:

```powershell
Start-DBLite <any random string>
```

3. Add your connection string aliases to the generated `config\aliases.json` then start DBLite again

```json
"alias": "connection_string"
```

```powershell
Start-DBLite <any random string>
```

---

## Configuration

DBLite generates and maintains several configuration and data files under the project directory.

#### `config\savedqueries.json`

- Stores user-defined saved queries
- Queries are named and reusable across sessions
- Designed for quick access to frequently used SQL

#### `config\aliases.json`

- Stores connection aliases
- Maps a short, human-readable name to a full connection string or server address
- Allows connecting to databases without repeatedly pasting sensitive or long connection strings
- Designed for quick access to databases

#### `logs\queryhistory.json`

- Stores most executed queries from within DBLite
- Includes metadata such as database, timestamp, and execution status
- Intended for performance analysis and auditing
- Safe to delete, but **history will be lost**

#### `logs\dblite-YYYY-MM-DD.log`

- Daily log files using ISO date format
- Contains informational, warning, and error messages
- Used for debugging, auditing, and issue reporting

---

## Supported Databases

### Currently Supported

- SQL Server

### Planned / Next Providers

- PostgreSQL
- MySQL
- Schema Visualization

The provider model is intentionally abstracted so each database engine can be added as a standalone implementation.

---

## Usage & Examples

### Starting DBLite

DBLite is launched from PowerShell after importing the module. A lightweight bootstrap script initializes the UI and core services.
Typical flow:

- Import the module
- Start the application with a connection string or alias

### Connecting to a Database

Connections are defined using aliases rather than raw connection strings:

1. Define a connection alias in `aliases.json`
2. Provide the full connection string or server address with a memorable name
3. Use the alias name when starting DBLite
   This avoids repeatedly pasting long or sensitive connection details and allows quick switching between environments.

### Executing Queries

- Queries are written in the query editor view
- Queries are executed on the active database connection
- Queries can be executed directly from the UI
- Frequently used queries can be stored in `savedqueries.json` or through the UI
- Double-clicking a saved query loads it into the SQL text editor
  Executed queries are automatically recorded in `queryhistory.json` along with metadata such as timestamp, database, and execution status. Saved queries are intended for administrative tasks, diagnostics, and recurring inspections.

### Query History

- Review previously executed queries from within DBLite
- Only shows queries for the database you are currently connected to by database name
- Use historical data for performance analysis
  This data is stored locally and can be safely cleared if needed.

### Schema Browser

The schema browser provides read-only insight into the database structure, including:

- Tables and views
- Data types and constraints
- Indexes
  Information is sourced from system catalogs and DMVs where available.

### Performance and Index Views

Performance-related views expose database metadata such as:

- Index size
- Index usage statistics (since latest restart)
- Current amount of connections
- Database resource usage
- Statistics derived from `queryhistory.json`

### Example Workflow

1. Add a SQL Server connection alias to `aliases.json`
2. Launch DBLite
3. Browse schemas to inspect tables and indexes
4. Run diagnostic queries
5. Save useful queries for later reuse
6. Review query history and performance data

---

## Logging & Debugging

- Centralized logging via a dedicated logger utility
- Logs are written to disk with daily rotation
- Log files older than 30 days are automatically deleted
- Includes structured messages for:
  - Startup and shutdown
  - Database connections
  - Query execution
  - Errors and warnings
- Logs should be included when reporting bugs or unexpected behaviour

---

## Contributing

Contributions are welcome. Guidelines:

- Follow the existing project structure (See Project Structure & Architecture)
- Add Pester tests for new functionality
- Keep providers isolated and self-contained
- Ensure logging is added for non-trivial operations
- Update documentation when behaviour changes

---

## Project Structure & Architecture

DBLite is structured as a modular PowerShell application with a clear separation between core logic, providers, UI, utilities and tests. This allows new database engines to be added without modifying existing code and keeps the UI decoupled from database implementations:

- The UI never talks directly to a database
- All database interaction is handled by a provider
- Providers expose a consistent method surface
- Logging and configuration are centralized

### Project Tree

```
├───config
├───logs
├───src
│   ├───core
│   ├───gui
│   │   ├───assets
│   │   ├───controllers
│   │   └───views
│   ├───providers
│   └───utils
└───tests
    ├───controllers
    ├───providers
    └───utils
```

### Core

Defines provider contracts and shared behaviour.

`IDatabaseProvider.ps1`

- Defines the expected provider surface
- Ensures all providers expose the same capabilities

`DatabaseProviderBase.ps1`

- Creates the base provider object
- Tracks shared state
- Providers extend this base object and add behaviour

### Providers

Database-specific implementation. Each provider:

- Is fully self-contained
- Handles its own dependencies
- Logs all operations

Adding a new database engine means:

1. Creating a new provider file
2. Implementing the same method set
3. Registering it in the bootstrap logic

### GUI

Presentation and interaction only.

`MainForm.ps1`

- Initializes the WinForms UI
- Loads controllers and views

**Controllers** `src/gui/controllers`

- Acts as the glue between UI and provider
- Call provider methods
- Transform results into UI-friendly formats
- Never execute SQL directly

**Views** `src/gui/views`

- Pure WinForms layout and rendering
- No business logic
- No database access

### Utilities

Cross-cutting concerns.

`Logger.ps1`

- Centralized logging
- Daily log rotation
- Support Info, Warning, Error, Debug levels

`Aliases.ps1`

- Manages connection aliases
- Reads and writes aliases.json

### Testing

DBLite uses Pester for unit testing:

- Tests mirror the src folder structure
- Providers are tested in isolation

---

## Sources

- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
- [WinForms Documentation](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/)
- [Microsoft - How to write a powershell module manifest?](https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest?view=powershell-7.5)
- [SQL Server DMV Documentation](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver17)
- [ss64.com - Messagebox](https://ss64.com/ps/messagebox.html)
- [Pester Documentation](https://pester.dev/docs/quick-start)
- [gwalkey: Using Microsoft.Data.SqlClient in PowerShell](https://gist.github.com/gwalkey/00fe9e353ac755e5278bd6d092f20746)
- System Automation & Scripting Course Powerpoints
- [ChatGPT Chat - Project Structure & psd1](https://chatgpt.com/share/6953c550-d814-800b-8ed0-999a0f9cd4de)
- [ChatGPT Chat - SQL Server data resources](https://chatgpt.com/share/6953c594-8ef8-800b-9103-c64dd12fedff)
- [ChatGPT Chat - Project Structure and testing](https://chatgpt.com/share/6953c612-530c-800b-aa94-298ef792cef6)
- [ChatGPT Chat - Logging Setup](https://chatgpt.com/share/6953c62f-2f28-800b-8612-0cabd0e6ae55)
- [ChatGPT Chat - Test philosophy and setup](https://chatgpt.com/share/6953c653-a0e4-800b-9e9d-2640181ee504)
- [ChatGPT Chat - UI layout design](https://chatgpt.com/share/6953c676-867c-800b-a56b-828c66e4918f)
- [ChatGPT Chat - Documentation](https://chatgpt.com/share/6953c6b8-9a70-800b-a8ca-29c735733b54)
- [ChatGPT Chat - Build Folder](https://chatgpt.com/share/695417fc-0718-800b-81ff-9be528d9983a)

### Generative AI Usage

ChatGPT was used during development as a productivity aid. It was primarily used to speed up repetitive tasks, validate design decisions, and act as a sounding board for alternative approaches. As this is my first PowerShell project, GenAI served as a secondary helper rather than a primary decision-maker, with all architectural and implementation choices reviewed and applied deliberately.

- WinForms UI
- Project structure and architecture
- General Debugging
- Test review
- SQL query formulation
- Build folder (not included in Git)
- All documentation (proof-read by me)
