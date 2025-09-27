// models/User.js
const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const userSchema = new Schema(
  {
    auth0Id: {
      type: String,
      required: true,
      unique: true, // Each user has a unique Auth0 ID
    },
    email: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
); // Automatically adds createdAt and updatedAt

module.exports = mongoose.model("User", userSchema);
