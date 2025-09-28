import SwiftUI

struct IngredientsView: View {
    @Binding var ingredients: [Ingredient]
    @Binding var isLoading: Bool
    
    var onDelete: (IndexSet) -> Void
    var onSaveQuantity: (Ingredient, String) -> Void
    var onAdd: (String, String) -> Void
    var onGenerate: () -> Void
    var onAddByVoice: () -> Void
    
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""
    @State private var editingIngredientID: String? = nil
    @State private var editingQuantityText: String = ""

    var body: some View {
        VStack {
            Text("Ingredients").font(.largeTitle).padding()
            
            HStack {
                TextField("Ingredient Name", text: $newIngredientName)
                    .textFieldStyle(.roundedBorder)
                TextField("Quantity", text: $newIngredientQuantity)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    onAdd(newIngredientName, newIngredientQuantity)
                    newIngredientName = ""
                    newIngredientQuantity = ""
                }
                .buttonStyle(.borderedProminent)
            }.padding(.horizontal)
            
            List {
                Section(header: Text("In Your Fridge")) {
                    if ingredients.isEmpty {
                        Text("No ingredients yet. Add one to get started!").foregroundColor(.secondary)
                    } else {
                        ForEach($ingredients) { $ingredient in
                            HStack {
                                Toggle(isOn: $ingredient.isSelected) {
                                    Text(ingredient.name).font(.headline)
                                }.toggleStyle(CheckboxToggleStyle())
                                
                                Spacer()
                                
                                if editingIngredientID == ingredient.id {
                                    TextField("Quantity", text: $editingQuantityText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                        .multilineTextAlignment(.trailing)
                                        .onSubmit {
                                            onSaveQuantity(ingredient, editingQuantityText)
                                            editingIngredientID = nil
                                        }
                                } else {
                                    Text("Qty: \(ingredient.quantity)")
                                        .onTapGesture {
                                            editingIngredientID = ingredient.id
                                            editingQuantityText = ingredient.quantity
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: onDelete)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            HStack {
                Spacer()
                Button(action: onAddByVoice) {
                    Image(systemName: "mic.fill").padding(8)
                }.buttonStyle(.bordered)
                Spacer()
                
                if !ingredients.isEmpty {
                    Button(action: onGenerate) {
                        if isLoading { ProgressView() }
                        else { Text("✨ Generate Recipes") }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .padding([.horizontal, .bottom])
        }
        
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .purple : .gray)
                configuration.label
            }
        }.buttonStyle(PlainButtonStyle())
    }
}
