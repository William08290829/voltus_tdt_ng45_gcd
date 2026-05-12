# Voltus TDT File Interpretation Question - ng45_gcd testcase

## Design information
- Design name: gcd
- Platform: Nangate45
- Source flow: OpenROAD-flow-scripts / ORFS
- Voltus version: v23.11-s111_1
- Analysis: self-heating analysis
- Tile setting: 100 x 100

## Tcl script
- scripts/ng45_gcd_self.tcl

## File description
- inputs/: design and platform input files
- self_heat_inputs/: files used by self-heating setup
- outputs/: generated Voltus outputs

## Run
```bash
voltus -no_gui -log ./logs/run_ng45_gcd -overwrite -files ./scripts/ng45_gcd_self.tcl
```