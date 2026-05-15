# ==============================================================================
# Design    : gcd
# Platform  : Nangate45 / OpenROAD-flow-scripts output
# Purpose   : Reproduce/check Tile Delta Temperature (.tdt) behavior
#
# Expected testcase folder structure:
#
# <case_root>/
#   scripts/
#     ng45_gcd_self.tcl       <-- this file
#   inputs/
#     lef/
#       NangateOpenCellLibrary.tech.lef
#       NangateOpenCellLibrary.macro.mod.lef
#       NangateOpenCellLibrary.macro.rect.lef   ;# optional, used if present
#     lib/
#       NangateOpenCellLibrary_typical.lib
#     qrc/
#       NG45.tch
#     design/
#       6_final.v
#       6_final.sdc
#       6_final.def
#       6_final.spef
#     pgv/
#       techonly.cl
#   dummy_files/
#     dummy_ictem.txt
#   outputs/
#     ;# generated output will be written here
#
# Suggested run command from <case_root>:
#   voltus -log outputs/voltus_rerun.log -overwrite \
#          -files scripts/ng45_gcd_self_AE_relative.tcl
#
# Notes:
# - This script uses relative paths so the testcase can be moved/downloaded.
# - The cell thermal resistance file is generated from library-cell area by a
#   helper procedure below. This follows the original experimental flow.
# - The main question is about interpreting the generated TDT file and the
#   sharp tile-to-tile delta-T discontinuity.
# ==============================================================================

# ---------------------------------------------------------------------------- --
# Basic testcase settings
# ---------------------------------------------------------------------------- --
set platform_name       nangate45
set design_config_name  gcd
set design_name         gcd
set top_module          gcd

# The script is expected to be under <case_root>/scripts/.
set script_dir [file normalize [file dirname [info script]]]
set case_root  [file normalize [file join $script_dir ..]]

set inputs_root          [file join $case_root inputs]
set self_heat_input_root [file join $case_root dummy_files]
set output_root          [file join $case_root outputs]

set lef_root     [file join $inputs_root lef]
set lib_root     [file join $inputs_root lib]
set qrc_root     [file join $inputs_root qrc]
set design_root  [file join $inputs_root design]
set pgv_root     [file join $inputs_root pgv]

set static_root  [file join $output_root static_db]
set dynamic_root [file join $output_root dynamic_db]
set rail_root    [file join $output_root rail_dynamic]
set she_root     [file join $output_root she_out]

file mkdir $output_root
file mkdir $static_root
file mkdir $dynamic_root
file mkdir $rail_root
file mkdir $she_root

# ---------------------------------------------------------------------------- --
# Helper procedures
# ---------------------------------------------------------------------------- --
proc require_file {file_path description} {
    if {![file exists $file_path]} {
        puts stderr "ERROR: Missing $description: $file_path"
        error "Missing required file: $file_path"
    }
    puts "INFO: Found $description: $file_path"
}

