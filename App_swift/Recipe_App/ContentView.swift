// ContentView.swift
import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject var authManager = AuthenticationManager()

    var body: some View {
        VStack {
            if authManager.isAuthenticated {
                // --- Logged In View ---
                Text("Welcome, \(authManager.userProfile?.name ?? "User")!")
                    .font(.title)
                Text("Access Token: \(authManager.accessToken ?? "N/A")")
                    .font(.caption)
                    .padding()

                Button("Log Out", action: authManager.logout)
                    .buttonStyle(.borderedProminent)
            } else {
                // --- Logged Out View ---
                Text("Recipe App 🍳")
                    .font(.largeTitle)
                    .padding()
                Button("Log In", action: authManager.login)
                    .buttonStyle(.borderedProminent)
            }
        }
        .background(Color.yellow)
        .padding()
    }
}
