// routes/ingredients.js
const express = require("express");
const router = express.Router();
const Ingredient = require("../models/Ingredient");
const User = require("../models/User");
const { checkJwt } = require("../middleware/auth");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// --- Code for Image Uploads and AI ---
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });

function bufferToBase64(buffer) {
  return buffer.toString("base64");
}

if (!process.env.GEMINI_API_KEY) {
  throw new Error("GEMINI_API_KEY is not set in the environment variables.");
}
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
// --- End New Code ---

// === GET /api/ingredients ===
router.get("/", checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.payload.sub;
    const user = await User.findOne({ auth0Id: auth0Id });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    const ingredients = await Ingredient.find({ owner: user._id });
    res.json(ingredients);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// === POST /api/ingredients ===
router.post("/", checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.payload.sub;
    let user = await User.findOne({ auth0Id: auth0Id });

    if (!user) {
      user = new User({ auth0Id: auth0Id, email: "user@example.com" });
      await user.save();
    }

    const ingredient = new Ingredient({
      name: req.body.name,
      quantity: req.body.quantity,
      owner: user._id,
    });

    const newIngredient = await ingredient.save();
    res.status(201).json(newIngredient);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// ==========================================================
// === NEW ENDPOINTS FOR IMAGE SCANNING AND BATCH ADDING ===
// ==========================================================

// === POST /api/ingredients/scan ===
router.post("/scan", checkJwt, upload.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image file uploaded." });
    }

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-pro-latest" });

    const imagePart = {
      inlineData: {
        data: bufferToBase64(req.file.buffer),
        mimeType: req.file.mimetype,
      },
    };

    const prompt = `
      Analyze the food items in this image of a fridge or pantry.
      Identify only the primary, edible food items. Ignore containers, brands, and non-food objects.
      Your response MUST be ONLY a valid JSON array of objects. Do not include any text before or after the JSON.
      Each object must have this exact structure: { "name": "...", "quantity": "..." }.
      For quantity, provide a reasonable estimate (e.g., "1 bottle", "half a carton", "about 2"). If you cannot determine the quantity, use "1".
      Example response: [{"name": "Milk", "quantity": "1 gallon"}, {"name": "Eggs", "quantity": "1 dozen"}]
    `;

    const result = await model.generateContent([prompt, imagePart]);
    const text = result.response.text();

    const jsonResponse = JSON.parse(
      text.replace(/```json/g, "").replace(/```/g, "")
    );
    res.json(jsonResponse);
  } catch (error) {
    console.error("Error scanning image:", error);
    res.status(500).json({ message: "Failed to process image." });
  }
});

// === POST /api/ingredients/batch-add ===
router.post("/batch-add", checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.payload.sub;
    const user = await User.findOne({ auth0Id });

    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    const ingredientsToAdd = req.body.ingredients.map((scannedIngredient) => ({
      ...scannedIngredient,
      owner: user._id,
    }));

    const newIngredients = await Ingredient.insertMany(ingredientsToAdd);
    res.status(201).json(newIngredients);
  } catch (error) {
    console.error("Error adding ingredients in batch:", error);
    res.status(500).json({ message: "Failed to add ingredients." });
  }
});

module.exports = router;
