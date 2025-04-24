import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import axios from 'axios';


export const generatePeacefulEventFromAI = onCall(
  {
    secrets: ['OPENAI_API_KEY'],
  },
  async (request) => {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error('Missing OpenAI API Key');

    const prompt = `
Generate a JSON object representing a peaceful fantasy game event for a text-based browser RPG.
All events must include:
- id (snake_case string)
- title (short event name)
- description (1–2 sentences of flavor text)
- type: always "peaceful"
- minCombatLevel (1–30)
- maxCombatLevel (same or higher)
- rarity (1 = common, 5 = ultra rare)
- reward: an object with effect ("restore_health", "grant_gold", or "restore_mana") and xp (number)

✅ Output ONLY JSON. Do NOT include markdown, explanations, or formatting.

Here is an example:
{
  "id": "shrine_of_silence",
  "title": "Shrine of Silence",
  "description": "You encounter a moss-covered shrine deep in the woods. A strange calm surrounds it.",
  "type": "peaceful",
  "minCombatLevel": 5,
  "maxCombatLevel": 25,
  "rarity": 2,
  "reward": {
    "effect": "restore_mana",
    "xp": 14
  }
}

Generate a new peaceful event:
`;

    const response = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model: 'gpt-4',
        messages: [
          { role: 'system', content: 'You are a fantasy game event generator.' },
          { role: 'user', content: prompt },
        ],
        temperature: 0.7,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const raw = response.data.choices?.[0]?.message?.content;
    if (!raw) throw new Error('No content from OpenAI');

    let event;
    try {
      event = JSON.parse(raw);
    } catch (e) {
      throw new Error('Invalid JSON from OpenAI');
    }

    // 🔍 Check for ID collisions in Firestore
    const baseId = event.id;
    let uniqueId = baseId;
    let attempt = 1;
    const collectionRef = admin.firestore().collection('encounterEvents');

    while ((await collectionRef.doc(uniqueId).get()).exists) {
      uniqueId = `${baseId}_${attempt}`;
      attempt++;
    }

    event.id = uniqueId; // Update to resolved unique ID
    await collectionRef.doc(uniqueId).set(event);

    return {
      success: true,
      id: uniqueId,
      message: `New event "${event.title}" saved to Firestore as "${uniqueId}"`,
    };
  }
);
