## Inspiration
As college students, we often face the common issue of reaching the end of the week without knowing what to cook. We end up buying a lot of random ingredients that later on we don't need so they just occupy space in our pantry or fridge and stay there for months. That's how the idea for Next Meal came to our minds!

## What it does
What Next Meal does is receive voice notes with all your ingredients, and we get generative AI to make you recipes with the ingredients we already have, and only that! Without having to run to the grocery store, we get our personalized recipes.

## How we built it
# The Mobile App: A Native iOS Experience

We chose Swift with SwiftUI for the frontend to create a fast, responsive, and seamless experience for iPhone users. This allowed us to build a clean user interface where users can easily manage their ingredient list. For user login and security, we integrated the Auth0 SDK, which handles sign-up, login, and secure token management, ensuring all user data is protected.

## The Backend: A Smart and Scalable Server

The server was built with Node.js and the Express framework, a popular and efficient choice for creating APIs. This backend handles three critical tasks:

* User and Ingredient Management: It securely communicates with our MongoDB database, which stores user profiles and their list of pantry items. MongoDB's flexible, document-based structure is perfect for handling varied ingredient lists.

* Authentication: The backend uses a middleware to verify the JSON Web Tokens (JWTs) issued by Auth0, making sure that users can only access their own data.

* AI-Powered Recipe Generation: This is the core of our app. When a user requests recipes, the backend takes their ingredient list and uses prompt engineering to construct a highly specific query for the Google Gemini API. This prompt instructs the AI to act as a chef and return its response in a clean, structured JSON format, which is then sent back to the app to be displayed as recipe cards.

# Challenges we ran into
We faced difficulties implementing user authentication, as errors occurred when the wrong users were in use. Another challenge was integrating Gemini into our code to generate recipes—the API was not returning the recipes as expected within the app.

# Accomplishments that we're proud of
We successfully got all of the API endpoints to work together, ensuring smooth communication between different parts of the application.

# What we learned
Although Auth0 authentication was difficult to implement at first, we learned that each user needed to be properly configured when creating an account for the system to work correctly.

# What's next for Next Meal
Our next steps are to add the ability for users to save recipes for later, as well as implement a feature that checks for missing ingredients in saved recipes.

# Built With

    auth0
    gemini
    javascript
    mongodb
    postman
    swift

