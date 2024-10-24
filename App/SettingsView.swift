import SwiftUI

struct SettingsView: View {
    @Binding var questions: [String]
    @Binding var useSuggestedQuestions: Bool
    @Binding var selectedLanguage: String // Binding to pass the selected language to other parts of the app
    @State private var keywordQuestions: [KeywordQuestion] = []
    
    let languages = ["en-US", "es-ES", "fr-FR", "zh-CN"] // List of supported languages

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Questions")) {
                    ForEach(questions.indices, id: \.self) { index in
                        TextField("Question \(index + 1)", text: $questions[index])
                    }
                    .onDelete(perform: deleteQuestion)
                    
                    Button(action: addQuestion) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Question")
                        }
                    }
                }
                
                Section(header: Text("Suggested Questions")) {
                    Toggle("Use Suggested Questions", isOn: $useSuggestedQuestions)
                    
                    if useSuggestedQuestions {
                        List {
                            ForEach(keywordQuestions.indices, id: \.self) { index in
                                HStack {
                                    TextField("Keyword", text: $keywordQuestions[index].keyword)
                                    TextField("Suggested Question", text: $keywordQuestions[index].question)
                                }
                            }
                            .onDelete(perform: deleteKeywordQuestion)
                            
                            Button(action: addKeywordQuestion) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Keyword Question")
                                }
                            }
                        }
                    }
                }
                
                // New Section for Language Setting
                Section(header: Text("Language")) {
                    Picker("Select Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(languageDisplayName(language: language)).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Picker style as a dropdown menu
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                EditButton()
            }
            .onAppear {
                loadKeywordQuestions()
            }
            .onChange(of: keywordQuestions) { _ in
                saveKeywordQuestions()
            }
        }
    }

    private func addQuestion() {
        questions.append("New Question")
    }

    private func deleteQuestion(at offsets: IndexSet) {
        questions.remove(atOffsets: offsets)
    }
    
    private func addKeywordQuestion() {
        keywordQuestions.append(KeywordQuestion(keyword: "", question: ""))
    }

    private func deleteKeywordQuestion(at offsets: IndexSet) {
        keywordQuestions.remove(atOffsets: offsets)
    }
    
    private func loadKeywordQuestions() {
        if let data = UserDefaults.standard.data(forKey: "keywordQuestions"),
           let savedQuestions = try? JSONDecoder().decode([KeywordQuestion].self, from: data) {
            keywordQuestions = savedQuestions
        }
    }
    
    private func saveKeywordQuestions() {
        if let data = try? JSONEncoder().encode(keywordQuestions) {
            UserDefaults.standard.set(data, forKey: "keywordQuestions")
        }
    }

    private func languageDisplayName(language: String) -> String {
        // Return a human-readable language name
        switch language {
        case "en-US": return "English (US)"
        case "es-ES": return "Spanish (Spain)"
        case "fr-FR": return "French (France)"
        case "zh-CN": return "Chinese (Simplified)"
        default: return language
        }
    }
}

struct KeywordQuestion: Identifiable, Codable, Equatable {
    var id = UUID()
    var keyword: String
    var question: String
}
