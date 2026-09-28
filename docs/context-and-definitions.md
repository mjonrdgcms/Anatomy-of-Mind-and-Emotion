# Context and Definitions

How the app keeps its working context small, and what it is actually working on.

## 1. The problem is definitions

What slows the heart and the mind down is the lack of an accurate working definition of each tool. A person's favourite tools have definitions so broad that they look like the right answer for everything. Their least favourite approaches have definitions so narrow that they never seem to apply to anything. Once the app finds the tool whose definition has become a panacea, it can see the space that tool is occupying that belongs to a different tool, and that other tool is nearly always one on the far side of the wheel.

The ideal is calculus. You cannot divide by zero, and a definition that covers everything divides by zero: it explains every case and so distinguishes none. But you can reduce the number you are dividing by. Every exception found, every proportion named instead of an absolute, every "where does this not apply" answered, shrinks the bias, and the definition approaches the right one without ever needing to be perfect.

## 2. The stores

| Store | Holds | In context? |
|---|---|---|
| **Archive** | Every transcript, whole, as spoken. Searchable. | Never. Searched only when something specific is needed. |
| **Folders** | Short distilled entries (dreams, people, animals, places, waking, alarms). | One or two entries, only when a question needs them. |
| **Definitions** | For each approach, dichotomy pole, tool and weapon: the specific phrases the person has used about it, with dates and what they were talking about at the time. This is the personality profile. | The definition summary of the three focus items only. |
| **Absolutes** | Every statement with an absolute or hyperbole in it, with the words that made it absolute and the tool or approach it was about. | The most recent one, when it is the reason for the question. |
| **Profile** | Favourites, disliked weapons, taboo and load-bearing pair, reframers, running lexicon profile. | The short form. |

## 3. The working context

What the app thinks with, at any moment, is:

1. **The three tools or weapons currently being referenced.** Recency-weighted: each turn's hits are added and older weight decays, so the focus follows the conversation without being thrown by one word.
2. **For each of the three, a summary of the question about it.** What the person's definition of it currently is (from their own phrases), how broad it has become, whether it is a panacea or a blind spot, and the one open question.

That is the entire context handed to the model, when there is one. It is a few hundred words. The archive, the folders and the rest of the profile are reached by lookup, not by loading.

## 4. Measuring a definition

For each tool and weapon the app keeps:

- **Phrases**: the sentences in which the person used that tool's words. These are the person's working definition, in their own words.
- **Breadth**: how many different situations the tool has been applied to (distinct folders, distinct co-occurring approaches, distinct weeks).
- **Boundary**: whether the person has ever said where it does not apply.

From these:

- A **panacea** is a tool of a favourite or load-bearing approach with high breadth (at least four situations, from at least four phrases) and no boundary. The definition has become "the right answer for everyone."
- A **blind spot** is a tool of an unseen approach with no phrases at all, or with phrases that are all negative. The definition does not seem to apply to anything.
- The **space taken** by a panacea is the approach whose axis is most often absent in the passages where the panacea appears, restricted to the unseen approaches. That is the tool whose place is being occupied.

## 5. Absolutes

Any time an absolute or hyperbole is used (always, never, everyone, nobody, everything, nothing, completely, impossible, the only, the worst, ruined, perfect, literally, a hundred percent, every single time), the definition is being missed. The statement is filed in Absolutes with the tool it was about, and the app's next question is the calculus move, phrased so it cannot lead:

- **The exception**: "When was a time it went differently?"
- **The proportion**: "Out of the last ten times, how many?"
- **The boundary**: "Where does that not apply?"

The app does not argue with the absolute. An overruled alarm gets louder. It asks for one more data point, which is all that reducing the divisor takes.

## 6. Where the questions come from now

In order of precedence for each turn:

1. An absolute in what was just said: the exception or the proportion, about the tool it was about.
2. A focus item with no definition yet: "What does [tool] mean when you use it? Tell me the last time." Then the boundary.
3. A panacea in focus: the boundary question, and then who they know who is good at the space it is taking.
4. A missing axis: who do you know who is good at that, and what would they do.
5. A person described by one mechanism: three words.
6. Otherwise: what happened just before.
