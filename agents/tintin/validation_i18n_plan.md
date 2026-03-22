# PLAN VALIDATION INTERNATIONALISATION S1-QA-02
QA LEAD: TINTIN

## DEPENDENCIES
- NESTOR S1-SYS-01 Structure /Engine/Resources
- DUPONT1 S1-UI-01 Fichiers Localizable.strings (fr/de/it)

## TESTS À EFFECTUER

### 1. Validation fichiers localisation
- Vérifier Engine/Resources/fr.lproj/Localizable.strings
- Vérifier Engine/Resources/de.lproj/Localizable.strings
- Vérifier Engine/Resources/it.lproj/Localizable.strings

### 2. Test changement locale
- Interface fr -> "Suivant"
- Interface de -> "Weiter"
- Interface it -> "Avanti"

### 3. Détection texte dur
- Script detect_hardcoded_text.sh préparé
- Scan Engine/Views pour chaînes littérales
- Validation 100% clés localisation

### 4. Screenshots obligatoires
- Capture 3 langues interface quiz
- Validation visuelle UX multilingue
- Documentation pour rapport

## STATUS
READY - En attente livraison Engine structure