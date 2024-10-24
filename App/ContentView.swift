import SwiftUI
import AVFoundation

struct SpeechView: View {
    @State private var questions = [
        "Describe the patient's condition.",
        "Identify the patient.",
        "Are there any assistive devices the patient uses?",
        "When should we coordinate the transfer?"
    ]
    
    @State private var useSuggestedQuestions: Bool = false
    @State private var keywordQuestions: [KeywordQuestion] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var accumulatedText: String = ""
    @State private var summarizedText: String = ""
    @State private var speechRecognizer = SpeechRecognizer()

    @State private var selectedLanguage: String = "en-US" // Add a default selected language
    @State private var isRecording: Bool = false
    @State private var currentText: String = ""
    @State private var recordingCount: Int = 0
    @State private var showingSettings = false
    @State private var showingOnboarding = UserDefaults.standard.bool(forKey: "onboardingCompleted") == false
    @State private var followUpQuestions: [String] = []
    @State private var askedFollowUpQuestions: Set<String> = []
    @State private var isEndReached: Bool = false

    // Add a speech synthesizer
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
            ZStack{
                
                if showingOnboarding {
                    OnboardingView(isOnboarding: $showingOnboarding)
                } else {
                    Image("Home Page")
                        .resizable()
                        .scaledToFill()
                    
                    VStack {
                        HStack {
                            Spacer() // Pushes the button to the right
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .imageScale(.large)
                                    .padding([.top], 100)
                                    .padding([.trailing], 25)
                            }
                            .sheet(isPresented: $showingSettings) {
                                SettingsView(questions: $questions, useSuggestedQuestions: $useSuggestedQuestions, selectedLanguage: $selectedLanguage)
                            }
                        }
                        .padding([.top, .trailing], 16) // Add padding to position it correctly at the top-right
                        Spacer() // This ensures the button stays at the top
                    }
                    
                    VStack(spacing: 20) {
                        // Safely access questions array
                        if currentQuestionIndex < questions.count {
                            HStack {
                                Text(questions[currentQuestionIndex])
                                    .font(.headline)
                                    .padding()
                                
                                // Add sound button to read the question aloud
                                Button(action: {
                                    readQuestionAloud(text: questions[currentQuestionIndex])
                                }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .imageScale(.large)
                                        .padding(.leading, 10)
                                }
                            }
                        } else {
                            Text("Is there extra information? If not, click to continue to the summary.")
                                .font(.headline)
                                .padding()
                        }
                        
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .imageScale(.large)
                                .scaleEffect(2.0)
                                .foregroundColor(isRecording ? .accentColor : .primary)
                        }
                        
                        if !summarizedText.isEmpty {
                            HStack {
                                Text("Summary:")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = summarizedText
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .imageScale(.large)
                                        .padding()
                                }
                            }
                            
                            Text(summarizedText)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                keywordQuestions = getKeywordQuestions()
            }
    }
    
    private func startRecording() {
        print("Starting speech recognition")
        currentText = ""
        isRecording = true
        // Pass the selected language to SpeechRecognizer
        speechRecognizer = SpeechRecognizer(locale: Locale(identifier: selectedLanguage))
        speechRecognizer.record { newText in
            self.currentText = newText
        }
    }
    
    private func stopRecording() {
        print("Stopping speech recognition")
        isRecording = false
        if !currentText.isEmpty {
            accumulatedText += "\n\n" + currentText
        }
        speechRecognizer.stopRecording()
        currentText = ""
        print("Accumulated Text: \(accumulatedText)")
        
        recordingCount += 1
        
        handleNextQuestion()
    }
    
    private func handleNextQuestion() {
        // Safely increment currentQuestionIndex only if within bounds
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else if !isEndReached {
            isEndReached = true
            checkForFollowUps()
        } else {
            summarizeText(accumulatedText)
            resetSession()
        }
    }
    
    private func checkForFollowUps() {
        var matchedQuestions: [String] = []
        
        for keywordQuestion in keywordQuestions {
            if accumulatedText.contains(keywordQuestion.keyword),
               !askedFollowUpQuestions.contains(keywordQuestion.question) {
                matchedQuestions.append(keywordQuestion.question)
                askedFollowUpQuestions.insert(keywordQuestion.question)
            }
        }
        
        if !matchedQuestions.isEmpty {
            followUpQuestions.append(contentsOf: matchedQuestions)
            questions.append(contentsOf: matchedQuestions)
        }
        
        currentQuestionIndex = questions.count - followUpQuestions.count
    }
    
    private func summarizeText(_ text: String) {
        let prompt = "Summarize the following conversation in bullet point notes: \(text). MAKE SURE TO USE BULLET POINTS; THE TEXT STARTS HERE:"
        let parameters: [String: String] = ["inputs": prompt]
        
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("Failed to encode JSON")
            return
        }

        guard let url = URL(string: "https://api-inference.huggingface.co/models/mistralai/Mixtral-8x7B-Instruct-v0.1") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.addValue("Bearer [API key]", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }

            do {
                if let responseArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let firstItem = responseArray.first,
                   let generatedText = firstItem["generated_text"] as? String {
                    
                    let cleanedText = generatedText.replacingOccurrences(of: prompt, with: "")
                    
                    DispatchQueue.main.async {
                        self.summarizedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } else {
                    print("Unexpected response format")
                }
            } catch {
                print("Failed to decode summary response: \(error.localizedDescription)")
            }
        }

        task.resume()
    }
    
    private func resetSession() {
        accumulatedText = ""
        followUpQuestions.removeAll()
        askedFollowUpQuestions.removeAll()
        isEndReached = false
        currentQuestionIndex = 0
        recordingCount = 0
        summarizedText = ""
    }
    
    private func getKeywordQuestions() -> [KeywordQuestion] {
        if let data = UserDefaults.standard.data(forKey: "keywordQuestions"),
           let savedQuestions = try? JSONDecoder().decode([KeywordQuestion].self, from: data) {
            return savedQuestions
        }
        return []
    }
    
    // Function to read question aloud
    private func readQuestionAloud(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage)
        speechSynthesizer.speak(utterance)
    }
}
