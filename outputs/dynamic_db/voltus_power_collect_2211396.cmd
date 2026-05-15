set_message -limit 20 
sxclDesign design /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db
design rUseSfeDefParser  1
design rSuppressStdout  1
design calLef /home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db/voltus_dummy.lef
design calDef voltus_dummy.def
sxclPowerMeter ChipPwr design
create_result_json -dir {/home/wei0829/voltus_tdt_question_ng45_gcd/outputs/dynamic_db}