import SwiftUI
import StoreKit
import FoundationModels   // iOS 26 +
import AVFoundation
import UniformTypeIdentifiers
import Combine

// MARK: ----- Model Layer -----

struct Persona: Identifiable, Codable, Equatable {
    let id: UUID
    let age: Int
    let gender: String
    let language: String
    let country: String
    let city: String
    let personality: PersonalityProfile
    let funPersonality: [FunPersonalityTrait]
    let responseType: String
    let creationDate: Date
    var backstory: String?
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let isUser: Bool
    var text: String
}

struct SavedPersonaSession: Identifiable, Codable, Equatable {
    let id: UUID
    var persona: Persona
    var chatHistory: [ChatMessage]
}

struct PersonalityProfile: Codable, Equatable {
    var friendliness: Double = 0.5
    var humor:        Double = 0.5
    var optimism:     Double = 0.5
    var energy:       Double = 0.5
}

struct FunPersonalityTrait: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var value: Double
}

struct FormField<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            content
        }
    }
}

// MARK: ----- Constants & Helpers -----

/// UN-member countries (+ Vatican)
private let allCountries = [
    "Afghanistan","Albania","Algeria","Andorra","Angola","Antigua and Barbuda","Argentina","Armenia",
    "Australia","Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados","Belarus","Belgium",
    "Belize","Benin","Bhutan","Bolivia","Bosnia and Herzegovina","Botswana","Brazil","Brunei","Bulgaria",
    "Burkina Faso","Burundi","Cabo Verde","Cambodia","Cameroon","Canada","Central African Republic","Chad",
    "Chile","China","Colombia","Comoros","Congo (Congo-Brazzaville)","Costa Rica","Côte d’Ivoire","Croatia",
    "Cuba","Cyprus","Czechia","Democratic Republic of the Congo","Denmark","Djibouti","Dominica","Dominican Republic",
    "Ecuador","Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Eswatini","Ethiopia","Fiji","Finland",
    "France","Gabon","Gambia","Georgia","Germany","Ghana","Greece","Grenada","Guatemala","Guinea","Guinea-Bissau",
    "Guyana","Haiti","Honduras","Hungary","Iceland","India","Indonesia","Iran","Iraq","Ireland","Israel","Italy",
    "Jamaica","Japan","Jordan","Kazakhstan","Kenya","Kiribati","Kuwait","Kyrgyzstan","Laos","Latvia","Lebanon",
    "Lesotho","Liberia","Libya","Liechtenstein","Lithuania","Luxembourg","Madagascar","Malawi","Malaysia","Maldives",
    "Mali","Malta","Marshall Islands","Mauritania","Mauritius","Mexico","Micronesia","Moldova","Monaco","Mongolia",
    "Montenegro","Morocco","Mozambique","Myanmar","Namibia","Nauru","Nepal","Netherlands","New Zealand","Nicaragua",
    "Niger","Nigeria","North Korea","North Macedonia","Norway","Oman","Pakistan","Palau","Panama","Papua New Guinea",
    "Paraguay","Peru","Philippines","Poland","Portugal","Qatar","Romania","Russia","Rwanda","Saint Kitts and Nevis",
    "Saint Lucia","Saint Vincent and the Grenadines","Samoa","San Marino","São Tomé and Príncipe","Saudi Arabia",
    "Senegal","Serbia","Seychelles","Sierra Leone","Singapore","Slovakia","Slovenia","Solomon Islands","Somalia",
    "South Africa","South Korea","South Sudan","Spain","Sri Lanka","Sudan","Suriname","Sweden","Switzerland",
    "Syria","Tajikistan","Tanzania","Thailand","Timor-Leste","Togo","Tonga","Trinidad and Tobago","Tunisia",
    "Turkey","Turkmenistan","Tuvalu","Uganda","Ukraine","United Arab Emirates","United Kingdom","United States",
    "Uruguay","Uzbekistan","Vanuatu","Vatican City","Venezuela","Vietnam","Yemen","Zambia","Zimbabwe"
]

private func randomCountry(excluding recent: [String]) -> String {
    let pool = allCountries.filter { !recent.contains($0) }
    return (pool.isEmpty ? allCountries : pool).randomElement() ?? "Canada"
}

/// Produces a block of personality slider values (Friendliness, Humor, etc.) for use in a prompt.
/// Includes all personality and fun trait sliders, showing percentage values from 0–100.
private func personalityBlock(for profile: PersonalityProfile, funTraits: [FunPersonalityTrait]) -> String {
    var out = "[PERSONALITY TRAITS]\n"
    out += "Friendliness: \(Int(profile.friendliness * 100))%\n"
    out += "Humor: \(Int(profile.humor * 100))%\n"
    out += "Optimism: \(Int(profile.optimism * 100))%\n"
    out += "Energy: \(Int(profile.energy * 100))%\n"
    for t in funTraits {
        out += "\(t.name): \(Int(t.value * 100))%\n"
    }
    return out
}

