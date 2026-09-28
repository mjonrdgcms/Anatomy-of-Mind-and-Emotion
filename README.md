# Anatomy of Mind and Emotion: Dream Interpreter

An AI dream interpreter built on the author's books: the symbol grammar of *The Four Rivers of Paradise*, the sorting model of *Beyond Flat Land*, and the stress physiology of *World of Alphas* and *Postpartum: The Lion Is Real*. The author intends all of their books to be in the AI's knowledge base; the four above are the ones read so far.

## Status

Understanding phase. Nothing is built yet. The theory has been restated for the author to check before any code is written.

- `docs/theory.md`: the system as understood, with the points that need confirmation at the end.
- `docs/reading-method.md`: the step-by-step procedure an interpreter follows, with the guards that keep it honest.
- `docs/seven-in-dreams.md`: how the seven approaches of *Beyond Flat Land* enter a dream reading.
- `docs/seven-symbols.md`: the body register as the primary symbol set for the seven (settled with the author), with secondary built forms and animal classes.
- `docs/seven-emotions.md`: the seven emotions on their axes, each with its heard side and its screaming side, drawn from all four books.
- `docs/approach-wheel.md`: the two wheel diagrams decoded: the seven dichotomies and their boundaries, each approach as six poles plus a bridge, the asset and risk halves, the eight types of data, the 56 tools and 56 weapons, and the opposites rule behind the author's early survey.
- `grammar/approaches.json`: the same wheel as data (first file in the grammar layer).

## Proposed shape

A standalone, free, local phone app. Voice in, voice out. The smallest language model that can tidy a transcript and file it into a folder, and no bigger, because the knowledge lives in the app's grammar files rather than in the model. Everything a reading needs is kept in small folders (dreams, people, animals, places, waking life, alarms, approach profile) so only a few short entries are ever in context. The full plan is `docs/app-plan.md`.

The core is model-agnostic and lives in this repo:

1. `grammar/`: the symbol dictionary and the approach wheel as structured data, plus the author's text-analysis word lists.
2. `prompts/`: the interpreter's instructions, built from `docs/reading-method.md`, one step at a time.
3. `evals/`: the books' own worked dreams as test cases.

The same core can later be exported as a Claude Project, a custom GPT, or a plugin, but the phone app is the target.
