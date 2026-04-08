import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var preferredLanguage = "en"
    @State private var errorMessage = ""

    let languages = AppLanguages.all

    var body: some View {
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
            
            Spacer()

            VStack(spacing: 12) {
                Text("Create Account")
                    .font(.custom("CoffeeMenus", size: 37))
                    .bold()
                    .foregroundColor(.black)

                TextField("First Name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                TextField("Last Name", text: $lastName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(width: 300)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                Picker("Preferred Language", selection: $preferredLanguage) {
                    ForEach(languages) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 300)
                .background(Color.white.opacity(0.85))
                .cornerRadius(8)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Sign Up") {
                    session.signUp(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        preferredLanguage: preferredLanguage
                    ) { error in
                        if let error = error {
                            errorMessage = error
                        } else {
                            errorMessage = ""
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Back to Login") {
                    dismiss()
                }
                .foregroundColor(.black)
                .font(.subheadline)
            }
            .offset(y: -50)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
    }
}
