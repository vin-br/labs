# Cancer Detection -  Détection cancer du sein 

Dépôt git de Vincent Boettcher

## Description du projet

Vous travaillez pour un clinique qui souhaite développer un modèle permettant de prédire la présence de cellules cancéreuse à partir des caractéristiques de cellules prélevées sur le sein à l'aide d'une biopsie à l'aiguille fine.  

Pour cette mission, vous disposez du fichier de données `breast_cancer.csv`, de la documentation de ces données (https://www.kaggle.com/datasets/uciml/breast-cancer-wisconsin-data?resource=download) et du code d'un consultant avant vous, qui a eu le temps d'entraîner un premier modèle de prédiction.  

Cependant, ce consultant n'a pas fait de travail préliminaire d'exploration des données et le client pense que le modèle pourrait être amélioré. Votre mission est donc :  
- De présenter de manière extensive les données à votre client, par des statistiques descriptives et des visualisations adaptées.  
- De proposer de nouveaux modèles de prédiction et de présenter les métriques d'évaluation adaptées pour justifier ou non des meilleurs résultats que le précédent.

## 1.  Analyse exploratoire des données  

- Affichage de quelques lignes du dataframe pour montrer sa structure.  
- Présentation des différentes variables de la base et de leur type.  
- Statistiques descriptives sur chacune des variables en fonction de leur type.  
- Présenter des statistiques par diagnostic (bénin/malin) pour les variables, permettant de mettre en évidence l'aspect plus ou moins discriminant de certaines variables.  
- Illustrer à l'aide de graphiques les variables les plus discriminantes en fonction du diagnostic (scatterplot avec différentes couleurs).

## 2. Évaluation d'un modèle  

- Expliquez les étapes du code :  
        - En quoi consiste la standardisation des données? Pourquoi est-elle importante ici?   
        - Expliquez à quoi sert le fait de séparer les données en entraînement et en test.  
- Expliquez simplement comment fonctionne les arbres de décision.
- Quelles sont les limites de la métrique choisie pour évaluer le modèle? Pour le même modèle, sortez d'autres métriques d'évaluation en les commentant (précision, recall, F1 score, matrice de confusion...)