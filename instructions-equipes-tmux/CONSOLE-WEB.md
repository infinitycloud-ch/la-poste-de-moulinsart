# 🌐 Console de Briefing Web - Guide d'Utilisation

## 🎯 Accès à la Console

Ouvrez votre portail Oracle : `http://localhost:5175`

Cliquez sur l'onglet **🎩 Briefing TMUX** dans la barre de navigation.

## 🖥️ Interface Console

### **📋 Panel Gauche - Équipes et Actions**

#### **👥 Sélection d'Agent**
- **Équipe Nestor** : nestor, tintin, dupont1, dupont2
- **Équipe Haddock** : haddock, rastapopoulos, tournesol1, tournesol2

Cliquez sur un agent pour le sélectionner. L'agent actif apparaît surligné en couleur.

#### **⚡ Actions Disponibles**
- **🚀 Exécuter Briefing** : Lance le script `reset-briefing.sh` pour l'agent
- **💾 Sauvegarder Version** : Crée une sauvegarde avec commentaire
- **📜 Voir Historique** : Charge l'historique des versions

### **📺 Panel Central - Console et Éditeur**

#### **Terminal Console**
- Affiche les sorties des commandes en temps réel
- Messages colorés : info (bleu), succès (vert), erreur (rouge)
- Auto-scroll vers le bas

#### **📝 Éditeur d'Instructions**
- Modifie les instructions spécifiques de l'agent sélectionné
- Sauvegarde automatiquement dans les fichiers d'équipe
- Bouton "💾 Sauvegarder Instructions" actif si modifications détectées

### **📜 Panel Droit - Historique et Versions**

#### **Gestion des Versions**
- **👁️ Prévisualiser** : Voir le contenu d'une version
- **🔄 Restaurer** : Revenir à une version antérieure
- **🗑️ Supprimer** : Effacer une version (irréversible)

#### **Versions par Projet**
- L'historique change automatiquement selon le projet sélectionné
- Versions marquées "courante" en vert

## 🔄 Workflow Complet

### **1. Sélectionner un Projet**
```
Projet actuel : [22 - MonoCLI] ▼
```

### **2. Sélectionner un Agent**
Cliquez sur un agent dans l'équipe Nestor ou Haddock.

### **3. Modifier les Instructions**
Éditez le contenu dans la zone "📝 Instructions Spécifiques" puis cliquez "💾 Sauvegarder Instructions".

### **4. Sauvegarder une Version**
1. Cliquez "💾 Sauvegarder Version"
2. Ajoutez un commentaire descriptif
3. Cliquez "💾 Sauvegarder"

### **5. Exécuter le Briefing**
Cliquez "🚀 Exécuter Briefing" pour générer le CLAUDE.md de l'agent.

### **6. Vérifier l'Output**
La console affiche :
- ✅ Statut Oracle/TMUX/Mail
- 📧 Nombre d'emails dans la boîte
- 📋 Chemin du CLAUDE.md généré

## 🎯 Cas d'Usage Types

### **Briefing Mission Complète**
```
1. Modifier instructions → Nestor (orchestrateur)
2. Modifier instructions → Tintin (enquête)
3. Modifier instructions → Dupont1 (dev)
4. Modifier instructions → Dupont2 (docs)
5. Sauvegarder version → "Mission Projet X - Sprint 8"
6. Exécuter briefing → Tous les agents
7. Vérifier console → Output succès
```

### **Rollback d'Urgence**
```
1. Aller à l'historique → Agent concerné
2. Trouver version → "Version stable"
3. Restaurer version → Confirmer
4. Exécuter briefing → Régénérer CLAUDE.md
```

### **Test et Expérimentation**
```
1. Sauvegarder version → "Backup avant test"
2. Modifier instructions → Nouvelles directives
3. Exécuter briefing → Tester
4. Si KO → Restaurer version "Backup avant test"
5. Si OK → Sauvegarder version → "Version validée"
```

## 🔧 Fonctionnalités Avancées

### **Basculement entre Projets**
- L'historique et les instructions sont **liés au projet**
- Changement de projet = nouveau contexte complet
- Permet de gérer plusieurs missions simultanément

### **Console Temps Réel**
- Horodatage de tous les messages
- Scroll automatique vers les nouveaux messages
- Messages persistants durant la session

### **Sauvegarde Intelligente**
- Détection automatique des modifications
- Commentaires obligatoires pour traçabilité
- Versions liées au projet et à l'agent

## ⚠️ Points d'Attention

### **Sauvegardes**
- **Toujours commenter** vos versions pour traçabilité
- **Tester après restauration** d'une version
- **Une version par agent par projet**

### **Instructions**
- **Sauvegarder avant d'exécuter** le briefing
- **Les instructions modifiées** ne sont actives qu'après sauvegarde + briefing
- **Cohérence d'équipe** : vérifier que les agents de la même équipe ont des instructions cohérentes

### **Console Output**
- **Vérifier les statuts système** avant d'exécuter un briefing
- **Messages d'erreur** contiennent des détails pour le debugging
- **Session active = console réinitialisée**

## 🚀 Commandes Rapides

### **Briefing Express**
```
Agent → Instructions → Sauvegarder → Exécuter → Vérifier
```

### **Backup Sécurisé**
```
Version → Commentaire → Sauvegarder → Historique → Confirmer
```

### **Rollback d'Urgence**
```
Historique → Version OK → Restaurer → Exécuter → Vérifier
```

---

**💡 Astuce** : Gardez toujours une version stable sauvegardée avant d'expérimenter !

**🎯 Support** : Tous les scripts fonctionnent aussi en ligne de commande si nécessaire.