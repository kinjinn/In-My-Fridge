// Create this new file: ConfirmationSheetView.swift
import SwiftUI

struct ConfirmationSheetView: View {
    // Data passed in from ContentView
    let ingredientsToConfirm: [Ingredient]
    
    // Callbacks to notify ContentView of user actions
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        VStack {
            Text("Confirm Ingredients")
                .font(.largeTitle)
                .padding()
            
            // This list now correctly reads the data passed into it
            List(ingredientsToConfirm) { ingredient in
                VStack(alignment: .leading) {
                    Text(ingredient.name).font(.headline)
                    Text("Qty: \(ingredient.quantity)").font(.subheadline)
                }
            }
            
            HStack(spacing: 20) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                Button("Confirm & Add", action: onConfirm)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
