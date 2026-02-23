#!/usr/bin/env python3
"""
Rename auto-generated LXXXX labels in bank0C_weapons_ui.asm to descriptive names.

This script replaces all occurrences of each label (both definitions like
"L804F:" and references like "jsr L804F") with human-readable names based
on the code's function in the Mega Man 2 NES ROM.

Bank $0C is the weapons & UI bank, containing:
  - Weapon select screen handler (CHR-RAM tile loading for weapons)
  - HUD energy bar rendering (per-frame update of 4 weapon slots)
  - Lives display
  - Password screen initialization
  - APU sound channel control for weapon UI
  - Sound/music data tables (~75% of bank is encoded music/sound data)
"""

import re
import sys
import os

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0C_weapons_ui.asm')

# =============================================================================
# External label renames: LXXXX := $XXXX references
# These are addresses used in .byte data or indirect jumps — most are data
# artifacts from the disassembler interpreting music/sound data as addresses.
# =============================================================================
EXTERNAL_RENAMES = {
    # RAM entity array addresses used in jmp indirect (data artifacts)
    'L0604': 'data_ref_0604',
    'L0660': 'data_ref_0660',
    'L1501': 'data_ref_1501',
    'L1F05': 'data_ref_1F05',
    'L2260': 'data_ref_2260',
    'L606C': 'data_ref_606C',
    'L608A': 'data_ref_608A',
    'L6868': 'data_ref_6868',
    'L6A60': 'data_ref_6A60',
    'L6A6C': 'data_ref_6A6C',
    'L6D80': 'data_ref_6D80',
    'L6F6C': 'data_ref_6F6C',
    'L7171': 'data_ref_7171',
    'LED06': 'data_ref_ED06',
}

