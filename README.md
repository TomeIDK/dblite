# DBLite

**A lightweight PowerShell database inspection and querying tool with a WinForms UI.**

---

## Table of Contents

- [Overview](#overview)  
- [Purpose](#purpose)  
- [Features](#features)  
- [Installation](#installation)  
- [Configuration](#configuration)  
- [Supported Databases](#supported-databases)  
- [Usage & Examples](#usage--examples)  
- [Requirements](#requirements)  
- [Logging & Debugging](#logging--debugging)  
- [Contributing](#contributing)  
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
4. Launch DBLite:
```powershell
Start-DBLite <connection string OR alias>
```

### PowerShell Gallery (Planned)
Once published, DBLite will be installable via:
```powershell
Install-Module -Name DBLite -Scope CurrentUser
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

## Requirements
- Windows
- PowerShell 7+
- .NET Framework (for WinForms)
- Database-specific client libraries:
  - SQL Server: `System.Data.SqlClient`

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
- Follow the existing project structure
- Add Pester tests for new functionality
- Keep providers isolated and self-contained
- Ensure logging is added for non-trivial operations
- Update documentation when behaviour changes

---

## Sources
[PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)  
[WinForms Documentation](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/)  
[Microsoft - How to write a powershell module manifest?](https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest?view=powershell-7.5)  
[SQL Server DMV Documentation](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver17)  
[ss64.com - Messagebox](https://ss64.com/ps/messagebox.html)  
[Pester Documentation](https://pester.dev/docs/quick-start)  
[ChatGPT](https://chatgpt.com/)  

### Generative AI Usage
ChatGPT was used during development as a productivity aid. It was primarily used to speed up repetitive tasks, validate design decisions, and act as a sounding board for alternative approaches. As this is my first PowerShell project, GenAI served as a secondary helper rather than a primary decision-maker, with all architectural and implementation choices reviewed and applied deliberately.
- WinForms UI
- Project structure and architecture
- General Debugging
- Test review
- SQL query formulation