proc write_instance_power_file {infile outfile} {
    set fin  [open $infile r]
    set fout [open $outfile w]

    set dash_count 0
    set data_started 0
    set count 0

    while {[gets $fin line] >= 0} {
        set s [string trim $line]
        if {$s eq ""} {
            continue
        }

        # Detect report-table separator lines.
        if {[regexp {^-+$} $s]} {
            incr dash_count
            if {$dash_count >= 2} {
                set data_started 1
            }
            continue
        }

        if {!$data_started} {
            continue
        }

        set fields [regexp -all -inline {\S+} $s]

        # Expected row format:
        # instance internal switching total leakage cell
        if {[llength $fields] < 6} {
            continue
        }

        set inst  [lindex $fields 0]
        set total [lindex $fields 3]

        # The total-power column must be a valid number.
        if {[regexp {^[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?$} $total]} {
            puts $fout "$inst $total"
            incr count
        }
    }

    close $fin
    close $fout
    return $count
}

# Generate a simple cell thermal-resistance file from library-cell area.
# This was used in the original experimental flow as a dummy TRF source.
# Format written: <cell_name> <rth_value>
proc generate_area_based_dummy_trf {output_file {base_constant 500.0}} {
    set fout [open $output_file w]
    set count 0

    puts "INFO: Generating area-based dummy TRF file: $output_file"
    puts "INFO: Rth formula: Rth = $base_constant / cell_area"

    # Query all library cells from the loaded Voltus database.
    set all_lib_cells [dbGet head.libCells]

    foreach cell $all_lib_cells {
        set cell_name [dbGet $cell.name]
        set size_raw  [dbGet $cell.size]
        set size_flat [join $size_raw]

        set width  [lindex $size_flat 0]
        set height [lindex $size_flat 1]

        if {![string is double -strict $width] || ![string is double -strict $height]} {
            continue
        }

        if {$width == 0 || $height == 0} {
            continue
        }

        set area    [expr {$width * $height}]
        set rth     [expr {$base_constant / $area}]
        set rth_fmt [format "%.2f" $rth]

        puts $fout "$cell_name $rth_fmt"
        incr count
    }

    close $fout
    puts "INFO: Generated $count thermal-resistance entries in $output_file"
    return $count
}

proc check_trf_covers_used_cells {trf_file} {
    puts "INFO: Checking whether TRF covers all used master cells..."

    array set trf_cells {}

    set fin [open $trf_file r]
    while {[gets $fin line] >= 0} {
        set s [string trim $line]
        if {$s eq ""} {
            continue
        }

        set fields [regexp -all -inline {\S+} $s]
        if {[llength $fields] < 2} {
            continue
        }

        set cell_name [lindex $fields 0]
        set trf_cells($cell_name) 1
    }
    close $fin

    set used_cells [lsort -unique [dbGet top.insts.cell.name]]

    set missing_cells {}

    foreach cell_name $used_cells {
        if {$cell_name eq "" || $cell_name eq "0x0"} {
            continue
        }

        if {![info exists trf_cells($cell_name)]} {
            lappend missing_cells $cell_name
        }
    }

    if {[llength $missing_cells] > 0} {
        puts stderr "ERROR: The following used master cells are missing in TRF:"
        foreach c $missing_cells {
            puts stderr "  $c"
        }
        error "TRF coverage check failed: missing Rth entries for used cells."
    } else {
        puts "INFO: TRF coverage check passed. All used master cells have Rth entries."
    }
}

# ---------------------------------------------------------------------------- --
# Required input files
# ---------------------------------------------------------------------------- --
set tech_lef       [file join $lef_root NangateOpenCellLibrary.tech.lef]
set macro_mod_lef  [file join $lef_root NangateOpenCellLibrary.macro.mod.lef]
set macro_rect_lef [file join $lef_root NangateOpenCellLibrary.macro.rect.lef]
set stdcell_lib    [file join $lib_root NangateOpenCellLibrary_typical.lib]
set qrc_tech_file  [file join $qrc_root NG45.tch]

set netlist_file   [file join $design_root 6_final.v]
set sdc_file       [file join $design_root 6_final.sdc]
set def_file       [file join $design_root 6_final.def]
set spef_file      [file join $design_root 6_final.spef]

set techonly_pgv   [file join $pgv_root techonly.cl]
set ictem_file     [file join $self_heat_input_root dummy_ictem.txt]

require_file $tech_lef      "technology LEF"
require_file $macro_mod_lef "macro LEF"
require_file $stdcell_lib   "timing library"
require_file $qrc_tech_file "QRC tech file"
require_file $netlist_file  "final Verilog netlist"
require_file $sdc_file      "final SDC"
require_file $def_file      "final DEF"
require_file $spef_file     "final SPEF"
require_file $techonly_pgv  "tech-only PGV library"
require_file $ictem_file    "ICT EM model file"

# ---------------------------------------------------------------------------- --
# Multi-CPU setting
# ---------------------------------------------------------------------------- --
# Change local_cpu if the available license/machine uses a different CPU limit.
set local_cpu 8
set_multi_cpu_usage -localCpu $local_cpu -verbose

# ---------------------------------------------------------------------------- --
# Design import and MMMC setup
# ---------------------------------------------------------------------------- --
set timing_libs [list $stdcell_lib]

set lef_files [list $tech_lef $macro_mod_lef]
if {[file exists $macro_rect_lef]} {
    lappend lef_files $macro_rect_lef
    puts "INFO: Optional macro rect LEF found and will be read: $macro_rect_lef"
} else {
    puts "INFO: Optional macro rect LEF not found; continuing without it: $macro_rect_lef"
}

read_lib -lef {*}$lef_files

foreach lib $timing_libs {
    read_lib -min $lib
    read_lib -max $lib
}

read_verilog $netlist_file
set_top_module $top_module

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

read_def $def_file
read_spef -rc_corner nominal $spef_file

# ---------------------------------------------------------------------------- --
# Power analysis
# ---------------------------------------------------------------------------- --
set_default_switching_activity \
  -input_activity 0.2 \
  -period 10ns \
  -seq_activity 0.1 \
  -clock_gates_output_ratio 2.0

propagate_activity

# Static power analysis, also used to generate instance_power.txt.
set static_rpt         [file join $static_root static_power.rpt]
set instance_power_txt [file join $static_root instance_power.txt]

set_power_analysis_mode -reset
set_power_analysis_mode \
  -method static \
  -write_static_currents true \
  -create_binary_db true \
  -binary_db_name staticPower.db

set_power_output_dir $static_root
report_power -rail_analysis_format VS -outfile $static_rpt

set inst_power_count [write_instance_power_file $static_rpt $instance_power_txt]
puts "INFO: Generated $inst_power_count rows in $instance_power_txt"

# Dynamic power analysis, used for dynamic current files.
set dynamic_rpt [file join $dynamic_root dynamic_power.rpt]

set_power_analysis_mode -reset
set_power_analysis_mode \
  -method dynamic \
  -create_binary_db true \
  -binary_db_name dynamicPower.db

set_power_output_dir $dynamic_root
report_power -rail_analysis_format VS -outfile $dynamic_rpt

# ---------------------------------------------------------------------------- --
# Rail analysis setup
# ---------------------------------------------------------------------------- --
set_pg_nets -net VDD -voltage 1.1 -threshold 0.99
set_pg_nets -net VSS -voltage 0.0 -threshold 0.11

set_rail_analysis_domain -name PDcore -pwrnets VDD -gndnets VSS

set dynamic_vdd_ptiavg [file join $dynamic_root dynamic_VDD.ptiavg]
set dynamic_vss_ptiavg [file join $dynamic_root dynamic_VSS.ptiavg]

set_power_data -reset
set_power_data -format current -scale 1 [list \
  $dynamic_vdd_ptiavg \
  $dynamic_vss_ptiavg]

set_power_pads -reset
set_power_pads -net ALL -auto_voltage_source_creation true

# Current ORFS Nangate45 setup lacks usable stdcell/macro PGV in this flow;
# use techonly.cl as the practical PG library, matching the original testcase.
#
# Important for the TDT interpretation question:
# This flow explicitly uses -temperature 25 in set_rail_analysis_mode.
set rail_temperature_c 25

set_rail_analysis_mode \
  -method dynamic \
  -accuracy hd \
  -vsrc_search_distance 100 \
  -power_grid_library [list $techonly_pgv] \
  -temperature $rail_temperature_c \
  -process_techgen_em_rules true \
  -ict_em_models $ictem_file

# ---------------------------------------------------------------------------- --
# Self-heating analysis setup
# ---------------------------------------------------------------------------- --
# Dummy TRF based on cell area. Keep the file in outputs so reruns are portable.
set trf_file [file join $output_root dummy_TRF_area_based.txt]
set trf_count [generate_area_based_dummy_trf $trf_file 2000.0]
puts "INFO: Generated $trf_count rows in $trf_file"
check_trf_covers_used_cells $trf_file

set idt_file    [file join $output_root ${platform_name}_${design_name}_idt.txt]
set tdt_file    [file join $output_root ${platform_name}_${design_name}_tdt.txt]
set detail_file [file join $output_root ${platform_name}_${design_name}_detail.rpt]

# Main TDT-related settings:
# - tiles: 100 x 100
# - tdt_file: tile delta temperature output
set_self_heat_analysis_mode \
  -alpha_parameters {{metal1 0.74 0.85} {metal2 0.62 0.85} {metal3 0.53 0.85} {metal4 0.53 0.85} {metal5 0.53 0.85} {metal6 0.53 0.85} {metal7 0.53 0.85} {metal8 0.53 0.85} {metal9 0.53 0.85} {metal10 0.53 0.85}} \
  -beta_parameters {0.00423 -0.00045 0.81534} \
  -instance_power_file $instance_power_txt \
  -cell_thermal_resistance_file $trf_file \
  -instance_delta_temperature_file $idt_file \
  -tile_delta_temperature_file $tdt_file \
  -tiles {100 100} \
  -detail_delta_temperature_file $detail_file

puts "INFO: Running analyze_self_heat for domain PDcore"
puts "INFO: TDT output will be written to: $tdt_file"
puts "INFO: Rail analysis temperature setting in this testcase: $rail_temperature_c degC"

analyze_self_heat -domain PDcore -output_directory $she_root

puts "INFO: Self-heating analysis completed."
puts "INFO: Generated TDT file: $tdt_file"
puts "INFO: Generated IDT file: $idt_file"
puts "INFO: Generated detail report: $detail_file"
