//
//  NewDrinkView.swift
//  sip.ai
//
//  Created by Jon Grimes on 6/14/25.
//

import SwiftUI
import PhotosUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct NewDrinkView: View {
    @EnvironmentObject var model: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var drinkName: String = ""
    @State private var drinkType: DrinkType = .beer
    @State private var drinkNotes: String = ""
    @State private var enjoyment: Enjoyment = .null
    
    @State private var selectedImage: UIImage? = nil
    @State private var isCameraPresented: Bool = false
    @State private var isPhotoPickerPresented: Bool = false
    @State private var photoPickerItem: PhotosPickerItem? = nil
    
    // MARK: - Ranking State
    @State private var showRankingOverlay: Bool = false
    @State private var existingDrinks: [Drink] = []
    @State private var comparisonDrink: Drink? = nil
    @State private var provisionalRating: Double? = nil
    
    var body: some View {
        ZStack {
            // Background Color
            Color(red: 0.96, green: 0.96, blue: 0.94)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    Text("New Drink")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                    
                    drinkNameSection(drinkName: $drinkName)
                    
                    drinkTypeSection(drinkType: $drinkType)
                    
                    drinkNotesSection(drinkNotes: $drinkNotes)
                    
                    drinkImageSection(selectedImage: $selectedImage, isCameraPresented: $isCameraPresented, isPhotoPickerPresented: $isPhotoPickerPresented, photoPickerItem: $photoPickerItem)
                    
                    enjoymentSection(enjoyment: $enjoyment)
                    
                    Button(action: { prepareRanking() }, label: {
                        Text("Add To Your List")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .cardStyle()
                    })
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $photoPickerItem)
        .sheet(isPresented: $isCameraPresented) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .overlay(
            Group {
                if showRankingOverlay, let comparisonDrink = comparisonDrink {
                    RankingOverlayView(
                        newDrink: Drink(
                            id: UUID(),
                            name: drinkName,
                            type: drinkType,
                            rating: provisionalRating ?? 0,
                            notes: drinkNotes.isEmpty ? nil : drinkNotes,
                            image: selectedImage != nil ? (selectedImage!.jpegData(compressionQuality: 0.8)?.base64EncodedString()) : nil
                        ),
                        comparisonDrink: comparisonDrink
                    ) { didChooseNewDrink in
                        recordComparisonResult(choosingNew: didChooseNewDrink)
                    }
                }
            }
        )
    }
    
    /// Returns the rating range for an enjoyment level
    private func ratingRange(for enjoyment: Enjoyment) -> ClosedRange<Double> {
        switch enjoyment {
        case .like: return 8.0...10.0
        case .indifferent: return 4.0...7.0
        case .dislike: return 0.0...3.0
        default: return 0.0...10.0
        }
    }
    
    /// Prepares to rank the new drink by filtering existing drinks and starting overlay
    private func prepareRanking() {
        guard enjoyment != .null else { return }
        let range = ratingRange(for: enjoyment)
        existingDrinks = model.drinks.filter { $0.rating >= range.lowerBound && $0.rating <= range.upperBound }
        guard !existingDrinks.isEmpty else {
            provisionalRating = range.lowerBound
            submitDrink()
            return
        }
        comparisonDrink = existingDrinks.randomElement()
        showRankingOverlay = true
    }
    
    /// Handles the user's comparison choice recursively
    private func recordComparisonResult(choosingNew: Bool) {
        let range = ratingRange(for: enjoyment)
        if choosingNew {
            existingDrinks.removeAll { $0.id == comparisonDrink?.id }
            if let next = existingDrinks.randomElement() {
                comparisonDrink = next
            } else {
                provisionalRating = range.upperBound
                showRankingOverlay = false
                submitDrink()
            }
        } else {
            provisionalRating = comparisonDrink?.rating ?? range.lowerBound
            showRankingOverlay = false
            submitDrink()
        }
    }
    
    /// Validates and saves the new drink using the data manager
    private func submitDrink() {
        guard !drinkName.isEmpty else { return }
        guard let rating = provisionalRating else { return }
        
        let imageBase64: String? = {
            guard let selectedImage = selectedImage else { return nil }
            return selectedImage.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        }()
        
        let drink = Drink(
            id: UUID(),
            name: drinkName,
            type: drinkType,
            rating: rating,
            notes: drinkNotes.isEmpty ? nil : drinkNotes,
            image: imageBase64
        )
        
        model.saveDrink(drink)
        dismiss()
    }
}

// MARK: Helper Views
struct drinkNameSection: View {
    @Binding var drinkName: String
    var body: some View {
        TextField("Drink Name", text: $drinkName)
            .cardStyle()
    }
}

struct drinkTypeSection: View {
    @Binding var drinkType: DrinkType
    var body: some View {
        Picker("Drink Type", selection: $drinkType) {
            Text("Beer").tag(DrinkType.beer)
            Text("Wine").tag(DrinkType.wine)
            Text("Cocktail").tag(DrinkType.cocktail)
        }
        .pickerStyle(.segmented) // You can use .menu or .wheel for different styles
        .cardStyle()
    }
}

