# Titanic Dataset

## Overview

The dataset is split into two groups:

- Training set (`train.csv`)
- Test set (`test.csv`)

**Training set:** Use this to build your machine learning models. For each passenger in the training set we provide the outcome (the "ground truth"). Models are built from features such as passenger gender and class. You can also apply [feature engineering](https://triangleinequality.wordpress.com/2013/09/08/basic-feature-engineering-with-the-titanic-data/) to create new features.

**Test set:** Use this to evaluate model performance on unseen data. The ground truth for the test set is not provided — your task is to predict whether each passenger survived.

We also provide `gender_submission.csv`, a sample submission that assumes that all and only female passengers survived; it shows the expected format for submissions.

## Data dictionary

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
| embarked     | Port of embarkation                        | C = Cherbourg, Q = Queenstown, S = Southampton |

## Variable notes

**pclass** — A proxy for socio-economic status (SES):

- 1 = Upper
- 2 = Middle
- 3 = Lower

**age** — Age is fractional if less than 1. If the age is estimated, it is given as xx.5.

**sibsp** — Family relations included here:

- Sibling: brother, sister, stepbrother, stepsister
- Spouse: husband, wife (mistresses and fiancés were ignored)

**parch** — Family relations included here:

- Parent: mother, father
- Child: daughter, son, stepdaughter, stepson

Some children travelled only with a nanny, so `parch = 0` for them.