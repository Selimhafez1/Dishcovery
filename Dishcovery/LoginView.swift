import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("loginBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: -34)
                    .clipped()
                    .ignoresSafeArea()

                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Dishcovery Login")
                        .font(.custom("CoffeeMenus", size: 37))
                        .bold()
                        .foregroundColor(.black)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(width: 300)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button("Login") {
                        session.signIn(email: email, password: password) { error in
                            if let error = error {
                                errorMessage = error
                            } else {
                                errorMessage = ""
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Create Account") {
                        showSignUp = true
                    }
                    .foregroundColor(.black)
                    .font(.subheadline)
                }
                .offset(y: -90)
            }
            .ignoresSafeArea(.keyboard)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}
