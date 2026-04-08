import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        NavigationView {
            ZStack {

                Image("favoriteBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: -43)
                    .clipped()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            if favoritesManager.favorites.isEmpty {
                                Text("No favorites yet.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(favoritesManager.favorites) { favorite in
                                    HStack {
                                        NavigationLink(
                                            destination: RestaurantDetailView(
                                                restaurantName: favorite.restaurantName,
                                                rawRestaurantName: favorite.rawRestaurantName,
                                                placeID: favorite.placeID
                                            )
                                        ) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(favorite.restaurantName)
                                                        .font(.headline)
                                                        .foregroundColor(.black)
                                                    
                                                    if !favorite.rawRestaurantName.isEmpty &&
                                                        favorite.rawRestaurantName != favorite.restaurantName {
                                                        Text(favorite.rawRestaurantName)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button {
                                            favoritesManager.removeFavorite(id: favorite.id)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.78))
                                    .cornerRadius(18)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: 330, height: 400)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 170)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack{
                        Spacer()
                            .frame(height: 300)
                        
                        Text("Favorites")
                            .font(.custom("CoffeeMenus", size: 32))
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                favoritesManager.fetchFavorites()
            }
        }
    }
}
