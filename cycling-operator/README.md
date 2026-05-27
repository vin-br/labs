# Cycling Tour Operator

---

[![Python](https://img.shields.io/badge/Python-3.14+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org) [![uv](https://img.shields.io/badge/uv-latest-261230?style=for-the-badge&logo=uv&logoColor=DE5FE9)](https://docs.astral.sh/uv/) [![OpenJDK](https://img.shields.io/badge/OpenJDK-26+-437291?style=for-the-badge&logo=openjdk&logoColor=white)](https://openjdk.org/)

---

## Overview

This project focuses on designing and implementing an XML-based database platform for a **cycling tour operator**. The system integrates and manages diverse entities—such as destinations, cycling paths, rental bikes, activities and events, tour packages, bookings, clients, and guides—to ensure efficient coordination and streamlined access to information.

---

## Table of Contents

- [Python Setup](#python-setup)
- [Java Setup](#java-setup)
- [XSLT Setup](#xslt-setup)
- [Running Use Cases](#running-use-cases)
- [Use Case Reference](#use-case-reference)

---

## Python Setup

<details>
<summary>Install uv & Python</summary>

Install [uv](https://docs.astral.sh/uv/):

```shell
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Install Python and sync dependencies:

```shell
uv python install 3.14
uv sync
```

Activate the virtual environment:

```shell
# macOS / Linux
source .venv/bin/activate

# Windows
.venv\Scripts\activate
```

**Python version used:** 3.14.5

</details>

<details>
<summary>VS Code configuration</summary>

Recommended extension: **Ruff** (formatter + linter)

In `.vscode/settings.json`:

```json
{
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true
  }
}
```

</details>

---

## Java Setup

<details>
<summary>Install Java</summary>

Install OpenJDK 21 (latest LTS open source version):

```shell
# macOS (via Homebrew)
brew install openjdk@26

# Linux (Ubuntu/Debian)
sudo apt install openjdk-26-jdk

# Windows
# Download from https://adoptium.net/
```

Verify installation:

```shell
java -version
```

</details>

## XSLT Setup

<details>
<summary>Download Java libraries for XSLT</summary>

Run once from the project root to download Saxon HE and XML Resolver into `libs/`:

```shell
bash xslt_setup.sh
```

</details>

---

## Running Use Cases

<details>
<summary>Use cases with CLI</summary>

All use cases (01–10) are driven by a single interactive CLI. Run from the project root:

```shell
uv run python run.py
```

The program prompts for a command and loops until you exit. Available commands:

```
0                         exit
01                        list all tours (HTML)
02                        list all guides (HTML)
03 --lang <language>      guides filtered by language (HTML)
04                        interactive map of tour locations (HTML)
05                        emergency contacts dashboard (HTML)
06                        bikes inventory dashboard (HTML)
07                        business analysis (JSON)
08                        operational analysis (JSON)
09                        merge sub-datasets (XML)
10                        anonymize the dataset (XML)
```

> Use case 11 (`python/11_generate_tours_map.py`) is a standalone script — see [Use Case Reference](#use-case-reference).

</details>

<details>
<summary>Use case 11 — Generate tours map</summary>

```shell
uv run python scripts/generate_tours_map.py \
  --xml dataset/merged_datasets.xml \
  --out outputs/html/11_tours_map_py.html
```

![Python HTML Map - Merged Datasets](screenshots/tours_map_py.png)

</details>

---

## Use Case Reference

| # | Description | Output |
|---|-------------|--------|
| 01 | List of all tours | `outputs/html/01_tours.html` |
| 02 | List of all guides | `outputs/html/02_guides.html` |
| 03 | Guides filtered by language | `outputs/html/03_<lang>_speaking_guides.html` |
| 04 | Interactive map of tour locations | `outputs/html/04_tours_map.html` |
| 05 | Emergency contact dashboard | `outputs/html/05_emergency_contacts.html` |
| 06 | Bike inventory dashboard | `outputs/html/06_bikes_inventory.html` |
| 07 | Business analysis | `outputs/json/07_business_analysis.json` |
| 08 | Operational analysis | `outputs/json/08_operational_analysis.json` |
| 09 | Datasets merge | `outputs/xml/09_merged_datasets.xml` |
| 10 | Anonymized dataset | `outputs/xml/10_anonymized_data.xml` |
| 11 | Generate tours map (Python script) | `outputs/html/11_tours_map_py.html` |
