const express = require("express");
const router = express.Router();
const Ingredient = require("../models/Ingredient");
const User = require("../models/User");
const { checkJwt } = require("../middleware/auth");
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// GET /api/ingredients
router.get("/", checkJwt, async (req, res) => {
    try {
        const user = await User.findOne({ auth0Id: req.auth.payload.sub });
        if (!user) return res.status(404).json({ message: "User not found" });
        const ingredients = await Ingredient.find({ owner: user._id });
        res.json(ingredients);
    } catch (err) { res.status(500).json({ message: err.message }); }
});

// POST /api/ingredients
router.post("/", checkJwt, async (req, res) => {
    try {
        let user = await User.findOne({ auth0Id: req.auth.payload.sub });
        if (!user) {
            user = new User({ auth0Id: req.auth.payload.sub, email: "user@example.com" });
            await user.save();
        }
        const ingredient = new Ingredient({
            name: req.body.name,
            quantity: req.body.quantity,
            owner: user._id,
        });
        const newIngredient = await ingredient.save();
        res.status(201).json(newIngredient);
    } catch (err) { res.status(400).json({ message: err.message }); }
});

// DELETE /api/ingredients/:id
router.delete('/:id', checkJwt, async (req, res) => {
    try {
        const user = await User.findOne({ auth0Id: req.auth.payload.sub });
        if (!user) return res.status(404).json({ message: "User not found" });
        const ingredient = await Ingredient.findOneAndDelete({ _id: req.params.id, owner: user._id });
        if (!ingredient) return res.status(404).json({ message: "Ingredient not found or permission denied." });
        res.json({ message: "Ingredient deleted successfully" });
    } catch (err) { res.status(500).json({ message: err.message }); }
});

// PATCH /api/ingredients/:id
router.patch('/:id', checkJwt, async (req, res) => {
  const { quantity } = req.body;
  if (!quantity) {
      return res.status(400).json({ message: 'Quantity is required.' });
  }

  try {
      const user = await User.findOne({ auth0Id: req.auth.payload.sub });
      const ingredient = await Ingredient.findOne({ _id: req.params.id, owner: user._id });

      if (!ingredient) return res.status(404).json({ message: 'Ingredient not found.' });

      // Update the quantity with the new value from the app
      ingredient.quantity = quantity;
      
      await ingredient.save();
      res.json(ingredient); // Send the updated ingredient back
  } catch (err) {
      res.status(500).json({ message: err.message });
  }
});

// POST /api/ingredients/parse-preview
router.post('/parse-preview', checkJwt, async (req, res) => {
  const { text } = req.body;
  if (!text) {
      return res.status(400).json({ message: 'Text input is required.' });
  }

  try {
      const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
      const prompt = `
          You are an expert grocery list parser. Analyze the following text and extract all ingredients and their quantities.
          The text is: "${text}".
          Your response MUST be a valid JSON array of objects. Do not include any text, notes, or markdown before or after the JSON array.
          Each object must have the structure: {"name": "ingredient_name", "quantity": "ingredient_quantity"}.
          If a quantity is not specified, use "1" as the default quantity.
          Quantity should not be letters.
      `;

      const result = await model.generateContent(prompt);
      const responseText = result.response.text();
      console.log('--- Raw AI Response ---');
        console.log(responseText);
        console.log('-----------------------');
      const parsedIngredients = JSON.parse(responseText.replace(/```json/g, '').replace(/```/g, ''));

      // Send the parsed ingredients back to the app for confirmation
      res.json(parsedIngredients); 

  } catch (error) {
      console.error('Error parsing text for preview:', error);
      res.status(500).json({ message: 'Failed to parse text.' });
  }
});

module.exports = router;