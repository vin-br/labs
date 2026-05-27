# Enron Email Analysis

---

[![R](https://img.shields.io/badge/R-4.6.0+-073042?style=for-the-badge&logo=r&logoColor=white)](https://www.r-project.org)

---

## R Setup

Install R 4.6+

<details>
<summary>macOS (via Homebrew)</summary>

```shell
brew install --cask r-app
```

</details>

<details>
<summary>Linux (Ubuntu/Debian)</summary>

```shell
sudo apt update
sudo apt install r-base r-base-dev
```

</details>

<details>
<summary>Windows</summary>
Download and run the installer from [CRAN](https://cran.r-project.org/bin/windows/base/).

</details>

<details>
<summary>Verify installation</summary>

```shell
R --version
```

</details>

## Usage

Compile R Markdown to generate HTML report (requires pandoc):

```R
rmarkdown::render("analysis.Rmd")
```

Run Shiny app from R terminal:

```R
shiny::runApp("app.R")
```
