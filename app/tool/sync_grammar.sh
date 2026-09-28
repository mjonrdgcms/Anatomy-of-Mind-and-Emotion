#!/bin/sh
# Copy the grammar files from the repo into the app's assets.
cd "$(dirname "$0")/.." && cp ../grammar/approaches.json ../grammar/lexicon.json assets/grammar/
