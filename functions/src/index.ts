import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Hello World test function
export const helloWorld = functions.https.onRequest((request, response) => {
  response.send("👋 Hello from Roots Cloud Functions!");
});
