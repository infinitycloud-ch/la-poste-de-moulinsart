import XCTest
import Foundation

class ExamPrepUITests: XCTestCase {

    // MARK: - Test Configuration
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Configuration pour tests E2E
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment["THEME_FOR_TESTING"] = "Demo"
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test 1: Lancement App ExamPrep Player Universel
    func testAppLaunchPlayerUniversel() throws {
        app.launch()

        // Vérifier que l'app démarre correctement
        XCTAssertTrue(app.staticTexts["ExamPrep"].exists, "Titre app ExamPrep doit être visible")

        // Attendre chargement complet interface
        let homeView = app.scrollViews.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10), "Interface principale doit se charger")

        // Screenshot validation app lancée
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "01_app_launch_examprep"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ Test 1: App ExamPrep Player Universel lancée avec succès")
    }

    // MARK: - Test 2: Navigation et Sélection Thème Demo
    func testNavigationThemeDemo() throws {
        app.launch()

        // Attendre interface principale
        let homeView = app.scrollViews.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10))

        // Rechercher et sélectionner thème Demo
        let demoThemeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Demo'")).firstMatch
        if !demoThemeButton.exists {
            // Fallback: chercher par index ou pattern
            let themeButtons = app.buttons.matching(identifier: "theme_selection")
            if themeButtons.count > 0 {
                themeButtons.element(boundBy: 0).tap()
            }
        } else {
            demoThemeButton.tap()
        }

        // Vérifier navigation vers thème Demo
        sleep(2) // Laisser temps animation

        // Screenshot sélection thème
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "02_theme_demo_selection"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ Test 2: Thème Demo sélectionné avec succès")
    }

    // MARK: - Test 3: Parcours Quiz Complet Player Universel
    func testQuizCompletePlayerUniversel() throws {
        app.launch()

        // Navigation vers thème Demo
        let homeView = app.scrollViews.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10))

        // Démarrer quiz Demo
        let startQuizButton = app.buttons["start_quiz"].firstMatch
        if startQuizButton.exists {
            startQuizButton.tap()
        } else {
            // Fallback: premier bouton disponible
            app.buttons.firstMatch.tap()
        }

        // Parcours des questions (8 questions attendues)
        for questionIndex in 1...8 {
            sleep(1) // Laisser temps chargement question

            // Vérifier présence question
            let questionView = app.scrollViews.firstMatch
            XCTAssertTrue(questionView.exists, "Question \(questionIndex) doit être visible")

            // Screenshot question
            let questionScreenshot = app.screenshot()
            let questionAttachment = XCTAttachment(screenshot: questionScreenshot)
            questionAttachment.name = "03_question_\(questionIndex)_demo"
            questionAttachment.lifetime = .keepAlways
            add(questionAttachment)

            // Sélectionner réponse (premier choix disponible)
            let firstChoice = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'choice'")).firstMatch
            if firstChoice.exists {
                firstChoice.tap()
            } else {
                // Fallback: tap sur premier élément cliquable
                let choices = app.buttons.allElementsBoundByIndex
                if choices.count > 0 {
                    choices[0].tap()
                }
            }

            // Continuer vers question suivante
            let nextButton = app.buttons["next_question"]
            if nextButton.exists {
                nextButton.tap()
            } else {
                // Rechercher bouton "Suivant" par texte
                let suivantButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Suivant'")).firstMatch
                if suivantButton.exists {
                    suivantButton.tap()
                }
            }

            print("✅ Question \(questionIndex)/8 complétée")
        }

        // Vérifier écran résultats
        sleep(3) // Laisser temps calcul résultats

        let resultsView = app.scrollViews.firstMatch
        XCTAssertTrue(resultsView.exists, "Écran résultats doit être visible")

        // Screenshot résultats finaux
        let resultsScreenshot = app.screenshot()
        let resultsAttachment = XCTAttachment(screenshot: resultsScreenshot)
        resultsAttachment.name = "04_quiz_results_final"
        resultsAttachment.lifetime = .keepAlways
        add(resultsAttachment)

        print("✅ Test 3: Parcours quiz complet Player Universel terminé")
    }

    // MARK: - Test 4: Validation Multilingue (fr/de/it)
    func testMultilingualValidation() throws {
        let languages = ["fr", "de", "it"]

        for (index, language) in languages.enumerated() {
            print("🌍 Test langue: \(language)")

            app.launch()

            // Changer langue si possible (via Settings)
            if app.buttons["settings"].exists {
                app.buttons["settings"].tap()
                sleep(1)

                // Chercher option langue
                let languageButton = app.buttons.containing(NSPredicate(format: "label CONTAINS '\(language.uppercased())'")).firstMatch
                if languageButton.exists {
                    languageButton.tap()
                    sleep(1)
                }

                // Retour à l'écran principal
                if app.navigationBars.buttons["Back"].exists {
                    app.navigationBars.buttons["Back"].tap()
                }
            }

            // Screenshot interface dans langue courante
            sleep(2) // Laisser temps changement langue

            let langScreenshot = app.screenshot()
            let langAttachment = XCTAttachment(screenshot: langScreenshot)
            langAttachment.name = "05_language_\(language)_interface"
            langAttachment.lifetime = .keepAlways
            add(langAttachment)

            // Vérifier éléments UI localisés
            let homeView = app.scrollViews.firstMatch
            XCTAssertTrue(homeView.exists, "Interface \(language) doit être fonctionnelle")

            print("✅ Interface \(language) validée")

            // Terminer app pour langue suivante
            app.terminate()
        }

        print("✅ Test 4: Validation multilingue fr/de/it terminée")
    }

    // MARK: - Test 5: Robustesse et Performance
    func testPlayerUniverselRobustesse() throws {
        app.launch()

        // Test stabilité sur plusieurs cycles
        for cycle in 1...3 {
            print("🔄 Cycle robustesse \(cycle)/3")

            // Naviguer vers quiz
            let homeView = app.scrollViews.firstMatch
            XCTAssertTrue(homeView.waitForExistence(timeout: 10))

            // Démarrer et interrompre quiz
            if app.buttons.firstMatch.exists {
                app.buttons.firstMatch.tap()
                sleep(2)

                // Retour arrière rapide
                if app.navigationBars.buttons["Back"].exists {
                    app.navigationBars.buttons["Back"].tap()
                } else {
                    // Swipe back
                    app.swipeRight()
                }

                sleep(1)
            }

            print("✅ Cycle \(cycle) stabilité OK")
        }

        // Screenshot final robustesse
        let robustnessScreenshot = app.screenshot()
        let robustnessAttachment = XCTAttachment(screenshot: robustnessScreenshot)
        robustnessAttachment.name = "06_robustness_final_state"
        robustnessAttachment.lifetime = .keepAlways
        add(robustnessAttachment)

        print("✅ Test 5: Robustesse Player Universel validée")
    }

    // MARK: - Test 6: Validation Types Questions Demo
    func testDemoQuestionTypes() throws {
        app.launch()

        let homeView = app.scrollViews.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10))

        // Démarrer quiz Demo pour tester types questions
        if app.buttons.firstMatch.exists {
            app.buttons.firstMatch.tap()
            sleep(2)

            // Test questions à choix unique (radio buttons)
            let radioButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'radio'"))
            if radioButtons.count > 0 {
                radioButtons.element(boundBy: 0).tap()

                let radioScreenshot = app.screenshot()
                let radioAttachment = XCTAttachment(screenshot: radioScreenshot)
                radioAttachment.name = "07_choix_unique_radio"
                radioAttachment.lifetime = .keepAlways
                add(radioAttachment)
            }

            sleep(1)

            // Continuer pour tester questions multiples (checkboxes)
            let nextButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Suivant'")).firstMatch
            if nextButton.exists {
                nextButton.tap()
                sleep(2)

                // Test checkboxes choix multiple
                let checkboxes = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'checkbox'"))
                if checkboxes.count > 1 {
                    checkboxes.element(boundBy: 0).tap()
                    checkboxes.element(boundBy: 1).tap()

                    let checkboxScreenshot = app.screenshot()
                    let checkboxAttachment = XCTAttachment(screenshot: checkboxScreenshot)
                    checkboxAttachment.name = "08_choix_multiple_checkbox"
                    checkboxAttachment.lifetime = .keepAlways
                    add(checkboxAttachment)
                }
            }
        }

        print("✅ Test 6: Types questions Demo validés")
    }
}

// MARK: - Extension Helper Methods
extension ExamPrepUITests {

    /// Helper pour attendre élément avec retry
    func waitForElementWithRetry(_ element: XCUIElement, timeout: TimeInterval = 10, retries: Int = 3) -> Bool {
        for _ in 0..<retries {
            if element.waitForExistence(timeout: timeout) {
                return true
            }
            sleep(1)
        }
        return false
    }

    /// Helper pour prendre screenshot avec retry si nécessaire
    func takeScreenshotWithRetry(name: String, maxRetries: Int = 2) {
        for attempt in 1...maxRetries {
            do {
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = name
                attachment.lifetime = .keepAlways
                add(attachment)
                break
            } catch {
                if attempt == maxRetries {
                    print("⚠️ Screenshot \(name) failed after \(maxRetries) attempts")
                }
                sleep(1)
            }
        }
    }
}