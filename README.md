# AFM-Force-Curve-Analyzer-IgorPro
An Igor Pro toolkit to process and evaluate Atomic Force Microscopy Force-Distance Measurements

The licence for the code in this repository is contained in the included license.md file.

I have written these IGOR Pro procedures to process, analyze and evalute collected AFM force-distance curve during my PhD thesis. All processes and interactions with this software are handled through a graphical user interface (GUI, see picture) to ease the handeling. The reliablity and variability of the code was tested and improved over a time period of ~5 years by my collegues and me in the field of soft matter research. In particular for hydrogel and polymer mechanics and adhesion, capsule mechanics and polymer brush interactions.

General information:
- All code is commented to ease understanding the tasks and ideas behind commands used.
- This software processes raw detector deflection signals in voltage vs raw piezo movement waves in meter. Therefore, it is suitable for measurements collected at any atomic force microscope, provided the data is importable to Igor Pro. No header-information from waves are used. Only 'name style' of the measurements must follow the principles of Asylum Research.(everything is explained in XXX)
- The procedure first indexes all force-distance curves in a specified Igor Pro Folder. All curves can be processed and visualizied in graph indiviually or all at once.
- All systems constants like cantilever spring constant, sensitivity, probe radius etc. are requested by user input.
- General processing features include: determination of baseline tilt angle and its correction to be flat; "easy" calculation of the adhesion force (lowest force value while retracting); determination of the contact point: 5 different algorithm adjustable through different input values; conversion from raw deflection and piezo movement to force versus deformation/separation

Specialized features: 
- Calculation of "advanced" adhesion properties based on JKR and DMT theory for different contact geometries. Determination of        load and dissipated energy.
- Mechanical interpretation of force-deformation curves: available contact mechanics theorys are Hertz-Model, 'regular' Johnson-Kendal-Roberts theory, '2 point' Johnson-Kendal-Roberts theory, Derjaguin-Muller-Toporov theory, Reissner theory for thin-shell capsuls, Maugis-Dugdale theory in the approximation of Carprick and others. This mechanics panel supports a great varity of adjustable variables to adjust the fitting algorithm to experimental data in regard to size, geometry, fitting ranges and many others.
- Fitting panels for polymer brush measurements based on a mean-field theory and the Alexander deGennes model.
- Additionally, further smaller scripts are available for other kind of interaction forces, BUT they are not yet perfected since they were not used to same excess as the ones mentioned above.

User interactions and data management:
- Almost all interactions with this software are handled through the graphical user interace. It includs a graphical display of the current force distance measurement. The displayed 'kind' of curve (raw deflection vs raw piezomovement, force vs deformation/separation and so on) can be adjusted by checkboxes. This will trigger certain zoom-in processes to simplify checking the results after processing. These automated zoom-in ranges can be adjusted only within the source-code.
- Modifying the raw data will create new results waves. When extracting informations a corresponding overview wave for the currentfolder will be generated to sum up the results.
- Additionally, some command-window only procedures ("folder_info2XXX") are supplied to extract every kind of information wanted.
- All created new wave types follow the nameing principles of Asylum Research (ONLY NAMES). See alos file XXX



Since I am only a semi-professional programmer, this code is not 100% bug-free. With increasing experience you will learn how to handle the software in its best way possilbe and how to avoid running into bugs or error messages, as I could follow this processes for my collegues and myself.