/// Returns the selected response style/type for prompts, e.g., "Motivational" or "Jokes"
private func responseTypeBlock(for responseType: String) -> String {
    "[RESPONSE STYLE]\nType: \(responseType)"
}

/// Summarizes the persona, including slider values, for lists/summaries.
private func summarizePersona(_ p: Persona) -> String {
    let fun = p.funPersonality.map { "\($0.name): \(Int($0.value * 100))%" }.joined(separator: ", ")
    let back = p.backstory ?? ""
    return "\(p.age)-year-old \(p.gender.lowercased()) in \(p.city), \(p.country). \(back) Sliders — Friendliness: \(Int(p.personality.friendliness * 100))%, Humor: \(Int(p.personality.humor * 100))%, Optimism: \(Int(p.personality.optimism * 100))%, Energy: \(Int(p.personality.energy * 100))%. Fun traits: \(fun)."
}

// Voice picker tag used for "Get More Voices" row
private let getMoreVoicesTag = "__getmorevoices__"

/// SpeechManager class for TTS
class SpeechManager: ObservableObject {
    let synthesizer = AVSpeechSynthesizer()
}

@available(iOS 26.0, *)
struct ContentView: View {

    // MARK: - Static Generators

    static func randomFunTraits() -> [FunPersonalityTrait] {
        let pool = [
            "Sarcasm", "Curiosity", "Seriousness", "Empathy", "Bluntness",
            "Creativity", "Chattiness", "Pessimism", "Wit", "Patience",
            "Excitement", "Mystery", "Directness", "Pragmatism",
            "Adventurousness", "Cautiousness", "Warmth", "Shyness", "Introversion",
            "Extroversion", "Confidence", "Anxiety", "Calmness", "Stubbornness",
            "Open-mindedness", "Traditionalism", "Imagination", "Methodicalness",
            "Impulsivity", "Diligence", "Spontaneity", "Politeness", "Assertiveness",
            "Adaptability", "Tactfulness", "Rebelliousness", "Loyalty", "Jealousy",
            "Sensitivity", "Ambition", "Cynicism", "Enthusiasm", "Sincerity",
            "Resourcefulness", "Discipline", "Forgiveness", "Greediness",
            "Cooperativeness", "Independence", "Grumpiness", "Romanticism"
        ].shuffled()
        return (0..<3).map { FunPersonalityTrait(name: pool[$0], value: Double.random(in: 0...1)) }
    }

    static func randomFunResponseTypes() -> [String] {
        let pool = [
            "Philosophical", "Sarcastic", "Dry Humor", "Cynical", "Motivational",
            "Cryptic", "Excitable", "Flirty", "Childlike", "Overly Polite",
            "Teasing", "Sassy", "Old-Fashioned", "Nostalgic", "Minimalist",
            "Shakespearean", "Haiku", "Dramatic", "Melodramatic", "Super Detailed",
            "Confessional", "Shy", "Skeptical", "Punny", "Dense Slang",
            "Formal", "Very Formal", "Gossipy", "Teacherly", "Lecturing",
            "Curious", "Rhyme-heavy", "Cheerleader", "Apathetic", "Chill",
            "Random", "Fangirl/Fanboy", "Exaggerated", "Clueless", "Overly Honest",
            "Overly Positive", "Self-Deprecating", "Rambling", "Whimsical", "Hesitant",
            "Hypothetical", "Anecdotal", "Techno-Speak", "Sarcastic Comebacks", "TMI (Too Much Info)"
        ].shuffled()
        return Array(pool.prefix(4))
    }

    // MARK: - Storage & State

    @StateObject private var iap = IAPManager.shared
    @AppStorage("hasUnlockedPass") private var hasUnlockedPass = false
    @AppStorage("lastCreationTime") private var lastCreationTime: Double = 0
    @AppStorage("savedSessions") private var savedData: Data = Data()

    @State private var selectedLanguage = ""
    @State private var selectedAgeRange = 0
    @State private var customAge = "20"
    @State private var selectedGender = 0
    @State private var isCreatingPersona = false
    @State private var scrollToLastMessage: (() -> Void)?
    @State private var lastMessageID: UUID? = nil
    @State private var conversationSummary: String = ""
    @State private var personaSummary: String = ""
    @State private var conversationSummaries: [String] = []

