// models/Ingredient.js
const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const ingredientSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true, // Removes whitespace from both ends
    },
    quantity: {
      type: String, // Using String to be flexible (e.g., "1", "1/2 cup", "a pinch")
      required: true,
    },
    // This is the link to the user who owns this ingredient
    owner: {
      type: Schema.Types.ObjectId,
      required: true,
      ref: "User", // This refers to the 'User' model we just created
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Ingredient", ingredientSchema);
