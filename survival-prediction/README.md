# Survival Prediction

Titanic dataset from kaggle.

## Overview

The Titanic dataset is a widely used benchmark for binary classification tasks in machine learning. It contains information about the passengers aboard the RMS Titanic, including their demographics, ticket details, and whether they survived the disaster. The goal is to predict survival based on these features.

## Dataset

<details>
<summary>Files description</summary>

### Description

The dataset is split into two groups:
- **Training set** (`train..parquet`): Build models using features (passenger gender, class, age, etc.) with known survival outcomes
- **Test set** (`test..parquet`): Evaluate models on unseen data; ground truth is not provided

A sample submission file (`gender_submission.parquet`) assumes all and only female passengers survived and shows the expected output format.

</details>

<details>
<summary>Data Dictionary</summary>

### Data Dictionary

| **Variable** | **Definition**                             | **Key**                                        |
| ------------ | ------------------------------------------ | ---------------------------------------------- |
| survival     | Survival                                   | 0 = No, 1 = Yes                                |
| pclass       | Ticket class                               | 1 = 1st, 2 = 2nd, 3 = 3rd                      |
| sex          | Sex                                        |                                                |
| age          | Age in years                               |                                                |
| sibsp        | # of siblings / spouses aboard the Titanic |                                                |
| parch        | # of parents / children aboard the Titanic |                                                |
| ticket       | Ticket number                              |                                                |
| fare         | Passenger fare                             |                                                |
| cabin        | Cabin number                               |                                                |
| embarked     | Port of embarkation                        | C = Cherbourg, Q = Queenston, S = Southampton  |

</details>

<details>
<summary>Notes</summary>

### Notes

- **pclass** — Proxy for socio-economic status: 1 = Upper, 2 = Middle, 3 = Lower
- **age** — Fractional if less than 1; estimated ages given as xx.5
- **sibsp** — Siblings/spouses aboard (brother, sister, stepbrother, stepsister, husband, wife)
- **parch** — Parents/children aboard (mother, father, daughter, son, stepchild). Children travelling only with a nanny have parch = 0
- **embarked** — Port of embarkation (C = Cherbourg, Q = Queenstown, S = Southampton)

</details>
