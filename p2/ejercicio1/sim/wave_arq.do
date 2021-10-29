onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /processor_tb/i_processor/Clk
add wave -noupdate /processor_tb/i_processor/Reset
add wave -noupdate -expand -group {Instruction Fetch} /processor_tb/i_processor/PC_nextIF
add wave -noupdate -expand -group {Instruction Fetch} /processor_tb/i_processor/Pc_regIF
add wave -noupdate -expand -group {Instruction Fetch} /processor_tb/i_processor/InstructionIF
add wave -noupdate -expand -group {Instruction Fetch} /processor_tb/i_processor/desition_JumpMEM
add wave -noupdate -expand -group {Instruction Fetch} /processor_tb/i_processor/PC_plus4IF
add wave -noupdate -expand -group {Instruction Fetch} /processor_tb/i_processor/Addr_Jump_destMEM
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/InstructionIFID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/PC_plus4IFID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_JumpID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_BranchID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_MemToRegID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_MemWriteID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_MemReadID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_AluSrcID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_AluOpID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_RegWriteID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Ctrl_RegDestID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/Inm_extID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/reg_RSID
add wave -noupdate -expand -group {Instruction Decode} /processor_tb/i_processor/reg_RTID
add wave -noupdate -group Execution /processor_tb/i_processor/PC_plus4IDEX
add wave -noupdate -group Execution /processor_tb/i_processor/reg_RSIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/reg_RTIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_JumpIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_BranchIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_MemToRegIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_MemWriteIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_MemReadIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_AluSrcIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_AluOpIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_RegWriteIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Ctrl_RegDestIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Inm_extIDEX
add wave -noupdate -group Execution /processor_tb/i_processor/InstructionIDEX_RT
add wave -noupdate -group Execution /processor_tb/i_processor/InstructionIDEX_RD
add wave -noupdate -group Execution /processor_tb/i_processor/InstructionIDEX_Inm
add wave -noupdate -group Execution /processor_tb/i_processor/AluControlEX
add wave -noupdate -group Execution /processor_tb/i_processor/Alu_Op2EX
add wave -noupdate -group Execution /processor_tb/i_processor/Alu_ResEX
add wave -noupdate -group Execution /processor_tb/i_processor/Alu_IgualEX
add wave -noupdate -group Execution /processor_tb/i_processor/reg_RDEX
add wave -noupdate -group Execution /processor_tb/i_processor/Addr_BranchEX
add wave -noupdate -group Execution /processor_tb/i_processor/Addr_JumpEX
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Ctrl_RegWriteEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Ctrl_MemToRegEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Ctrl_BranchEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Ctrl_JumpEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Ctrl_MemWriteEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Ctrl_MemReadEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Addr_BranchEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Addr_JumpEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Alu_IgualEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Alu_ResEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Alu_Op2_FWEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/reg_RDEXMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/desition_JumpMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/Addr_Jump_destMEM
add wave -noupdate -expand -group {Memory Write} /processor_tb/i_processor/dataIn_MemMEM
add wave -noupdate -group {Write Back} /processor_tb/i_processor/reg_RDMEMWB
add wave -noupdate -group {Write Back} /processor_tb/i_processor/Ctrl_RegWriteMEMWB
add wave -noupdate -group {Write Back} /processor_tb/i_processor/Ctrl_MemToRegMEMWB
add wave -noupdate -group {Write Back} /processor_tb/i_processor/dataIn_MemMEMWB
add wave -noupdate -group {Write Back} /processor_tb/i_processor/Alu_ResMEMWB
add wave -noupdate -group {Write Back} /processor_tb/i_processor/reg_RD_dataWB
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {50 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 334
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {556 ns}
