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
            currentTheme.background.ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text("R")
                            .font(.title.monospaced().weight(.black))
                            .foregroundStyle(Color.rhythmPaper)
                            .frame(width: 64, height: 64)
                            .background(Color.rhythmSignal)

                        Spacer()

                        Text(isSignUpMode ? "NEW ACCOUNT" : "SIGN IN")
                            .swissSectionLabel(color: .rhythmSignal)
                    }
                    
                    Text("Rhythm")
                        .font(.system(size: 52, weight: .bold))
                        .tracking(-2)
                        .foregroundStyle(currentTheme.text)
                    
                    Text(isSignUpMode ? "Create Your Account" : "Welcome Back")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(currentTheme.textSecondary)

                    SwissRule(strong: true)
                }
                .padding(.horizontal, QuietSwiss.screenPadding)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL")
                            .swissSectionLabel()
                        
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle(theme: currentTheme))
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .swissSectionLabel()
                        
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
                        .background(Color.rhythmInk)
                        .foregroundStyle(Color.rhythmPaper)
                        .clipShape(RoundedRectangle(cornerRadius: QuietSwiss.compactRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: QuietSwiss.compactRadius)
                                .stroke(Color.rhythmInk, lineWidth: 1)
                        }
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
                .padding(20)
                .swissSurface()
                .padding(.horizontal, QuietSwiss.screenPadding)
                
                Spacer()
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
            .clipShape(RoundedRectangle(cornerRadius: QuietSwiss.compactRadius))
            .overlay(
                RoundedRectangle(cornerRadius: QuietSwiss.compactRadius)
                    .stroke(theme.border, lineWidth: 1)
            )
    }
}

#Preview {
    AuthView(authService: AuthService())
}
