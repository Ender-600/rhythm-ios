// Rhythm/Services/AuthService.swift
import Foundation
import Supabase
import SwiftUI

@Observable
@MainActor
final class AuthService {
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false
    private(set) var isLoading = false
    private(set) var error: AuthError?
    
    private let client = SupabaseConfig.client
    
    enum AuthError: LocalizedError {
        case signUpFailed(String)
        case signInFailed(String)
        case signOutFailed(String)
        case sessionError(String)
        
        var errorDescription: String? {
            switch self {
            case .signUpFailed(let msg): return "fail to register: \(msg)"
            case .signInFailed(let msg): return "fail to login: \(msg)"
            case .signOutFailed(let msg): return "fail to logout: \(msg)"
            case .sessionError(let msg): return "session error: \(msg)"
            }
        }
    }
    
    init() {
        Task {
            await checkSession()
        }
    }
    
    // check current session
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // sign up with email and password
    func signUp(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            currentUser = response.user
            isAuthenticated = response.session != nil
        } catch {
            let authError = AuthError.signUpFailed(error.localizedDescription)
            self.error = authError
            throw authError
        }
    }
    
    // sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            isAuthenticated = true
        } catch {
            let authError = AuthError.signInFailed(error.localizedDescription)
            self.error = authError
            throw authError
        }
    }
    
    // sign in with apple
    func signInWithApple() async throws {
        // 需要配置 Sign in with Apple
        // 参考: https://supabase.com/docs/guides/auth/social-login/auth-apple
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // 实现 Apple Sign In 流程
        // 这里需要使用 AuthenticationServices 框架
    }
    
    // sign out
    func signOut() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            let authError = AuthError.signOutFailed(error.localizedDescription)
            self.error = authError
            throw authError
        }
    }
    
    // get current user id
    var userId: UUID? {
        guard let user = currentUser else { return nil }
        return UUID(uuidString: user.id.uuidString)
    }
}
