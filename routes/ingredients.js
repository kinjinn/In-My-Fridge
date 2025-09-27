// routes/ingredients.js
const express = require("express");
const router = express.Router();
const Ingredient = require("../models/Ingredient");
const User = require("../models/User"); // We need the User model now
const { checkJwt } = require("../middleware/auth"); // Import our security middleware

// === GET /api/ingredients ===
// Fetches all ingredients for the LOGGED IN user
router.get("/", checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.payload.sub;
    const user = await User.findOne({ auth0Id: auth0Id });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    const ingredients = await Ingredient.find({ owner: user._id }); // Find ingredients by our database user ID
    res.json(ingredients);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// === POST /api/ingredients ===
// Adds a new ingredient for the LOGGED IN user
router.post("/", checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.payload.sub;
    let user = await User.findOne({ auth0Id: auth0Id });

    // If the user doesn't exist in our DB, create them
    if (!user) {
      // NOTE: In a real app, you might get the email from the token payload as well
      user = new User({ auth0Id: auth0Id, email: "user@example.com" });
      await user.save();
    }

    const ingredient = new Ingredient({
      name: req.body.name,
      quantity: req.body.quantity,
      owner: user._id, // Link to our database user ID
    });

    const newIngredient = await ingredient.save();
    res.status(201).json(newIngredient);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

module.exports = router;
