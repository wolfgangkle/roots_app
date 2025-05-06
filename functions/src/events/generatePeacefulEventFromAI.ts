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
    The description must be immersive and detailed — at least 6–8 full sentences. Make it feel like a short story excerpt, not just a summary. Write it in second person (“you enter... you notice...”).
    All events must include:
    - id (snake_case string)
    - title (short event name)
    - description: an immersive short story-like scene, minimum 6–8 full sentences in second person
    - type: always "peaceful"
    - minCombatLevel (1–30)
    - maxCombatLevel (same or higher)
    - rarity (1 = common, 5 = ultra rare)
    - reward: an object with effect ("restore_health", "grant_gold", or "restore_mana") and xp (number)
    - terrain: an array of one or more allowed terrain strings from this list: ["plains", "forest", "swamp", "snow", "tundra", "dungeon"]

    ✅ Output ONLY JSON. Do NOT include markdown, explanations, or formatting.

    Here is an example:
    {
      "id": "shrine_of_silence",
      "title": "Shrine of Silence",
      "description": "You step into a meadow that glows faintly in the fading sunlight. The tall grass brushes your legs, and wildflowers sway as if greeting you. There's a hush here—not silence, but a reverent stillness. You pause, your breath slowing, your heart strangely calm. The wind carries something other than sound: a warmth that soothes your weariness. Then, just on the edge of your hearing, a voice—soft and ancient—whispers your name. You turn quickly, but no one is there. Only a pouch of gold rests at your feet, as though the meadow itself has offered tribute for your presence.",
      "type": "peaceful",
      "minCombatLevel": 5,
      "maxCombatLevel": 25,
      "rarity": 2,
      "terrain": ["plains"],
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
        model: 'gpt-4o',
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

    let cleaned = raw.trim();

    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
    }

    let event;
    try {
      event = JSON.parse(cleaned);
    } catch (e) {
      console.error('❌ Raw content from OpenAI:\n', raw);
      throw new Error('Invalid JSON from OpenAI');
    }

    // ✅ Add reward validation logic
    if (event.reward?.effect === 'grant_gold' && typeof event.reward.gold !== 'number') {
      throw new Error('Missing "gold" value in reward for effect: grant_gold');
    }

    const baseId = event.id;
    let uniqueId = baseId;
    let attempt = 1;
    const collectionRef = admin.firestore().collection('encounterEvents');

    while ((await collectionRef.doc(uniqueId).get()).exists) {
      uniqueId = `${baseId}_${attempt}`;
      attempt++;
    }

    const fullEvent = {
      ...event,
      id: uniqueId,
      source: 'AI',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await collectionRef.doc(uniqueId).set(fullEvent);

    return {
      success: true,
      id: uniqueId,
      message: `New peaceful event "${event.title}" saved as "${uniqueId}"`,
    };
  }
);