    @State private var isCountryRandom = true
    @State private var countryField = ""
    @State private var isCityRandom = true
    @State private var cityField = ""

    @State private var lastGeneratedCountry = ""
    @State private var lastGeneratedCity = ""

    @State private var funTraits = randomFunTraits()
    @State private var funResponseTypes = randomFunResponseTypes()
    @State private var personalityProfile = PersonalityProfile()
    @State private var responseType = "Neutral"
    @State private var responseTypes = ["Neutral", "Short Informal", "Long Informal", "Storytelling", "Jokes", "Emoji-laced", "Long-winded"]

    @State private var showPersonalitySheet = false
    @State private var showResponseTypeSheet = false

    // Chat/session state
    @State private var savedSessions: [SavedPersonaSession] = []
    @State private var currentSession: SavedPersonaSession?
    @State private var inputText = ""
    @State private var isGenerating = false
    @State private var summarizing = false
    @State private var personaCreatedBanner = false
    @State private var tabIndex = 0
    @State private var llmSession: LanguageModelSession?
    @State private var selectedVoice: AVSpeechSynthesisVoice?
    @State private var showVoiceSettingsAlert = false
    private let getMoreVoicesTag = "GET_MORE_VOICES"
    @State private var showDeleteAlert = false
    @State private var personaToDelete: SavedPersonaSession?
    @State private var timeLeft: TimeInterval = 0
    @StateObject private var speechManager = SpeechManager()

    private let supportedLanguages = ["English", "Mandarin", "Spanish", "French", "German", "Hindi", "Japanese"]
    private let ageRanges = ["20–39", "40–59", "60–79"]
    private let genders = ["Female", "Male"]

    private func summarizePersona(_ p: Persona) -> String {
        let fun = p.funPersonality.map { "\($0.name): \(Int($0.value * 100))%" }.joined(separator: ", ")
        let back = p.backstory ?? ""
        return """
        \(p.age)-year-old \(p.gender.lowercased()) in \(p.city), \(p.country). \(back) \
        Friendliness: \(Int(p.personality.friendliness * 100))%, \
        Humor: \(Int(p.personality.humor * 100))%, \
        Optimism: \(Int(p.personality.optimism * 100))%, \
        Energy: \(Int(p.personality.energy * 100))%. \
        Fun traits: \(fun)
        """
    }
    private func updateConversationSummary() {
        guard let session = currentSession else { return }
        let history = session.chatHistory.suffix(10)
        let joined = history.map { ($0.isUser ? "User: " : "AI: ") + $0.text }
                            .joined(separator: " / ")
        conversationSummary = String(joined.prefix(1000))
    }

    
    // MARK: - Computed Helpers

    private var defaultLanguage: String {
        switch Locale.preferredLanguages.first?.prefix(2) ?? "en" {
        case "fr": return "French"
        case "es": return "Spanish"
        case "de": return "German"
        case "zh": return "Mandarin"
        case "hi": return "Hindi"
        case "ja": return "Japanese"
        default:   return "English"
        }
    }

    private func randomAge() -> Int {
        let range = [(20,39), (40,59), (60,79)][selectedAgeRange]
        return Int.random(in: range.0...range.1)
    }

