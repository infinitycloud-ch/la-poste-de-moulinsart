Product Requirements Document (PRD-V3)
PrivExpensIA - Projet "Phénix"
Version: 3.0
Date: Janvier 2025
Classification: Confidentiel
Auteur: [Author]

Executive Summary
PrivExpensIA est une application iOS native de gestion de dépenses personnelles, conçue avec une architecture "IA-first" et optimisée pour une implémentation par ferme agentique. Ce document définit les spécifications complètes pour la reconstruction accélérée de l'application via le Projet Phénix.

1. Vision & Objectifs
1.1 Vision Produit
Application premium de gestion financière personnelle combinant confidentialité absolue (traitement 100% on-device) et intelligence artificielle avancée pour l'extraction automatique des données de reçus.
1.2 Objectifs Stratégiques

Recréation complète de l'application existante avec architecture modernisée
Réduction de 70% du temps de développement via approche agentique
Élimination de la dette technique accumulée
Préparation pour évolution multi-plateforme future

1.3 Utilisateur Cible
Professionnels et particuliers exigeants recherchant une solution de gestion financière alliant simplicité, rapidité et confidentialité absolue des données.

2. Architecture Technique
2.1 Vue d'Ensemble
┌─────────────────────────────────────────────┐
│            APPLICATION iOS                   │
│                                              │
│  ┌────────────────────────────────────┐     │
│  │         UI Layer (SwiftUI)         │     │
│  │  ┌──────────────────────────────┐  │     │
│  │  │    Source de Vérité Unique   │  │     │
│  │  │  (EnvironmentObjects, Data)  │  │     │
│  │  └──────────────────────────────┘  │     │
│  └────────────────────────────────────┘     │
│                                              │
│  ┌────────────────────────────────────┐     │
│  │      Processing Layer              │     │
│  │  ┌──────────────────────────────┐  │     │
│  │  │   UnifiedPipelineManager     │  │     │
│  │  │  ┌─────────┐  ┌──────────┐  │  │     │
│  │  │  │ Parser  │→ │ IA Qwen  │  │  │     │
│  │  │  │(Rapide) │  │(Précise) │  │  │     │
│  │  │  └─────────┘  └──────────┘  │  │     │
│  │  └──────────────────────────────┘  │     │
│  └────────────────────────────────────┘     │
│                                              │
│  ┌────────────────────────────────────┐     │
│  │        Storage Layer               │     │
│  │    (CoreData + CloudKit Sync)     │     │
│  └────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
2.2 Composants Clés
2.2.1 Source de Vérité Unique

Responsabilité: Gestion centralisée de l'état global
Technologies: SwiftUI EnvironmentObjects, @Published properties
Données gérées:

Devise active (CHF/EUR/USD)
Langue d'interface (FR/EN/DE/IT)
État de synchronisation CloudKit
Préférences utilisateur



2.2.2 UnifiedPipelineManager

Responsabilité: Orchestration intelligente de l'extraction de données
Modes opératoires:

.auto - Sélection automatique basée sur la complexité
.forceParser - Parser uniquement (mode rapide)
.forceQwen - IA uniquement (mode précis)


Architecture "Filet de Sécurité": Fallback automatique Parser → IA

2.2.3 Module IA Qwen2-VL (7B)

Modèle: Qwen2-VL quantifié 4-bit
Taille: ~3.5GB on-device
Capacités: OCR avancé, extraction structurée, multi-langue
Performance cible: P95 < 2 secondes

2.3 Stack Technologique
CoucheTechnologiesUISwiftUI 6.0, Glass morphism, SF Symbols 5LogiqueSwift 5.10, Async/Await, ActorsIACoreML, MLX Swift, Qwen2-VLStockageCoreData, CloudKit, UserDefaultsTestsXCTest, Swift Testing Framework

3. Fonctionnalités MVP
3.1 Écrans Principaux
HomeGlassView

Liste des dépenses récentes avec effet glassmorphism
Barre de recherche avec filtres avancés
Statistiques en temps réel (total jour/semaine/mois)
Action button flottant pour ajout rapide

AddExpenseGlassView

Capture photo du reçu
Extraction automatique via UnifiedPipelineManager
Édition manuelle des champs extraits
Catégorisation intelligente
Validation et sauvegarde

SettingsGlassView

Sélection devise (CHF/EUR/USD)
Changement de langue
Gestion synchronisation CloudKit
Export de données (CSV/PDF)
Informations légales

StatsGlassView

Graphiques interactifs (camembert, barres, courbes)
Analyse par catégorie
Tendances temporelles
Comparaisons période vs période

3.2 Flux Utilisateur Principal
mermaidgraph LR
    A[Ouverture App] --> B[HomeGlassView]
    B --> C[Tap +]
    C --> D[Capture Photo]
    D --> E[Extraction Auto]
    E --> F[Vérification]
    F --> G[Sauvegarde]
    G --> B
