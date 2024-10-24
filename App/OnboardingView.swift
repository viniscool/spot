import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool

    var body: some View {
        NavigationView {
            ZStack{
                Image("App Background")
                    .resizable()
                    .scaledToFill()
                
                VStack(spacing: 20) {
                    Text("Welcome to SPOT!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("SPOT helps you record, transcribe, and summarize conversations on patient transfers.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        isOnboarding = false
                        UserDefaults.standard.set(false, forKey: "onboardingCompleted")
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
}
