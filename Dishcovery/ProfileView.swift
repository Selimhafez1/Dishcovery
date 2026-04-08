import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager

    @State private var showDeleteAlert = false
    @State private var deleteErrorMessage = ""
    @State private var isDeleting = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("profileBackground2")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: -40)
                    .clipped()
                    .ignoresSafeArea()

                Color.black.opacity(0.08)
                    .ignoresSafeArea()

                VStack {
                    Form {
                        Section("Account") {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text("\(session.firstName) \(session.lastName)".trimmingCharacters(in: .whitespaces))
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("Preferred language")
                                Spacer()
                                Text(AppLanguages.name(for: session.preferredLanguage))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Section("Change Language") {
                            Picker("Preferred Language", selection: Binding(
                                get: { session.preferredLanguage },
                                set: { newValue in
                                    session.updatePreferredLanguage(newValue)
                                }
                            )) {
                                ForEach(AppLanguages.all) { language in
                                    Text(language.name).tag(language.code)
                                }
                            }
                        }

                        Section {
                            Button("Sign Out") {
                                session.signOut()
                            }
                            .foregroundColor(.red)
                        }

                        Section {
                            Button {
                                showDeleteAlert = true
                            } label: {
                                if isDeleting {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Text("Delete Account")
                                        .foregroundColor(.red)
                                }
                            }
                            .disabled(isDeleting)
                        }

                        if !deleteErrorMessage.isEmpty {
                            Section {
                                Text(deleteErrorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(width: 320, height: 500)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Spacer()
                            .frame(height: 150)

                        Text("Profile")
                            .font(.custom("CoffeeMenus", size: 30))
                            .foregroundColor(.black)
                    }
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }

                Button("Delete Account", role: .destructive) {
                    isDeleting = true
                    deleteErrorMessage = ""

                    session.deleteAccount { error in
                        DispatchQueue.main.async {
                            isDeleting = false

                            if let error = error {
                                deleteErrorMessage = error
                            }
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account and saved data.")
            }
        }
    }
}
