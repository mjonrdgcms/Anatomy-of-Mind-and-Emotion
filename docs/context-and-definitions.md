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
| **Fallacies** | Every logical or meaningful fallacy, with the passage around it, the cue, and whether it has been worked. | Only the names of the pending ones, so a model knows what is held back. |
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

## 5. Fallacies

The black-and-white file is really the file of every logical fallacy. The mind is bound to logic, so whenever a fallacy is used the mind has been bypassed, and the definition is being missed. Absolutes (always, never, everyone, nobody) are one fallacy among many: overgeneralisation, false dilemma, catastrophising, slippery slope, mind reading, fortune telling, should statements, sunk cost, appeals to popularity and authority, post hoc, personalisation, emotional reasoning, tu quoque, self-labeling, loaded questions, straw man.

There are also **meaningful fallacies**, where the heart is bypassed rather than the mind. The main one is the **double standard**: one rule for me, another for them. The shadow forms of *Beyond Flat Land* ch. 13 are the others: the ledger ("after everything I have done"), reduction to one mechanism ("you're just doing X"), kitchen-sinking, the freeze-out, the unilateral fact, the zoom-out that erases the complaint, and charm at the wrong moment. The author will add to this list.

The catalogue is `grammar/fallacies.json`. Each entry has its side (logic or meaning), the cues that detect it, and a **chain** of questions.

**Timing.** The app never cuts the person off to point out a fallacy when it happens. The context in which it was used is the data: why it was needed just then. So the fallacy is recorded with the whole passage around it, marked pending, and nothing is said. When the person later asks the app something, the app answers with the first question of the chain for the most urgent pending fallacy (the double standard first, then other meaningful ones, then logical ones, most recent first), and walks the chain one question per turn. The double standard's chain:

1. "What would it look like if we reversed the roles? What would you do in their situation?"
2. "And what are all the reasons that person wouldn't see it the way you do?"
3. "Having listed those, what, if anything, looks different about the original situation?"

The person sees the fallacy themselves or does not; the app never names it. When the chain ends the record is marked worked, with the answers filed beside it. Pending fallacies survive between sessions, and the working context lists their names so a model knows what is being held back.

The app uses calculus, and it also teaches it. Each chain is one more data point that reduces the divisor: an exception, a proportion, a reversed role, a list of reasons the other person has.

## 6. Where the questions come from now

In order of precedence for each turn:

0. A fallacy chain in progress: its next step. Or, when the person has just asked the app something and a fallacy is pending: the first step of its chain.
1. (Absolutes are not raised in the moment any more; they are fallacies, above.)
2. A focus item with no definition yet: "What does [tool] mean when you use it? Tell me the last time." Then the boundary.
3. A panacea in focus: the boundary question, and then who they know who is good at the space it is taking.
4. A missing axis: who do you know who is good at that, and what would they do.
5. A person described by one mechanism: three words.
6. Otherwise: what happened just before.
