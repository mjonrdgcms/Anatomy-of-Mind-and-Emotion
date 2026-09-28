# App Plan: A Small, Local, Voice-First Interpreter

The author's brief: the lightest, most stripped-down model that knows no science, history or politics. Voice in, voice out. Runs locally on a phone. Organises what people say into folders so the context window stays small. Standalone and free, like Voicebox.

## 0. The reference point: Voicebox

Voicebox (voicebox.sh) is an open-source, local-first voice studio for macOS and Windows: voice cloning from a few seconds of audio, speech generation across several text-to-speech engines (Qwen3-TTS, Kokoro, Chatterbox and others), dictation into any app by hotkey, and a multi-voice timeline. It is free and open source forever, everything runs on the machine, there is no cloud dependency and no limits. It is built as a Tauri and Rust desktop app with a React front end and a Python FastAPI backend.

What this app takes from it: free and open source, local-first, no account, no server, no limits, the model files downloaded once and owned by the user. What is different: Voicebox is a desktop app and speaks in cloned voices; this app is a phone app and its job is to listen, file and read back. Kokoro, one of Voicebox's engines, is also the voice this plan proposes, so the two can sound alike.

Voicebox's stack is a second option for the app framework. Tauri 2 builds for Android and iOS as well as desktop, and the speech and language-model engines exist as Rust crates. Flutter remains the recommendation because the on-device speech and model bindings are more mature there, but a Tauri build would let a desktop version and the phone version share code.

## 1. The principle: the knowledge lives in the app, not in the model

A language model cannot have its general knowledge removed, but it can be made small enough that it has almost none, and then given a narrow job. The design below uses the model for three jobs only, and none of them requires it to know anything:

1. Tidy a transcript (punctuation, false starts, "um").
2. Route a passage into a folder, from a fixed list of folder names.
3. Phrase a reading whose content has already been decided by rules.

Everything the interpreter knows comes from files in this repo: the dream grammar (`docs/theory.md`, to become `grammar/symbols.json`), the approach wheel (`grammar/approaches.json`), the seven emotions, and the author's text-analysis word lists. Most of the interpretation can be done without a model at all:

- **Symbol lookup** is a dictionary: house, kitchen, bathroom, teeth, dog, horse, water, stone, and so on, each with its country markers and reading.
- **Two-symbol rule** is a count: two or more heart markers (female, mammal, dark, invisible, round, water, gold, low) or mind markers (male, reptile, white, light, square, silver, rock, high) in a passage.
- **Approach scoring** is word matching against the author's 2025 dictionaries: count hits per tool and per weapon.
- **The reading method** is a fixed sequence of questions (who is this person in three words; what does the animal do for you; where is the water), asked by the app, answered by voice.

The model is the clerk, not the interpreter. That is what lets it be tiny.

## 2. Folders: why they keep the context small

Nothing is ever loaded whole. Each spoken passage is transcribed, split, routed into one folder, and stored as a short entry. When a reading is needed, only the folders it depends on are opened.

| Folder | What goes in it | Opened when |
|---|---|---|
| **Dreams** | One entry per dream: transcript, date, the symbols found, the reading, the one thing to check. Grouped into series of three. | Reading a new dream (the last two are opened for the series rule). |
| **People** | One entry per person: their three words, their role in the dreamer's life. | A person appears in a dream. |
| **Animals and relationships** | Who each animal is; which facet (loyalty, motivation, independence). | An animal appears. |
| **Places and objects** | The dreamer's personal overrides: what this house, this car, this road means to them. | The symbol recurs. |
| **Waking life** | Day entries: what happened, what was decided, what was left open. | Connecting a dream to something specific in the week. |
| **Alarms** | Graded readings: the number, the criterion, the re-check time. | Fear or anger is the loudest emotion in a dream. |
| **Approach profile** | Running tool and weapon scores; the three most disliked weapons; the opposites. | Naming which approach the heart is running. |
| **Loose** | Anything the router was unsure about, for the person to file by hand. | Never automatically. |