    private var countdown: String {
        guard timeLeft > 0 else { return "now" }
        let hours = Int(timeLeft) / 3600
        let minutes = (Int(timeLeft) % 3600) / 60
        let seconds = Int(timeLeft) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $tabIndex) {
            builderTab
                .tabItem { Label("Builder", systemImage: "person.crop.circle.badge.plus") }
                .tag(0)

            chatTab
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(1)

            savedTab
                .tabItem { Label("Saved", systemImage: "tray.full.fill") }
                .tag(2)
        }
        .onAppear {
            if selectedLanguage.isEmpty { selectedLanguage = defaultLanguage }
            loadSessions()
            updateTimeLeft()
        }
    }

    private func updateTimeLeft() {
        if canCreatePersona { timeLeft = 0 }
        else {
            let remaining = 24*3600 - (Date().timeIntervalSince1970 - lastCreationTime)
            timeLeft = max(0, remaining)
        }
    }
    private var canCreatePersona: Bool {
        hasUnlockedPass || Date().timeIntervalSince1970 - lastCreationTime > 24*3600
    }

    // MARK: - Builder Tab

    private var builderTab: some View {
        VStack(spacing: 0) {
    #if DEBUG
            if !hasUnlockedPass {
                Button("🔓 Unlock All Features (DEV ONLY)") {
                    hasUnlockedPass = true
                    iap.isUnlocked = true
                }
                .padding(8)
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(8)
                .padding(.top, 6)
            }
    #endif
            Text("ChatWithAnyone")
                .font(.largeTitle.bold())
                .padding(.vertical, 6)

            Form {
                builderFormFields           // <<== NEW!
                personalityButtonsRow
                createPersonaButton

                if !canCreatePersona && !hasUnlockedPass {
                    Text("You can create a new persona in \(countdown)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                paywallSection
            }
            .animation(.default, value: personaCreatedBanner)
            .task { await iap.fetch() }
            .onChange(of: iap.isUnlocked) { _, newValue in
                hasUnlockedPass = newValue
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: Builder Tab Helper Views

    @ViewBuilder private var builderFormFields: some View {
        VStack(spacing: 18) {
            // LANGUAGE
            HStack(alignment: .firstTextBaseline) {
                Text("Language")
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Picker("", selection: $selectedLanguage) {
                    ForEach(supportedLanguages, id: \.self) { lang in Text(lang) }
                }
                .pickerStyle(.menu)
                .frame(width: 140, height: 32)
                .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] }
            }
            
            // AGE + GENDER: side-by-side, aligned
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                // AGE
                HStack(alignment: .firstTextBaseline) {
                    Text("Age")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    if hasUnlockedPass {
                        TextField("Age", text: $customAge)
                            .keyboardType(.numberPad)
                            .frame(width: 90, height: 32)
                            .textFieldStyle(.roundedBorder)
                            .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] }
                    } else {
                        Picker("", selection: $selectedAgeRange) {
                            ForEach(ageRanges.indices, id: \.self) { idx in Text(ageRanges[idx]) }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 90, height: 32)
                        .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] }
                    }
                }
                .frame(maxWidth: .infinity)

                // GENDER (aligned with Age)
                HStack(alignment: .firstTextBaseline) {
                    Text("Gender")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $selectedGender) {
                        ForEach(genders.indices, id: \.self) { idx in Text(genders[idx]) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90, height: 32)
                    .alignmentGuide(.firstTextBaseline) { $0[.firstTextBaseline] }
                }
                .frame(maxWidth: .infinity)
            }

            // COUNTRY
            HStack {
                Text("Country")
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if hasUnlockedPass {
                    if isCountryRandom {
                        // --- Toggling random OFF
                        HStack(spacing: 4) {
                            Button(action: {
                                isCountryRandom = false
                            }) {
                                Image(systemName: "checkmark.square.fill")
                                    .foregroundColor(.green)
                            }
                            Text("Random")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        }
                    } else {
                        // --- Show text field, allow random again
                        HStack(spacing: 6) {
                            TextField("Enter country", text: $countryField)
                                .foregroundColor(.primary)
                                .frame(width: 220, height: 32)
                                .padding(8)
                                .background(Color.gray.opacity(0.13))
                                .cornerRadius(5)
                            Text("Random")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                                .padding(.leading, 4)
                            Button(action: {
                                isCountryRandom = true
                                countryField = ""
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Random")
                            .foregroundColor(.gray.opacity(0.5))
                        Text("LOCKED")
                            .foregroundColor(.red)
                            .bold()
                    }
                }
            }

            // CITY
            HStack {
                Text("City")
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if hasUnlockedPass {
                    if isCityRandom {
                        HStack(spacing: 4) {
                            Button(action: {
                                isCityRandom = false
                            }) {
                                Image(systemName: "checkmark.square.fill")
                                    .foregroundColor(.green)
                            }
                            Text("Random")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        }
                        .disabled(isCountryRandom)
                    } else {
                        HStack(spacing: 6) {
                            TextField("Enter city", text: $cityField)
                                .foregroundColor(.primary)
                                .frame(width: 220, height: 32)
                                .padding(8)
                                .background(Color.gray.opacity(0.13))
                                .cornerRadius(5)
                                .disabled(isCountryRandom)
                            Text("Random")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                                .padding(.leading, 4)
                            Button(action: {
                                isCityRandom = true
                                cityField = ""
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.gray)
                            }
                            .disabled(isCountryRandom)
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Random")
                            .foregroundColor(.gray.opacity(0.5))
                        Text("LOCKED")
                            .foregroundColor(.red)
                            .bold()
                    }
                }
            }
        }
    }

    @ViewBuilder private var personalityButtonsRow: some View {
        HStack(spacing: 14) {
            Spacer()
            Button("Personality Type") { showPersonalitySheet = true }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .sheet(isPresented: $showPersonalitySheet) {
                    PersonalityTypeView(profile: $personalityProfile, funTraits: $funTraits)
                }
            Button("Response Type") { showResponseTypeSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .sheet(isPresented: $showResponseTypeSheet) {
                    ResponseTypeView(selected: $responseType, builtins: $responseTypes, funTypes: $funResponseTypes)
                }
            Spacer()
        }
    }


    @ViewBuilder private var createPersonaButton: some View {
        Button(action: {
            Task {
                isCreatingPersona = true
                await createPersona()
                isCreatingPersona = false
                tabIndex = 1
            }
        }) {
            if isCreatingPersona {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("CREATE NEW PERSONA")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreatePersona ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .disabled(!canCreatePersona || isCreatingPersona)
        .padding(.bottom, 6)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder private var paywallSection: some View {
        if !hasUnlockedPass {
            VStack(spacing: 10) {
                Button(action: {
                    Task { await iap.buy() }
                }) {
                    VStack(spacing: 3) {
                        Text("UNLOCK ALL FEATURES")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(iap.product?.displayPrice ?? "$2.99")
                            .font(.title2)
                            .foregroundColor(.white)
                        VStack(alignment: .center, spacing: 2) {
                            Text("- Unlimited saveable personas per day")
                            Text("- Select an exact age and location")
                        }
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.95))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.pink, Color.purple, Color.orange],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.pink.opacity(0.38), radius: 20, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1.5)
                    )
                }
                .disabled(iap.purchaseInProgress || iap.isUnlocked)
                .padding(.top, 10)
                .frame(maxWidth: .infinity)

                if iap.purchaseInProgress {
                    ProgressView("Processing...")
                }

                Button("Restore Purchase") {
                    Task { await iap.restore() }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .alert(isPresented: Binding(
                get: { iap.errorMessage != nil },
                set: { _ in iap.errorMessage = nil }
            )) {
                Alert(title: Text("Purchase Error"),
                      message: Text(iap.errorMessage ?? ""),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    private var chatTab: some View {
        VStack(spacing: 0) {
            // Persona header
            if let current = currentSession {
                let p = current.persona
                let genderSymbol: String? = {
                    switch p.gender.lowercased() {
                    case "female": return "♀︎"
                    case "male": return "♂︎"
                    default: return nil
                    }
                }()

                HStack(alignment: .center, spacing: 14) {
                    // Avatar
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                        if let symbol = genderSymbol {
                            Text(symbol)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(4)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }
                    // Persona details
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(p.age) — \(p.city), \(p.country)")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("[\(p.language)]")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Premium/Enhanced Voice Picker
                    let proVoices = AVSpeechSynthesisVoice.speechVoices()
                        .filter { $0.quality == .premium || $0.quality == .enhanced }
                        .sorted { $0.quality.rawValue > $1.quality.rawValue }

                    Picker("", selection: Binding(
                        get: { selectedVoice?.identifier ?? "" },
                        set: { newValue in
                            if newValue == getMoreVoicesTag {
                                // Try to open Settings for Voices
                                if let url = URL(string: "App-Prefs:root=General&path=ACCESSIBILITY/SPEECH"),
                                   UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                } else {
                                    showVoiceSettingsAlert = true
                                }
                            } else if let match = proVoices.first(where: { $0.identifier == newValue }) {
                                selectedVoice = match
                            } else {
                                selectedVoice = nil
                            }
                        }
                    )) {
                        Text("No Voice").tag("" as String)
                        ForEach(proVoices, id: \.identifier) { v in
                            let label = v.quality == .premium ? "Premium" : "Enhanced"
                            Text("\(v.name) (\(v.language)) [\(label)]").tag(v.identifier)
                        }
                        // Green instruction row at the bottom!
                        Text("GET MORE VOICES IN APPLE ACCESSIBILITY")
                            .foregroundColor(.green)
                            .tag(getMoreVoicesTag)
                    }
                    .frame(width: 180) // Small width to keep details visible
                    .padding(.trailing, 2)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                // ALERT: Must be attached to HStack or VStack, NOT Picker!
                .alert("More Voices", isPresented: $showVoiceSettingsAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("To install more voices:\nSettings → Accessibility → Spoken Content → Voices")
                }

            } else {
                Text("Create a persona in the builder tab.")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Divider()

            // Show persona backstory (never as a chat message)
            if let backstory = currentSession?.persona.backstory, !backstory.isEmpty {
                Text(backstory)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
            }

            // Chat log and input
            if let session = currentSession {
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(session.chatHistory.indices, id: \.self) { idx in
                            let msg = session.chatHistory[idx]
                            HStack {
                                if msg.isUser { Spacer() }
                                Text(msg.text)
                                    .italic(!msg.isUser && idx == 0)
                                    .foregroundColor(!msg.isUser && idx == 0 ? .black : .primary)
                                    .padding(8)
                                    .background(msg.isUser ? Color.blue.opacity(0.12) : Color.green.opacity(0.11))
                                    .cornerRadius(10)
                                    .frame(maxWidth: 300, alignment: msg.isUser ? .trailing : .leading)
                                if !msg.isUser { Spacer() }
                            }
                            .padding(.horizontal, 6)
                            .id(msg.id)
                        }
                    }
                    .onChange(of: lastMessageID) { oldValue, newValue in
                        if let id = newValue {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let last = session.chatHistory.last {
                            lastMessageID = last.id
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                HStack {
                    TextField("Type a message...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isGenerating)
                    Button(action: sendUserMessage) {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                    }
                    .disabled(inputText.isEmpty || isGenerating)
                }
                .padding()
                
                if session.chatHistory.count >= 50 {
                    HStack {
                        Button("Summarize Conversation") {
                            summarizeChatHistory()
                        }
                        .disabled(summarizing)
                        
                        if summarizing {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        
                        Spacer()
                        
                        Text("100% on-device, zero cloud, zero logging")
                            .font(.footnote)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Saved Tab

    private var savedTab: some View {
        List {
            ForEach(savedSessions) { s in
                let p = s.persona
                let symbol = p.gender == "Female" ? "♀︎ " : (p.gender == "Male" ? "♂︎ " : "")
                HStack {
                    let genderSymbol: String? = {
                        switch p.gender.lowercased() {
                        case "female": return "♀︎"
                        case "male": return "♂︎"
                        default: return nil
                        }
                    }()

                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.gray))

                        if let symbol = genderSymbol {
                            Text(symbol)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(3)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(symbol)\(p.age)")
                                .font(.headline)
                            Text("[\(p.language)]")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        Text("\(p.city), \(p.country)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let backstory = p.backstory {
                            Text(backstory)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("\(s.chatHistory.count) messages")
                            .font(.caption2)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        personaToDelete = s
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectSession(s)
                    tabIndex = 1
                }
            }
        }
        .alert("Delete Persona?", isPresented: $showDeleteAlert, presenting: personaToDelete) { s in
            Button("Delete", role: .destructive) { deleteSession(s) }
            Button("Cancel", role: .cancel) { personaToDelete = nil }
        } message: { _ in
            Text("Are you sure you want to delete this persona and all its chats? This action cannot be undone.")
        }
    }

    // MARK: - Persona Creation & Chat Logic

    private func createPersona() async {
        let age = hasUnlockedPass ? (Int(customAge) ?? 20) : randomAge()
        let gender = genders[selectedGender]

        // Determine country and city
        let (country, city): (String, String) = await {
            if hasUnlockedPass && !(isCountryRandom || isCityRandom) {
                return (countryField, cityField)
            }
            let result = await llmCountryCityRandomization(age: age)
            return (isCountryRandom ? result.0 : (countryField.isEmpty ? result.0 : countryField),
                    isCityRandom    ? result.1 : (cityField.isEmpty    ? result.1 : cityField))
        }()

        let backstory = await generateBackstory(city: city, country: country, gender: gender)

        let persona = Persona(
            id: UUID(),
            age: age,
            gender: gender,
            language: selectedLanguage,
            country: country,
            city: city,
            personality: personalityProfile,
            funPersonality: funTraits,
            responseType: responseType,
            creationDate: Date(),
            backstory: backstory
        )

        let session = SavedPersonaSession(id: persona.id, persona: persona, chatHistory: [])
        // No need to append backstory as a message.
        // The backstory stays in persona.backstory, e.g. persona.backstory = backstory
        savedSessions.append(session)
        saveSessions()
        currentSession = session
        personaSummary = String(summarizePersona(persona).prefix(1000))
        updateConversationSummary()
        personaCreatedBanner = true
        funTraits = ContentView.randomFunTraits()
        funResponseTypes = ContentView.randomFunResponseTypes()
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { personaCreatedBanner = false }

        llmSession = LanguageModelSession()
    }

    private func llmCountryCityRandomization(age: Int) async -> (String, String) {
        let recent = Array(Set(savedSessions.suffix(10).map { $0.persona.country } + [lastGeneratedCountry]))
        let country = randomCountry(excluding: recent)
        let prompt = """
        Pick one real, populous city (≥200,000 people) in \(country).
        Prefer a large city that is _not_ the capital.
        Return EXACTLY: City: <city>
        """
        let cityResp = try? await LanguageModelSession().respond(to: prompt)
        let city = cityResp?.content
            .components(separatedBy: .newlines)
            .first(where: { $0.starts(with: "City: ") })?
            .replacingOccurrences(of: "City: ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        lastGeneratedCountry = country
        lastGeneratedCity = city
        return (country, city)
    }

    private func generateBackstory(city: String, country: String, gender: String) async -> String? {
        let pronoun = gender.lowercased() == "male" ? "He" : (gender.lowercased() == "female" ? "She" : "They")
        let prompt = """
        Write a 2-sentence backstory about a person living in \(city), \(country). Use simple language and short sentences. Do not use a name. Refer to them as “\(pronoun)”.
        """
        return try? await LanguageModelSession().respond(to: prompt).content
    }

    private func selectSession(_ s: SavedPersonaSession) {
        currentSession = s
        personaSummary = String(summarizePersona(s.persona).prefix(1000))
        updateConversationSummary()
        llmSession = LanguageModelSession()
    }

    private func deleteSession(_ s: SavedPersonaSession) {
        savedSessions.removeAll { $0.id == s.id }
        saveSessions()
        if currentSession?.id == s.id {
            currentSession = nil
        }
    }

    // MARK: - Persistence & Unlock Helpers

    private func saveSessions() {
        savedData = (try? JSONEncoder().encode(savedSessions)) ?? Data()
    }

    private func loadSessions() {
        savedSessions = (try? JSONDecoder().decode([SavedPersonaSession].self, from: savedData)) ?? []
    }

    // MARK: - Messaging

    private func sendUserMessage() {
        guard var session = currentSession, !inputText.isEmpty, let llm = llmSession else { return }

        // --- CHANGE 1: Defensive cleanup ---
        // Remove any trailing blank AI messages (shouldn't happen, but can if interrupted)
        while let last = session.chatHistory.last, !last.isUser && last.text.isEmpty {
            session.chatHistory.removeLast()
        }

        // 1. Append user message
        let userMessage = ChatMessage(id: UUID(), isUser: true, text: inputText)
        session.chatHistory.append(userMessage)
        inputText = ""
        isGenerating = true
        currentSession = session
        saveSessions()

        // 2. Add placeholder for AI response (ONE per user message!)
        let aiMessage = ChatMessage(id: UUID(), isUser: false, text: "")
        session.chatHistory.append(aiMessage)
        currentSession = session
        saveSessions()

        // 3. Stream LLM response (with error recovery and automatic retry)
        Task {
            var didRetry = false
            var fullReply = ""

            retryLoop: while true {
                do {
                    let usedLLM = llmSession ?? llm
                    let persona = session.persona
                    personaSummary = String(summarizePersona(persona).prefix(200))
                    updateConversationSummary()
                    let chatHistory = currentSession?.chatHistory ?? session.chatHistory

                    // Track latest full text to prevent repetition
                    for try await partial in usedLLM.streamResponse(to: buildPrompt(for: persona, history: chatHistory, responseType: persona.responseType)) {
                        if var cs = currentSession,
                           let aiIdx = cs.chatHistory.lastIndex(where: { !$0.isUser }) {
                            let partialText = partial.content
                            let newText = String(partialText.dropFirst(fullReply.count))
                            cs.chatHistory[aiIdx].text += newText
                            fullReply = partialText
                            currentSession = cs
                            saveSessions()
                            if let last = cs.chatHistory.last {
                                lastMessageID = last.id
                            }
                        }
                    }

                    // --- ONLY SPEAK THE FULL REPLY ONCE IT'S DONE ---
                    if let voice = selectedVoice, !fullReply.isEmpty {
                        speechManager.synthesizer.stopSpeaking(at: .immediate)
                        let utterance = AVSpeechUtterance(string: fullReply)
                        utterance.voice = voice
                        speechManager.synthesizer.speak(utterance)
                    }

                    break // Success

                } catch {
                    if !didRetry, error.localizedDescription.contains("Exceeded model context window size") {
                        print("🟠 LLM session was reset due to context error. Retrying...")
                        llmSession = LanguageModelSession()
                        didRetry = true

                        // Remove ONLY the last AI message (regardless of text)
                        if var cs = currentSession, let last = cs.chatHistory.last, !last.isUser {
                            cs.chatHistory.removeLast()
                            currentSession = cs
                            saveSessions()
                        }
                        // Add a new empty AI message to retry LLM response
                        if var cs = currentSession {
                            cs.chatHistory.append(ChatMessage(id: UUID(), isUser: false, text: ""))
                            currentSession = cs
                            saveSessions()
                        }
                        continue retryLoop

                    } else {
                        // On OTHER errors, just show in last AI placeholder if one exists
                        if var cs = currentSession,
                           let aiIdx = cs.chatHistory.lastIndex(where: { !$0.isUser }) {
                            cs.chatHistory[aiIdx].text = "Error: \(error.localizedDescription)"
                            currentSession = cs
                            saveSessions()
                        }
                        break
                    }
                }
            }
            isGenerating = false

            // Trim history if needed
            if var cs = currentSession, cs.chatHistory.count > 300 {
                cs.chatHistory.removeFirst(cs.chatHistory.count - 300)
                currentSession = cs
                saveSessions()
            }
        }
    }

    // MARK: - Prompt Building & Summarization

    private func buildPrompt(for persona: Persona, history: [ChatMessage], responseType: String) -> String {
        let funTraitList = persona.funPersonality.map { "- \($0.name): \(Int($0.value * 100))%" }.joined(separator: "\n    ")
        let prompt = """
        Reply to the latest message as a real person, not an assistant or chatbot. Never mention you are AI. Always stay in character.

        [CHARACTER CARD]
        - Age/Gender: \(persona.age) / \(persona.gender)
        - Location: \(persona.city), \(persona.country)
        - Always reply in [Language]: \(persona.language)
        - Backstory: \(persona.backstory ?? "")
        - Tone:
            - Friendliness: \(Int(persona.personality.friendliness * 100))%
            - Humor: \(Int(persona.personality.humor * 100))%
            - Optimism: \(Int(persona.personality.optimism * 100))%
            - Energy: \(Int(persona.personality.energy * 100))%
        - Fun Traits:
        \(funTraitList)

        [VOICE]
        - Response Style: \(responseType)

        [Chat History]
        \(history.suffix(10).map { $0.isUser ? "User: \($0.text)" : "AI: \($0.text)" }.joined(separator: "\n"))

        [Your response:]
        """
        return prompt
    }

    private func summarizeChatHistory() {
        guard let personaSession = currentSession,
              let session = llmSession,
              personaSession.chatHistory.count > 50 else { return }

        summarizing = true
        let text = personaSession.chatHistory
                  .map { ($0.isUser ? "User: " : "AI: ") + $0.text }
                  .joined(separator: "\n")

        Task {
            let prompt = """
            Summarize this conversation between the user and the persona. No more than 6 sentences. Make it friendly and readable:
            \(text)
            """
            if let summary = try? await session.respond(to: prompt) {
                conversationSummary = summary.content
                if var cs = currentSession {
                    let tail = cs.chatHistory.suffix(6)
                    cs.chatHistory = [
                        ChatMessage(
                            id: UUID(),
                            isUser: false,
                            text: "[Summary]\n" + summary.content
                        )
                    ] + tail
                    currentSession = cs
                    saveSessions()
                }
            }
            summarizing = false
        }
    }

}

// MARK: - Helper Views (now at file scope, not nested!)

struct PersonalityTypeView: View {
    @Binding var profile: PersonalityProfile
    @Binding var funTraits: [FunPersonalityTrait]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                SliderView(label: "Friendliness", value: $profile.friendliness)
                SliderView(label: "Humor", value: $profile.humor)
                SliderView(label: "Optimism", value: $profile.optimism)
                SliderView(label: "Energy", value: $profile.energy)
                ForEach($funTraits) { $trait in
                    VStack(alignment: .leading) {
                        HStack {
                            Spacer()
                            Text("\(trait.name): \(Int(trait.value * 100))%")
                                .foregroundColor(.red).bold()
                            Spacer()
                        }
                        Slider(value: $trait.value)
                    }
                }
                Button("Randomize") {
                    profile.friendliness = Double.random(in: 0...1)
                    profile.humor = Double.random(in: 0...1)
                    profile.optimism = Double.random(in: 0...1)
                    profile.energy = Double.random(in: 0...1)
                    funTraits = ContentView.randomFunTraits()
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Personality Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SliderView: View {
    let label: String
    @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(Int(value * 100))%")
            Slider(value: $value)
        }
    }
}

struct ResponseTypeView: View {
    @Binding var selected: String
    @Binding var builtins: [String]
    @Binding var funTypes: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(builtins, id: \.self) { opt in
                        HStack {
                            Text(opt)
                            if opt == selected {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selected = opt }
                    }
                }
                Section(header: Text("Fun/New (random)")) {
                    ForEach(funTypes, id: \.self) { opt in
                        HStack {
                            Text(opt)
                                .foregroundColor(.red)
                                .bold()
                            if opt == selected {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selected = opt }
                    }
                }
            }
            .navigationTitle("Response Type")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
