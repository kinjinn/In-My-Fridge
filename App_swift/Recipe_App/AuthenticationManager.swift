import Foundation
import Combine
import Auth0

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserInfo?
    @Published var accessToken: String?
    
    func login() {
        Auth0
            .webAuth()
            // IMPORTANT: Using the audience from your working branch
            .audience("https://api.gridge.com")
            .scope("openid profile email")
            .start { result in
                switch result {
                case .success(let credentials):
                    self.isAuthenticated = true
                    self.accessToken = credentials.accessToken
                    self.fetchUserProfile(credentials: credentials)
                case .failure(let error):
                    print("❌ Failed with login: \(error.localizedDescription)")
                }
            }
    }
    
    private func fetchUserProfile(credentials: Credentials) {
        Auth0
            .authentication()
            .userInfo(withAccessToken: credentials.accessToken)
            .start { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        self.userProfile = profile
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
                    case .failure(let error):
                        print("❌ Failed with logout: \(error.localizedDescription)")
                    }
                }
            }
    }
}
