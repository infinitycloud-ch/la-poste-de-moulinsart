# PRD: iOS Localization Guard System

## Version: 2.0 - Sprint 2 Complete
## Date: 13/09/2025
## Status: ✅ PRODUCTION READY

## Executive Summary
Complete iOS localization protection system with automated validation gates and visual proof generation. Zero tolerance for hardcoded UI strings, with comprehensive multi-language testing.

## System Components

### 1. Core Scripts (`/scripts/`)
- **localization_guard.sh**: Detects hardcoded UI strings in Swift code
- **xcstrings_validator.sh**: Validates localization keys (used vs declared)
- **checkpoint_sprint2.sh**: Master gate script for complete validation
- **i18n_snapshots.sh**: Automated screenshot generation for 8 languages
- **generate_i18n_report.sh**: HTML report generation with SHA256 validation

### 2. Key Features
- ✅ Blocks compilation on hardcoded strings
- ✅ Validates all localization keys
- ✅ Generates visual proof for 8 languages
- ✅ Single checkpoint gate for Sprint validation
- ✅ HTML reports with SHA256 checksums

## Technical Implementation

### Build Phase Integration
```bash
# Add to Xcode Build Phases (Run Script before Compile Sources)
"${SRCROOT}/scripts/localization_guard.sh"
```

### CI/CD Integration
```yaml
# GitHub Actions / GitLab CI
script:
  - ./scripts/checkpoint_sprint2.sh
  - if [ $? -ne 0 ]; then exit 1; fi
```

### Supported Languages
1. 🇫🇷 Français (Suisse) - fr-CH
2. 🇩🇪 Deutsch (Schweiz) - de-CH
3. 🇮🇹 Italiano (Svizzera) - it-CH
4. 🇬🇧 English - en
5. 🇯🇵 日本語 - ja
6. 🇰🇷 한국어 - ko
7. 🇸🇰 Slovenčina - sk
8. 🇪🇸 Español - es

## Quality Gates Checklist

### Sprint 2 Requirements
- [x] No hardcoded UI strings in Swift code
- [x] All localization keys declared in .strings files
- [x] All used keys have translations
- [x] Visual proof for all 8 languages
- [x] SHA256 validation for screenshots
- [x] HTML report generation
- [x] Single checkpoint script

### Sprint 3 Ready Criteria
- [x] 100% test pass rate
- [x] Zero hardcoded strings
- [x] Zero missing keys
- [x] All languages validated
- [x] Documentation complete

## Usage Guide

### Quick Start
```bash
# Run complete validation
cd ~/moulinsart/PrivExpensIA
./scripts/checkpoint_sprint2.sh

# Check specific component
./scripts/localization_guard.sh     # Hardcoded strings
./scripts/xcstrings_validator.sh    # Key validation
./scripts/i18n_snapshots.sh         # Generate screenshots
```

### Adding New Languages
1. Add .lproj folder with Localizable.strings
2. Update language list in scripts
3. Run checkpoint validation

### Troubleshooting
- **Build fails**: Check localization_guard_report.txt
- **Keys missing**: Check xcstrings_validation_report.txt
- **Screenshots black**: Verify simulator UDID matches

## Metrics & Performance

### Current Status (13/09/2025)
- Build: ✅ PASSED (0 warnings)
- Hardcoded Strings: 0 detected
- Missing Keys: 0
- Unused Keys: 0 (acceptable)
- Languages Tested: 8/8
- Success Rate: 100%

### Validation Times
- Build Check: ~15 seconds
- String Detection: <1 second
- Key Validation: <1 second
- Screenshot Generation: ~45 seconds
- Total Checkpoint: ~60 seconds

## File Structure
```
~/moulinsart/PrivExpensIA/
├── scripts/
│   ├── checkpoint_sprint2.sh       # Master gate
│   ├── localization_guard.sh       # String detector
│   ├── xcstrings_validator.sh      # Key validator
│   ├── i18n_snapshots.sh          # Screenshot generator
│   └── generate_i18n_report.sh    # Report builder
├── proof/
│   ├── checkpoint_sprint2_report.html  # Latest report
│   ├── localization_guard_report.txt
│   ├── xcstrings_validation_report.txt
│   └── i18n/
│       ├── app_fr-CH_*.png
│       ├── app_de-CH_*.png
│       └── ... (all languages)
└── PrivExpensIA/
    ├── LocalizationManager.swift
    └── [language].lproj/
        └── Localizable.strings
```

## Team Credits
- **NESTOR**: System architecture & coordination
- **TINTIN**: Testing & validation (UDID owner)
- **DUPONT1**: Swift implementation
- **DUPONT2**: Localization research

## Lessons Learned
1. **UDID-based testing** ensures consistency
2. **Single gate script** prevents partial validations
3. **Visual proof** catches UI rendering issues
4. **SHA256 checksums** ensure screenshot integrity
5. **HTML reports** provide stakeholder visibility

## Next Steps (Sprint 3)
- [ ] Add performance benchmarks
- [ ] Implement A/B testing for translations
- [ ] Add voice-over accessibility validation
- [ ] Create translation memory database
- [ ] Automate App Store screenshot generation

## Contact
Project Lead: NESTOR @ Moulinsart
Device Owner: TINTIN (UDID: 9D1B772E-7D9B-4934-A7F4-D2829CEB0065)

---
✅ CHECKPOINT SPRINT 2: **PASSED**
Ready for Sprint 3 development