#!/usr/bin/env python3
"""
Phase 5: Update stage data bank file headers with correct stage names.

From stage_bank_table in bank0E (confirmed):
  $2A=0 → bank $03 (Heat Man)
  $2A=1 → bank $04 (Air Man)
  $2A=2 → bank $01 (Wood Man)
  $2A=3 → bank $07 (Bubble Man)
  $2A=4 → bank $06 (Quick Man)
  $2A=5 → bank $00 (Flash Man)
  $2A=6 → bank $05 (Metal Man)
  $2A=7 → bank $02 (Crash Man)
  $2A=8,9 → bank $08 (Wily Stages 1-2)
  $2A=10-12 → bank $09 (Wily Stages 3-5)
"""

HEADER_FIXES = {
    'src/bank00_stage_data_1.asm': (
        '; Bank $00 — Stage Data 1',
        '; Bank $00 — Flash Man Stage (stage index $05)',
    ),
    'src/bank01_stage_data_2.asm': (
        '; Bank $01 — Stage Data 2',
        '; Bank $01 — Wood Man Stage (stage index $02)',
    ),
    'src/bank02_stage_data_3.asm': (
        '; Bank $02 — Stage Data 3',
        '; Bank $02 — Crash Man Stage (stage index $07)',
    ),
    'src/bank03_stage_data_4.asm': (
        '; Bank $03 — Stage Data 4',
        '; Bank $03 — Heat Man Stage (stage index $00)',
    ),
    'src/bank04_stage_data_5.asm': (
        '; Bank $04 — Stage Data 5',
        '; Bank $04 — Air Man Stage (stage index $01)',
    ),
    'src/bank05_stage_data_6.asm': (
        '; Bank $05 — Stage Data 6',
        '; Bank $05 — Metal Man Stage (stage index $06)',
    ),
    'src/bank06_stage_data_7.asm': (
        '; Bank $06 — Stage Data 7',
        '; Bank $06 — Quick Man Stage (stage index $04)',
    ),
    'src/bank07_stage_data_8.asm': (
        '; Bank $07 — Stage Data 8',
        '; Bank $07 — Bubble Man Stage (stage index $03)',
    ),
    'src/bank08_stage_data_9.asm': (
        '; Bank $08 — Stage Data 9',
        '; Bank $08 — Wily Stages 1-2 (stage indices $08-$09)',
    ),
}


def main():
    count = 0
    for filepath, (old, new) in HEADER_FIXES.items():
        with open(filepath, 'r') as f:
            content = f.read()
        if old in content:
            content = content.replace(old, new, 1)
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"  Updated: {filepath}")
            count += 1
        else:
            print(f"  Skipped (already updated?): {filepath}")

    print(f"\nUpdated {count} file headers.")


if __name__ == '__main__':
    main()
