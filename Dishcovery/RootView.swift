//
//  RootView.swift
//  Dishcovery
//
//  Created by Selim Hafez on 22/03/2026.
//


import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    
    var body: some View {
        if session.user != nil {
            MainTabView()
        } else {
            LoginView()
        }
    }
}