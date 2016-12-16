# redpitaya_guide
Collections of guides and projects related to testing Red Pitaya

More information at http://antonpotocnik.com/?cat=29


Projects:

	1 LED blink (Installation, Generating Bitstream, uploading to FPGA)

	2 Kinght Rider (Verilog example, modules, parallelism)
	
	3 Stopwatch (AXI protocol, communication between FPGA and Linux on the ARM porcessor, GPIO IP core)
	
	4 Averager (ADC, DAC, Setting Configuration, Reading Data from FPGA, plotting data on a client machine, IP cores)
	
	
	
Start a project in Vivado using following steps:

1. Open "make_project.tcl" in an editor and uncomment desired "set project_name ###" line

2. Open Vivado

3. In Vivado's Tcl Console navigate to "redpitaya_guide/" folder and execute "source make_project.tcl"

