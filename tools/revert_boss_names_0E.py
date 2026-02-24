#!/usr/bin/env python3
"""
Revert the boss name renames in bank $0E ONLY.

The fix_boss_names.py script correctly renamed boss AI in bank $0B
(dispatch indexed by $B3=$2A), but INCORRECTLY renamed bank $0E's
entity AI routines. Bank $0E routines handle entity TYPES (projectile/
physics behaviors shared by multiple bosses), not specific boss indices.

Phase 4's original naming in bank $0E was behavior-based:
  bubbleman_state_swim = swim physics behavior
  woodman_check_leaf_wall = leaf shield behavior
  heatman_spawn_fire = fire projectile behavior
  airman_dec_timer = tornado behavior
  flashman_stop_freeze = time stopper behavior

This script reverses the fix_boss_names.py changes in bank $0E only.
"""
import re

# Reverse of the forward mapping from fix_boss_names.py
# Forward was: bubbleman→heatman, woodman→airman, airman→woodman,
#              crashman→bubbleman, heatman→flashman, flashman→crashman
# Reverse is:
REVERSE_RENAMES = {
    'heatman':    'bubbleman',   # undo bubbleman→heatman
    'airman':     'woodman',     # undo woodman→airman
    'woodman':    'airman',      # undo airman→woodman
    'bubbleman':  'crashman',    # undo crashman→bubbleman
    'flashman':   'heatman',     # undo heatman→flashman
    'crashman':   'flashman',    # undo flashman→crashman
}

COMMENT_REVERSE = {
    'Heat Man':   'Bubbleman',
    'Air Man':    'Woodman',
    'Wood Man':   'Airman',
    'Bubble Man': 'Crashman',
    'Flash Man':  'Heatman',
    'Crash Man':  'Flashman',
}

FILEPATH = 'src/bank0E_game_engine.asm'


def main():
    with open(FILEPATH, 'r') as f:
        content = f.read()

    original = content

    # Pass 1: label renames to temp
    temp_map = {}
    for i, (old_prefix, new_prefix) in enumerate(REVERSE_RENAMES.items()):
        temp = f'__RVTEMP{i}__'
        temp_map[temp] = new_prefix
        pattern = re.compile(r'\b' + re.escape(old_prefix) + r'_')
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(temp + '_', content)
            print(f"  Pass 1: {old_prefix}_ → {temp}_ ({matches})")

    # Pass 2: temp to final
    for temp, new_prefix in temp_map.items():
        pattern = re.compile(re.escape(temp) + r'_')
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(new_prefix + '_', content)
            print(f"  Pass 2: {temp}_ → {new_prefix}_ ({matches})")

    # Pass 3: revert comment names to temp
    comment_temps = {}
    for i, (old_name, new_name) in enumerate(COMMENT_REVERSE.items()):
        temp = f'__RCTEMP{i}__'
        comment_temps[temp] = new_name
        pattern = re.compile(r'\b' + re.escape(old_name) + r'\b')
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(temp, content)
            print(f"  Comment Pass 1: {old_name} → {temp} ({matches})")

    # Pass 4: temp to final comment names
    for temp, new_name in comment_temps.items():
        pattern = re.compile(re.escape(temp))
        matches = len(pattern.findall(content))
        if matches > 0:
            content = pattern.sub(new_name, content)
            print(f"  Comment Pass 2: {temp} → {new_name} ({matches})")

    if content != original:
        with open(FILEPATH, 'w') as f:
            f.write(content)
        print(f"\nReverted bank $0E boss names successfully.")
    else:
        print(f"\nNo changes needed.")


if __name__ == '__main__':
    main()