3.3 Matrice de Priorités
FonctionnalitéSprintPrioritéComplexitéArchitecture Source de Vérité1CRITIQUEÉlevéeParser de base1CRITIQUEMoyenneUI HomeGlassView2HAUTEMoyenneUI AddExpenseGlassView2HAUTEÉlevéeIntégration IA Qwen3HAUTETrès ÉlevéeArchitecture Filet de Sécurité3CRITIQUEÉlevéeUI SettingsGlassView4MOYENNEFaibleSync CloudKit5MOYENNEÉlevéeExport CSV/PDF6BASSEMoyenne

4. Organisation de la Ferme Agentique
4.1 Structure d'Équipe
NESTOR - Orchestrateur Principal

Rôle: Décomposition des objectifs en tâches atomiques
Responsabilités:

Assignation des tâches aux agents spécialisés
Coordination inter-agents
Reporting d'avancement
Gestion des dépendances



DUPONT1 - Spécialiste UI/UX

Rôle: Implémentation SwiftUI
Responsabilités:

Création des vues glassmorphism
Intégration des EnvironmentObjects
Animations et transitions
Responsive design



MARTIN - Architecte Backend

Rôle: Logique métier et persistance
Responsabilités:

Modèles CoreData
UnifiedPipelineManager
Sync CloudKit
Gestion des états



BERNARD - Expert IA

Rôle: Intégration Qwen2-VL
Responsabilités:

Optimisation du modèle
Pipeline MLX Swift
Gestion mémoire GPU
Métriques de performance



TINTIN - Ingénieur QA

Rôle: Qualité et tests
Responsabilités:

Tests unitaires XCTest
Tests d'intégration
Validation des builds
Documentation des bugs



4.2 Protocoles de Communication
Règle de la Ferme: Les agents communiquent exclusivement via:

Artefacts de code versionné
Rapports JSON structurés
Pull requests avec descriptions atomiques
Jamais de prose libre pour éviter l'hallucination contagieuse

4.3 Format de Tâche Standard
json{
  "taskId": "UI-01",
  "assignee": "DUPONT1",
  "type": "implementation",
  "sprint": 2,
  "description": "Coder SettingsGlassView.swift",
  "acceptanceCriteria": [
    "Vue utilise données mockées",
    "Lit langue/devise depuis EnvironmentObjects",
    "Tests unitaires passent",
    "Aucun warning de compilation"
  ],
  "dependencies": ["ARCH-01", "ARCH-02"],
  "estimatedHours": 4,
  "status": "NOT_STARTED"
}

5. Plan de Développement
5.1 Philosophie de Développement

Sprints courts (1 semaine) et focalisés
Intégration continue avec validation à chaque commit
Build fonctionnel à la fin de chaque sprint
Validation manuelle par [Author] avant clôture

5.2 Roadmap des Sprints
Sprint 1: Fondations (Semaine 1)

Architecture "Source de Vérité"
Modèles de données CoreData
Parser de base
Setup environnement de test

Sprint 2: Interface Core (Semaine 2)

HomeGlassView complète
AddExpenseGlassView (sans IA)
Navigation et transitions
Persistence locale

Sprint 3: Intelligence (Semaine 3)

Intégration Qwen2-VL
Architecture "Filet de Sécurité"
Optimisations performance
Tests de charge

Sprint 4: Fonctionnalités Étendues (Semaine 4)

SettingsGlassView
StatsGlassView
Début sync CloudKit
Localisation multi-langue

Sprint 5: Polish & Sync (Semaine 5)

Finalisation CloudKit
Animations avancées
Optimisations UI
Bug fixes prioritaires

Sprint 6: Préparation Launch (Semaine 6)

Export CSV/PDF
BetaFeedbackView
Tests d'acceptance finaux
Préparation App Store

5.3 Définition de "Fini"
Une tâche est considérée terminée lorsque:

✅ Code implémenté selon les spécifications
✅ Tests unitaires écrits et passants
✅ Build réussi sans warnings
✅ Code review approuvée
✅ Documentation à jour
✅ Validation manuelle par [Author]


6. Gestion des Risques
6.1 Matrice des Risques
RisqueImpactProbabilitéMitigationSprintIncohérence UI (Devise/Langue)CRITIQUEÉlevéeArchitecture "Source de Vérité" implémentée en premier1Défaillance IA QwenÉLEVÉMoyenneArchitecture "Filet de Sécurité" avec fallback Parser3Hallucination ContagieuseMOYENMoyenneCommunication inter-agents via JSON uniquementContinuTests UI Non FiablesMOYENÉlevéeValidation manuelle + focus sur tests unitairesContinuPerformance DégradéeÉLEVÉFaibleProfiling systématique + optimisation continue3-6Dérive des DélaisMOYENMoyenneSprints courts + révision hebdomadaire du scopeContinu
6.2 Stratégies de Mitigation
Stratégie "Fail-Fast"