struct drinkNotesSection: View {
    @Binding var drinkNotes: String
    var body: some View {
        TextField("Notes...", text: $drinkNotes, axis: .vertical)
            .lineLimit(4...8)
            .cardStyle()
            .frame(minHeight: 120, maxHeight: 180)
    }
}

struct drinkImageSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var isCameraPresented: Bool
    @Binding var isPhotoPickerPresented: Bool
    @Binding var photoPickerItem: PhotosPickerItem?
    
    @State private var showImageSourceDialog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Photo")
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .clipped()
            } else {
                Button(action: { showImageSourceDialog = true }) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 180)
                        .overlay(
                            Text("No photo selected")
                                .foregroundColor(.secondary)
                        )
                        .contentShape(Rectangle())
                }
            }
        }
        .cardStyle()
        .confirmationDialog("Upload Photo", isPresented: $showImageSourceDialog, titleVisibility: .visible) {
            Button("Take Photo") {
                isCameraPresented = true
            }
            Button("Choose from Library") {
                isPhotoPickerPresented = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

enum Enjoyment {
    case like
    case indifferent
    case dislike
    case null // used to allow a state var to be nullable
}

struct enjoymentSection: View {
    @Binding var enjoyment: Enjoyment
    
    var body: some View {
        HStack {
            VStack {
                Text("I Liked It!")
                Button(action: { enjoyment = .like }, label: {
                    ZStack {
                        Circle()
                            .foregroundStyle(.green)
                            .frame(width: 50)
                        if enjoyment == .like {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                        }
                    }
                })
            }
            .padding()
            .frame(maxWidth: .infinity)
            VStack {
                Text("It's fine")
                Button(action: { enjoyment = .indifferent }, label: {
                    ZStack {
                        Circle()
                            .foregroundStyle(.yellow)
                            .frame(width: 50)
                        if enjoyment == .indifferent {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                        }
                    }
                })
            }
            .padding()
            .frame(maxWidth: .infinity)
            VStack {
                Text("I hated it")
                Button(action: { enjoyment = .dislike }, label: {
                    ZStack {
                        Circle()
                            .foregroundStyle(.red)
                            .frame(width: 50)
                        if enjoyment == .dislike {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                        }
                    }
                })
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }
}

struct submitButton: View {
    @Binding var drinkName: String
    @Binding var drinkType: DrinkType
    @Binding var drinkNotes: String
    @Binding var enjoyment: Enjoyment
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        Button(action: {
            // Start ranking process instead of directly saving
            // This will handle enjoyment-based ranking overlay
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first?
                .rootViewController?.view?.endEditing(true)
            // Call prepareRanking on the parent view
            // Trick: We need to bubble up, so using Notification or via environment in real case
            // Here assuming parent view's prepareRanking is invoked via binding or environmentObject
            
            // But since this View is a subview, call binding action via closure is better.
            // For now, to meet spec, assume action calls prepareRanking on parent:
            
            // We will wrap the submitButton usage in NewDrinkView so that this calls prepareRanking:
            // So just call prepareRanking() in NewDrinkView's submitButton action.
        }, label: {
            Text("Add To Your List")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .cardStyle()
        })
    }
}

// Because we need submitButton to call prepareRanking in NewDrinkView, override the action in NewDrinkView:
extension NewDrinkView {
    private func submitButtonAction() {
        prepareRanking()
    }
}

extension NewDrinkView {
    // To replace the submitButton with action that calls prepareRanking
    var submitButton: some View {
        Button(action: {
            submitButtonAction()
        }, label: {
            Text("Add To Your List")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .cardStyle()
        })
    }
}

/// A view modifier that applies a card-like style with padding, background,
/// rounded corners, stroke, and shadow to a view.
///
/// This style is used to give inputs and containers a consistent card appearance.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
    }
}

extension View {
    /// Applies the card style modifier to the view.
    ///
    /// This is a convenience method to easily apply the CardStyle to any view.
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

/// A view that displays a section header with a title, styled with a headline font.
///
/// Used to label sections of the beer input form clearly.
struct SectionHeader: View {
    /// The title text to display in the section header.
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .medium, design: .none))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}

import UIKit
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Ranking Overlay View
/// Overlay view to compare new drink against existing drinks for ranking purposes.
/// Prompts user to select which drink they prefer, enabling an iterative ranking.
struct RankingOverlayView: View {
    let newDrink: Drink
    let comparisonDrink: Drink
    let onChoice: (Bool) -> Void // true if new drink preferred, false if existing preferred

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Which do you prefer?")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(red: 0.96, green: 0.96, blue: 0.94))
                            .frame(width: 120, height: 160)
                        Button(action: { onChoice(true) }) {
                            VStack {
                                Text(newDrink.name)
                                    .foregroundColor(.black)
                                    .bold()
                            }
                            .frame(width: 120, height: 160)
                        }
                    }
                    Text("OR")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(red: 0.96, green: 0.96, blue: 0.94))
                            .frame(width: 120, height: 160)
                        Button(action: { onChoice(false) }) {
                            VStack {
                                Text(comparisonDrink.name)
                                    .foregroundColor(.black)
                                    .bold()
                            }
                            .frame(width: 120, height: 160)
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
    }
}

#Preview {
    NewDrinkView()
        .environmentObject(DataManager())
}
