// routes/ingredients.js
const express = require("express");
const router = express.Router();
const Ingredient = require("../models/Ingredient");
const User = require("../models/User");
const { checkJwt } = require("../middleware/auth");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });

function bufferToBase64(buffer) {
  return buffer.toString("base64");
}

if (!process.env.GEMINI_API_KEY) {
  throw new Error("GEMINI_API_KEY is not set in the environment variables.");
}
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

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

router.post("/scan", checkJwt, upload.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image file uploaded." });
    }

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

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

router.delete("/:id", checkJwt, async (req, res) => {
  try {
    const user = await User.findOne({ auth0Id: req.auth.payload.sub });
    if (!user) return res.status(404).json({ message: "User not found" });
    const ingredient = await Ingredient.findOneAndDelete({
      _id: req.params.id,
      owner: user._id,
    });
    if (!ingredient)
      return res
        .status(404)
        .json({ message: "Ingredient not found or permission denied." });
    res.json({ message: "Ingredient deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

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

router.post("/parse-preview", checkJwt, async (req, res) => {
  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ message: "Text input is required." });
  }

  try {
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
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
    console.log("--- Raw AI Response ---");
    console.log(responseText);
    console.log("-----------------------");
    const parsedIngredients = JSON.parse(
      responseText.replace(/```json/g, "").replace(/```/g, "")
    );

    // Send the parsed ingredients back to the app for confirmation
    res.json(parsedIngredients);
  } catch (error) {
    console.error("Error parsing text for preview:", error);
    res.status(500).json({ message: "Failed to parse text." });
  }
});

module.exports = router;
