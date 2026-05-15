#######################################################
#                                                     
#  Voltus IC Power Integrity Solution Command Logging File                     
#  Created on Thu May 14 13:51:19 2026                
#                                                     
#######################################################

#@(#)CDS: Voltus IC Power Integrity Solution v23.11-s111_1 (64bit) 05/16/2024 09:07 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 23.11-s111_1 NR240401-0735/23_11-UB (database version 18.20.622) {superthreading v2.20}
#@(#)CDS: AAE 23.11-s031 (64bit) 05/16/2024 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 23.11-s025_1 () May 16 2024 01:47:36 ( )
#@(#)CDS: SYNTECH 23.11-s010_1 () Apr  5 2024 04:21:08 ( )
#@(#)CDS: CPE v23.11-s059

set_multi_cpu_usage -localCpu 8 -verbose
read_lib -lef /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lef/NangateOpenCellLibrary.tech.lef /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lef/NangateOpenCellLibrary.macro.mod.lef /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lef/NangateOpenCellLibrary.macro.rect.lef
read_lib -min /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lib/NangateOpenCellLibrary_typical.lib
read_lib -max /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/lib/NangateOpenCellLibrary_typical.lib
read_verilog /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/design/6_final.v
set_top_module gcd
create_library_set -name libs_min -timing $timing_libs
create_library_set -name libs_max -timing $timing_libs
create_rc_corner -name nominal -qx_tech_file $qrc_tech_file
create_delay_corner -name corner_min -library_set libs_min -rc_corner nominal
create_delay_corner -name corner_max -library_set libs_max -rc_corner nominal
create_constraint_mode -name setup_func_mode -sdc_files $sdc_file
create_analysis_view -constraint_mode setup_func_mode \
  -name setup_func \
  -delay_corner corner_max
create_analysis_view -constraint_mode setup_func_mode \
  -name hold_func \
  -delay_corner corner_min
set_analysis_view -setup [list setup_func] -hold [list hold_func]
set_analysis_mode -analysisType onChipVariation -checkType hold
set_design_mode -process 45
read_def /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/design/6_final.def
read_spef -rc_corner nominal /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/design/6_final.spef
set_default_switching_activity -input_activity 0.2 -period 10ns -seq_activity 0.1 -clock_gates_output_ratio 2.0
propagate_activity
set_power_analysis_mode -reset
set_power_analysis_mode -method static -write_static_currents true -create_binary_db true -binary_db_name staticPower.db
set_power_output_dir /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/static_db
report_power -rail_analysis_format VS -outfile /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/static_db/static_power.rpt
set_power_analysis_mode -reset
set_power_analysis_mode -method dynamic -create_binary_db true -binary_db_name dynamicPower.db
set_power_output_dir /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db
report_power -rail_analysis_format VS -outfile /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db/dynamic_power.rpt
set_pg_nets -net VDD -voltage 1.1 -threshold 0.99
set_pg_nets -net VSS -voltage 0.0 -threshold 0.11
set_rail_analysis_domain -name PDcore -pwrnets VDD -gndnets VSS
set_power_data -reset
set_power_data -format current -scale 1 {/home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db/dynamic_VDD.ptiavg /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db/dynamic_VSS.ptiavg}
set_power_pads -reset
set_power_pads -net ALL -auto_voltage_source_creation true
set_rail_analysis_mode -method dynamic -accuracy hd -vsrc_search_distance 100 -power_grid_library /home/wei0829/voltus_tdt_question_ng45_gcd/inputs/pgv/techonly.cl -temperature 25 -process_techgen_em_rules true -ict_em_models /home/wei0829/voltus_tdt_question_ng45_gcd/dummy_files/dummy_ictem.txt
set_self_heat_analysis_mode -alpha_parameters {{metal1 0.74 0.85} {metal2 0.62 0.85} {metal3 0.53 0.85} {metal4 0.53 0.85} {metal5 0.53 0.85} {metal6 0.53 0.85} {metal7 0.53 0.85} {metal8 0.53 0.85} {metal9 0.53 0.85} {metal10 0.53 0.85}} -beta_parameters {0.00423 -0.00045 0.81534} -instance_power_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/static_db/instance_power.txt -cell_thermal_resistance_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dummy_TRF_area_based.txt -instance_delta_temperature_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/nangate45_gcd_idt.txt -tile_delta_temperature_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/nangate45_gcd_tdt.txt -tiles {100 100} -detail_delta_temperature_file /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/nangate45_gcd_detail.rpt
analyze_self_heat -domain PDcore -output_directory /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/she_out
exit
