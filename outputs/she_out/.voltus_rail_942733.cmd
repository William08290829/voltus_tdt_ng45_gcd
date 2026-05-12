# Voltus_rail Command File

#Result directory
setvar output_directory_name /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out

#Distributed processing setting
setvar max_cpu 8
setvar nga_enabled true
nga_dp_hosts max_cpu=8 mode=local time_out=3600

#Layout Files
layout_file /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/design/6_final.def 

#Cell Library
cell_library /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/pgv/techonly.cl
setvar tesla_accuracy_mode hd
use_cell_view type standard fast
use_cell_view type macro fast_accurate
use_cell_view type io fast_accurate
setvar unified_power_switch_flow true
setvar power_up_fast_mode true
setvar report_msmv_format true
setvar compress_powergrid_database false
setvar operation_mode signoff_verification
setvar hierarchy_char /
setvar use_cell_id true
nga_setvar nga_enable_new_transient_analysis true
setvar enable_smx true
setvar extract_oci_flow true
setvar ignore_shorts false
setvar enable_manufacturing_effects true
setvar cluster_via1_ports true
setvar ignore_fillers true
setvar ignore_fillers_with_cap true
nga_setvar nga_limit_number_of_steps true
setvar vsrc_search_distance 100
setvar em_redundancy_via_current_threshold 0.0
setvar temperature 25
setvar gif_zoom_topcell_diearea false
setvar process_techgen_em_rules true
setvar ict_em_file /home/wei0829/voltus_tdt_question_ng45_gcd/dummy_files/dummy_ictem.txt
setvar keep_log false
setvar enable_report_db true
setvar eiv_report_auto true
nga_setvar nga_current_redistribution true
setvar mge_load_static_pti false
nga_setvar nga_protect_rail_simulation_time false
layout_file -lef /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lef/NangateOpenCellLibrary.tech.lef
layout_file -lef /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lef/NangateOpenCellLibrary.macro.mod.lef
layout_file -lef /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lef/NangateOpenCellLibrary.macro.rect.lef
net_voltage VDD 1.1 0.99
power_pin_supply_tolerance 0.77 1.43 net=VDD
net_voltage VSS 0 0.11
power_pin_supply_tolerance 0 0.3 net=VSS
power_domain PDcore pwrnet="VDD" gndnet="VSS"
current_data_file scale=1 /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db/dynamic_VDD.ptiavg
current_data_file scale=1 /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db/dynamic_VSS.ptiavg
power_pin ALL auto_vsrc_creation=true
# self heat analysis
setvar trf_file "/home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dummy_TRF_area_based.txt"
setvar ipf_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/static_db/instance_power.txt
setvar sh_lp_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out/sh_alpha_parameters.txt
setvar sh_beta_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out/sh_beta_parameters.txt
setvar sh_itm_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out/gcd.idt.rpt
setvar sh_ttm_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out/vr_gcd.tdt.rpt
setvar sh_detail_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out/vr_gcd.ddt.rpt
setvar sh_tiles_x 100
setvar sh_tiles_y 100
setvar sh_tile_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out/sh_tile_vr.txt
nga_setvar nga_enable_rc_avg_report true
analyze PDcore 1.1 dynamic 0.10 dtrms jrms rc rv
