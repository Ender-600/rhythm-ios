//
//  AuthView.swift
//  Rhythm
//
//  login/register view
//

import SwiftUI

struct AuthView: View {
    @Bindable var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var showError = false
    
    private var currentTheme: Color.Theme {
        Color.theme(for: colorScheme)
    }
    
    var body: some View {
        ZStack {
            // background gradient
            LinearGradient(
                colors: [currentTheme.primary.opacity(0.1), currentTheme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(currentTheme.primary)
                    
                    Text("Rhythm")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(currentTheme.text)
                    
                    Text(isSignUpMode ? "Create Your Account" : "Welcome Back")
                        .font(.title3)
                        .foregroundStyle(currentTheme.textSecondary)
                }
                
                Spacer()
                
                // 输入表单
                VStack(spacing: 16) {
                    // email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(currentTheme.textSecondary)
                        
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle(theme: currentTheme))
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    
                    // password input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundStyle(currentTheme.textSecondary)
                        
                        SecureField("At least 6 characters", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle(theme: currentTheme))
                            .textContentType(isSignUpMode ? .newPassword : .password)
                    }
                    
                    // error message
                    if let error = authService.error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    // main button
                    Button {
                        Task {
                            await handleAuth()
                        }
                    } label: {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSignUpMode ? "Register" : "Login")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(currentTheme.primary)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                    }
                    .disabled(authService.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)
                    
                    // toggle login/register
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isSignUpMode.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(currentTheme.textSecondary)
                            Text(isSignUpMode ? "Login" : "Register")
                                .foregroundStyle(currentTheme.primary)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Apple login (future feature)
                // Button("使用 Apple 登录") { }
            }
            .padding(.vertical, 32)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        email.contains("@") && 
        password.count >= 6
    }
    
    private func handleAuth() async {
        do {
            if isSignUpMode {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            // error is handled in authService
            print("Auth error: \(error)")
        }
    }
}

// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    let theme: Color.Theme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.border, lineWidth: 1)
            )
    }
}

#Preview {
    AuthView(authService: AuthService())
}
