# DBLite

**A lightweight Powershell database inspector with WinForms.**

---

## Table of Contents

- [Overview](#overview)  
- [Purpose](#purpose)  
- [Features](#features)  
- [Installation](#installation)  
- [Configuration](#configuration)  
- [Usage](#usage)  
- [Examples](#examples)  
- [Requirements](#requirements)  
- [Logging & Debugging](#logging--debugging)  
- [Contributing](#contributing)  
- [Sources](#sources)  
- [License](#license)  

---

## Overview

**DBLite** is a PowerShell module designed to provide a lightweight, GUI-based interface for browsing, managing, and querying relational databases.  
It aims to provide fast database access, clear visualizations of tables, indexes, and query history, and easy integration with multiple database providers, all from within PowerShell.

---

## Purpose

This module is used for managing and exploring relational databases without needing full-featured database management tools.  
Target users include database administrators, developers, and IT professionals who work with multiple database types.  
Typical scenarios include browsing table structures, inspecting indexes, running queries, tracking query history, and performing lightweight database maintenance tasks.

---

## Features

- [x] Connect to a database
- [x] Database support for SQL Server
- [x] WinForms GUI
- [x] Database aliases
- [x] Logging module
- [x] Query editor
- [x] Query history
- [x] Performance analysis
- [x] Index analysis
- [x] Backup manager
- [x] Schema browser
- [ ] Schema visualization
- [x] Error handling with informative messages
- [x] Pester tests
- [ ] Documentation

---

## Installation

### PowerShell Gallery

```powershell
Install-Module -Name DBLite -Scope CurrentUser
```


Wat, waarvoor, hoe installeren, configureren, hoe te gebruiken, sources, code references, psd1 files, README heel belangrijk, demo met large-scale complex data

Sources:
https://learn.microsoft.com/en-us/powershell/scripting/developer/module/ how-to-write-a-powershell-module-manifest?view=powershell-7.5
https://ss64.com/ps/messagebox.html
https://pester.dev/docs/quick-start  
