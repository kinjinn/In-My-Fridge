// routes/recipes.js
const express = require("express");
const router = express.Router();
const { checkJwt } = require("../middleware/auth");
const { GoogleGenerativeAI } = require("@google/generative-ai");
require("dotenv").config();

if (!process.env.GEMINI_API_KEY) {
  throw new Error("GEMINI_API_KEY is not set in the environment variables.");
}

// Initialize the Google Generative AI client
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

router.post("/generate", checkJwt, async (req, res) => {
  try {
    const { ingredients } = req.body;

    if (!ingredients || ingredients.length === 0) {
      return res.status(400).json({ message: "Ingredients are required." });
    }

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
    });

    const prompt = `
    You are a recipe API. Your only function is to return valid JSON.
    Based on this list of ingredients: ${ingredients.join(", ")}.
    Assume basic pantry items like salt, pepper, oil, water.
    Generate 2 simple recipes.
    Your entire response must be ONLY a valid JSON array of objects.
    Do NOT include any explanatory text, markdown, or anything before or after the opening and closing brackets.
    Each object must have this exact structure:
    {
      "title": "...",
      "description": "...",
      "ingredients_used": ["...", "..."],
      "instructions": ["...", "..."]
    }
    `;

    // ✅ fixed: no need to await `result.response` separately
    const result = await model.generateContent(prompt);
    const text = result.response.text();

    console.log("--- RAW RESPONSE FROM GEMINI ---");
    console.log(text);
    console.log("--------------------------------");

    try {
      const jsonResponse = JSON.parse(
        text.replace(/```json/g, "").replace(/```/g, "")
      );
      res.json(jsonResponse);
    } catch (parseError) {
      console.error("Failed to parse JSON from Gemini:", parseError);
      res.status(500).json({ message: "AI response was not valid JSON." });
    }
  } catch (error) {
    console.error("Error generating recipes:", error);
    res.status(500).json({ message: "Failed to contact the AI service." });
  }
});

module.exports = router;
