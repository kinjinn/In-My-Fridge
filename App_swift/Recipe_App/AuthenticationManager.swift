// AuthenticationManager.swift
import Foundation
import Combine
import Auth0

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserInfo?
    @Published var accessToken: String?

//    func login() {
//        Auth0
//            .webAuth()
//            .start { result in
//                switch result {
//                case .success(let credentials):
//                    // Login was successful, now save credentials...
//                    self.isAuthenticated = true
//                    self.accessToken = credentials.accessToken
//                    
//                    // ...and fetch the user's profile separately.
//                    self.fetchUserProfile(credentials: credentials) // <-- FIX #2: Call new function
//
//                case .failure(let error):
//                    print("❌ Failed with login: \(error.localizedDescription)")
//                }
//            }
//    }
        func login() {
            Auth0
                .webAuth()
                .audience("https://api.fridge.com") // <-- Must match the Identifier in your Auth0 API settings
                .scope("openid profile email") // request ID token claims too
                .start { result in
                    switch result {
                    case .success(let credentials):
                        self.isAuthenticated = true
                        self.accessToken = credentials.accessToken

                        // Fetch user profile with the access token
                        self.fetchUserProfile(credentials: credentials)

                        print("✅ Access Token: \(credentials.accessToken ?? "none")")
                    case .failure(let error):
                        print("❌ Failed with login: \(error.localizedDescription)")
                    }
                }
    }
    
    // This is the new function to get the user profile
    private func fetchUserProfile(credentials: Credentials) {
        Auth0
            .authentication()
            .userInfo(withAccessToken: credentials.accessToken)
            .start { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        self.userProfile = profile
                        print("✅ Fetched Profile: \(profile.name ?? "No name")")
                    case .failure(let error):
                        print("❌ Failed with fetching profile: \(error.localizedDescription)")
                    }
                }
            }
    }

    func logout() {
        Auth0
            .webAuth()
            .clearSession { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.isAuthenticated = false
                        self.userProfile = nil
                        self.accessToken = nil
                        print("✅ Logout successful")
                    case .failure(let error):
                        print("❌ Failed with logout: \(error.localizedDescription)")
                    }
                }
            }
    }
}
