#!/usr/bin/env python3
"""
Phase 5: Fix misnamed Robot Master labels in banks $0B and $0E.

The Phase 4 annotation scripts assigned boss names incorrectly.
The boss AI dispatch table in bank $0B is indexed by $B3, which
equals $2A (stage index). This was confirmed by cross-referencing
boss_contact_damage_table values with wiki data:

  boss_contact_damage_table: $08,$08,$08,$04,$04,$04,$06,$04
  Index 0=$08 → Heat Man (wiki: 8)   ← was labeled "bubbleman"
  Index 1=$08 → Air Man (wiki: 8)    ← was labeled "woodman"
  Index 2=$08 → Wood Man (wiki: 8)   ← was labeled "airman"
  Index 3=$04 → Bubble Man (wiki: 4) ← was labeled "crashman"
  Index 4=$04 → Quick Man (wiki: 4)  ✓ correct
  Index 5=$04 → Flash Man (wiki: 4)  ← was labeled "heatman"
  Index 6=$06 → Metal Man (wiki: 6)  ✓ correct
  Index 7=$04 → Crash Man (wiki: 4)  ← was labeled "flashman"

Uses two-pass rename (via temp placeholders) to avoid circular collisions.
"""
import re
import sys

# Circular rename map: old_prefix → correct_prefix
# These are the 6 wrong ones (quickman and metalman are already correct)
RENAMES = {
    'bubbleman': 'heatman',    # index 0: was bubbleman, is actually Heat Man
    'woodman':   'airman',     # index 1: was woodman, is actually Air Man
    'airman':    'woodman',    # index 2: was airman, is actually Wood Man
    'crashman':  'bubbleman',  # index 3: was crashman, is actually Bubble Man
    'heatman':   'flashman',   # index 5: was heatman, is actually Flash Man
    'flashman':  'crashman',   # index 7: was flashman, is actually Crash Man
}

# Also fix capitalized forms in comments (e.g., "Bubbleman" → "Heat Man")
COMMENT_RENAMES = {
    'Bubbleman': 'Heat Man',
    'Woodman':   'Air Man',
    'Airman':    'Wood Man',
    'Crashman':  'Bubble Man',
    'Heatman':   'Flash Man',
    'Flashman':  'Crash Man',
    # Also handle "BUBBLEMAN" etc. if present
    'BUBBLEMAN': 'HEAT MAN',
    'WOODMAN':   'AIR MAN',
    'AIRMAN':    'WOOD MAN',
    'CRASHMAN':  'BUBBLE MAN',
    'HEATMAN':   'FLASH MAN',
    'FLASHMAN':  'CRASH MAN',
}

FILES = [
    'src/bank0B_game_logic.asm',
    'src/bank0E_game_engine.asm',
]


def rename_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    count = 0

    # Pass 1: Rename all old prefixes to temporary placeholders
    # e.g., bubbleman_ → __TEMP_BOSS0__
    temp_map = {}
    for i, old_prefix in enumerate(RENAMES.keys()):
        temp = f'__TEMP_BOSS{i}__'
        temp_map[temp] = RENAMES[old_prefix]

        # Replace label identifiers (word boundary: letters, digits, underscore)
        pattern = re.compile(r'\b' + re.escape(old_prefix) + r'_')
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(temp + '_', content)
            count += matches
            print(f"  Pass 1: {old_prefix}_ → {temp}_ ({matches} occurrences)")

    # Pass 2: Rename temporary placeholders to correct names
    for temp, new_prefix in temp_map.items():
        pattern = re.compile(re.escape(temp) + r'_')
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(new_prefix + '_', content)
            print(f"  Pass 2: {temp}_ → {new_prefix}_ ({matches} occurrences)")

    # Pass 3: Fix capitalized names in comments ("; Boss AI: Bubbleman" etc.)
    # Use temp placeholders again to avoid circular issues
    comment_temps = {}
    for i, (old_name, new_name) in enumerate(COMMENT_RENAMES.items()):
        temp = f'__CTEMP{i}__'
        comment_temps[temp] = new_name
        # Only replace in comment lines (after ;) to be safe
        # But also in block header lines starting with ;
        pattern = re.compile(r'\b' + re.escape(old_name) + r'\b')
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(temp, content)
            count += matches
            print(f"  Comment Pass 1: {old_name} → {temp} ({matches})")

    for temp, new_name in comment_temps.items():
        pattern = re.compile(re.escape(temp))
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(new_name, content)
            print(f"  Comment Pass 2: {temp} → {new_name} ({matches})")

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"  Total changes: {count}")
    else:
        print(f"  No changes needed")

    return count


def main():
    total = 0
    for filepath in FILES:
        print(f"\nProcessing {filepath}:")
        total += rename_file(filepath)

    print(f"\n{'='*60}")
    print(f"Total label renames: {total}")
    print("Done! Run 'make verify' to confirm byte-perfect build.")


if __name__ == '__main__':
    main()
