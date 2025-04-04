# Analyse Économétrique du Modèle Gravitaire avec SAS  

## Introduction  
Bonjour à tous,  

Ce projet propose une analyse économétrique du **modèle gravitaire**, une approche utilisée en économie internationale pour estimer les flux commerciaux entre deux pays en fonction de leurs caractéristiques économiques et de la distance qui les sépare. Inspiré de la loi de gravitation de Newton, ce modèle postule que les échanges commerciaux sont proportionnels à la taille des économies (PIB, population) et inversement proportionnels à la distance entre les pays.  

### Problématique  
**Comment les facteurs économiques et géographiques influencent-ils les échanges entre les pays ?**  

---

## Données  
Nous utilisons les **données gravitaires des pays de l’OCDE** entre **1998 et 2002**, issues du **CEPII (Centre d'Études Prospectives et d'Informations Internationales)**.  

### Variables principales  
- **Variable expliquée** :  
  - `q` : volume des exportations entre un pays exportateur `i` et un pays importateur `j`.  
- **Variables explicatives** :  
  - `pump` : Prix unitaire moyen pondéré par secteur, par pays et par année.  
  - `PIB_exportateur` & `PIB_importateur` : Indicateurs de la taille économique des pays.  
  - `Population_exportateur` & `Population_importateur` : Indicateurs du potentiel économique.  
  - `Distance` : Mesure de la séparation géographique entre les deux pays.  

---

## Méthodologie  
Nous utilisons un **modèle linéaire multiple log-log**, où toutes les variables sont transformées en logarithmes pour :  
  **- Faciliter l’interprétation** des coefficients (élasticités).  
  **- Linéariser les relations non linéaires**.  
  **- Éviter les écarts d’échelles entre variables**.  

Le modèle est estimé avec **PROC REG** et **PROC MODEL** dans SAS.  

---

## Analyse des Données  
- Les exportations (`q`) sont **fortement dispersées**, avec une moyenne élevée et une médiane bien plus basse, indiquant une asymétrie due à quelques grands exportateurs.  
- Le `pump` (prix unitaire moyen pondéré) présente également une distribution **très étalée**, influencée par des produits très chers.  
- Le `PIB` et la `population` montrent une forte **concentration économique**, où quelques grandes économies dominent le commerce.  
- La `distance` impacte négativement les échanges, illustrant l’effet des coûts de transport et des barrières géographiques.  

---

## Résultats de la Régression  
### Effets des Variables Explicatives  
- **PIB exportateur** : baisse paradoxale des échanges (-70 %), possiblement due à la **multicolinéarité** avec la population.  
- **PIB importateur** : augmentation des échanges (+34 %), confirmant que les pays riches importent plus.  
- **Population exportateur** : effet très fort (+162 %), soulignant la capacité de production accrue dans les pays peuplés.  
- **Population importateur** : effet plus modéré (+16 %), reflétant une légère hausse de la demande intérieure.  
- **Distance** : une augmentation de 1 % de la distance entre les pays réduit les échanges de **81 %**, ce qui reflète l’impact des coûts de transport.  
- **Prix unitaire moyen pondéré (pump)** : une hausse de 1 % diminue les échanges de **70 %**, indiquant une sensibilité des flux commerciaux aux coûts unitaires.  

**Le modèle explique environ 26 % de la variance des exportations**, mais des problèmes de multicolinéarité pourraient affecter certaines estimations.  

---

## Limites et Perspectives  
- Le modèle reste simplifié et peut être enrichi avec des **variables additionnelles** (barrières commerciales, accords économiques, infrastructures logistiques).  
- L’**analyse de la multicolinéarité** (via un test VIF) pourrait aider à ajuster les variables explicatives et améliorer la robustesse des résultats.  

---

## Technologies Utilisées  
- **SAS** : Importation, traitement et analyse des données avec `PROC IMPORT`, `PROC REG` et `PROC MODEL`.  
- **GitHub** : Versionning du projet et partage du code.  

---

## 📜 Auteur  
👤 **EL HACHMI Séhame**  
📧 Contact : [lhmisehame@gmail.com]  
 
