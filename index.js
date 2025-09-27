// Import necessary packages
const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");

// Load environment variables from .env file
dotenv.config();

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5001;

// Middleware
app.use(cors()); // Enable Cross-Origin Resource Sharing
app.use(express.json()); // Allow server to accept JSON data

// --- Connect to MongoDB ---
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("Successfully connected to MongoDB! 👍"))
  .catch((err) => console.error("Connection error:", err));

// --- Basic Route ---
// A simple test route to make sure the server is working
app.get("/", (req, res) => {
  res.send("Recipe App API is running!");
});

const ingredientRoutes = require("./routes/ingredients");
app.use("/api/ingredients", ingredientRoutes); // All routes in ingredients.js will be prefixed with /api/ingredients

//Recipe Routes
const recipeRoutes = require("./routes/recipes"); // Add this
app.use("/api/recipes", recipeRoutes);

// --- Start the Server ---
app.listen(PORT, () => {
  console.log(`Server is listening on port ${PORT}`);
});
