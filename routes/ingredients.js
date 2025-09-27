const { GoogleGenerativeAI } = require('@google/generative-ai'); // Make sure this is at the top
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY); // Make sure this is at the top

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

// === POST /api/ingredients/parse-voice ===
// Takes raw text, parses it with AI, and adds ingredients to the database
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
