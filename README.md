# CalcRegim_M
![Image alt](https://github.com/DimaKovalchuk066/Regim_mlab/raw/master/ЛЭП.jpg)
Сalculation of the electric networks of 6-10 kV of arbitrary configuration. Language - Matlab (version 2015b)

This project is the program, which implements the calculation of the mode
networks of 6-10 kV of arbitrary configuration (including a closed
configuration with multiple power sources, but one nominal
voltage) by the method of contour equations. Implemented work with xls files for
input and output calculation results.

To run the program, you must:
1. Copy the Regim_Mlab folder to the hard disk
2. Open the main file in Matlab;
3. Run the main file in Matlab;
4. Select the working directory in Matlab;
5. The source data and results are stored in the xls format in the Excel Data folder
 under the name "Source_data.xls", "Results.xls";
* Additional test patterns are stored in the archive for their use
in the program, you need to rename the corresponding file.

There are 2 m-files in the folder:
1) main.m - Matlab script - is the control unit for calculating the mode,
uses the environment to create a network model, a graph representing the network,
graphical output of the circuit and calculation of the network mode.
2) go.m - Matlab script - provides the directory and subdirectories with the file
main in the Matlab search path.


Also in the folder are 5 subdirectories:
1) Excel Data - the folder contains the source and excel data files
2) FGraphs - the folder contains m-files with functions and a class for working with the graph
3) FRegim - the folder contains files with functions for organizing the calculation mode
4) Model_Data - the folder contains m-files with classes and functions for creating
model, input and output of source data
5) Other - the folder contains m-files that implement special features, not related
with the main tasks of the system (calculation and optimization of the 6-10 kV network mode).
