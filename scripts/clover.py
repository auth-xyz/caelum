import random

magic = {
    "Common": [
        "Fire Magic", "Water Magic", "Wind Magic", "Earth Magic", "Ice Magic",
        "Stone Magic", "Sand Magic", "Smoke Magic", "Mud Magic", "Plant Magic",
        "Lightning Magic", "Ink Magic", "Sound Magic", "Glass Magic", "Hair Magic",
        "Metal Magic", "Bubble Magic", "Paint Magic", "Soda Magic", "Snow Magic"
    ],
    "Uncommon": [
        "Ash Magic", "Mirror Magic", "Chain Magic", "Beast Magic", "Thread Magic",
        "Whip Magic", "Compass Magic", "Eye Magic", "Vortex Magic", "Poison Magic",
        "Fog Magic", "Magma Magic", "Paper Magic", "Spring Magic", "Acid Magic"
    ],
    "Rare": [
        "Blood Magic", "Spatial Magic", "Time Magic", "Sound Wave Magic",
        "Dream Magic", "Bone Magic", "Crystal Magic", "Gravity Magic",
        "Darkness Magic", "Light Magic", "Sealing Magic", "Shadow Magic",
        "Memory Magic", "Fortune Magic", "Curse Magic"
    ],
    "Epic": [
        "Demon Magic", "Spirit Magic", "Soul Magic", "Star Magic",
        "Creation Magic", "Sword Magic", "Fire Spirit Magic",
        "Water Spirit Magic", "Wind Spirit Magic", "Earth Spirit Magic",
        "Spatial Distortion Magic", "Dimension Slash Magic", "Forbidden Magic"
    ],
    "Legendary": [
        "Anti Magic", "Kotodama Magic (Word Soul)", "Arcane Stage Magic",
        "Time Reversal Magic", "Ultimate Spirit Magic", "Demon-Dweller Magic",
        "Devil Union Magic", "Light-Darkness Fusion Magic", "Five-Leaf Grimoire Magic",
        "World Tree Magic", "Reality Warp Magic"
    ]
}

rarity = random.choice(list(magic.keys()))
attribute = random.choice(magic[rarity])

print(f"Rarity: {rarity}")
print(f"Magical Attribute: {attribute}")

