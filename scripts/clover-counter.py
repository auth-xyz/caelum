#!/usr/bin/env python3
from collections import Counter

rarities = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
grimoires = ["Three-Leaf", "Four-Leaf", "Five-Leaf"]

rarity_counts = Counter()
grimoire_counts = Counter()

with open("compare", "r") as f:
    for line in f:
        # Count rarities
        for r in rarities:
            if r in line:
                rarity_counts[r] += 1
        # Count grimoire types
        for g in grimoires:
            if g in line:
                grimoire_counts[g] += 1

print("Rarity counts:")
for r in rarities:
    print(f"{r}: {rarity_counts[r]}")

print("\nGrimoire counts:")
for g in grimoires:
    print(f"{g}: {grimoire_counts[g]}")

