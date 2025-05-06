import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import axios from 'axios';

export const generateCombatEventFromAI = onCall(
  {
    secrets: ['OPENAI_API_KEY'],
  },
  async (request) => {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error('Missing OpenAI API Key');

    const prompt = `
    Generate a JSON object with a fantasy COMBAT encounter and optionally one or more new enemy types.

    The "description" must be immersive and detailed — at least 6–8 full sentences.
    It should feel like a short story scene where the player stumbles into danger. Use second person (“you hear... you step... you reach for your weapon…”).

    The JSON must contain:
    - "event": a combat event object
    - "enemies": an array of enemyType definitions (may be empty)

    Each enemy must include:
    - a numeric "xp" value that the player receives for defeating it

    Event format:
    {
      "id": "bandit_bridge_blockade",
      "title": "Bridge Blockade",
      "description": "You approach a narrow bridge just as a group of bandits emerge from the trees. The leader grins wickedly and draws his blade...",
      "type": "combat",
      "enemyTypes": ["bandit"],
      "minLevel": 5,
      "maxLevel": 25,
      "scale": {
        "base": 2,
        "scalePerLevel": 0.15,
        "max": 8
      },
      "terrain": ["forest"]
    }

    Enemy format:
    {
      "id": "shadow_rat",
      "name": "Shadow Rat",
      "description": "A mutated rat with pitch-black fur and glowing eyes.",
      "combatLevel": 7,
      "baseStats": {
        "hp": 80,
        "minDamage": 6,
        "maxDamage": 10,
        "attackSpeedMs": 90000,
        "at": 15,
        "def": 12,
        "defense": 2
      },
      "xp": 6,
      "scaleWithEvent": true
    }

    The "terrain" field must be an array of one or more strings chosen from the following: ["plains", "forest", "swamp", "snow", "tundra", "dungeon"]

    Sometimes reuse existing enemies (like "bandit", "goblin", "skeleton") and sometimes invent new ones.

    Return ONLY a valid JSON object. No markdown or explanation.
    `;



    const response = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: 'You are a fantasy game content generator.' },
          { role: 'user', content: prompt },
        ],
        temperature: 0.75,
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

    // Remove triple backticks and markdown if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
    }

    let result;
    try {
      result = JSON.parse(cleaned);
    } catch (err) {
      console.error('❌ Failed to parse JSON. Raw content:\n', raw);
      throw new Error('Invalid JSON returned by OpenAI');
    }

    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const event = {
      ...result.event,
      source: 'AI',
      createdAt: timestamp,
    };

    const eventRef = admin.firestore().collection('encounterEvents').doc(event.id);
    const eventSnap = await eventRef.get();

    if (eventSnap.exists) {
      throw new Error(`Event ID "${event.id}" already exists.`);
    }

    await eventRef.set(event);

    // Save new enemies, skip if already exists
    if (Array.isArray(result.enemies)) {
      for (const enemy of result.enemies) {
        const enemyRef = admin.firestore().collection('enemyTypes').doc(enemy.id);
        const enemySnap = await enemyRef.get();
        if (!enemySnap.exists) {
          await enemyRef.set({
            ...enemy,
            source: 'AI',
            createdAt: timestamp,
          });
        }
      }
    }

    return {
      success: true,
      eventId: event.id,
      createdEnemies: result.enemies?.map((e: any) => e.id) ?? [],
      message: `Combat event "${event.title}" generated with ${result.enemies?.length ?? 0} new enemies.`,
    };
  }
);
