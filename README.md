# Unnamed Chronicle *(Working Title)*  
*A world that remembers. A story shaped by you.*

---

## What Is It?

**Unnamed Chronicle** is a cooperative, AI-powered roleplaying game set in a shared text-based world. You and other players inhabit a living setting — one where your decisions carry weight, your presence leaves marks, and every action becomes part of a growing, evolving chronicle.

There are no cutscenes, no static quests, and no fixed narrative.

Instead, the world unfolds around you in real time, shaped by your choices and recorded by a narrator AI that writes your story as you live it.

> ⚠️ **Project Name Note**:  
> “Unnamed Chronicle” is a placeholder title. A permanent name will be announced in a future release. All references to this name are provisional.

---

## Key Ideas

- **Persistent World**: Actions change the world permanently. The story doesn’t reset when you log out.
- **Shared Narrative**: You and other players influence the same world, whether together or apart.
- **AI Dungeon Master**: Every action is reviewed by a fair and impartial AI referee that applies the world’s logic and rules.
- **Chronicled History**: A separate AI watches events and writes a story in real time — your character becomes a legend (or a warning).
- **No Graphics. Just Imagination.** The game lives in text. The world unfolds through what you do and what’s remembered.

---

## Status

The core gameplay loop is playable:

1. **Create a character** in the character creator (stats are saved to `user://`).
2. **Type an action** in the chat. Actions are queued and judged on the next world tick.
3. **The Referee judges it** using **Jev**, a typed decision model. Jev answers four questions about the action
   (outcome, energy cost, injury, mana cost) with calibrated probabilities. Only *impossible* actions are rejected;
   success, partial success and failure are all narrated. Energy, Health and Mana change accordingly.
4. **The GameMaster narrates** how the world reacts, honoring the Referee's verdict.
5. **The Chronicler records everything** and, every few events, writes a new chapter of the world's history.

Everything persists between sessions: the world and its chat log (`user://world.res`), your character
(`user://PlayerStats*.tres`), the raw event log (`user://chatlog.json`) and the chronicle
(`user://chronicle.json`, readable as `user://chronicle.md`).

In-game commands: `/stats`, `/chronicle`, `/help`.

---

## Running It

Requires **Godot 4.4** and locally served AI models.

| Role | Kind of model | Default |
|------|---------------|---------|
| Referee | **Jev** decision model (TypeSafe System One) | `jev` at `http://127.0.0.1:11435/api/decide` |
| Referee fallback | Text LLM, used only if Jev is unreachable | Phi-3.5 mini via Ollama |
| GameMaster | Text LLM | Llama 3.2 MoE via Ollama |
| Chronicler | Text LLM | `llama3.1` via Ollama |

All of this is configured in [`assets/data/ai/ai_config.json`](assets/data/ai/ai_config.json). To override settings
without touching the repo, put a partial copy at `user://ai_config.json`; its keys are merged per section.

**Pointing Jev somewhere else:**
- *Local (Ollaya / Ollama):* keep `"path": "/api/decide"` and set `endpoint` and `model` (e.g. an open Jev-style
  model such as `nimble` or `tev1`) to whatever your server runs.
- *Hosted TypeSafe:* set `endpoint` to the API base URL (`https://...`), `"path": "/v1/systemone"`, and export your
  key in the environment variable named by `api_key_env` (default `TYPESAFE_API_KEY`).

---

## License

This project is licensed under a **custom adaptation** of the  
**Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)** license.

You are free to:
- View and use this project for non-commercial purposes
- Share, remix, and build upon it with proper credit
- Submit contributions that may be included in future builds

You may not:
- Sell, rebrand, or commercially redistribute this project
- Claim ownership over the core systems or concept
- Use this work or its code in commercial AI training or derivative games

All contributions are submitted under these terms, and the project remains solely credited to its original creator, **Adan Garcia**.

Full license: [https://creativecommons.org/licenses/by-nc-sa/4.0/](https://creativecommons.org/licenses/by-nc-sa/4.0/)

---

## Learn More

- **Wiki**: [See the documentation and design notes](./wiki) *(coming soon)*
- **Credits**: AI models and libraries used are detailed in the `/docs` folder.
- **Author**: Developed by Adan Garcia

---

> “In most games, you play through a story. In this one, you live it — and the world remembers.”

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