Identification précoce des problèmes critiques
Sprint 1 dédié aux fondations architecturales
Tests de charge dès Sprint 3

Stratégie "Filet de Sécurité"

Toujours un fallback fonctionnel
Parser comme backup de l'IA
Mode dégradé mais jamais d'échec total

Stratégie "Communication Structurée"

JSON Schema strict pour échanges inter-agents
Pas de communication en langage naturel
Validation automatique des formats


7. Métriques de Succès
7.1 KPIs de Performance
MétriqueCible MVPMesureTemps extraction (Parser)P95 < 200msAutomatiqueTemps extraction (IA)P95 < 2sAutomatiqueLancement app à froid< 1.5sManuelMémoire utilisée< 150MB idleInstrumentsTaille du bundle< 100MBApp Store Connect
7.2 KPIs de Fiabilité
MétriqueCible MVPMesureTaux succès Parser> 80%AnalyticsTaux de crash< 0.1%CrashlyticsDisponibilité sync> 99%CloudKit DashboardTests unitaires> 80% coverageXCode
7.3 KPIs d'Expérience Utilisateur
MétriqueCible MVPMesureTime to Value< 15s (photo→sauvegarde)Test utilisateurTaux de complétion> 90% des flows initiésAnalyticsSatisfaction> 4.5/5Beta feedbackRétention J7> 60%Analytics

8. Stratégie de Lancement
8.1 Phases de Déploiement
Phase 1: Beta Interne (Semaines 1-6)

Validation continue par [Author]
Tests automatisés via CI/CD
Itérations rapides

Phase 2: Beta TestFlight (Semaines 7-8)

50 utilisateurs sélectionnés
BetaFeedbackView intégrée
Collecte de métriques réelles
Corrections prioritaires

Phase 3: Soft Launch (Semaine 9)

App Store Suisse + France uniquement
Monitoring intensif
A/B testing sur l'onboarding
Optimisation ASO

Phase 4: Expansion (Semaine 10+)

Rollout progressif Europe
Marketing ciblé
Partenariats potentiels
Roadmap V2

8.2 Critères Go/No-Go
Critères pour passage en Beta TestFlight:

✅ Tous les écrans MVP fonctionnels
✅ Extraction IA opérationnelle
✅ Aucun crash critique connu
✅ Performance dans les cibles

Critères pour Soft Launch:

✅ Feedback Beta > 4/5
✅ Taux de crash < 0.1%
✅ Rétention J7 > 60% en Beta
✅ Conformité App Store validée


9. Considérations Techniques Spécifiques
9.1 Gestion Mémoire IA
swift// Configuration optimale pour Qwen2-VL
let mlxConfig = MLXConfiguration(
    maxMemoryGB: 4.0,
    quantization: .int4,
    batchSize: 1,
    cacheStrategy: .aggressive
)
9.2 Exemple d'Architecture SwiftUI
swift@main
struct PrivExpensIAApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
                .environment(\.locale, settingsManager.currentLocale)
        }
    }
}
9.3 Structure de Données Core
swift// Entité principale CoreData
@objc(Expense)
public class Expense: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var amount: Decimal
    @NSManaged public var currency: String
    @NSManaged public var merchantName: String?
    @NSManaged public var category: String
    @NSManaged public var date: Date
    @NSManaged public var receiptImageData: Data?
    @NSManaged public var extractionMethod: String // "parser" ou "ai"
    @NSManaged public var confidence: Float
    @NSManaged public var syncStatus: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

10. Documentation & Ressources
10.1 Documentation Requise

README.md technique détaillé
Guide d'architecture (Architecture.md)
Documentation API interne
Guide de contribution agents
Runbook de déploiement

10.2 Outils & Environnements

IDE: Xcode 15.2+
CI/CD: GitHub Actions
Monitoring: Firebase Crashlytics
Analytics: MixPanel
Beta: TestFlight
Communication: Format JSON strict

10.3 Contacts & Responsabilités
RôleResponsableContactProduct Owner[Author]-OrchestrationNESTORVia système de tâchesUI/UXDUPONT1Via pull requestsBackendMARTINVia pull requestsIABERNARDVia pull requestsQATINTINVia rapports JSON

Annexes
A. Glossaire
TermeDéfinitionFerme AgentiqueInfrastructure d'agents IA spécialisés collaborant sur le développementHallucination ContagieusePropagation d'erreurs entre agents via communication non structuréeFilet de SécuritéMécanisme de fallback garantissant un fonctionnement minimalSource de VéritéArchitecture centralisant l'état global de l'applicationGlass MorphismStyle UI avec effets de transparence et de flou
B. Références Techniques

SwiftUI Documentation
CoreML Framework
CloudKit Guide
MLX Swift
Qwen2-VL Model


FIN DU DOCUMENT
Version 3.0 - Janvier 2025
Confidentiel - Usage Interne Uniquement