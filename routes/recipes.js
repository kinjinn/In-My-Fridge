// routes/recipes.js
const express = require('express');
const router = express.Router();
const { checkJwt } = require('../middleware/auth');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

// Initialize the Google Generative AI client
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// === POST /api/recipes/generate ===
router.post('/generate', checkJwt, async (req, res) => {
  try {
    const { ingredients } = req.body;

    if (!ingredients || ingredients.length === 0) {
      return res.status(400).json({ message: 'Ingredients are required.' });
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    // --- This is our Prompt Engineering! ---
    const prompt = `
      You are a creative chef. Based ONLY on the following list of ingredients, create 2 simple recipes.
      Available ingredients: ${ingredients.join(', ')}.
      You can assume the user has basic pantry items like salt, pepper, oil, and water.
      Your response MUST be a valid JSON array of objects. Do not include any text before or after the JSON array.
      Each object in the array should have the following structure:
      {
        "title": "Recipe Title",
        "description": "A short, appealing description of the dish.",
        "ingredients_used": ["list", "of", "ingredients", "from the provided list"],
        "instructions": ["Step 1", "Step 2", "Step 3"]
      }
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Clean the response to ensure it's valid JSON
    const jsonResponse = JSON.parse(text.replace(/```json/g, '').replace(/```/g, ''));

    res.json(jsonResponse);

  } catch (error) {
    console.error('Error generating recipes:', error);
    res.status(500).json({ message: 'Failed to generate recipes.' });
  }
});

module.exports = router;