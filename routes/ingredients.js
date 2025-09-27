// routes/ingredients.js
const express = require("express");
const router = express.Router();
const Ingredient = require("../models/Ingredient"); // Import the Ingredient model

// A placeholder for the user ID.
// LATER, we will get this dynamically from the authenticated user.
const MOCK_USER_ID = "633d9a7b3e4f3a0069a12345"; // This is a fake but valid-looking ID

// === GET /api/ingredients ===
// Fetches all ingredients for a specific user
router.get("/", async (req, res) => {
  try {
    const ingredients = await Ingredient.find({ owner: MOCK_USER_ID });
    res.json(ingredients);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// === POST /api/ingredients ===
// Adds a new ingredient for a specific user
router.post("/", async (req, res) => {
  const ingredient = new Ingredient({
    name: req.body.name,
    quantity: req.body.quantity,
    owner: MOCK_USER_ID, // Using the mock user ID for now
  });

  try {
    const newIngredient = await ingredient.save();
    res.status(201).json(newIngredient);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

module.exports = router;