Each folder entry is a few hundred words at most. A reading opens perhaps five entries. A 4,000-token context is enough, which is what small models on phones handle comfortably.

## 3. The pipeline

```
microphone
  → speech to text (on device)
  → tidy (model, or rules)
  → split into passages (rules: pauses, "and then I", topic words)
  → route each passage to a folder (model, choosing from the folder list)
  → store as an entry (local database)
  → if the folder is Dreams: run the reading method
      → symbol lookup, two-symbol count, country sort (rules)
      → ask the dreamer the questions the grammar needs (voice)
      → score approaches from the word lists (rules)
      → assemble the six-part output (rules + model for phrasing)
  → text to speech (on device)
```

The reading method itself is `docs/reading-method.md`, executed as a state machine in the app, with the model asked only to phrase each step in plain words.

## 4. Components, all free and on-device

| Job | Choice | Why |
|---|---|---|
| Speech to text | sherpa-onnx running a Whisper-tiny or Moonshine model | Open source, offline, runs on Android and iOS, small models (tens of MB). The platform recognisers (Apple Speech, Android SpeechRecognizer) are a fallback with no download at all. |
| Text to speech | sherpa-onnx running Piper or Kokoro | Open source, offline, natural enough to listen to for a full reading. Platform TTS is the zero-download fallback. |
| Language model | llama.cpp with a GGUF model in the 0.3 to 1 billion parameter range (SmolLM2-360M-Instruct, Qwen2.5-0.5B-Instruct, or Gemma 3n at the small end if the phone allows) | These follow a routing instruction and tidy text reliably, and know very little else. A few hundred MB. Quantised to 4-bit. |
| Storage | SQLite, one table per folder | Local, private, exportable. |
| App framework | Flutter | One codebase for Android and iOS; sherpa-onnx and llama.cpp both have Flutter bindings. |

Nothing leaves the phone. There is no account and no server.

A later option, if the routing quality of an off-the-shelf tiny model is not good enough: fine-tune the small model on the author's books and dictionaries (a LoRA on a few thousand examples). That gives a model that knows the grammar and still knows nothing else.

## 5. What a tiny model cannot do, and how the design compensates

- **It cannot interpret a dream freely.** It will produce fluent nonsense if asked to. So it is never asked to. The grammar decides; the model phrases.
- **It cannot hold a long conversation.** So the app holds the state (which step of the reading it is on, which questions are answered) and gives the model one step at a time.
- **It will misroute sometimes.** So every entry shows its folder, moving it is one tap, and the Loose folder catches doubt.
- **It cannot know the dreamer.** So the People, Animals and Places folders are the dreamer's own words, asked for once and reused.

## 6. Stages

1. **Capture and file.** Record, transcribe, tidy, route, store, read back. No interpretation yet. This is already a useful app and proves the voice loop and the folders.
2. **Symbols and sort.** Symbol dictionary, two-symbol rule, the headline "what got filed in the wrong box." Rule-based.
3. **The reading method.** The twelve steps as a guided voice conversation, with the six-part output spoken back.
4. **The seven.** Word-list scoring, emotion heard or screaming, approach profile, opposites.
5. **Series and recurrence.** Dreams in threes, the same grain returned, personal overrides.

Each stage ships on its own. The books' worked dreams become the test set at stage 2 onward.

## 7. Decisions still open

- **Platform first.** Android can be built and installed free. iOS needs an Apple developer account to put on the App Store. Recommendation: build in Flutter so both come from one codebase, and test on Android first.
- **The exact small model.** To be chosen by testing routing accuracy on real transcripts, smallest model that passes wins.
- **Whether transcript tidying needs the model at all.** Modern on-device recognisers punctuate; rules may be enough.

## 8. Context and definitions (added)

The folder table in section 2 is superseded by `docs/context-and-definitions.md`: transcripts go whole into a searchable Archive that is never in context; the working context is the three tools or weapons currently referenced plus a summary of the open question about each; a Definitions store keeps the person's own phrases about every approach, pole, tool and weapon; an Absolutes store keeps every black-and-white statement.
