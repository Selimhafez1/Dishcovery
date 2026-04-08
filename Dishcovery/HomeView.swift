import SwiftUI
import UIKit



struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Image("homeBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(x: -90)
                    .clipped()
                    .ignoresSafeArea()
                
                
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 30)
                    
                    Image(systemName: "camera.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.orange)
                    

                    
                    Spacer()
                        .frame(height: 200)
                    
                        NavigationLink(destination: LogoScanView(autoStartCamera: true)) {
                            Text("Scan Now")
                                .fontWeight(.bold)
                                .padding()
                                .frame(width: 200)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("DISHCOVERY")
                        .font(.custom("CloudeTrial", size: 37))
                        .foregroundColor(.white)
                        .padding(.top, 120)
                }
            }
        }
    }
}
