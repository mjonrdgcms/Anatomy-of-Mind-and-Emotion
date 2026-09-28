# Anatomy of Mind and Emotion: Dream Interpreter

An AI dream interpreter built on the symbol grammar of *The Four Rivers of Paradise* and the sorting model of *Beyond Flat Land*.

## Status

Understanding phase. Nothing is built yet. The theory has been restated for the author to check before any code is written.

- `docs/theory.md`: the system as understood, with the points that need confirmation at the end.
- `docs/reading-method.md`: the step-by-step procedure an interpreter follows, with the guards that keep it honest.

## Proposed shape (for discussion)

The core is model-agnostic and lives in this repo:

1. `grammar/`: the symbol dictionary as structured data (each symbol: country markers, function-in-relation-to-a-body, reading, scripture parallels, worked examples from the books).
2. `prompts/`: the interpreter's instructions, built from `docs/reading-method.md`.
3. `evals/`: the books' own worked dreams (the kitchen, the sea of glass, the money changers, the she-bear, the coin in the fish) as test cases, so any model can be checked against the author's readings.

Two runtimes on top of that core:

- **Claude-backed** (best reading quality): a small chat app or CLI that sends the grammar and method as the system prompt.
- **Fully local** (private, offline): the same app pointed at a local model through Ollama. Weaker, but nothing leaves the machine.

Either way the interpreter keeps a local dream journal so it can read series of three, recurring symbols, and each dreamer's personal overrides (a house that means debt to one person and refuge to another).

"Plugin" can mean several things (a Claude Project, a ChatGPT custom GPT, an Obsidian plugin, a Claude Code skill). The core above can be exported to any of those once the theory is confirmed.