# =============================================================================
# Internal label renames: LXXXX labels within bank $0C ($8000-$BFFF)
# Organized by functional region
# =============================================================================
INTERNAL_RENAMES = {
    # =========================================================================
    # Weapon Selection Handler ($8003-$80BA)
    # =========================================================================
    'L804F': 'weapon_select_store_type',
    'L8085': 'chr_ram_tile_copy_end',
    'L8088': 'chr_ram_padding_fill',
    'L808B': 'chr_ram_padding_byte',
    'L808F': 'chr_ram_padding_loop',
    'L809A': 'weapon_select_advance_slot',
    'L809D': 'weapon_select_dec_count',
    'L80A6': 'weapon_select_store_palette',
    'L80BB': 'weapon_select_high_nybble',
    'L80C6': 'weapon_select_high_store',
    'L80FE': 'weapon_select_bit_loop',
    'L810E': 'weapon_bit_advance_slot',

    # =========================================================================
    # Password / Weapon Secondary Init ($8128-$816B)
    # =========================================================================
    'L8148': 'weapon_secondary_loop',
    'L8153': 'weapon_secondary_advance',

    # =========================================================================
    # Weapon Sound / CHR-RAM Helpers ($816C-$8218)
    # =========================================================================
    'L816C': 'weapon_check_sound_slot',
    'L819C': 'weapon_clear_loop',
    'L81BC': 'energy_bar_clear_loop',
    'L81C4': 'weapon_sound_copy_data',
    'L81E4': 'weapon_sound_calc_offset',
    'L81EA': 'weapon_sound_calc_done',
    'L81F2': 'weapon_sound_copy_loop',
    'L8211': 'display_offset_skip',
    'L8219': 'weapon_shift_e1_right4',
    'L822F': 'apu_enable_channels',

    # =========================================================================
    # HUD Update Main ($8233-$82EB)
    # =========================================================================
    'L823C': 'hud_init_slot_vars',
    'L8266': 'hud_check_pause_flag',
    'L826E': 'hud_check_slot_active',
    'L8286': 'hud_slot_silent_check',
    'L8294': 'hud_shift_ef_flag',
    'L829E': 'hud_next_slot',
    'L82D9': 'hud_lives_reset_timer',
    'L82DD': 'hud_check_refill_timer',
    'L82E3': 'hud_final_shift_ef',
    'L82EC': 'hud_energy_bar_update',
    'L82F8': 'hud_energy_store_f4',

    # =========================================================================
    # Energy Bar Rendering ($82F8-$837B)
    # =========================================================================
    'L830A': 'hud_energy_timer_add',
    'L8310': 'hud_energy_check_drain',
    'L8317': 'hud_energy_drain_loop',
    'L8324': 'hud_energy_refill_loop',
    'L832B': 'hud_energy_clamp_check',
    'L8347': 'hud_energy_reset_counter',
    'L835E': 'hud_energy_delta_read',
    'L836C': 'hud_energy_clamp_max',
    'L8372': 'hud_energy_store_result',
    'L837C': 'hud_energy_check_sweep',

    # =========================================================================
    # Sound Sweep / Envelope Engine ($8388-$84FC)
    # =========================================================================
    'L8388': 'hud_sound_sweep_init',
    'L838F': 'hud_sound_sweep_check',
    'L83A0': 'hud_sweep_reset_counter',
    'L83B1': 'hud_sweep_clamp_low',
    'L83B8': 'hud_sweep_store_value',
    'L83C2': 'hud_sweep_negate_delta',
    'L83CB': 'hud_sweep_read_current',
    'L83D5': 'hud_sweep_compare_slot',
    'L83E8': 'hud_sound_write_volume',
    'L83FA': 'hud_sound_sweep_mode_b',
    'L83FE': 'hud_sound_envelope_run',
    'L840C': 'hud_envelope_add_delta',
    'L8418': 'hud_envelope_check_mode',
    'L8422': 'hud_vibrato_check',
    'L842D': 'hud_vibrato_timer_cmp',
    'L8436': 'hud_vibrato_reset',
    'L8456': 'hud_vibrato_apply_delta',
    'L849C': 'hud_vibrato_set_dir_neg',
    'L84A3': 'hud_vibrato_toggle_dir',
    'L84A9': 'hud_frequency_calc',
    'L84E5': 'hud_frequency_write',
    'L84F5': 'hud_frequency_update_hi',
    'L84FD': 'hud_sound_channel_off',
    'L8509': 'hud_sound_silence_pair',

    # =========================================================================
    # Sound State Reset / Init ($8516-$856C)
    # =========================================================================
    'L8516': 'sound_state_init_slot',
    'L8531': 'sound_state_store_value',
    'L8535': 'sound_state_clear_regs',
    'L853B': 'sound_state_clear_loop',
    'L8548': 'sound_state_save_restore',
    'L8556': 'sound_dispatch_table',

    # =========================================================================
    # Sound Data Stream Interpreter ($856D-$869F)
    # =========================================================================
    'L856D': 'sound_stream_check',
    'L8574': 'sound_stream_refill_check',
    'L857E': 'sound_stream_refill_read',
    'L8589': 'sound_stream_set_mode',
    'L8592': 'sound_stream_fetch',
    'L859B': 'sound_stream_cmd_check',
    'L85A8': 'sound_stream_new_note',
    'L85C2': 'sound_stream_dispatch',
    'L8608': 'sound_cmd_store_param',
    'L8644': 'sound_cmd_load_regs',
    'L868F': 'sound_cmd_load_instrument',
    'L86A0': 'sound_data_read_byte',

    # =========================================================================
    # Sound Note Processing ($86B4-$86FD)
    # =========================================================================
    'L86B4': 'sound_note_process',
    'L86B8': 'sound_note_repeat_loop',
    'L86C3': 'sound_note_tick',
    'L86D3': 'sound_note_check_active',
    'L86FB': 'sound_note_goto_bar_update',
    'L86FE': 'sound_note_done',

    # =========================================================================
    # Sound Instrument / Pattern Engine ($8706-$87BF)
    # =========================================================================
    'L8706': 'sound_pattern_fetch',
    'L8710': 'sound_pattern_cmd_20',
    'L871F': 'sound_pattern_cmd_30',
    'L8726': 'sound_pattern_set_duty',
    'L8734': 'sound_pattern_volume_dec',
    'L874F': 'sound_pattern_goto_save',
    'L8752': 'sound_pattern_lookup_freq',
    'L875B': 'sound_pattern_noise_check',
    'L8766': 'sound_pattern_freq_table',
    'L877D': 'sound_pattern_store_freq',
    'L8792': 'sound_pattern_check_sweep',
    'L8798': 'sound_pattern_init_state',
    'L87A2': 'sound_pattern_set_vol_env',
    'L87B5': 'sound_pattern_set_loop',
    'L87C0': 'sound_cmd_dispatch',

    # =========================================================================
    # Sound Command Handlers ($87C0-$88E0)
    # =========================================================================
    'L880E': 'sound_cmd_store_duty',
    'L8844': 'sound_cmd_skip_note',
    'L8880': 'sound_cmd_set_detune',
    'L8885': 'sound_cmd_detune_table_ref',
    'L888A': 'sound_cmd_jump_pattern',
    'L888C': 'sound_cmd_jump_target',
    'L888D': 'sound_cmd_set_portamento',
    'L88A6': 'sound_cmd_portamento_done',
    'L88A9': 'sound_portamento_init',
    'L88B8': 'sound_portamento_dir_up',
    'L88BA': 'sound_portamento_store',
    'L88DE': 'sound_cmd_volume_done',
    'L88E1': 'sound_instrument_load',
    'L88E6': 'sound_instrument_offset',
    'L88EC': 'sound_instrument_copy',
    'L88FD': 'sound_instrument_byte',
    'L8907': 'sound_instrument_next',

    # =========================================================================
    # Sound Data Stream Read ($8935-$897F)
    # =========================================================================
    'L8935': 'sound_stream_read_next',
    'L8954': 'sound_freq_multiply',
    'L8961': 'sound_freq_mult_loop',
    'L8968': 'sound_freq_mult_dec',

    # =========================================================================
    # Sound/Music Data Tables ($8978-$8AD5)
    # These are frequency lookup tables and weapon data pointer tables.
    # =========================================================================
    'L8A80': 'weapon_data_unused_1',
    'L8A8A': 'weapon_data_unused_2',
    'L8A8C': 'weapon_data_unused_3',

    # =========================================================================
    # Music/Sound Pattern Data ($8AD6-$BFE0)
    # These labels are all within large .byte data blocks — they are
    # targets of indirect jumps in the music data (self-referencing
    # patterns). Named by address since they are data-internal.
    # =========================================================================
    'L8C76': 'snd_data_8C76',
    'L8C80': 'snd_data_8C80',
    'L8C8A': 'snd_data_8C8A',
    'L8C8D': 'snd_data_8C8D',
    'L8C8E': 'snd_data_8C8E',
    'L8D06': 'snd_data_8D06',
    'L8D0E': 'snd_data_8D0E',
    'L8D6D': 'snd_data_8D6D',
    'L8D80': 'snd_data_8D80',
    'L8D88': 'snd_data_8D88',
    'L8D8C': 'snd_data_8D8C',
    'L8D8D': 'snd_data_8D8D',
    'L8DA2': 'snd_data_8DA2',
    'L8DAF': 'snd_data_8DAF',
    'L8DB0': 'snd_data_8DB0',
    'L8DB1': 'snd_data_8DB1',
    'L8DBD': 'snd_data_8DBD',
    'L8E30': 'snd_data_8E30',
    'L8F46': 'snd_data_8F46',
    'L8F80': 'snd_data_8F80',
    'L8F86': 'snd_data_8F86',
    'L8F8C': 'snd_data_8F8C',
    'L8F8D': 'snd_data_8F8D',
    'L9006': 'snd_data_9006',
    'L9030': 'snd_data_9030',
    'L9083': 'snd_data_9083',
    'L90C1': 'snd_data_90C1',
    'L9188': 'snd_data_9188',
    'L918F': 'snd_data_918F',
    'L91A2': 'snd_data_91A2',
    'L924C': 'snd_data_924C',
    'L9468': 'snd_data_9468',
    'L9498': 'snd_data_9498',
    'L9672': 'snd_data_9672',
    'L96EB': 'snd_data_96EB',
    'L9702': 'snd_data_9702',
    'L9815': 'snd_data_9815',
    'L982D': 'snd_data_982D',
    'L98C7': 'snd_data_98C7',
    'L98FE': 'snd_data_98FE',
    'L991C': 'snd_data_991C',
    'L9956': 'snd_data_9956',
    'L9996': 'snd_data_9996',
    'L9999': 'snd_data_9999',
    'L9D34': 'snd_data_9D34',
    'L9D8D': 'snd_data_9D8D',
    'LA3E1': 'snd_data_A3E1',
    'LA7C7': 'snd_data_A7C7',
    'LA9F6': 'snd_data_A9F6',
    'LAA06': 'snd_data_AA06',
    'LAA21': 'snd_data_AA21',
    'LAACF': 'snd_data_AACF',
    'LAC29': 'snd_data_AC29',
    'LAD60': 'snd_data_AD60',
    'LAD74': 'snd_data_AD74',
    'LAEAF': 'snd_data_AEAF',
    'LAEB1': 'snd_data_AEB1',
    'LAF46': 'snd_data_AF46',
    'LAFC2': 'snd_data_AFC2',
    'LB025': 'snd_data_B025',
    'LB02B': 'snd_data_B02B',
    'LB02F': 'snd_data_B02F',
    'LB030': 'snd_data_B030',
    'LB034': 'snd_data_B034',
    'LB038': 'snd_data_B038',
    'LB03B': 'snd_data_B03B',
    'LB03F': 'snd_data_B03F',
    'LB045': 'snd_data_B045',
    'LB087': 'snd_data_B087',
    'LB09A': 'snd_data_B09A',
    'LB1B5': 'snd_data_B1B5',
    'LB1F4': 'snd_data_B1F4',
    'LB1FD': 'snd_data_B1FD',
    'LB300': 'snd_data_B300',
    'LB38C': 'snd_data_B38C',
    'LB38E': 'snd_data_B38E',
    'LB390': 'snd_data_B390',
    'LB394': 'snd_data_B394',
    'LB39F': 'snd_data_B39F',
    'LB3A8': 'snd_data_B3A8',
    'LB3AE': 'snd_data_B3AE',
    'LB3B2': 'snd_data_B3B2',
    'LB3B8': 'snd_data_B3B8',
    'LB3BD': 'snd_data_B3BD',
    'LB40C': 'snd_data_B40C',
    'LB40E': 'snd_data_B40E',
    'LB410': 'snd_data_B410',
    'LB41A': 'snd_data_B41A',
    'LB42C': 'snd_data_B42C',
    'LB488': 'snd_data_B488',
    'LB67F': 'snd_data_B67F',
    'LB77B': 'snd_data_B77B',
    'LB9DF': 'snd_data_B9DF',
    'LB9F8': 'snd_data_B9F8',
    'LBA03': 'snd_data_BA03',
    'LBA07': 'snd_data_BA07',
    'LBA0D': 'snd_data_BA0D',
    'LBA11': 'snd_data_BA11',
    'LBB2E': 'snd_data_BB2E',
    'LBB9A': 'snd_data_BB9A',
    'LBB9D': 'snd_data_BB9D',
    'LBBBA': 'snd_data_BBBA',
    'LBBCC': 'snd_data_BBCC',
    'LBBE1': 'snd_data_BBE1',
    'LBC62': 'snd_data_BC62',
    'LBC6F': 'snd_data_BC6F',
    'LBD0C': 'snd_data_BD0C',
    'LBD69': 'snd_data_BD69',
    'LBDC3': 'snd_data_BDC3',
    'LBDD8': 'snd_data_BDD8',
    'LBDED': 'snd_data_BDED',
    'LBE02': 'snd_data_BE02',
    'LBE3A': 'snd_data_BE3A',
    'LBE88': 'snd_data_BE88',
    'LBEF6': 'snd_data_BEF6',
    'LBF2A': 'snd_data_BF2A',
    'LBF4D': 'snd_data_BF4D',
}

# =============================================================================
# Merge all renames
# =============================================================================
ALL_RENAMES = {}
ALL_RENAMES.update(EXTERNAL_RENAMES)
ALL_RENAMES.update(INTERNAL_RENAMES)


def main():
    if not os.path.exists(ASM_FILE):
        print(f"ERROR: {ASM_FILE} not found")
        sys.exit(1)

    with open(ASM_FILE, 'r') as f:
        text = f.read()

    count = 0
    for old_name, new_name in ALL_RENAMES.items():
        # Word-boundary regex to avoid partial matches
        pattern = re.compile(r'\b' + re.escape(old_name) + r'\b')
        new_text, n = pattern.subn(new_name, text)
        if n > 0:
            count += 1
            text = new_text

    with open(ASM_FILE, 'w') as f:
        f.write(text)

    print(f"Renamed {count} labels (of {len(ALL_RENAMES)} defined) in {ASM_FILE}")

    # Verify: count remaining LXXXX labels
    remaining = len(re.findall(r'^L[0-9A-F]{4}\b', text, re.MULTILINE))
    print(f"Remaining LXXXX labels: {remaining}")


if __name__ == '__main__':
    main()
