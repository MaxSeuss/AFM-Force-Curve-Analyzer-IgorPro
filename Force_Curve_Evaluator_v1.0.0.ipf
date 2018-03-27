#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#if Exists("PanelResolution") != -1
Static Function PanelResolution2(wName)	// For compatibility with Igor7
	String wName
	return 72
End
#endif

// Copy&paste this line to Command window to adjust the GUI size on modern HD-monitors
//•SetIgorOption PanelResolution = 72

//Top-line drop-down menu to access certain single functions and to define hot-keys
menu "Single Force Curve Evaluation"
	"GUI", UserPanel_SingleFC()
	"Do Cursors/F9",/Q, cursorinfotowave2()
	"Do Curve Cut/F3",/Q, cutofcurvesmenu(40)
	"Do Baseline Correction/F4",/Q,AdhesionbuttonAL("test")
	"Do Contact Point/F5",/Q,contactbuttonal("test")
	"Do Adhesion Ramps/F6",/Q, adhesionbuttonalone("test")
	"Do E-Modul Button/F7",/Q, emodulbuttonal("test")
	"Next Force Curve/F8",/Q, nextcurve("test")
	"autoscale /q",/Q, autoscale()
end

// Autoscale graph within the GUI. Activated by hot-key ctrl+q
function autoscale()
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay
	setaxis/A
end

//Function defining the Graphical User Interface with all buttons, fields and stuff
function UserPanel_SingleFC()
//All input variables and strings are created/called as global objects in a specific folder.
//Most are named to closely relate to their purpose. All will be introducted in the subfunctions when called.
	setdatafolder root:
	if(datafolderexists("PanelControl")==0)
		newdatafolder PanelControl
	endif
	setdatafolder root:panelcontrol
	if(datafolderexists("SingleFCPanel")==0)
		newdatafolder SingleFCPanel
		setdatafolder root:panelcontrol:SingleFCPanel
		
		variable/G springconst_g, InvOLS_g, numLinesMap_g, numforcecurve_g, EModulGuess_g, SphereRadius_g, PossionRatio_g, currentLineDisp_g, currentPntDisp_g, showFit_g, showdefor_g
		variable /G showforce_g, contacttolerance_g=0.05, derivationbase_g=0.1,baselinepercent_g, showdeflCOR_g, lowExpo_g, HighExpo_g, LogFitSdev_g, percentContactFit_g, EModOffset_g, threshold_g, numberofmaxima_g, amountofpnts_g
		variable/G showlog_g, showsepa_g, exponentoffset_g, wholefolder_g, limitsdisplay_g, percentcontfit_g, boxsize_g, springconst_backup, retraceonly_g, Mechmodel_g
		variable/G showdwell_g, check_contact_g, highlight_adh_g, errorVirtualDefl_g, overview_g
		string/G nameMap_g//=stringfromlist(numpntsMap_g,BauListBasenameString(),";")
		string/G displaystring, folderstring_g="root:"
		variable/G percentcontfitoffset_g
		//displaystring:=namemap_g
		wave/T ListofBasenames_g
		make/N=1/T Displaywave
	endif
	setdatafolder root:panelcontrol:SingleFCPanel
	SVAR nameMap_g, folderstring_g
	NVAR springconst_g, InvOLS_g, numLinesMap_g, forcecurve_g, EModulGuess_g, SphereRadius_g, PossionRatio_g, currentlinedisp_g, currentpntdisp_g, showfit_G, showdefor_g
	NVAR showforce_g, contacttolerance_g, derivationbase_g,baselinepercent_g, showdeflCOR_g,lowExpo_g, HighExpo_g, LogFitSdev_g, percentContactFit_g, EModOffset_g
	NVAR showsepa_g, showlog_g, exponentoffset_g, wholefolder_g, limitsdisplay_g, percentcontfit_g, springconst_backup, retraceonly_g, mechmodel_g
	NVAR show_dwell_g, check_contact_g, highlight_adh_g, errorVirtualDefl_g, overview_g, percentcontfitoffset_g
	highlight_adh_g=0
	
//The first big Window (user panel) is created in size & style
	NewPanel/k=1 /W=(250,50,1250,690) /N=MechanicsPanel as "Mechanical_Characterisation"
	DoWindow/F Mechanical_Characterisation
	SetDrawEnv linefgc= (0,12800,52224),fillpat= 0,linethick= 3.00

//Top left part of the GUI is created. Containing general info about the folder-containing the Fd-curves,
//current force-curve treated and general infos about the cantilever.
	DrawRect 5,5,260,230
	SetDrawEnv fillbgc= (52224,0,0),fillpat= 0
	SetDrawEnv fstyle= 1,fsize= 15, textrgb= (0,12800,52224)
	DrawText 50,25 ,"Force Curve Properties"
	//Force curve folder and name
	SetVariable nameMap_G, pos={25,30}, size={200,200}, Value=root:panelcontrol:SingleFCPanel:namemap_g, title="Force Map name" 
	SetVariable numforcecurve_g, pos={25,50}, size={175,175}, Value=root:panelcontrol:SingleFCPanel:numforcecurve_g, title="Number of Force Curve",   proc=updateforcecurve, limits={0,limitsdisplay_g,1}
	SetVariable folderstring_g, pos={25,70}, size={225,225}, Value=root:panelcontrol:SingleFCPanel:folderstring_g, title="Force Curve Folder"

	SetDrawEnv fstyle= 1,fsize= 15,textrgb= (0,39168,0)
	DrawText 50,110 , "Cantilever Properties"
	SetVariable springconst_g, pos={28,115}, size={230,230}, Value=root:panelcontrol:SingleFCPanel:springconst_g, Title="Springconstant in N/m", proc=springconstwarning
	SetVariable InvOLS_g, pos={66,135}, size={152,152}, Value=root:panelcontrol:SingleFCPanel:InvOLS_g, Title="InvOLS in nm/V"
//Check to treat every force-curve at once with the current action.		
	checkbox wholefolder_g, Title="Use all Force Curves in Folder", pos={53,160}, size={130,20}, variable=root:panelcontrol:SingleFCPanel:wholefolder_g, value=0
//Initializing the measurements to the code architecture.	
	button grabdata, Title="Grab Force Curves", pos={50,180}, size={150,40}, proc=grabdata
	Button grabdata fSize=14,fstyle=1
//Defining the Graph-window within the GUI to see the current force-curve.	
	Display /N=MechDisplay /W=(270,10,975,430) /host=#
	modifygraph framestyle=1
	setactivesubwindow ##
	SetDrawEnv linefgc= (0,39168,0),fillpat= 0,linethick= 3.00
//Section controlling in which way the curve is displayed.
	DrawRect 5, 240, 260, 390
	SetDrawEnv textrgb= (39168,0,0),fstyle= 1,fsize= 15
	DrawText 50, 265, "Display Control"
	string ctrlname, test
//Show E-Modul fits No/Yes
	Checkbox ShowFit, value=0, Title="Show E-Modul Fit", variable=root:panelcontrol:SingleFCPanel:showfit_g, pos={9,270}
//Show tilt corrected Deflection/Force No/Yes	
	checkbox showdeflCOR, value=0, Title="Show corrected Deflection", variable=root:panelcontrol:SingleFCPanel:showdeflCOR_g, pos={9,290}
//Show Deformation rather than piezo-movement No/Yes	
	Checkbox ShowDefor, value=0, Title="Display Deformation", variable=root:panelcontrol:SingleFCPanel:showdefor_g, pos={9,310}
//Show Force rather than cantilever Deflection No/Yes
	checkbox ShowForce, value=0, Title="Display Force", variable=root:panelcontrol:SingleFCPanel:showforce_g, pos={9,330}
//Show Separation rather than piezo-movement No/Yes	
	checkbox ShowSepa, value=0, Title="Display Separation", variable=root:panelcontrol:SingleFCPanel:showsepa_g, pos={9,350}
//Show double logarithmic force-curve No/Yes; currently not working to well	
	checkbox ShowLog, value=0, Title="Display Log", variable=root:panelcontrol:SingleFCPanel:showlog_g, pos={9,370}
//Show the dwell parts of the force-curve - if present - No/Yes	
	checkbox showdwell, value=0, title="Display Dwell", variable=root:panelcontrol:singlefcpanel:show_dwell_g, pos={110,370}
//Update the Graph with current settings
	Button Update, Title="Update\rDisplay", pos={175,280}, size={80,90}, proc=UpdatedisplaybuttonAL
	Button Update fSize=14,fstyle=1
//Create an external Graph including all force-curves in the current folder with the chosen settings.	
	Button Overview, Title="Overview/All", pos={175,240}, size={70,40}, proc=OverviewDisplayButtonAL
		
//3rd Section controlling the modification of the raw curve
	SetDrawEnv linefgc= (0,43520,65280),fillpat= 0,linethick= 3.00
	DrawRect 5, 400, 260, 635
	SetDrawEnv fstyle= 1,fsize= 15
	DrawText 50, 425, "Force Curve Modification"
//Activates the Tilt-correction function and calcs a "basic" adhesion value	
	Button AdhesionFMap, Title="Cor for virtual Deflection\r&Calc Adhesion", pos={33,450}, size={180,40}, proc=AdhesionbuttonAL
	Button AdhesionFMap fSize=14,fstyle=1
//Activates the search for the contact-point and recalcs the piezo-movement to deformation.	
	Button ContactPointBtAL, Title="Determine Contact\r& Calc Deformation", pos={120,535}, size={130,40}, proc=contactbuttonal
	Button ContactPointBtAL fstyle=1
//When using the "line-fit" options in the deformation-calculation the percentage in the contact regime to be fitted is stated.
	Setvariable percentContFit_g, pos={15,540}, limits={0,100,5}, size={100,100}, value=root:panelcontrol:singleFcPanel:percentcontfit_g, Title="ContFit %"
//An offset towards the maximum indentation can be set.
	setvariable percentContFitOffset_g, pos={15,560}, limits={0,95,5}, size={100,100}, value=root:panelcontrol:singlefcpanel:percentcontfitoffset_g, title="ContFit Off"
//Functions like "Deformation calculation" need to search for a point in the curve. 
//"Derivationbase" practically is the 'search for value'	
	Setvariable derivationbase_g, pos={15,495}, limits={-5,100,0.01 }, size={215,215}, value=root:panelcontrol:SingleFCPanel:derivationbase_g, Title="Derivation from Baseline in nm"
	derivationbase_g=0.3
//The accuracy/tolerance of the search command	
	Setvariable contacttolerance_g, pos={15,515}, limits={-5,100,0.01 },size={190,190}, value=root:panelcontrol:SingleFCPanel:contacttolerance_g, Title="Tolerance in nm"
	contacttolerance_g=0.05
//Value for the baseline-tilt-correction in percent.
	setvariable baselinepercent_g, limits={0,100,2}, pos={15,430}, size={215,215}, value=root:panelcontrol:SingleFCPanel:baselinepercent_g, Title="Baseline till X % before Adhesion"
	baselinepercent_g=90
//Please see 'virtual deflection alone' function for details	
	setvariable errorVirtualDefl_g, limits={0,+inf,5}, pos={218,450}, size={40,40}, value=root:panelcontrol:singlefcpanel:errorVirtualDefl_g, Title=" "
	errorVirtualDefl_g=300
//Should the modification be done on both Trace&Retrace (No) or only for Retrace (Yes)	
	checkbox retraceonly, value=0, Title="", variable=root:panelcontrol:singlefcpanel:retraceonly_g, pos={218,473}
//If you want to set the contact point to the jump-in-point of the trace set Yes
	popupmenu DeforCalcChoice, pos={15,580}, size={180,545}, value="Yes;No", title="Use Jump-in-contact"
//Only changes the axis-range in the Graph, to visuallize the contact-point region more closely.	
	checkbox checkcontact, value=0, title="Contact", variable=root:panelcontrol:singlefcpanel:check_contact_g, pos={180,580}, size={150,150}
//Drop-down menu chosing from the 5 different way of contact-point determination included herein.
	popupmenu usecursor_defor, pos={15,610}, size={180,545}, value="Cursors;Deviation;Top2BottomDev;Line-Fits\r (Calc InvOLS);Line-Fits\r (Keep InvOLS)", title="Deformation Calculation"

//Top-most section showing the different ways how to evaluate your force-curve.	
	SetDrawEnv linefgc= (65280,0,0),linethick= 3.00, fillpat= 0
	DrawRect 270,440,975,625
	SetDrawENV fstyle=1, Fsize= 15
	DrawText 722,475, "Fit Panels"
//Opens a new panel supposed to search for sudden force-drops in the force-curve.
//Relict from old projects. Only works partially.
	button maximabut, Title="Find Drop Events", Pos={500,450}, size={130,40}, proc=maximabutton
	Button maximabut fstyle=1, fsize=14
//Opens a new panel employing more advanced ways to calc adhesion properties.	
	button Substratetilts, Title="Adhesion Force\r& Work", pos={500,500}, size={130,40}, proc=UserPanelAdhesionbutton
	button substratetilts fstyle=1, fsize=14
//Since rather rarely used, recalculates the separation from the deformation.	
	button Separation, Title="Calc. Separation", pos={500,550}, size={130,40}, proc=sepabutton
	button separation fstyle=1, fsize=14
//Opens new panel allowing to save the values of the A and B cursor when placed on the Graph.
//Helps for a quick&dirty evaluation of new stuff.	
	button Cursorinfo, Title="Cursor Infromation", pos={500,600}, size={130,20}, proc=cursorinfoPanel
//This is intended to calc and find the part of the force curve which could be treated with hertz-model
//Calcs a log(F) and log(D) and searches for a certain slope.	
	SetDrawENV fstyle=1, Fsize= 15
	DrawText 325,465,"Filter Parameters"
	setvariable lowExpo_g, pos={305,470}, size={160,160}, value=root:panelcontrol:SingleFCPanel:lowExpo_g, title="Lower Limit of Exponent", limits={0,10,0.1}
	setvariable highExpo_g, pos={305,490}, size={160,160}, value=root:panelcontrol:SingleFCPanel:highExpo_g, title="Upper Limit of Exponent", limits={0,10,0.1}
	setvariable logfitsdev_g, pos={326,510}, size={139,139}, value=root:panelcontrol:SingleFCPanel:logfitsdev_g, Title="Accuracy of Log-Fit", limits={0,10,0.01}
	setvariable exponentoffset_g, pos={311,530}, size={154,154}, value=root:panelcontrol:SingleFCPanel:exponentoffset_g, title="Offset Exponent Fit nm"
	setvariable percentContactFit_g, pos={273,550}, size={192,192}, value=root:panelcontrol:SingleFCPanel:percentContactFit_g, title="Percentage of fitted Ind.(% nm)", limits={5,100,5}
	percentcontactfit_g=100
	button ExponentofContact, title="Power Exponent\rin Contact", pos={320,575}, size={130,40}, proc=expoincontactalbutton
	button ExponentofContact fstyle=1, fsize=14
	
//Two panels to characterise brush mechanics and sterics with Mean-Field or Alexander-de-Genes model.
//Relict to Jens Neubauer Master-thesis :)	
	Button OpenMF, Title="Open Mean-Field Panel", pos={660,485}, size={190,40}, proc=MFButtonOpenAL
	Button OpenMf fstyle=1, fsize=14
	Button OpenAdG, Title="Open asym. AdG Panel", pos={660,530}, size={190,40}, proc=AdGButtonOpenAL
	Button openAdG fstyle=1, fsize=14
//Opens a new panel with all included ways to determine mechanical properties from the force-curve.	
	Button OpenEmodul, Title="Open E-Modul Panel", pos={660,575}, size={190,40}, proc=EmodulButtonOpenAL
	button openemodul fstyle=1, fsize=14
//Clear-up botton, deleting all unneccassary wave created while treating data and not needed if finished.
	button FinishFMap, title="Finish \r Force Map", pos={875,455}, size={90,150}, proc=finishFMbutton, fstyle=1, fsize=15
	
	springconst_backup=springconst_g
end

//Extra Panel to closely determine adhesion properties.
function UserPanelAdhesionProperties ()
	string ctrlname
//Similar to main GUI all neccassary input variables&strings are saved as global objects	
	setdatafolder root:panelcontrol:singleFCPanel
	NVAR baselinepercent_adh=root:panelcontrol:singlefcpanel:baselinepercentADH_g
	NVAR numforcecurve_g=Root:panelcontrol:singlefcpanel:numforcecurve_g
	if(stringmatch(num2str(baselinepercent_adh),"NaN")==1)
		variable/G baselinepercentADH_g, sphereradiusADH_g, sampleradiusADH_g, contacttoleranceADH_g, onlyadhforce_g, highlight_adh_g, check_woa_points_g, check_woa_choice_g, recalc_jkr_with_rips_g
		NVAR contacttolerance_G=root:panelcontrol:singlefcPanel:contacttolerance_g, sphereradius_g=root:panelcontrol:fit_panel:sphereradius_g, sampleradius_g=root:panelcontrol:fit_panel:sampleradius_g
		NVAR Recalc_JKR_with_rips_g=root:panelcontrol:singlefcpanel:recalc_jkr_with_rips_g
		contacttoleranceadh_g=contacttolerance_g
		sphereradiusadh_g=sphereradius_g
		sampleradiusadh_g=sampleradius_g		
	endif
	NVAR contacttolerance_G=root:panelcontrol:singlefcPanel:contacttoleranceADH_g, sphereradius_g=root:panelcontrol:singlefcPanel:sphereradiusadh_g, sampleradius_g=root:panelcontrol:singlefcPanel:sampleradiusadh_g
	NVAR baselinePercent=root:panelcontrol:SingleFCpanel:baselinepercentADH_g, wholefolder_g=root:panelcontrol:SingleFCpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR onlyadhesionforce=root:panelcontrol:singlefcpanel:onlyadhforce_g, highlight_adh_g=root:panelcontrol:singlefcpanel:highlight_adh_g
	NVAR check_woa_points_g=root:panelcontrol:singlefcpanel:check_woa_points_g, check_woa_choice_g=root:panelcontrol:singlefcpanel:check_woa_choice_g
	NVAR Recalc_JKR_with_rips_g=root:panelcontrol:singlefcpanel:recalc_jkr_with_rips_g
	SVAR Folderstring_g=Root:panelcontrol:SingleFCPanel:folderstring_g
	baselinepercent=60
//Create the Adhesion panel	
	dowindow/F mechanical_characterisation
	NewPanel/K=1/W=(0,50,250,390)/N=FitPanelAdhesion /host=mechanicsPanel /EXT=0 as "Adhesion Panel"
	dowindow/F fitpanelAdhesion
	SetDrawEnv fstyle=1, fsize=15, textrgb=(0,39168,0)
	Drawtext 50,25, "Adhesion Evaluation"
//To model data the radius of the probing sphere (colloidal probe) needs to be known	
	SetVariable SphereRadiusADH_g, pos={35,50}, size={167,167}, value=root:panelcontrol:singlefcpanel:sphereradiusADH_g, title="Probe Radius in µm"
//Radius of curvature for the sample.
	SetVariable sampleradiusadh_g, pos={27,70}, size={176,176}, value=root:panelcontrol:singlefcpanel:sampleradiusadh_g, title="Sample Radius in µm"
//How much percent of the curve are covered by baseline
	setvariable baselinepercentadh_g, pos={49,110}, size={154,154}, value=root:panelcontrol:singlefcpanel:baselinepercentadh_g, title="Baseline % range", proc=adhesionbuttonalone2scroll
//Tolerance to search for important points within the curve.
	setvariable contacttoleranceadh_g, pos={17,130}, size={186,186}, value=root:panelcontrol:singlefcpanel:contacttoleranceadh_g, title="Serach tolerance in nm", limits={0,50,0.01}, proc=adhesionbuttonalone2scroll
//Another way to browse through the curves within the folder
	setvariable numforcecurve_g, pos={210,290}, size={35,35}, value=root:panelcontrol:singlefcpanel:numforcecurve_g, Title=" ", limits={0,inf,1}
//Drop-down to select the intended Adhesion-model and geometry.
	popupmenu FitModelChoice, pos={61,157}, size={180,180}, value="JKR Model;DMT Model", title="Contact Model"
	popupmenu FitFunctionGeometery, pos={45,183}, size={180,180}, value="Sphere-Plane;Sphere-Sphere", Title="Contact Geometry"
//If classic JKR (only till the first lose of contact) No; if include all rip of events Yes	
	checkbox recalc_jkr_with_rips, value=0, pos={50,210}, title="Recalc JKR inc. Rips", variable=root:panelcontrol:singlefcpanel:recalc_jkr_with_rips_g
//If Yes opens a new input window while evaluating.
	checkbox check_woa_points, value=0, pos={50,230}, title="Check WoA Range", variable=root:panelcontrol:singlefcpanel:check_woa_points_g
//No: both adhesion force&work is determined; Yes: only adhesion force
	checkbox onlyadhesionforce, value=0, pos={50,250}, title="Only Adhesion Force", variable=root:panelcontrol:singlefcpanel:onlyadhforce_g
//If selected the point of max. adhesion, 0-force in contact, and jump-out are visually highlighted.
	checkbox highlight_adh, value=0, pos={50,270}, title="Highlight Points", variable=root:panelcontrol:singlefcpanel:highlight_adh_g
//Start the adhesion evaluation
	button CalcAdhesion, Title="Calc Adhesion", pos={50,290}, size={160,40}, proc=AdhesionbuttonAlone
	button calcadhesion fstyle=1, fsize=14
//If force-curves where measured in a ramp-like fashion (e.g. varying dwells) they can be split.
	button Adhesion_ramp, Title="Split Adhesion Ramp", pos={50,340}, size={160,40}, proc=AdhesionRampButtonAlone
	button Adhesion_ramp fstyle=1, fsize=14
//If the evaluation does not work for the current curve all adhesion values can be set to NotANumber.
	button nanit, title="NaN", pos={200,240}, size={40,40},fColor=(65280,0,0), proc=nanit_adh
end	

//Opens mechanical characterisation panel
function UserPanelFitting_EModulAL ()
//Similar to others all input variables&strings are stored as global objects
	setdatafolder root:
	if(datafolderexists("PanelControl")==0)
		newdatafolder PanelControl
	endif
	setdatafolder root:PanelControl
	if(datafolderexists("Fit_Panel")==0)
		newdatafolder Fit_Panel
		setdatafolder root:PanelControl:Fit_panel
		string/G mess_rc
		variable /G EModulGuess_g, SphereRadius_g, PossionRatio_g, EModOffset_g, temperature_g, brushthicknessMF_g, chaindistanceAdG_g, chaindistanceMF_G, repetionsnumber_g, EffMonomerLength_g, brushthicknessAdG_g,  showMF_fit_g, show_AdG_fit_g
		variable/G percentcontactfit_g, usecurosr_g, sampleradius_g, HertzFitOffset_g, searchfit_g, Fixadhesion_g, UseWorkAdh_g, depthcontactfit_g, mechmodel_g, fitlength_g
		variable/G shellthickness_g
	endif
	setdatafolder root:PanelControl:Fit_panel
	SVAR mess_rc
	NVAR lowExpo_g, HighExpo_g, LogFitSdev_g, percentContactFit_g, EModOffset_g, percentContactFit_g,  showMF_fit_g, show_AdG_fit_g
	NVAr showFit_g=root:panelcontrol:singlefcPanel:showfit_g, usecurosr_g, sampleradius_g, HertzFitOffset_g, searchfit_g, Fixadhesion_g, UseWorkAdh_g
	NVAR depthcontactfit_g, mechmodel_g, fitlength_g, shellthickness_g
	
//Create panel
	DoWindow/F Mechanical_Characterisation
	NewPanel/k=1 /W=(0,50,250,460) /N=FitPanelEMod /host=MechanicsPanel /Ext=0 as "Fit Panel E-Modul"
	DoWindow/F FitPanelEMod
	SetDrawEnv fstyle= 1,fsize= 15, textrgb= (0,12800,52224)
	DrawText 50,25 ,"Fit Young's Modulus"
	SetDrawEnv linefgc= (65280,0,0),linethick= 3.00, fillpat= 0
	DrawRect 270,440,975,625
	SetDrawENV fstyle=1, Fsize= 15
	DrawText 75,45, "Fit Parameters"
//Input probe radius (colloidal probe radius)	
	SetVariable SphereRadius_g, pos={35,50}, size={167,167}, value=root:panelcontrol:fit_panel:sphereradius_g, title="Sphere Radius in µm"
//Input poisson-ratio of the sample. Probe is always assumed to be non-deformable herein.
	SetVariable PossionRatio_g, pos={20,70}, size={182,182}, value=root:panelcontrol:fit_Panel:possionratio_g, title="Poisson Ratio Substrate"
//Guessed E-Modul of the sample to hit the fit of.
	SetVariable Emodulguess_g, pos={34,90}, size={168,168}, value=root:panelcontrol:fit_Panel:emodulguess_g, Title="Guess E-Modul in Pa"
//Sets an deformation offset for the fitting range	
	setvariable EModOffset_g, pos={2,110},  size={210,210}, value=root:panelcontrol:Fit_Panel:EModOffset_g, Title="Offset for Modul fitting in nm", limits={-inf,inf,0.1}
	Emodoffset_g=1
//Input the radius of curvature for the sample.
	Setvariable SampleRadius_g, pos={34,130}, size={161,161}, value=root:panelcontrol:fit_panel:sampleradius_g, title="Sampel Radius in µm"
//In case measureing capsules input the shell-thickness.
	Setvariable Shellthickness_g, pos={34,150}, size={161,161}, value=root:panelcontrol:fit_panel:shellthickness_g, title="Shell thickness in nm"
//Three ways to set the upperlimit in deformation for the fit.
//1. To how many percent of the contact regime should the fit go.	
	setvariable percentcontactFit_G, pos={2,170}, size={230,230}, value=root:panelcontrol:fit_panel:percentcontactfit_g, Title="Percentage of fitted Defor. (% nm)"
//2. Specify a the depht of deformation to be fitted.
	setvariable depthcontactfit_g, pos={10,190}, size={192,192}, value=root:panelcontrol:fit_panel:depthcontactfit_g, Title="Contact Depth to Fit in nm"
//3. Specify the length of the fit, starting from offset or 0.	
	setvariable fitlength_g, pos={64,210}, size={138,138}, value=root:panelcontrol:fit_panel:fitlength_g, Title="Fit Length in nm"
//Display the resulting fit No/Yes
	Checkbox ShowFit, value=0, Title="Show E-Modul Fit", variable=root:panelcontrol:SingleFCPanel:showfit_g, pos={10,345}
//Rahter than useing values to set the fit range use the cursors on the graph.	
	checkbox usecursor, value=0, Title="Use Cursors", variable=root:panelcontrol:fit_panel:usecurosr_g, pos={150,345}
//If using JKR/DMT use the work of adhesion value previously determined as fix (Yes) or leave it as free fitting parameter (No)	
	checkbox fixadhesion, value=0, Title="Fixed Adhesion", Variable=root:panelcontrol:fit_panel:fixadhesion_g, Pos={10,415}
//If using JKR/DMT use the work of adhesion value previously determined as fix (Yes) or leave it as free fitting parameter (No)	
	checkbox useworkadh, value=0, title="Use Work of Adhesion", Variable=root:panelcontrol:fit_panel:useworkadh_g, pos={120,415}
//Use the retrace for the fit instead of trace. Currently of no importance anymore.(I think)	
	checkbox retrace_only, value=0, title="Use Retrace for Fit", variable=root:panelcontrol:singlefcpanel:retraceonly_g, pos={10,435}
//Allow the fit to offset the whole force-curve horizontal (in deformation)	
	checkbox HertzFitOffset, value=0, title="Allow for deformation Offset", variable=root:panelcontrol:fit_panel:hertzfitoffset_g, pos={10,375}
//Choose one of 6 fitting models
	popupmenu FitFunctionChoiceAl, pos={65,235}, size={180,180}, value="Hertz Model;JKR Model;JKR Model 2-Points;DMT Model;Reissner;Maugis", title="Contact Model"
//Choose contact geometry
	popupmenu FitFunctionGeometery, pos={49,263}, size={180,180}, value="Sphere-Plane;Sphere-Sphere", Title="Contact Geometry"
//Save the selected model as variable
	controlinfo/W=MechanicsPanel FitfunctionChoiceal
	mechmodel_g=V_value
//Start mechanical fitting	
	Button CalcEmodul, Title="Fit Young's Modulus", pos={35,295}, size={160,40}, proc=EmodulButtonal
	button calcemodul fstyle=1, fsize=14
//Go to Next force curve	
	button next, title="Next", pos={200,295}, size={40,40},fColor=(0,65280,0), proc=nextfunc
//Redo the old fit with same parameters, as it was done before.
	checkbox searchfit, value=0, title="Keep old fit range", variable=root:panelcontrol:fit_panel:searchfit_g, pos={10,395}
//Set all saved mechanical values for this curve to NotANumber	
	button nanit, title="NaN", pos={200,365}, size={40,40},fColor=(65280,0,0), proc=nanit
//Opens a new panel for showing and inputting error values while using Hertz.	
	button showerrorpanel, title="Show Error Panel", pos={140,435}, size={100,20}, proc=ShowerrorButtonOpenAL
end

//Extra panel for Evaluation of brush-mechanics. A tribute to Jens' master thesis
function UserPanelFitting_AdGAL ()
//Introduce a input variables&strings as global variables.		
	setdatafolder root:
	if(datafolderexists("PanelControl")==0)
		newdatafolder PanelControl
	endif
	setdatafolder root:PanelControl
	if(datafolderexists("Fit_Panel")==0)
		newdatafolder Fit_Panel
		setdatafolder root:PanelControl:Fit_panel
		string/G mess_rc
		variable /G EModulGuess_g, SphereRadius_g, PossionRatio_g, EModOffset_g, temperature_g, brushthicknessMF_g, chaindistanceAdG_g, chaindistanceMF_G, repetionsnumber_g, EffMonomerLength_g, brushthicknessAdG_g,  showMF_fit_g, show_AdG_fit_g
	endif
	setdatafolder root:PanelControl:Fit_panel
	SVAR mess_rc
	NVAR SphereRadius_g, temperature_g, brushthicknessAdG_g, chaindistanceAdG_g, repetionsnumber_g, EffMonomerLength_g,  showMF_fit_g, show_AdG_fit_g
//Create the panel attatched to the right of the GUI.	
	DoWindow/F Mechanical_Characterisation
	NewPanel/k=1 /W=(0,50,255,260) /N=FitPanelAdGasym /host=MechanicsPanel /Ext=0 as "Fit Panel asym. Alexander-de Gennes"
	DoWindow/F FitPanelAdGasym
	SetDrawEnv fstyle= 1,fsize= 15, textrgb= (0,12800,52224)
	DrawText 20,25 ,"Fit asym. Alexander-de Gennes"
	SetDrawEnv linefgc= (65280,0,0),linethick= 3.00, fillpat= 0
	DrawRect 270,440,975,625
	SetDrawENV fstyle=1, Fsize= 15
	DrawText 75,45, "Fit Parameters"
//Radius of the indenting sphere	
	SetVariable SphereRadius_g, pos={51,50}, size={167,167}, value=root:panelcontrol:fit_panel:sphereradius_g, title="Sphere Radius (R) in µm"
//Temperature of the medium, since used in the model	
	SetVariable Temperature_g, pos={69,70}, size={150,150}, value=root:panelcontrol:fit_Panel:temperature_g, title="Temperature (T) in K"
//Guess on brush-thickness to be fitted.	
	SetVariable brushthicknessAdG_g, pos={44,90}, size={175,175}, value=root:panelcontrol:fit_Panel:brushthicknessAdG_g, Title="Brush Thickness (L) in nm"
//Input guess to interchain distance in the brush.	
	setvariable chaindistanceAdG_g, pos={32,110},  size={188,188}, value=root:panelcontrol:Fit_Panel:chaindistanceAdG_g, Title="Interchain Distance (s) in nm", limits={0,inf,0.1}
//Visuallisation checkbox of displaying fit (Yes) or not (No)
	checkbox show_adg_fit_g, value=0, title="Show asym. AdG Fit", variable=root:panelcontrol:Fit_panel:show_adg_fit_g, pos={10,200}
	Button CalcAdG, Title="Fit asym. AdG", pos={50,155}, size={160,40}, proc=AdGButtonal
	button calcAdG fstyle=1, fsize=14
end

//Extra panel for Evaluation of brush-mechanics. A tribute to Jens' master thesis
function UserPanelFitting_MeanFieldAL ()  
//Introduce all input variables&strings as global objects
	setdatafolder root:
	if(datafolderexists("PanelControl")==0)
		newdatafolder PanelControl
	endif
	setdatafolder root:PanelControl
	if(datafolderexists("Fit_Panel")==0)
		newdatafolder Fit_Panel
		setdatafolder root:PanelControl:Fit_panel
		string/G mess_rc
		variable /G EModulGuess_g, SphereRadius_g, PossionRatio_g, EModOffset_g, temperature_g, brushthicknessMF_g, chaindistanceAdG_g, chaindistanceMF_G, repetionsnumber_g, EffMonomerLength_g, brushthicknessAdG_g,  showMF_fit_g, show_AdG_fit_g
	endif
	setdatafolder root:PanelControl:Fit_panel
	SVAR mess_rc
	NVAR SphereRadius_g, temperature_g, brushthicknessMF_g, chaindistanceMF_g, repetionsnumber_g, EffMonomerLength_g,  showMF_fit_g, show_AdG_fit_g
//Create panel right to the main panel	
	DoWindow/F Mechanical_Characterisation
	NewPanel/k=1/EXT=0 /W=(0,200,255,260) /N=FitPanelMeanField /host=MechanicsPanel  as "Fit Panel Mean-Field Theory"
	DoWindow/F FitPanelAdGasym
	SetDrawEnv fstyle= 1,fsize= 15, textrgb= (0,12800,52224)
	DrawText 75,25 ,"Fit Mean-Field"
	SetDrawEnv linefgc= (65280,0,0),linethick= 3.00, fillpat= 0
	DrawRect 270,440,975,625
	SetDrawENV fstyle=1, Fsize= 15
	DrawText 75,45, "Fit Parameters"
//Indenting sphere radius.	
	SetVariable SphereRadius_g, pos={65,50}, size={167,167}, value=root:panelcontrol:fit_panel:sphereradius_g, title="Sphere Radius (R) in µm"
//Temperature of the medium, since involved in fit
	SetVariable Temperature_g, pos={83,70}, size={150,150}, value=root:panelcontrol:fit_Panel:temperature_g, title="Temperature (T) in K"
//Guessed brush thickness.	
	SetVariable brushthicknessMF_g, pos={58,90}, size={175,175}, value=root:panelcontrol:fit_Panel:brushthicknessMF_g, Title="Brush Thickness (L) in nm"
//Number of "monomers" in brush as repetition units in model.
	setvariable repetionsnumber_g, pos={93,110},  size={141,141}, value=root:panelcontrol:Fit_Panel:repetionsnumber_g, Title="Repetion Units (N)" , limits={0,inf,1}
//Effective monomer length, as 3rd input parameter to fit
	setvariable EffMonomerLength_g, pos={12,130}, size={222,22}, value=root:panelcontrol:Fit_Panel:EffMonomerLength_g, Title="Effective Monomer Length (a) in nm"
//Distance between neighbouring anker-groups	
	setvariable chaindistanceMF_g, pos={46,150},  size={188,188}, value=root:panelcontrol:Fit_Panel:chaindistanceMF_g, Title="Interchain Distance (s) in nm", limits={0,inf,0.1}
//Show/dont show fit in graph.
	checkbox showmf_fit_g, value=0, Title="Show Mean-Field Fit", variable=root:panelcontrol:fit_panel:showmf_fit_G, pos={10,230}
	Button CalcMF, Title="Fit Mean-Flied", pos={50,185}, size={160,40}, proc=MeanFieldButtonal
	button calcMF fstyle=1, fsize=14
end

//Extra panel dealing and showing E-Modul error contributions in Hertz Model
function UserPanelShowErrorOpenAL()
//All input variables&strings are stored as global objects
	setdatafolder root:
	if(datafolderexists("PanelControl")==0)
		newdatafolder PanelControl
	endif
	setdatafolder root:PanelControl
	if(datafolderexists("Fit_Panel")==0)
		newdatafolder Fit_Panel
		setdatafolder root:PanelControl:Fit_panel
		variable /G error_SpringConstAbs_g, Error_Invols_g, Error_radiusSample_g, Error_radiusProbe_G, Error_contactPoint_g, Error_shellthickness_g
		variable/G error_springConst_avg, error_invols_avg, error_fit_avg, error_effradius_avg, error_contactpoint_avg, error_shellthickness_avg, error_total_avg
		variable /G average_Emodul
	endif
	setdatafolder root:PanelControl:Fit_panel
	NVAR error_springconstabs_g
	if(numtype(error_springconstabs_g)==2)
		variable /G error_SpringConstAbs_g, Error_Invols_g, Error_radiusSample_g, Error_radiusProbe_G, Error_contactPoint_g, Error_shellthickness_g
		variable/G error_springConst_avg, error_invols_avg, error_effradius_avg, error_contactpoint_avg, error_shellthickness_avg, error_fit_avg, error_total_avg
		variable /G average_Emodul
	endif	
	NVAR error_SpringConstAbs_g, Error_Invols_g, Error_radiusSample_g, Error_radiusProbe_G, Error_contactPoint_g, Error_shellthickness_g
	NVAR numforcecurve=root:panelcontrol:singleFCPanel:numforcecurve_g
	NVAR error_springConst_avg, error_invols_avg,error_effradius_avg, error_contactpoint_avg, error_shellthickness_avg, error_total_avg, error_fit_avg
	NVAR average_emodul
	wave listofbasenames_g=root:panelcontrol:singlefcpanel:listofbasenames_g
//Opening panel right to the main window.
	DoWindow/F Mechanical_Characterisation
	NewPanel/k=1/EXT=0 /W=(0,200,255,430) /N=ShowErrorPanel /host=MechanicsPanel  as "Emodul Error Panel"
	DoWindow/F EModErrorPanel
	SetDrawEnv fsize= 15;DelayUpdate
	DrawText 40,36,"\\f01Error Values Used In Calc."
//Input the error from spring constant calculation; either known or guessed.	
	setvariable error_springconstabs_g, pos={12,50}, size={213,213}, value=root:panelcontrol:fit_panel:error_springconstabs_g, Title="Spring Constant in N/m"
//Display the calced error based only on springconstant.	
	ValDisplay vd1,pos={60,75},size={150,27.00},title="Avg. Error", value=#"root:panelcontrol:fit_panel:error_springconst_avg", fsize=18, live=1, format="%.1f"
//Input the error from INVers Optical Lever Sensitivity determination.
	setvariable error_invols_g, pos={56,110}, size={169,169}, value=root:panelcontrol:fit_panel:error_invols_g, title="InvOLS in nm/V"
//Display calced E-Modul error based only on InvOLS.
	ValDisplay vd2,pos={60,135},size={150,27.00},title="Avg. Error", value=#"root:panelcontrol:fit_panel:error_invols_avg", fsize=18, live=1, format="%.1f"
//Input error for the sample radius	
	setvariable error_radiussample_g, pos={28,170}, size={196,196}, value=root:panelcontrol:fit_panel:error_radiussample_g, title="Sample Radius in µm"
//	ValDisplay vd3,pos={60,205},size={150,27.00},title="Avg. Error", value=_NUM:error_radiussample_avg, fsize=18
//Input error for indenter radius determination.	
	setvariable error_radiusProbe_g, pos={36,190}, size={188,188}, value=root:panelcontrol:fit_panel:error_radiusprobe_g, title="Probe Radius in µm"
//Display calced E-Modul error based on the effective radius (sampel and indenter radius)	
	ValDisplay vd4,pos={60,215},size={150,27.00},title="Avg. Error", value=#"root:panelcontrol:fit_panel:error_effradius_avg", fsize=18, live=1, format="%.1f"
//Input the estimated error/unaccuracy of the contact point determination.
	setvariable error_contactPoint_g, pos={32,250}, size={193,193}, value=root:panelcontrol:fit_panel:error_contactpoint_g, title="Contact Point in nm"
//Display calced E-Modul error based on uncertainty of contact point.
	ValDisplay vd5,pos={60,275},size={150,27.00},title="Avg. Error", value=#"root:panelcontrol:fit_panel:error_contactpoint_avg", fsize=18, live=1, format="%.1f"
//??Input error in shell-thickness derivation.
	setvariable error_shellthickness_g, pos={31,310}, size={193,193}, value=root:panelcontrol:fit_panel:error_shellthickness_g, Title="Shellthickness in µm"
//Display the overall errors combining all errors used above.	
	ValDisplay vd6,pos={60,335},size={150,27.00},title="Avg. Error", value=#"root:panelcontrol:fit_panel:error_shellthickness_avg", fsize=18, live=1, format="%.1f"
	ValDisplay vd3,pos={36,365},size={175,27.00},title="Avg. Fit Error", value=#"root:panelcontrol:fit_panel:error_fit_avg", fsize=18, live=1, format="%.1f"
	ValDisplay vd7,pos={57,395},size={163,27.00},title="Total Error", value=#"root:panelcontrol:fit_panel:error_total_avg",mode=2,barmisc={0,50}, fsize=18, live=1, format="%.1f", limits={0.05*average_emodul,average_emodul,0.5*average_emodul}, lowColor= (0,65535,0),zeroColor= (65535,43690,0)
end

//Button to create an overview graph containing all force-curves in the folder.
function OverviewDisplayButtonAL(ctrlname) :Buttoncontrol
//Basically nothing happens here. 1 NVAR is set to 1.
	string ctrlname
	SVAR foldername=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR overview_g=root:panelcontrol:singlefcpanel:overview_g
	setdatafolder $foldername
	overview_g=1
	Wave/T listofbasenames
	variable i
//UpdateddisplayAL is called for all force-curves sequentially. With overview_g==1 all traces will be ploted in an extra graph.(see function)
	for(i=0;i<numpnts(listofbasenames);i+=1)
		updatedisplayAL(foldername,i)
	endfor
end



//FUnction activated when pressing on the "Nan-It" button in the E-Modul panel.
//Sets the saved mechanical values for the current curve to NaN.
function nanit(ctrlname) :buttoncontrol
	string ctrlname
	NVAR currentnum=root:panelcontrol:singlefcpanel:numforcecurve_g
//Check which mechanical model is currently used.
//Based on the model the save-waves are named differently. Current item there is set NaN.
	controlinfo/W=mechanicspanel#FitPanelEMod FitFunctionChoiceAl
	if(v_value==1)
		wave emoduL_by_hertz, emodul_by_hertz_sdev
		emodul_by_hertz[currentnum]=nan
		emodul_by_hertz_sdev[currentnum]=nan
	elseif(v_value==1||v_value==2)
		wave emodul_by_JKR, emodul_by_jkr_sdev
		emodul_by_JKR[currentnum]=nan
		emodul_by_JKR_sdev[currentnum]=nan
	elseif(V_value==6)
		wave emodul_by_maugis, maugis_alpha, maugis_adhesionF, workofadhesion_MD, maugis_areaundercurve, workadhf_md_rips
		SVAR name=root:panelcontrol:singlefcpanel:namemap_g
		wave fcurve=$name+"maugis"
		emodul_by_maugis[currentnum]=nan
		maugis_alpha[currentnum]=nan
		maugis_adhesionF[currentnum]=nan
		workofadhesion_MD[currentnum]=nan
		workadhf_md_rips[currentnum]=nan
		maugis_areaundercurve[currentnum]=nan
		fcurve=nan
	endif
//The number of the current force curve display is increased by 1 automatically updateing the GUI-graph.
	currentnum+=1
end

//Similar as for NaN-ing the mechanical stuff but for adhesion values
function nanit_adh(ctrlname) :buttoncontrol
	string ctrlname
	NVAR currentnum=root:panelcontrol:singlefcpanel:numforcecurve_g
	wave/T listofbasenames
//Deleting the Appendix of the force-curve names, so it fits for the contactarea appendix
	string basename=listofbasenames[0]	
	basename=basename[0,strlen(basename)-5]
//Introducing the 3 overview adhesion result waves.
	wave adhesion_list, workofadhesion_list
	wave workadh_perArea_list
//Check which adhesion model is chosen to get the correct abreviation.
	controlinfo/W=mechanicspanel#fitpanelAdhesion FitModelChoice
	variable mechmodel=V_value
	if(waveexists($basename+"contactarea")==1)
		wave contactarea=$Basename+"contactarea"
	endif
	if(mechmodel==1)
		wave model=$"workofadhesion_JKR"
	else
		wave model=$"workofadhseion_DMT"
	endif
//NaN all adhesion related values
	adhesion_list[currentnum]=nan
	workofadhesion_list[currentnum]=nan
	contactarea[currentnum]=nan
	model[currentnum]=nan
	workadh_perarea_list[currentnum]=nan
//Increase the current force-curve number by 1 to also refresh the graph with the next curve.
	currentnum+=1
end

//Function determining force-maxima and drop events after maxima in force-curves.
//This evaluation was related to an old study of depletion and structual force measurements.
//Never coded to perfection though...
function maximabutton(ctrlname) :buttoncontrol
	string ctrlname
//Create input variables&strings as global objects	
	setdatafolder root:
	if(datafolderexists("PanelControl")==0)
		newdatafolder PanelControl
		string/g mess_Rc
		variable/G threshold_g, numberofmaxima_g, amountofpnts_g, moreevents_g
	endif
	setdatafolder root:PanelControl
//Make input-panel right to the main panel	
	DoWindow/F MechanicsPanel
	NewPanel/K=1/Ext=0/W=(0,180,225,255) /N=FindDropEvent /host=mechanicspanel as "Find Drop Events"
	DoWindow/F FindDropEvent
	SetDrawEnv linefgc=(65280,0,0), linethick=3.00, fillpat=0
	DrawRect 5,5,220,250
	SetDrawEnv fstyle=1, Fsize=15
	Drawtext 40,30, "Adjusting Parameters"
//Specify input variables and values. Their meaning and function are explained in "magicbutton"&"CalcLocalStiffness"	
	Setvariable threshold_g, pos={30,45}, size={167,167}, value=root:panelcontrol:singlefcpanel:threshold_g, Title="Derviation from 0 slope"
	Setvariable numberofmaximia_g, pos={50,70}, size={147,147}, value=root:panelcontrol:singlefcpanel:numberofmaxima_g, Title="Number of Maxima", limits={0,50,1}
	setvariable amountofpnts_g, pos={43,95}, size={154,154}, value=root:panelcontrol:singlefcpanel:amountofpnts_g, Title="NumPnts in one box", limits={0,inf,10}
	setvariable boxsize_g, pos={55,120}, size={142,142}, value=root:panelcontrol:singlefcpanel:boxsize_g, Title="Boxsize Sumation"
	button SearchDrops, Title="Search Drops", pos={40,145}, size={160,40}, proc=magicbutton
	button CalcStiff, Title="Calc local Stiffness", pos={40,195}, size={160,40}, proc=stiffnessbutton
end
//Button-function related to "Find-Drop Events". Here more variables needed are called and transfered to the main function at the end.
function stiffnessbutton(ctrlname):buttoncontrol
	string ctrlname
//Collecting all needed varialbes to perform the local stiffness calculation.	
	SVAR namemap_g=root:panelcontrol:SingleFCPanel:namemap_g, foldername=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR numforcecurves_g=root:panelcontrol:singlefcpanel:numforcecurve_g, limitsdisplay_g=root:panelcontrol:singlefcpanel:limitsdisplay_g
	wave/T list=root:panelcontrol:singlefcpanel:listofbasenames_g
	setdatafolder $foldername
	variable numpntsmap_g=numforcecurves_g
//Call the function to calc the local stiffness within a single force-curve.	
	calclocalstiffness($list[numforcecurves_g]+"MaxVal",$list[numforcecurves_g]+"MaxDefo",$list[numforcecurves_g]+"MaxPos",list[numforcecurves_g],foldername)
end

//IMPORTANT FUNCTION
//This button function kicks-off all mechanical evaluations.
Function EmodulButtonal(ctrlname) :Buttoncontrol
	string ctrlname
//Set the mechanics panel as active panel to read out some important settings.
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#fitpanelemod
//Read out the status of the fit-type drop-down menu
	controlinfo fitfunctionchoiceal
//The value corresponding to the chosen mechanics-model is saved in fittype
	variable fittype=V_value
//The status of the "use cursor" checkbox is read-out. //Could also be done by the linked global variable. Value is stored in Usecursorvar.
	controlinfo usecursor
	variable usecursorvar=V_value
//Loading all variables stated in the mechanics panel, which are save as global variables in the "singlefcpanel" folder
	NVAR numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g, wholefolder_G=root:panelcontrol:singlefcpanel:wholefolder_G
	NVAR emoduloffset=root:panelcontrol:fit_panel:emodoffset_g, percentcontactfit=root:panelcontrol:fit_panel:percentcontactfit_g, contacttolerance=root:panelcontrol:singlefcpanel:contacttolerance_g
	NVAR Emodulguess=root:panelcontrol:fit_panel:emodulguess_g, sphereradius=root:panelcontrol:fit_panel:Sphereradius_g, possionratio=root:panelcontrol:fit_panel:possionratio_g, sampleradius=root:panelcontrol:fit_panel:sampleradius_g
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR baselinepercent=root:panelcontroL:singlefcpanel:baselinepercent_g, depthcontactfit_g=root:panelcontroL:Fit_panel:depthcontactfit_g, fitlength_g=root:panelcontrol:fit_panel:fitlength_g
	NVAR shellthickness_g=root:panelcontrol:fit_panel:shellthickness_g, contacttoleranceadh=root:panelcontroL:singlefcpanel:contacttoleranceadh_g
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
//Just a backup check if the contacttolerance variable for adhesion is present or not. If not use the same value for adhesion as for baseline and e-modul search.
	if(NVAR_exists(contacttoleranceadh)==0)
		contacttoleranceadh=contacttolerance
	endif
//First level check is if all force-curve in the folder should be treated (wholefolder_g==1) or just a single forcecurve.
	if(wholefolder_g==1)
	//To go through all curve the run-variable i is introduced, the currently display force-curve is set to 0 (first one).
		variable i
		numforcecurve_g=0
	//All curves are sequentially treated by counting up i untill the last one, which is equal to numpnts(listofbasenames)
		for(i=0;i<numpnts(listofbasename);i+=1)
		//If the model-type-check equals 1 Hertz model is selected.
			updatedisplayAL(folderstring_G,i)
			if(fittype==1)
			//Call the EModul Hertz calculation function. Note: It treats the i-th item of listofbasenames.	
				EModulusHertzAlone(listofbasename[i], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,sampleradius,depthcontactfit_g, fitlength_g)
			//To save the results of the Hertz-fitting in overview waves they need to be generated in the first run or be recalled.
			//There names are fixed to the 2 strings below as E-Modul values (="Emodul_by_hertz") and the corresponding standard deviation (="Emodul_by_hertz_sdev")
				string EModulHertz_sdev="EModul_by_Hertz_sdev"
				string EModulHertz="EModul_by_Hertz"
			//In case these waves DO NOT YET EXSIST, they are created.
				if(waveexists($EmodulHertz)==0)
					make/N=(numpnts(listofbasename)) $Emodulhertz, $Emodulhertz_sdev
				endif
			//Introduce the save waves by name AND the hertz results wave for the SINGLE for force-curve created by the function above.
				wave Emod=$Emodulhertz, emod_sdev=$EmodulHertz_sdev, content=$Listofbasename[i]+"Hertz"
			//The result values are transfered from the single measurement waves to the overview one, depending on their run number within listofbasenames.
				Emod[i]=content[0]
				emod_sdev[i]=content[1]
			//The current display number is increased by 1 to see the next curve + the graph gets updated. //Maybe unneccassary for the whole folder call.
				numforcecurve_g=i
				updatedisplayAL(folderstring_g,i)
			endif
		//If model-type-check is 2 or 3 one of the two JKR fit-models is chosen.	
			if(fittype==2||fittype==3)
			//Before JKR mechanical fitting is employed, the workofadhesion function is called. In case it was done before nothing should change.
			//In case WoA_Alone wasn't yet done to the curve it determines some important points in the curve and (if chosen) also the fixed workofadhesion for the fit.
				WorkofAdhesionAlone(listofbasename[i],baselinepercent,contacttoleranceadh,sphereradius,1)
			//The JKR-mechanical fitting function is called including all possible neccassary variables to perform the fit. See details there.
				EModulusJKRAlone(listofbasename[i], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
			//As for Hertz, the important results from the fit are collected in an overview wave for the whole folder with the wavenames introduced as fixed strings.
				string EModulJKR_sdev="EModul_by_JKR_sdev"
				string EmodulJKR="EModul_by_JKR"
				string AdhesionFIT="Adhesion_JKR_Fit"
			//In case these folder-overview waves DO NOT YET exsist they are created.
				if(waveexists($EmodulJKR)==0)
					make/N=(numpnts(listofbasename)) $EmodulJKR, $EmodulJKR_sdev, $adhesionFIT
				endif
			//Include the folder-overview result waves to the function and the one containing all infos for the SINGLE force-curve
				wave EModJKR=$EmodulJKR, emodJKR_SDEV=$EmodulJKR_sdev, contentJKR=$listofbasename[i]+"JKR", adhesion=$adhesionFIT
			//Transfer the values from the single-force-curve-results wave (contentJKR) to the folder-overview ones.
				EmodJKR[i]=contentJKR[0]
				emodJKR_SDEV=contentJKR[1]
				adhesion[i]=contentJKR[4]
			//The current display number is increased by 1 to see the next curve + the graph gets updated. //Maybe unneccassary for the whole folder call.
				numforcecurve_g=i
				updatedisplayAL(folderstring_g,i)
			endif
		//If model-type-check is 4 DMT model is chosen.
			if(fittype==4)
			//As for JKR workofadhesion alone is run before mechanical fitting.
				WorkofAdhesionAlone(listofbasename[i],baselinepercent,contacttoleranceadh,sphereradius,1)
			//The DMT-mechanical fitting function is called including all possible neccassary variables to perform the fit. See details there.
				EModulusDMTAlone(listofbasename[i], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,depthcontactfit_g)
			//See above JKR or Hertz, it's the same stuff.
				string EModulDMT_sdev="EModul_by_DMT_sdev"
				string EmodulDMT="EModul_by_DMT"
				string adhesionDMT="Adhesion_DMT_Fit"
				if(waveexists($EmodulDMT)==0)
					make/N=(numpnts(listofbasename)) $EmodulDMT, $EmodulDMT_sdev, $adhesionDMT
				endif
				wave EModDMT=$EmodulDMT, emodDMT_SDEV=$EmodulDMT_sdev, contentDMT=$listofbasename[i]+"DMT", adhesion=$adhesionDMT
				EmodDMT[i]=contentDMT[0]
				emodDMT_SDEV=contentDMT[1]
				adhesion[i]=contentDMT[4]
				numforcecurve_g=i
				updatedisplayAL(folderstring_g,i)
			endif
		//If model-type-check is 5 Reissner-model is chosen
			if(fittype==5)
			//Start the Reissner fitting by handing down all needed variables stated before.
				EModulusReissnerAlone(listofbasename[i], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g,shellthickness_g)
			//As above results are transfered to folder-overview waves
				string EModulReissner_sdev="Emodul_by_Reissner_sdev"
				string EModulReissner="EModul_by_Reissner"
				if(waveexists($EModulReissner)==0)
					make/N=(numpnts(listofbasename)) $Emodulreissner, $Emodulreissner_sdev
				endif			
				wave emod=$emodulreissner, emod_sdev=$emodulreissner_sdev, content=$listofbasename[i]+"Reis"
				emod[i]=content[0]
				emod_sdev[i]=content[1]
				numforcecurve_g=i
				updatedisplayAL(folderstring_g,i)
			endif
		//If model-type-check is 6 Maugis-model in the "approximation" of Carpick is done.
			if(fittype==6)
			//Start the mechanical evaluation based on maugis theory.
				Maugis_Approximation(listofbasename[i], emoduloffset,percentcontactFit,contacttolerance, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
			//Again save all results in folder-overview waves
				string Maugis="Maugis_alpha"
				if(waveexists($Maugis)==0)
					make/N=(numpnts(listofbasename)) Maugis_alpha, Maugis_adhesionF, workofadhesion_MD, EModul_by_Maugis, Maugis_AreaUnderCurve, Workadhf_md_rips
				endif
				wave maugis_alpha, maugis_adhesionF, workofadhesion_MD, Emodul_by_Maugis, cont_area_MD=$listofbasename[i]+"contrad_ret", Maugis_AreaUnderCurve
				wave maugis_info=$listofbasename[i]+"Maugis", Workadhf_md_rips, workofadhesion_list
				maugis_alpha[i]=maugis_info[1]
				maugis_adhesionF[i]=maugis_info[2]
				workofadhesion_MD[i]=maugis_info[5]
				emodul_by_maugis[i]=maugis_info[7]
				maugis_AreaUnderCurve[i]=maugis_info[11]
			//In case the workofadhesion determined by maugis is NaN or non-exsisting print an error in the command-window with the corresponding force-curve number
				If(numtype(workofadhesion_list[i])==2||workofadhesion_list[i]==-1)	
					print "Error by forcecurve number "+num2str(i)
				else
			//If the evaluation went well, that the area under the retrace (workofadhesion_list) and divide it by the effectiv area determined by maugis-evaluation.
					workadhf_md_rips[i]=workofadhesion_list[i]/pi/maugis_info[12]^2
				endif
			//Update graph.
				updatedisplayAL(folderstring_g,i)
			endif
		endfor
//In case only a single force-curve should be treated, start here.
//Code below is exactly the same as above but without the for-loop and counting through all listofbasenames row.
//Instead the "numforcecurve_g"-th line of listofbasenames is used = currently shown and selected curve
	else
		if(fittype==1)
			EModulusHertzAlone(listofbasename[numforcecurve_g], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,sampleradius,depthcontactfit_g, fitlength_g)
			string EModulHertz_sdev1="EModul_by_Hertz_sdev"
			string EModulHertz1="EModul_by_Hertz"
			if(waveexists($EmodulHertz1)==0)
				make/N=(numpnts(listofbasename)) $Emodulhertz1, $Emodulhertz_sdev1
			endif
			wave Emod=$Emodulhertz1, emod_sdev=$EmodulHertz_sdev1, content=$Listofbasename[numforcecurve_g]+"Hertz"
			Emod[numforcecurve_g]=content[0]
			emod_sdev[numforcecurve_g]=content[1]
		endif
		if(fittype==2||fittype==3)
			WorkofAdhesionAlone(listofbasename[numforcecurve_g],baselinepercent,contacttoleranceadh,sphereradius,1)
			EModulusJKRAlone(listofbasename[numforcecurve_g], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
			string EModulJKR_sdev1="EModul_by_JKR_sdev"
			string EmodulJKR1="EModul_by_JKR"
			string AdhesionFIT1="Adhesion_JKR_Fit"
			if(waveexists($EmodulJKR1)==0)
				make/N=(numpnts(listofbasename)) $EmodulJKR1, $EmodulJKR_sdev1, $adhesionFIT1
			endif
			wave EModJKR=$EmodulJKR1, emodJKR_SDEV=$EmodulJKR_sdev1, contentJKR=$listofbasename[numforcecurve_g]+"JKR", adhesion=$adhesionfit1
			EmodJKR[numforcecurve_g]=contentJKR[0]
			emodJKR_SDEV[numforcecurve_g]=contentJKR[1]
			adhesion[numforcecurve_g]=contentJKR[4]
			updatedisplayAL(folderstring_g,numforcecurve_g)
		endif		
		if(fittype==4)
			WorkofAdhesionAlone(listofbasename[numforcecurve_g],baselinepercent,contacttoleranceadh,sphereradius,2)
			EModulusDMTAlone(listofbasename[numforcecurve_g], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,depthcontactfit_g)
			string EModulDMT_sdev1="EModul_by_DMT_sdev"
			string EmodulDMT1="EModul_by_DMT"
			string adhesionDMT1="Adhesion_DMT_Fit"
			if(waveexists($EmodulDMT1)==0)
				make/N=(numpnts(listofbasename)) $EmodulDMT1, $EmodulDMT_sdev1, $adhesionDMT1
			endif
			wave EModDMT=$EmodulDMT1, emodDMT_SDEV=$EmodulDMT_sdev1, contentDMT=$listofbasename[numforcecurve_g]+"DMT", adhesion=$adhesionDMT1
			EmodDMT[numforcecurve_g]=contentDMT[0]
			emodDMT_SDEV[numforcecurve_g]=contentDMT[1]
			adhesion[numforcecurve_g]=contentDMT[4]
		endif	
		if(fittype==5)
			EModulusReissnerAlone(listofbasename[numforcecurve_g], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g,shellthickness_g)
			string EModulReissner_sdev1="Emodul_by_Reissner_sdev"
			string EModulReissner1="EModul_by_Reissner"
			if(waveexists($EModulReissner1)==0)
				make/N=(numpnts(listofbasename)) $Emodulreissner1, $Emodulreissner_sdev1
			endif
			
			wave emod=$emodulreissner1, emod_sdev=$emodulreissner_sdev1, content=$listofbasename[numforcecurve_g]+"Reis"
			emod[numforcecurve_g]=content[0]
			emod_sdev[numforcecurve_g]=content[1]
		endif
		if(fittype==6)
			Maugis_Approximation(listofbasename[numforcecurve_g], emoduloffset,percentcontactFit,contacttolerance, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
			string Maugis1="Maugis_alpha"

			if(waveexists($Maugis1)==0)
				make/N=(numpnts(listofbasename)) Maugis_alpha, Maugis_adhesionF, workofadhesion_MD, EModul_by_Maugis, Maugis_AreaUnderCurve, workadhf_md_rips
			endif
			wave maugis_alpha, maugis_adhesionF, workofadhesion_MD, Emodul_by_Maugis, cont_area_MD=$listofbasename[numforcecurve_g]+"contrad_ret", Maugis_AreaUnderCurve
			wave maugis_info=$listofbasename[numforcecurve_g]+"Maugis", workofadhesion_list, workadhf_md_rips
			maugis_alpha[numforcecurve_g]=maugis_info[1]
			maugis_adhesionF[numforcecurve_g]=maugis_info[2]
			workofadhesion_MD[numforcecurve_g]=maugis_info[5]
			emodul_by_maugis[numforcecurve_g]=maugis_info[7]
			maugis_AreaUnderCurve[numforcecurve_G]=maugis_info[11]
			If(numtype(workofadhesion_list[numforcecurve_G])==2||workofadhesion_list[numforcecurve_G]==-1)	
				print "Error by forcecurve number "+num2str(i)
			else
				workadhf_md_rips[numforcecurve_G]=workofadhesion_list[numforcecurve_G]/pi/maugis_info[12]^2
			endif
			updatedisplayAL(folderstring_g,numforcecurve_g)
		endif
	endif
end

//Function creating a warning and check window if the springconstant values is changed
//This is to supposed to prevent accidental changing of this values while evaluating.
function springconstwarning(sva) :setvariablecontrol
	struct wmsetvariableaction &Sva
	NVAR springconst_g=root:panelcontrol:singlefcpanel:springconst_g, springconst_backup=Root:panelcontrol:singlefcpanel:springconst_backup
	variable springconstant=springconst_g
//Current value of the spring constant is loaded and shown by "prompting" a new window to open.
	prompt Springconstant, "Is this the correct spring constant in N/m?"
	doprompt "Warning! Sping constant change!", springconstant
//If the window is closed by chanceling the old value is reset.
	if(V_flag==1)
		springconst_g=springconst_backup
//If value is confirmed or changed within the window and window is closed by ok, new values is also transfered to the backup spring constant.
	else
		springconst_backup=springconst_g
	endif
end

//Function is used sometimes to update the currently displayed froce-curve in the graph.
function updateforcecurve1() 
	string ctrlname
//When activated the variables&strings included in the curve to show are loaded.
	SVAR namemap_g=root:panelcontrol:SingleFCPanel:namemap_g, foldername=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR numforcecurves_g=root:panelcontrol:singlefcpanel:numforcecurve_g, limitsdisplay_g=root:panelcontrol:singlefcpanel:limitsdisplay_g
	wave/T list=root:panelcontrol:singlefcpanel:listofbasenames_g
	variable numpntsmap_g=numforcecurves_g
//Short check if everything is done correctly.
//1. Check if there is even a "listofbasenames" wave.
	if(waveexists(list)==0)
		numpntsmap_g=0
	else
		limitsdisplay_g=numpnts(list)-1
	//2. Check if the intended, new force-curve-number is within the range of "listofbasenames"; if not set it to the last possible.
		if(numpntsmap_g>limitsdisplay_g)
			numpntsmap_g=limitsdisplay_g
			numforcecurves_g=limitsdisplay_g
		endif
	//The name of the force-curve which is display is set.
		namemap_g=list[numpntsmap_g]
	//The actuall update of the graph with the chosen settings is done.
		updatedisplayAL(foldername,numforcecurves_g)
	endif
end

//1. Adhesion Calculation triggerd by "Cor. for virtual deflection line &Calc Adhesion" Button. 
function AdhesionbuttonAL(ctrlname) :Buttoncontrol
	string ctrlname
//Introduce the needed global variables&strings also shown in the GUI
	NVAR baselinePercent=root:panelcontrol:SingleFCpanel:baselinepercent_g, wholefolder_g=root:panelcontrol:SingleFCpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	SVAR Folderstring_g=Root:panelcontrol:SingleFCPanel:folderstring_g
//Check the drop-down menu if 'Jump-in' is selected as yes or no.
	controlinfo DeforCalcChoice
	variable jumpto=V_value		//Why are both the same??? 
	variable jumpout=1			//Initially it was "V_Value". dont see a use there anymore.
	setdatafolder $Folderstring_g
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
//In case the "wholefolder" treatment is set:	
	if(wholefolder_g==1)
	//Introducing a run-variable (i) to change values between i and the last item in 'listofbasenames' in a for loop.
		variable i
		for(i=0;i<numpnts(listofbasename);i+=1)
		//Call the Virtual Deflection line correction function and the "normal", "standard", "easy" evaluation of the force of adhesion.
			VirtualDeflectionAlone(listofbasename[i],baselinePercent,jumpto)
			AdhesionAlone(listofbasename[i],jumpout,baselinepercent)
		endfor
//In case only ONE force-curve should be treated.
	else
		VirtualDeflectionAlone(listofbasename[numforcecurve_g],baselinePercent,jumpto)
		AdhesionAlone(listofbasename[numforcecurve_g],jumpout,baselinepercent)
	endif
end

//IMPORTANT FUNCTION
//Here the type and settings for the determination of the contactpoint are made.
function contactbuttonal(ctrlstring)	:buttoncontrol
	string ctrlstring
//Loading all needed global variables&string needed to calculate the contact point of force curves.
	NVAR  wholefolder_g=root:panelcontrol:SingleFCpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR invols_g=root:panelcontrol:singlefcpanel:invols_g, derivationbase_g=root:panelcontrol:singlefcpanel:derivationbase_g
	NVAR percentcontfit_g=root:panelcontrol:singlefcpanel:percentcontfit_g, baselinepercent_g=root:panelcontrol:singlefcpanel:baselinepercent_G
	NVAR contacttolerance_g=root:panelcontrol:singlefcpanel:contacttolerance_g
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	SVAR Folderstring_g=Root:panelcontrol:SingleFCPanel:folderstring_g
	setdatafolder $folderstring_g
//Setting the GUI as active panel to read out settings of 'Use Jump-in' and which type of calculation in the "Deformation calculation" menu is chosen.
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel
//Save menu stati in variables	
	controlinfo DeforCalcChoice
	variable jumpto=V_Value
	controlinfo usecursor_defor
	variable cursordefor=V_Value
	variable invols_contfit
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
//In case all force-curves of the folder should be treated.
	if(wholefolder_g==1)
	//Introduce i as run-variable in for-loops.
		variable i
	//// if and 1. elseif dont seem to make different stuff. Maybe relict from the past...
	//In case "jump-in" is chosen go in
		if(jumpto==1)
			for(i=0;i<numpnts(listofbasename);i+=1)
			//1. Determine the contactpoint based on the jump-in point of the trace. //The jump-in criterium should again be check inside cont.Base
				contactpointBASEalone(listofbasename[i],invols_g,derivationbase_g,baselinepercent_g)
			//2. Calculate the deformation of trace and retrace with the contactpoint found above.	
				DeformationAlone(listofbasename[i],invols_g)
			//3. In case the force-waves of the current force-curve were previously created they will be recalculated base on the current deformation and invols.
				recalc_force(i,invols_g,retraceonly_g)
			endfor
	//In case the contactpoint should be determined based on a certain deflection-deviation from the baseline search from maximal separation in direction of contact.
		elseif(cursordefor==2)
			for(i=0;i<numpnts(listofbasename);i+=1)
			//As above and call the deviation-from-baseline function for all curves.
				contactpointBASEalone(listofbasename[i],invols_g,derivationbase_g,baselinepercent_g)
				DeformationAlone(listofbasename[i],invols_g)
				recalc_force(i,invols_g,retraceonly_g)
			endfor
	//In case the contact point is chosen manually by setting a cursor:
		elseif(cursordefor==1)
			//NOTE: here NO TREATMENT of the WHOLE folder makes sense! Therefore, even if wholefolder is selcted, only the active curve is treated.
				contactpointcursor(listofbasename[numforcecurve_g],invols_g)
				deformationalone(listofbasename[numforcecurve_g],invols_g)
				recalc_force(numforcecurve_g,invols_g,retraceonly_g)
	//In case the contact is determined by searching in the direction of maximal piezo extension to maximum separation for a certain value close to baseline deflection.
		elseif(cursordefor==3)
			for(i=0;i<numpnts(listofbasename);i+=1)
			//As above but the "contact.MaximalDeflection2Baseline" function is called
				contactpointMaxDefl2BASEalone(listofbasename[i],invols_g,derivationbase_g,baselinepercent_g,contacttolerance_g)
				deformationalone(listofbasename[i],invols_g)
				recalc_force(i,invols_g,retraceonly_g)
			endfor	
	//Last cases refer to force-curves reaching constant-compliance = pressing on an undeformable surface.
	//Here the constant-compliance regime is determined. The contact point is the crossing point of a line fit of the baseline and a line-fit of the const. compl.
	//Two ways are possible: cursordefor =4 or 5 then the slope of the const. compli. is used to calc the Invols directly from the current force curve.
	//cursordefor = 6 or 7 the invols stated in the GUI are still used to calc the force-waves.
		elseif(cursordefor>=4)
			for(i=0;i<numpnts(listofbasename);i+=1)
			//In order to check later on the used Invols values 2 folder-overview waves for trace and retrace are created and the results are saved there.
				if(waveexists($"list_invols_tr")==0)
					make/N=(numpnts(listofbasename)) list_invols_tr
				endif
				if(waveexists($"list_invols_re")==0)
					make/N=(numpnts(listofbasename)) list_invols_re
				endif
				wave invols_tr=$"list_invols_tr"
				wave invols_re=$"list_invols_re"
			//Do the double line-fitting contact-point evalution. Resulting trace-invols (if not only retrace is fitted) is handed out of the function.
				invols_contfit=contactpointBaseContFit(listofbasename[i],invols_g,derivationbase_g,percentcontfit_g)
				if(retraceonly_g==0)
					invols_tr[i]=invols_contfit
					invols_re[i]=invols_contfit
				else
					invols_re[i]=invols_contfit
				endif
			//As above deformation and the new force-waves are calculated.
				DeformationAlone(listofbasename[i],invols_contfit)
				recalc_force(i,invols_g,retraceonly_g)
			endfor
		endif
//Same treatment as described above but for single force curves only.		
	else
		if(cursordefor==2)
			contactpointBASEalone(listofbasename[numforcecurve_g],invols_g,derivationbase_g,baselinepercent_g)
		elseif(cursordefor==1)
			contactpointcursor(listofbasename[numforcecurve_g],invols_g)
		elseif(cursordefor==3)
			contactpointMaxDefl2BASEalone(listofbasename[numforcecurve_g],invols_G,derivationbase_g,baselinepercent_g,contacttolerance_g)
		elseif(cursordefor>=4)
			invols_contfit=contactpointBaseContFit(listofbasename[numforcecurve_g],invols_g,derivationbase_g,percentcontfit_g)
			if(waveexists($"list_invols_tr")==0)
				make/N=(numpnts(listofbasename)) list_invols_tr
			endif
			if(waveexists($"list_invols_re")==0)
				make/N=(numpnts(listofbasename)) list_invols_re
			endif
			wave invols_tr=$"list_invols_tr"
			wave invols_re=$"list_invols_re"
			if(retraceonly_g==0)
				invols_tr[numforcecurve_g]=invols_contfit
				invols_re[numforcecurve_g]=invols_contfit
			else
				invols_re[numforcecurve_g]=invols_contfit
			endif
			
			invols_g=invols_contfit
		endif
		DeformationAlone(listofbasename[numforcecurve_g],invols_g)
		recalc_force(numforcecurve_g,invols_g,retraceonly_g)
	endif
//Updated the graph display to see the result.
	updatedisplayAL(Folderstring_g,numforcecurve_g)
end

//Function recalculating the force wave of a single curve. This may be need when InvLOS intentionally change during evaluation.
//E.g. when the constant compliance regime is used or an former error in InvOLS needs to be resolved.
function recalc_force(numforcecurve,invols,retraceonly_g)
	variable numforcecurve, invols, retraceonly_g
//Load all input variables&strings; partially from direct input and from global objects
	invols*=1e-9
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g  
	NVaR Springconst=root:panelcontrol:singlefcpanel:springconst_g
	string forcecurve=listofbasename[numforcecurve]
//Checkfoldercontent is another user function described elsewhere. Basically it reads the waves already in the Igor folder and checks for the endings.
//A string "content" is created with all possible force curve types and states afterwards if this type is present (1) or not there (0).
	string content=checkfoldercontent(forcecurve)
	string forcecurvecut=forcecurve
//Safety check, if Deflection Volt or force for the called force curve is existing. //Force check seems unneccessary.
	if(numberbykey("deflv",content,":",";")==1||numberbykey("Force",content,":",";")==1)
		if(numberbykey("deflv",content,":",";")==1)
		//Include the Defleciton Volts waves for trace (ext) and retrace (ret)
			wave defl_re=$forcecurve+"DeflV_Ret"
			wave defl_tr=$forcecurve+"DeflV_Ext"
		//Duplicate with forced overwrite the defl to force waves and recalc the force with current InvOLS and springconstant.
			duplicate/O defl_re $forcecurve+"Force_Ret"
			wave force_re=$forcecurve+"Force_Ret"
			force_re*=invols*springconst
		//Also do it for Trace
			duplicate/o defl_tr, $forcecurve+"Force_Ext"
			wave force_tr=$forcecurve+"Force_Ext"
			force_tr*=invols*springconst
		//The basename of the force curve is checked, if it has more than 20 characters; if so the name is shorten to avoid nameing issues.
			if(strlen(forcecurve)>19)
				forcecurveCUT=forcecurve[3,strlen(forcecurve)]
			endif
		//In case there is a baseline corrected Deflection wave recalc the baseline corrected Force wave.
		//In case of retrace it is always checked and done.
			if(waveexists($forcecurvecut+"DeflV_ret_co")==1)
				wave defl_re_co=$forcecurvecut+"DeflV_Ret_co"
				duplicate/o defl_re_co, $Forcecurvecut+"Force_Ret_co"
				wave force_re_co=$forcecurvecut+"Force_Ret_co"
				force_re_co*=invols*springconst
			endif
		//Same as above, but in case only retraces are modified (retraceonly =1) the trace should NOT be renewed.
			if(retraceonly_g!=1&&waveexists($Forcecurvecut+"DeflV_ext_co")==1)
				wave defl_tr_co=$forcecurveCUT+"deflv_ext_co"	
				duplicate/O defl_tr_co, $forcecurvecut+"Force_Ext_co"	
				wave force_tr_co=$forcecurvecut+"Force_ext_co"
				force_tr_co*=invols*springconst
			endif
		endif
	endif 
end

//Button corresponding to the Filter Parameters section "Power Exponent in Contact".
//Just kicks-off the contactexponentalone function with envirnoment parameters
function expoincontactalbutton(ctrlstring) :Buttoncontrol
	string ctrlstring
//Load input variables&strings from global objects.
	svar folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	setdatafolder $folderstring_g
//Contacttolerance: is the tolerance allowed for searching start&end point in the forcecurve. Exponentoffset: start offset deformation allowed for fitting contact regime
//Fitmaximium: Percentage value of how deep the deformation is fitted. Contactdepth: Alternativ to percentage absolute value of max deformation to fit.
	NVAR contacttolerance=root:panelcontrol:singlefcpanel:contacttolerance_g, exponentoffset=root:panelcontrol:singlefcpanel:exponentoffset_g, fitmaximum_g=root:panelcontrol:singlefcpanel:percentcontactfit_g
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g, contactdepth_g=root:panelcontroL:fit_panel:depthcontactfit_g
	variable absolutvalue, fitmaximum
//Check if contactdepth is set or not. If so use absolut value.
	if(contactdepth_g!=0)
		fitmaximum=contactdepth_g
		absolutvalue=1
	else
		fitmaximum=fitmaximum_g
	endif
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
//Call the main function either all curves at once or only one.
	if(wholefolder_g==1)
		variable i
		for(i=0;i<numpnts(listofbasename);i+=1)
			contactexponentalone(listofbasename[i],contacttolerance,exponentoffset,fitmaximum,absolutvalue,0)
		endfor
	else
		contactexponentalone(listofbasename[numforcecurve_g],contacttolerance,exponentoffset,fitmaximum,absolutvalue,0)
	endif
end

//Button to start the calculation of the separation waves of force curves.
function sepabutton(ctrlstring) : Buttoncontrol
	string ctrlstring
//Load input variables&strings.
	svar folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	setdatafolder $folderstring_g
	NVAR wholefolder_G=root:panelcontrol:singlefcpanel:wholefolder_G, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR percentcontfit_g=root:panelcontrol:singlefcpanel:percentcontfit_g
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_G
//Call the main function either for all curves at once or only one at a time.
	if(wholefolder_g==1)
		variable i
		for(i=0;i<numpnts(listofbasename);i+=1)
			calcseparation(listofbasename[i],percentcontfit_g)		
		endfor
	else
		calcseparation(listofbasename[numforcecurve_g],percentcontfit_g)
	endif
end

//Update button, somehow neccassary to call the standard updatedisplay function.
function updateDisplaybuttonAL(ctrlname) :buttoncontrol
	string ctrlname
	NVAR numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR overview_g=root:panelcontrol:singlefcpanel:overview_g
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	overview_g=0
	if(datafolderexists(folderstring_g)==1)
		updatedisplayAL(folderstring_g,numforcecurve_g)
	else
		print "No such data folder exists"
	endif
end

//Just calls the clearwaves function, which deletes all remaining waves from other functions which are not needed anymore.
function finishFMbutton(ctrlname) :buttoncontrol
	string ctrlname
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	wave/T listofbasenames=root:panelcontrol:singlefcpanel:listofbasenames_g
	setdatafolder $folderstring_g
	clearwaves(listofbasenames)
end

//One of the most compelx functions. Defines all the neccassary conditions of which and how force curves are displayed in the graph window.
function updatedisplayAL(foldername,forcecurvenumber)
	string foldername 
	variable forcecurvenumber
//Foldername and Forcecurvenumber define what the basename of the curve is.
//Forcecurvecut contains a potential shrunken basename string. Needed when basename is to long so endings like "force_co_ext" would expand the allowed wavename length.
	string forcecurvecut
//Global variables and strings are included to the funciton.
	NVAR springconstant_g=root:panelcontrol:singlefcPanel:springconst_g, invols_g=root:panelcontrol:singlefcPanel:Invols_G
//Overview: make an GUI-external overview plot (=1) or update the GUI-graph (=0)	
	NVAR overview_g=root:panelcontrol:singlefcpanel:overview_g
//Bring the GUI to front and set it as activ window so it can be modified.
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay
	setdatafolder $foldername
//Showdefor: display deformation as x wave(=1) or Zsnsr/Raw (=0); Showfit: display mechanical fits.
	NVAR showdefor_g=root:panelcontrol:singlefcpanel:showdefor_g, showfit_g=root:panelcontrol:singlefcpanel:showFit_g
//Showforce: display force as y wave(=1) or Deflection volt (=0); ShowdeflCor: display baseline corrected curves(Force&Defl) (=1) or raw Deflection Volt (=0)
	NVAR showforce_g=root:panelcontrol:singlefcpanel:showforce_g, showdeflCOR_g=root:panelcontrol:singlefcpanel:showdeflCOR_g
//Showsepa: display separation as x wave(=1) or Zsnsr/raw (=0); Showlog: display log log curves (don't think it works right now)	
	NVAR showsepa_g=root:panelcontrol:singlefcpanel:showsepa_g, showlog_g=root:panelcontrol:singlefcpanel:showlog_g
//Retraceonly: for some combinations retraces are not ploted (=0) but will with =1; Highlight_adh: Displays 3 important points of adhesion and the area under retrace (=1)
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g, highlight_adh_g=root:panelcontrol:singlefcpanel:highlight_adh_g
//Showdwell: Displays dwell parts of force curves(=1); Check_contact: while checking the contact point it offers a closer zoom-in to the current ContPoint (=1)	
	NVAR showdwell_g=Root:panelcontrol:singlefcpanel:show_dwell_g, check_contact_g=root:panelcontrol:singlefcpanel:check_contact_g
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
//Check which types of wave have been calculated sofar.	
	string content=checkfoldercontent(listofbasename[forcecurvenumber])	//Check Mechdisplay for upto 6 traces displayed and delete all of them
//Creates a list of all waves currently display in the GUI-graph; currently just used to remove the traces from graph
	getwindow mechanicspanel#mechdisplay, wavelist
	wave/T w_wavelist
//Variables needed later.	
	variable fitMech
	variable numberoftrace=0
//Check if a single graph update or a overview graph is intended.
	if(overview_g==0)
	//For single graph: repeat deleteing traces on graph until it's empty.
		do
		//Tracesongraph becomes a string with all tracenames on the GUI graph.
			string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
		//In case the string is not 0, there are still traces on the graph.
			if(strlen(tracesongraph)>0)
			//Remove the first trace in the list and redo.
				removefromgraph $stringfromlist(0,tracesongraph,";")
			endif
	//When tracesongraph is 0 there are no more traces on the graph and the loop is done.
		while(strlen(tracesongraph)>0)
//For Overview graphs:
//1. if tracenamelist of the graph call "overview" has zero length there is no trace on the graph or no such graph exists.
	elseif(strlen(tracenamelist("Overview",";",1))==0)
	//Make a new graph call "overview"
		display/N=overview
//2. there are already traces on the graph and the "overview button" calls this function again, since also forcecurvenumber>0
	elseif(strlen(tracenamelist("Overview",";",1))>0&&forcecurvenumber>0)
	//Just bring the Overview graph to front so the "appendtograph" command works on this graph.
		dowindow/F Overview
//3. In case the overview button calls this the first time (forcecurvenumber=0) but there is an old overview graph (there are already traces on it)
	elseif(strlen(tracenamelist("Overview",";",1))>0&&forcecurvenumber==0)
	//Kill the old overview-graph (all old traces are gone) and make a new one.
		killwindow Overview
		display/N=overview
	endif
//This do loop does not "loop" anything! Just here to be able to use the "break" command.
do	
//A variable "towd" (towards) is created and it is check if there is a dwell wave present in the folder.
	variable towd
	if(numberbykey("towd",content,":",";")==1)
		towd=1
	endif
//The basename of the current force curve is extraced from the listofbasenames
	string forcecurve=listofbasename[forcecurvenumber]
//Strings for x&y axis are stated. *_name are the axis names displayed on the graph. The others are to change trace colors.
	string x_axis_name, y_axis_name, y_axis_re2, y_axis_tr2, y_axis_to2
//Check for potential overlength of basenames.
	if(strlen(forcecurve)>19)
	//In case they are to long, the curves are shorten in the beginning to still have the suffix present. (Same fashion as in other functions)
		forcecurveCUT=forcecurve[3,strlen(forcecurve)]
	else
	//If the length is ok, the basename is just transfered to another string. This way you only need *cut later on.
		forcecurveCut=forcecurve
	endif
///Here the respected waves of the basename are selected to be display depending on the global variables selcted in the Update-section of GUI.
//1. Check if x axis should be Deformation (*Defor_*)
	if(showdefor_g==1)		
		wave x_axis_tr=$forcecurve+"Defor_ext"		//new +cut
		wave x_axis_re=$forcecurve+"Defor_ret"		//new +cut
	//Not really sure why this is here... But basically everytime there is a retrace and it is also always made in the deformation function.
		if(waveexists(x_axis_re)==0)		//??
			break
		endif
	//In case there is a dwell in the curve also introduce the deformation-dwell wave.
		if(towd==1)
			wave x_axis_to=$forcecurve+"Defor_towd"//new +cut
		endif
	//Set the name to be displayed on the graph axis.
		x_axis_name="Deformation \\u "
//If deformation is not selected display the piezomovement either as "raw" or "ZSnsr" (what ever measured)	
	else
	//Check content string (see above) if Raw or ZSnsr waves are present and include there trace and retrace waves.
	//Errors are just there as "short-cuts" to check for which kind of dwell wave should be looked in case.
		variable error1, error2
		if(numberbykey("raw",content,":",";")==1)
			wave x_axis_re=$forcecurve+"Raw_Ret"
			wave x_axis_tr=$forcecurve+"Raw_Ext"
		else
			error1=1
		endif
		if(numberbykey("ZSnsr",content,":",";")==1)
			wave x_axis_re=$forcecurve+"ZSnsr_Ret"
			wave x_axis_tr=$forcecurve+"zsnsr_ext"
		else
			error2=1
		endif
	//If there are dwell curve there waves are included.
		if(towd==1)
			if(error1==0)
				wave x_axis_to=$forcecurve+"Raw_Towd"
			elseif(error2==0)
				wave x_axis_to=$forcecurve+"ZSnsr_Towd"
			endif
		endif
	//The corresponding x-axis name is "displacement". Meant in the sense of piezo displacement.
		x_axis_name="Displacement / \\u"
	endif
//Check if forces should be display or raw piezo-deflection.	
	if(showforce_g==1)
	//Check if there are already any kind of force-waves present. If not they will be created when called later on.
		if(numberbykey("ForceCo",content,":",";")==1||numberbykey("Force",content,":",";")==1) //eig 1 ,1
		//If there are baseline corrected force-waves and the defl.-correction is selected.
			if(numberbykey("ForceCo",content,":",";")==1&&showdeflcor_G==1)	//Showdeflcor added 171107
			//Actually already done above and now is redone.	
				if(strlen(forcecurve)>19)
					forcecurveCUT=forcecurve[3,strlen(forcecurve)]
				else
					forcecurveCut=forcecurve
				endif
			//Include the force trace and retrace waves.
				wave y_axis_re=$forcecurvecut+"Force_Ret_co"
				wave y_axis_tr=$forcecurvecut+"Force_Ext_co"
			//Save the traces names in strings to later on alter there tracestyle.
				y_axis_re2=forcecurvecut+"force_ret_co"
				y_axis_tr2=forcecurvecut+"force_ext_co"
			//Include dwell wave if present.
				if(towd==1)
					wave y_axis_to=$forcecurvecut+"Force_Towd_c"
					y_axis_to2=forcecurvecut+"Force_Towd_c"
				endif
		//In case there are no baseline corrected force-wave or they shouldn't be display, display the unmodified force-waves.
			else
			//Include trace, retrace and dwell waves and wavenames.
				wave y_axis_re=$forcecurve+"Force_Ret"
				wave y_axis_tr=$forcecurve+"Force_Ext"
				y_axis_re2=forcecurve+"force_ret"
				y_axis_tr2=forcecurve+"force_ext"
				if(towd==1)
					wave y_axis_to=$forcecurve+"force_towd"
					y_axis_to2=forcecurve+"force_towd"
				endif
			endif
	//In case there are not yet force-waves but should be displayed -> make the force waves.
		else
		//Double check if there are really no force-waves present.
			if(waveexists($forcecurve+"Force_ext")==0)		
			//Actually already done above and now is redone.
				if(strlen(forcecurve)>19)
					forcecurveCUT=forcecurve[3,strlen(forcecurve)]
				else
					forcecurveCut=forcecurve
				endif
			//Include the unmodified Deflection Volt waves -> duplicate the wave and name them *force_*	
				wave defl_ext=$forcecurve+"DeflV_Ext"
				duplicate/O defl_ext, $forcecurve+"Force_Ext"	
				wave defl_ret=$forcecurve+"DeflV_ret"
				duplicate/O defl_ret, $forcecurve+"Force_Ret"
				wave y_axis_tr=$forcecurve+"Force_ext"
				wave y_axis_re=$forcecurve+"Force_ret"
			//Multiply the deflection Volts with InvOLS and springconstant == force
				y_axis_tr*=springconstant_g*invols_g*1e-9
				y_axis_re*=springconstant_g*invols_g*1e-9
				if(towd==1)
					wave defl_to=$forcecurve+"DeflV_towd"
					duplicate/O defl_to $forcecurve+"Force_Towd"
					wave force_to=$forcecurve+"Force_Towd"
					force_to*=springconstant_g*invols_g*1e-9
				endif
			//Save then name for the retrace to change color in the end.
				y_axis_re2=forcecurvecut+"force_ret"
			//In case there are corrected deflection waves but no force-waves (when unmod force is non-existing there shouldnt be corrected ones)
				if(waveexists($forcecurvecut+"Force_ext_co")==0&&waveexists($forcecurvecut+"DeflV_ext_co")==1)	//eig 0
				//Include the modified deflection waves duplicate them and rename them to *force_*
					wave defl_ext_co=$forcecurvecut+"DeflV_ext_co"
					wave defl_ret_co=$forcecurvecut+"DeflV_ret_co"
					duplicate/O defl_ext_co, $Forcecurvecut+"Force_ext_co"
					duplicate/O defl_ret_co, $Forcecurvecut+"Force_ret_co"
					wave y_axis_tr=$Forcecurvecut+"force_ext_co"
					wave y_axis_re=$forcecurvecut+"force_ret_co"
					y_axis_re2=forcecurvecut+"force_ret_co"
					if(towd==1)
						wave defl_to_co=$forcecurvecut+"Deflv_towd_c"
						duplicate/O defl_to_co $forcecurvecut+"Force_towd_c"
						wave force_to_co=$forcecurvecut+"Force_towd_c"
						force_to_co*=springconstant_g*invols_g*1e-9
					endif
				endif		
			//Again multiply the new force-wave(currently in volts) with InvOLS and springconstant to get real force waves.		
				y_axis_tr*=springconstant_g*invols_g*1e-9
				y_axis_re*=springconstant_g*invols_g*1e-9
		//Not sure if this else makes sense. It would mean that there are force waves for the basename present but the content function does not state them...
		//Should never be used and therefore not alter anything...
			else
				if(waveexists($forcecurvecut+"Force_ext_co")==1)
					wave y_axis_tr=$Forcecurvecut+"force_ext_co"
					wave y_axis_re=$forcecurvecut+"Force_ret_co"
					y_axis_re2=forcecurvecut+"force_ret_co"
					if(towd==1)
						wave y_axis_to=$forcecurvecut+"Force_towd_c"
						y_axis_to2=forcecurvecut+"force_towd_c"
					endif
				else
					wave y_axis_tr=$forcecurve+"force_ext"
					wave y_axis_re=$forcecurve+"force_ret"
					y_axis_re2=forcecurve+"force_ret"
					if(towd==1)
						wave y_axis_to=$forcecurve+"Force_towd"
						y_axis_to2=forcecurve+"force_towd"
					endif					
				endif		
			endif	
		endif
	//Check the order of magnitude of the Force values to get the right unit on the y-axis.
		if(y_axis_tr[numpnts(y_axis_tr)-1]<1e-6)
			y_axis_name="Force\\u#2 / nN"
		elseif(y_axis_tr[numpnts(y_axis_tr)-1]<1e-3)
			y_axis_name="Force\\u#2 / µN"
		elseif(y_axis_tr[numpnts(y_axis_tr)-1]<1)
			y_axis_name="Force\\u#2 / mN"
		endif
//Showforce is not selected(=0)		
	else
	//Check if the baseline corrected waves should be displayed.
		if(showdeflCOR_g==1)
		//Again check the basename length and shrink it.
			if(strlen(forcecurve)>19)
				forcecurveCUT=forcecurve[3,strlen(forcecurve)]
			else
				forcecurveCut=forcecurve
			endif
		//Include the waves to the function.
			wave y_axis_tr=$forcecurveCut+"DeflV_Ext_co"
			wave y_axis_re=$forcecurveCut+"DeflV_ret_co"	
			y_axis_re2=forcecurveCut+"DeflV_ret_co"		
			if(towd==1)
				wave y_axis_to=$forcecurvecut+"deflv_towd_c"
				y_axis_to2=forcecurvecut+"deflv_towd_c"
			endif		
	//In case the modified waves shouldnt be display = take the raw defleciton volts.
		else
			wave y_axis_tr=$forcecurve+"DeflV_ext"
			wave y_axis_re=$forcecurve+"Deflv_ret"
			y_axis_re2=forcecurve+"Deflv_ret"
			if(towd==1)
				wave y_axis_to=$forcecurve+"deflv_towd"
				y_axis_to2=forcecurve+"deflv_towd"
			endif		
		endif
	//In both cases the y-axis is name Deflection / V	
		y_axis_name="\\u#2Deflection / V"
		
	endif
//So far less used, but if separation should be displayed.
	if(showsepa_g==1)
		wave x_axis_tr=$forcecurvecut+"Sepa_ext"
		wave x_axis_re=$forcecurvecut+"Sepa_ret"

		x_axis_name="\\u#2Separation nm"
	endif
///Selction of which kind of "basic" waves should be shown in the graph.
//Set the GUI graph to active	
	setactivesubwindow MechanicsPanel#Mechdisplay
//Append both selected trace and retrace to graph.
	appendtograph y_axis_tr vs x_axis_tr
	appendtograph y_axis_re vs x_axis_re
//Change the color of the retrace to blue. (Note: when working with traces on a graph no waves can be used.
	ModifyGraph rgb($y_axis_re2)=(0,12800,52224)
//In case dwells should be shown they are appended and colored green.	
	if(showdwell_g==1)
		appendtograph y_axis_to vs x_axis_to
		MOdifygraph rgb($y_axis_to2)=(0,65535,0)
	endif
///From here on the display style of the traces is change, some may be removed, some evaluation or fitting traces are added and the zoom is varied.
//Mode=3 is "display traces as markers"
	Modifygraph mode=3	
//In case x-axis is separation remove the retrace (formerly not needed when looking at separation.
	if(showsepa_g==1)
		if(retraceonly_g==0)
			removefromgraph $Forcecurvecut+"Force_ret_co"
		endif
	//Set the graph zoom; here close to the surfaces.
		setaxis bottom -5e-9,0.25e-7
		setaxis left -1e-9,15e-9
	endif
//If showfit is selected in the "display control" mechanical fits are displayed.
	if(showfit_g==1)
	//1. the kind of model currently active is checked in the mechanical-fit panel.
		setactivesubwindow MechanicsPanel#fitpanelemod
		controlinfo fitfunctionchoiceal
		variable fittype=V_value
		fitmech=V_value
	//Reset the active window to the graph window.
		setactivesubwindow MechanicsPanel#Mechdisplay
	//Fittype=1 means Hertz fit.
		if(fittype==1)
		//A blank textbox is created and filled later.
			textbox/K/N=text0
		//The baseline corresponding Hertz-results wave is included to extract information.
			wave hertz=$forcecurvecut+"Hertz"
		//The name of the hertz fit wave and the recalculated Hertz deformation (HFIT_D) and Hertz-force (HFIT_F) are included.
			string fit_name="HertzFit"+forcecurvecut
			string HFIT_D=forcecurvecut+"HFIT_D", HFIT_F=forcecurvecut+"HFit_F"
		//If the fit was already done and there are fit waves. (It's possible that no fit is yet done but showfit is selected; would result in an error)
			if(waveexists($Hfit_d)==1)
				appendtograph $hfit_f vs $Hfit_D
			//Include the folder-overview waves for the contact exponent and the E-moduli from Hertz evaluation.
				wave exponent=$forcecurvecut+"expo"
				wave hertzwave=$"Emodul_by_hertz"
			//Change the textbox text to show relavent information about the fit-results.
				TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(hertz[0])+" ± "+num2str(hertz[1])+" Pa\rContact Slope: "+num2str(exponent[0])+" ± "+num2str(exponent[1])+" \rSaved E-Modul: "+num2str(hertzwave[forcecurvenumber])
			//Appends a "color-code" box showing quick info about the contact exponent. 
			//Is the exponent between 1.45 - 1.48 or 1.52 - 1.55 == organe box
				if((1.45<exponent[0]&&exponent[0]<1.48)||(1.52<exponent[0]&&exponent[0]<1.55))
					TextBox/C/N=text2/B=(65280,43520,0) "        \r           "
			//Between 1.48 - 1.52 == green box
				elseif(1.48<exponent[0]&&exponent[0]<1.52)
					TextBox/C/N=text2/B=(0,65280,0) "        \r           "
			//Below 1.45 or above 1.55 == red box
				else
					TextBox/C/N=text2/B=(65280,0,0) "        \r           "
				endif
			endif
		//Append the hertz-fit to the graph, change color, increase line-thickness.
			if(waveexists($fit_name)==1)
				appendtograph $fit_name
				modifygraph rgb($fit_name)=(0,39168,0), lsize($fit_name)=1.5
			//The A&B cursors are placed on the force-trace on the position of fit-start and -end. Note: helps when checking a fit and changing the position in cursor mode.
				cursor/P A $y_axis_tr2 Hertz[2]
				cursor/P B $y_axis_tr2 Hertz[3]
		//In case no fit is yet performed (or it resulted in an fitting-error) the cursors are placed on (random) 20 and 80% of deformation.
			else
				cursor/P A $y_axis_tr2, round(0.2*numpnts(y_axis_tr))
				cursor/p B $y_axis_tr2, round(0.8*numpnts(y_axis_tr))
			endif
		//Fitlimits are later used to set the zoom in the graph.
			wave fitlimits=$forcecurvecut+"Hertz"
	//Fittype =2/3 == JKR fits.
		elseif(fittype==2||fittype==3)
		//Append a textbox, state the names of the JKR-fit waves and the jkr-adhesion wave.
			textbox/K/N=text0
			string fit_nameJKR="JKRfit"+forcecurvecut
			string JFIT_F=forcecurvecut+"JKRFIT_F", JFIT_D=forcecurvecut+"JKRFIT_D"
			wave jkr_info=$forcecurvecut+"JKR"
			wave adhesionF=$forcecurvecut+"adhf"
		//This checks for the acutall JKR-fit, Can be appended, currently off.
			if(waveexists($fit_nameJKR)==1)
			//	appendtograph $fit_nameJKR
			//	modifygraph rgb($fit_nameJKR)=(0,39168,0), lsize($fit_nameJKR)=1.5
			endif	
		//If the recalculated JKR-Force and JKR-Deformation are present, append them, change style and set cursors on the graph.
			if(waveexists($JFIT_F)==1)
				appendtograph $JFIT_F vs $JFIT_D
				modifygraph rgb($JFIT_F)=(65535,65535,0), lsize($JFIT_F)=2
				cursor/P A $y_axis_re2 JKR_info[2]
				cursor/P B $y_axis_re2 JKR_info[3]
		//If no JKR-fit waves are present, set cursors to 20 and 80% of retrace deformation.
			else
				cursor/P A $y_axis_re2, round(0.2*numpnts(y_axis_re))
				cursor/p B $y_axis_re2, round(0.8*numpnts(y_axis_re))
			endif
		//Textbox is filled with selected fit-results.
			wave fitlimits=$forcecurvecut+"JKR"
			if(waveexists(fitlimits)==1)
				Textbox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(fitlimits[0])+" ± "+num2str(fitlimits[1])+" Pa"+"\rFitted Force of Adhesion :"+num2str(jkr_info[4])+"N vs True :"+num2str(adhesionF[0])+" N"
			endif
	//fittype=4 is DMT. Since only rarely used only a standard display is yet included.
		elseif(fittype==4)
			string fit_nameDMT="DMTFit"+forcecurvecut
			if(waveexists($fit_nameDMT)==1)
				appendtograph $fit_nameDMT
				modifygraph rgb($fit_nameDMT)=(0,39168,0), lsize($fit_nameDMT)=1.5
			endif
	//Fittype=5 is Reissner Model
		elseif(fittype==5)
		//Textox is created, Fit-Result waves and Fit-wave names are included.
			textbox/K/N=text0
			wave reissner=$forcecurvecut+"Reis"
			string fit_nameREIS="ReisFit"+forcecurvecut
			string RFIT_D=forcecurvecut+"RFIT_D", RFIT_F=forcecurvecut+"RFit_F"
		//In case recalculated Reissener-deformation wave is present.
			if(waveexists($Rfit_d)==1)
			//Append Reissner-Fit recalculated waves, fill the text box with results.
				appendtograph $Rfit_f vs $Rfit_D
				wave exponent=$forcecurvecut+"expo"
				TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(reissner[0])+" ± "+num2str(reissner[1])+" Pa\rContact Slope: "+num2str(exponent[0])+" ± "+num2str(exponent[1])
			//Again make a color-code box of how accurate the contact exponent matches the theory.	
				if((0.95<exponent[0]&&exponent[0]<0.98)||(1.02<exponent[0]&&exponent[0]<1.05))
					TextBox/C/N=text2/B=(65280,43520,0) "        \r           "
				elseif(0.98<exponent[0]&&exponent[0]<1.02)
					TextBox/C/N=text2/B=(0,65280,0) "        \r           "
				else
					TextBox/C/N=text2/B=(65280,0,0) "        \r           "
				endif
			endif
		//Additionally append the actuall Reissner fit if present.
			if(waveexists($fit_nameREIS)==1)
				appendtograph $fit_nameREIS
				modifygraph rgb($fit_nameREIS)=(0,39168,0), lsize($fit_nameREIS)=1.5
			endif
		//Fitlimits are later used to set the zoom in the graph.
			wave fitlimits=$forcecurvecut+"Reis"			
		endif
	//For Reissner Hertz and DMT the fitlimits (start and end) are used as reference values of where to zoom in the graph
		if(waveexists(fitlimits)==1)
			setaxis bottom x_axis_re[fitlimits[2]]-1e-7,x_axis_re[fitlimits[3]-2]+1e-7
			setaxis left y_axis_re[fitlimits[2]]-10e-9 ,y_axis_re[fitlimits[3]-2]+10e-9
			if(fittype==3||fittype==2)
				setaxis left *,*
				setaxis bottom *,*
			endif
		endif
		
	endif
//Sets some special case of where and how far to zoom in. Values and combinations are usually fit quiet well during the modification of raw curves.	
//When deformation and force are displayed usually the contact regime is of interest. (fitmech=2=JKR retrace is of importance and specificaiton are made later)
	if(showdefor_g==1&&showforce_g==1&&fitmech!=2)
	//Typically retrace is not of interest so it gets removed. Can be overruled when selecting retraceonly or highlightadhesion.	
		if(retraceonly_g==0&&highlight_adh_g==0)
			removefromgraph $y_axis_re2
		endif
	//Values typically used. Feel free to adjust	
		SetAxis bottom -1e-7,*
		setaxis left *,*
	//This includes y&x zero line to see deviations and contact points.
		ModifyGraph zero=1
		wave cont_tr=$forcecurve+"cont_tr"
		cursor/P A $forcecurvecut+"force_ext_co" cont_tr[1]		
//In case JKR fits were made.		
	elseif(showdefor_g==1&&showforce_g==1&&fitmech==2)
	//check for the JKR adhesion information containing wave.
		if(waveexists($forcecurvecut+"adhfjkr")==1)
			wave adhesionF=$forcecurvecut+"adhfjkr"
		//If an adhesion force was found set the lower x-axis limit close to it.
			if(adhesionf[4]==-1)
				setaxis bottom *,*
			else
				setaxis bottom x_axis_re[adhesionf[4]]-5e-8,*
			endif
	//When no JKR fitting was performed so far take the adhesion force from the "basic" evaluation during baseline correction.
		else
			wave adhesionF2=$forcecurvecut+"adhf"
			setaxis bottom x_axis_re[adhesionf2[1]]-5e-7,*		
		endif
		setaxis left *,*
		wave cont_tr=$forcecurve+"cont_tr"
		cursor/P A $forcecurvecut+"force_ext_co" cont_tr[1]
	endif
//In case ONLY the deflection correction is selected only zoom in very closely in y and display all x values. 	
	if(showlog_g==0&&showsepa_g==0&&showdefor_g==0&&showdeflcor_g==1)
		setaxis left, -0.025,+0.025
		ModifyGraph zero(left)=1
	endif
//When doing the more elaborated adhesion evalution from the adhesion panel more infos are generated and can be displayed.
	if(highlight_adh_g==1)
	//Make 2 new waves which will hold the positions of "Zero-force-in-contact", "Force-of-adhesion", and "jump-out of contact"
		make/O/N=3 highlight_x, highlight_y
		wave highlight_x, highlight_y
	//The adhesion panel is set active to read out which model was used.
		setactivesubwindow MechanicsPanel#fitpanelAdhesion
		controlinfo FitModelChoice
		variable fittype1=V_value
	//Include the "range" waves of adhesion. They contain the parts of retrace in mechanically stable contact (-> see adhesion function for details)
		Wave range_start=$forcecurvecut+"WoA_start"
		wave range_end=$forcecurvecut+"WoA_end"
		variable i 
	//Set GUI-graph back to active so it can be modified.
		setactivesubwindow MechanicsPanel#Mechdisplay
	//Get the correct name of the adhesion results containing wave.
		if(fittype1==1)
			wave adhesionF=$Forcecurvecut+"AdhFJKR"
		elseif(fittype1==2)
			wave adhesionF=$Forcecurvecut+"AdhFDMT"
		endif
	//Some value comparisons are made to avoid errors in display. It DOES NOT display any highlights, if the adhesion function didn't run properly.
		if(adhesionf[3]<=numpnts(y_axis_re)||adhesionf[4]<=numpnts(y_axis_re)||adhesionf[2]<=numpnts(y_axis_re)&&adhesionF[4]!=-1)
			Textbox/K/N=text3
		//The 3 adhesion important point numbers and values transfered to the highlights wave, so they can be displayed as traces (here green squares)
			highlight_y[0]=y_axis_re[adhesionF[3]]
			highlight_x[0]=x_axis_re[adhesionf[3]]
			highlight_y[1]=y_axis_re[adhesionf[4]]
			highlight_x[1]=x_axis_re[adhesionf[4]]
			highlight_y[2]=y_axis_re[adhesionf[2]]
			highlight_x[2]=x_axis_re[adhesionf[2]]
			appendtograph highlight_y vs highlight_x
			modifygraph rgb($"highlight_y")=(0,65535,0), mode=3,marker($"highlight_y")=16,msize($"highlight_y")=5
		//If adhesion function finds at least one stable section of mechanical stable adhesive contact it will be display as blue areas.	
			if(numpnts(range_start)>=1&&numpnts(range_end)>=1)
			//To display that the corresponding sections are read out of the Range-waves and that part of the traces are additionally append to the graph.
				for(i=0;i<numpnts(range_start);i+=1)
					appendtograph y_axis_re[range_start[i],range_end[i]] vs x_axis_re[range_start[i],range_end[i]]
					modifygraph rgb($y_axis_re2+"#"+num2str(i+1))=(0,12800,52224), mode($y_axis_re2+"#"+num2str(i+1))=7,hbFill($y_axis_re2+"#"+num2str(i+1))=5, lsize($y_axis_re2+"#"+num2str(i+1))=0
				endfor
			endif
		//Since we are here interested in adhesive properties positiv restoring forces are not display (left ,3e-9 Newton)
			setaxis left, *,3e-9
		//To much baseline is also not interesting so the plot begins 200nm left of the jump-out point.
			setaxis bottom, highlight_x[1]-200e-9,*
		//	setaxis bottom, *,*
	//If there were some problems in the adhesion function the user gets an error-note in form of a Textbox in the graph.
		else
			Textbox/C/N=text3 "Adhesion Error"
		endif
	endif
//This combination is supposed to be used when checking the determined contact points. It offers a close zoom to the contact point& sets a cursor to the found cont.point.
	if(showforce_g==1&&check_contact_g==1&&showdefor_g==1)
		setaxis left,-0.4e-9,0.4e-9 //-0.5e-9,2e-9
		setaxis bottom, -1e-7,1e-7//-2e-6,2e-6
		wave cont_tr=$forcecurve+"cont_tr"
		cursor/P A $forcecurvecut+"force_ext_co" cont_tr[1]
	endif
//Special Zoom for "Check Contact" + "Line fitting deformation"	
	controlinfo usecursor_defor
	if((v_value==4||v_value==5)&&check_contact_g==1)
		setaxis left, *,*
		setaxis bottom, x_axis_tr[numpnts(x_axis_tr)-1]-2e-9,x_axis_tr[numpnts(x_axis_tr)-1]+2e-9 
	endif
//Special display... Is supposed to show a log-log plot of force vs deformation. currently buggy.
	if(showlog_g==1)
	//First remove the appended traces
		do
			tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
			if(strlen(tracesongraph)>0)
				removefromgraph $stringfromlist(0,tracesongraph,";")
			endif
		while(strlen(tracesongraph)>0)
	//append the log log waves, the log-log fit and a textbox with informations.
		wave exponent=$forcecurvecut+"expo"
		appendtograph $"log_"+forcecurvecut+"For" vs $"log_"+Forcecurvecut+"Defor"
		appendtograph $"fit_log_"+forcecurvecut+"For"
		if((1.45<exponent[0]&&exponent[0]<1.48)||(1.52<exponent[0]&&exponent[0]<1.55))
			TextBox/C/N=text2/B=(65280,43520,0) "        \r           "
		elseif(1.48<exponent[0]&&exponent[0]<1.52)
			TextBox/C/N=text2/B=(0,65280,0) "        \r           "
		else
			TextBox/C/N=text2/B=(65280,0,0) "        \r           "
		endif
		TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+"\rContact Slope: "+num2str(exponent[0])+" ± "+num2str(exponent[1])
	endif
//Label the two axis with names	
	Label left y_axis_name
	label bottom x_axis_name
//Change the tick style of the axis.
	if(showlog_g==1)
		modifygraph log(left)=1
	else
		modifygraph log(left)=0
	endif
	if(showforce_g==1)
		modifygraph lowtrip=1e-15,prescaleExp=9
	else
		modifygraph lowtrip=0.001, prescaleExp=0
	endif
//Historically so far down. Could be moved up.
//Maugis evaluation needs a unique way to display the force curve.	
	if(fittype==6)	//Maugis evaluation
	//In case no overview is made: remove all traces from graph.
		if(overview_g==0)
			do
				string tracesongraph1=tracenamelist("mechanicspanel#mechdisplay",";",1)
				if(strlen(tracesongraph1)>0)
					removefromgraph $stringfromlist(0,tracesongraph,";")
				endif
			while(strlen(tracesongraph1)>0)
	//I think all this needs to be restated since its so far down in the function, but whatever...
		elseif(strlen(tracenamelist("Overview",";",1))==0)
			display/N=overview
		elseif(strlen(tracenamelist("Overview",";",1))>0&&forcecurvenumber>0)
			dowindow/F Overview
		elseif(strlen(tracenamelist("Overview",";",1))>0&&forcecurvenumber==0)
			killwindow Overview
			display/N=overview
		endif
	//Set the GUI-Graph as active.
		setactivesubwindow MechanicsPanel#Mechdisplay
	//Include the contactradius in trace and the Force-wave with only the forces matching the contradius
		wave y_axis_tr=$forcecurvecut+"contrad_ret", x_axis_tr=$forcecurvecut+"Force_ret_CR"
	//The maugis fit and accordingly recalculated force and deformation are included.
		wave fit=$forcecurvecut+"_MD_fit", Fit_recalc=$forcecurvecut+"MD_DRecalc", fit_Frecalc=$forcecurvecut+"MD_Frecalc"
	//If Present...
		if(waveexists(y_axis_tr)==1)
		//Also inculde the corresponding Maugis fit information wave.
			wave MD_info=$forcecurvecut+"Maugis"
		//Append the contactradius vs force waves to the graph.
			appendtograph y_axis_tr vs x_axis_tr
			ModifyGraph mode($forcecurvecut+"contrad_ret")=3
			ModifyGraph zero(bottom)=1
		//Fit[3] is just any result which is not 0 when the fit worked properly.
			if(fit[3]!=0)
			//Append both the recalced and fitted wave, change there style and add cursors to fit start and end.
				appendtograph fit_recalc vs fit_frecalc
				appendtograph fit
				ModifyGraph lsize($forcecurvecut+"_md_fit")=2
				ModifyGraph rgb($forcecurvecut+"_md_fit")=(0,65535,0)
				ModifyGraph rgb($forcecurvecut+"MD_drecalc")=(4369,4369,4369)
				cursor/P A $forcecurve+"contrad_ret" md_info[9]
				cursor/P B $forcecurve+"contrad_ret" md_info[10]
		//If fit didnt work proberly place cursors at 20 and 80% of the contactradius values.
			else
				cursor/P A $forcecurve+"contrad_ret", round(0.2*numpnts(y_axis_tr))
				cursor/p B $forcecurve+"contrad_ret", round(0.8*numpnts(y_axis_tr))
			endif
		//Change the axis labels according to there magnitude.
			if(y_axis_tr[numpnts(y_axis_tr)-1]<1e-6)
				y_axis_name="Contact Radius\\u#2 / nm"
			elseif(y_axis_tr[numpnts(y_axis_tr)-1]<1e-3)
				y_axis_name="Contact Radius\\u#2 / µm"
			elseif(y_axis_tr[numpnts(y_axis_tr)-1]<1)
				y_axis_name="Contact Radius\\u#2 / mm"
			endif
			if(x_axis_tr[numpnts(x_axis_tr)-1]<1e-6)
				x_axis_name="Force\\u#2 / nN"
			elseif(y_axis_tr[numpnts(x_axis_tr)-1]<1e-3)
				x_axis_name="Force\\u#2 / µN"
			elseif(y_axis_tr[numpnts(x_axis_tr)-1]<1)
				x_axis_name="Force\\u#2 / mN"
			endif
		//Creat a textbox includeing all fit relevant values and for comparison the formerly determined adhesion force.
			wave adhesionF=$forcecurvecut+"Adhf", workadhf_md_rips
			NVAR numforcecurve=root:panelcontrol:singlefcpanel:numforcecurve_g
			TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(md_info[7])+" Pa  Alpha: "+num2str(md_info[1])+"\r Calc. Force Adhesion :"+num2str(-md_info[2]*1e9)+" nN; Measured: "+num2str(adhesionF[0]*1e9)+" nN"
			appendtext/N=text0 "Work of adhesion: "+num2str(md_info[5])+" J/m²; Recalc. Contact Radius: "+num2str(md_info[12]*1e9)+" nm\r WoA MD rips: "+num2str(workadhf_md_rips[numforcecurve]*1e3)+" mJ m\S-2\M"
		//Find the point in contactradius where the fit results suggest the Work of adhesion is normalized to. see maugis.
			findvalue/V=(md_info[12])/T=2e-9 y_axis_tr
			make/o/N=1 md_highlightA, md_highlightF
			setaxis bottom *,10e-9
			if(V_value!=-1)
				md_highlightA[0]=y_axis_tr[V_value]
				md_highlightF[0]=x_axis_tr[V_value]
			endif
		//Append that radius point as highlight to the graph.	
			appendtograph md_highlightA vs md_highlightF
			ModifyGraph mode(md_highlightA)=3,marker(md_highlightA)=16,rgb(md_highlightA)=(0,65535,65535)
			
		endif
	endif
//Just a statement to flow-controll the display panel mixup.
	if(overview_g==0)
		setactivesubwindow ##
	endif
while(numberoftrace<-1)
end

//One of the key functions. Due to the experimental nature of force curve there are possible tilts and offset in the delfection volts in the non-contact part.
//This function is create to determine the actual region where no interaction force are acting. Since there is no force this region should be a line of zero slope and zero abszisse.
//Tilts and offsets are removed by line-fitting the no interaction region and substracting this line-fit from the acutal curve.
function VirtualDeflectionAlone(forcecurve,baselinePercent,jumpto)
	string forcecurve
	variable baselinePercent, jumpto //jumpto =1 if existing
//Basename(=forcecurve); the assumed percentage of baseline (how many points of the curve are baseline=baselinepercent)
//jumpto can be used to find the transition from no contact to contact regime.
//In case of overlength the basename is transfered to a secend, then editable string.
	string forcecurveCUT=forcecurve
//String containing the folder path in igor
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
//State if both trace&retrace or only retrace should be modified.
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
//Inverse Optical Lever Sensitivity. Needed to find values in meter space not in volt space.
	NVAR INvols_g=Root:panelcontrol:singlefcpanel:invols_g
//Springconstant.	
	NVAR springconst_g=root:panelcontrol:singlefcpanel:springconst_g
//Input value somehow influencing the criterium when the baseline range search is completed successfully.
	NVAr errorVirtualDefl_g=root:panelcontrol:singlefcpanel:errorvirtualdefl_g
//Set the correct folder in igor and transfer percent to "standard" number.
	setdatafolder $folderstring_g
	baselinepercent/=100
	string line_fit, baseline
//Similar to errorVirtualDefl; it's part of the criterium when the baseline search is completed. 
	variable slopelooper_criterium=750	//somehow arbitrary value used to check changes in baseline slope
//Create string containg info about the different types of the force-curve are available.
	string content=checkfoldercontent(forcecurve)
//As x-values the piezo-movement is used either in RAW or ZSNSR form(whatever was recorded)
	if(numberbykey("raw",content,":",";")==1)
		wave disp_re=$forcecurve+"Raw_Ret"
		wave disp_tr=$forcecurve+"Raw_Ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_re=$forcecurve+"ZSnsr_Ret"
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
//Also include the dwell part; Needs also be tilted according to trace and retrace to still match them.
	variable towd=0
	if(numberbykey("Towd",content,":",";")==1)
		towd=1
		if(error1==0)
			wave disp_towd=$forcecurve+"Raw_Towd"
		elseif(error2==0)
			wave disp_towd=$forcecurve+"Zsnsr_Towd"
		endif
	endif
//Check if the y-values(deflection volt) are present; Force alone would also be possible(then strangely recorded curve); the error sum-up to 2 when neither RAW/ZSNSR are there.	
	if(numberbykey("deflv",content,":",";")==1||numberbykey("Force",content,":",";")==1&&error1+error2!=2)
	//If Deflection Volt are present:
		if(numberbykey("deflv",content,":",";")==1)
		//Include the trace and retrace waves, also dwell if there are any.
			wave defl_re=$forcecurve+"DeflV_Ret"
			wave defl_tr=$forcecurve+"DeflV_Ext"
			if(towd==1)
				wave defl_towd=$forcecurve+"DeflV_Towd"
			endif
		//Wavestats give an overview of statistical values of the retrace. When used it will be stated later.
			wavestats/Q defl_re
		//Shrink basename length if to long, to avoid errors.
			if(strlen(forcecurve)>19)
				forcecurveCUT=forcecurve[3,strlen(forcecurve)]
			endif
		//When run first time, create a new wave with the additional appendix "_co" signaling the corrected/modified wave.
			if(waveexists($forcecurvecut+"DeflV_ret_co")==0)
				duplicate/o defl_re, $forcecurveCUT+"DeflV_Ret_co"	
			endif
		//In case not only the retrace should be modified also duplicate the trace to a new, corrected one.
			if(retraceonly_g!=1)
				duplicate/O defl_tr, $forcecurveCUT+"DeflV_Ext_co"	
				wave defl_tr_co=$forcecurveCUT+"deflv_ext_co"		
				if(towd==1)
					duplicate/O defl_towd, $Forcecurvecut+"DeflV_Towd_c"
					wave defl_towd_co=$forcecurvecut+"DeflV_Towd_c"
				endif
			endif
		//Include also the new corrected retrace wave.
			wave defl_re_co=$forcecurveCUT+"deflv_ret_co"	
		//Just state that there are these two wave, they are later created by fit-functions. They contain the fit-values (coef) and there standard deviations (sigma).
			wave w_coef, w_sigma
		//3 Variables later controlling the flow-loop and if the fit should be redone or not.
			variable slope1st, slopeerror1st, slopebreaker=0
		//Here only the trace is corrected. Actually both, trace and retrace, are always treated independently.	
			if(retraceonly_g!=1)
			//make an initial line fit of deflectionV tr vs piezodisplacement starting from max. contraction to the percent of baseline stated by the user in the GUI.
			//Note: it is already intended that roughly 20% of the curve are actually contact regime.
				CurveFit/NTHR=0/Q line Defl_tr[0,(1-0.2)*(numpnts(Defl_tr)-1)*baselinepercent] /X=Disp_tr
				wave w_coef, W_sigma
			//Based on this first line it the defl_tr_co is tilt and offset corrected by substracting the fitted line from the raw deflection.
				defl_tr_co=defl_tr-w_coef[1]*disp_tr-W_coef[0]
				if(towd==1)
					defl_towd_co=defl_towd-w_coef[1]*disp_towd-w_coef[0] //unsure...
				endif
			//The line fit done above has the following name, which is shorten (in case) like igor automatically shorts wavenames.
				line_fit="fit_"+forcecurve+"Deflv_ext"
				line_fit=line_fit[0,30]
			//Since the correction might be not perfect at the 1. shot and the slope and y-offset may gradually decrease to zero. This done be fitting the already fitted waves.
			//To have a good starting value for the retrace, the slopes and y-offsets of all the single fits need to summed up which should then be result in a 1 fit correction of the retrace.
				variable sumofslopesfitted_tr, sumofoffsetsfitted_tr
			//The initial values are stored in variables, for a later comparision, and the slopebreaker, controlling the do-while loop is set to 0.
				slope1st=W_coef[1]; slopeerror1st=W_sigma[1]; slopebreaker=0; sumofslopesfitted_tr=w_coef[1]; sumofoffsetsfitted_tr=w_coef[0]
			//The Lateral baseline percentage offset controls how many percent the baseline regions is shorten in each fitting step to find the longest and best baseline fit.
				variable laterbasepercentoffset=0.0
			//Redoing the baseline line fit until the criterions for a "good" line fit are met.
				do
				//The deviation/error of the slope from the fit is saved.
					slopeerror1st=W_sigma[1]
				//Make a line fit of deflectionV vs piezo displacement from max. piezo contraction to (initial percentage MINUS up-counting lateral shift)% of 80% of all points.
					CurveFit/NTHR=0/Q line Defl_tr_co[0,(1-0.2)*(numpnts(Defl_tr_co)-1)*(baselinepercent-laterbasepercentoffset)] /X=Disp_tr
				//3 cases are so far included.
				//1. The new slope is bigger then the criterium == too tilted AND the current slope error is smaller than the one before == measurement of the noise evolution AND the slope error is smaller than a critical value.
				//In the later two checks w_sigma gets very high when for example fitting through jump-in jump-out regions.
					if(abs(w_coef[1])>slopelooper_criterium&&slopeerror1st>w_sigma[1]&&w_sigma[1]<errorVirtualDefl_g)
					//There should be a better fit in the curve -> redo it.
						slopebreaker=0
				//2. Same as above but now the slope error increases with more fitting.
					elseif(abs(w_coef[1])>slopelooper_criterium&&slopeerror1st<w_sigma[1]&&w_sigma[1]<errorVirtualDefl_g)
					//We still want the slope of the corrected curve closer to 0 so redo!
						slopebreaker=0
//edited whlie using JPK-Files						
//original					elseif(abs(w_coef[1])<slopelooper_criterium&&slopeerror1st<w_sigma[1]&&w_sigma[1]<errorVirtualDefl_g)
				//3. The current slope is below our criterium for a good baseline AND the slope-error increases (typically when less points are fited withthe same result) AND y-Offset is below 1V
				//Note to the last: both early arguments can be met even though the fit is completly tilted while fitting some artefacts or adhesive stuff.
					elseif(abs(w_coef[1])<slopelooper_criterium&&slopeerror1st<w_sigma[1]&&w_sigma[0]<1)
					//All criteria are met so exit do-loop after this one.
						slopebreaker=1
					endif
				//In case we didnt find a proper baseline fit and we are running out of points to treat.
					if((1-baselinepercent-laterbasepercentoffset)<0.05)
					//Add up the current slope and y-offset values and leave the do-loop.
						sumofslopesfitted_tr+=w_coef[1]; sumofoffsetsfitted_tr+=w_coef[0]
						break
					endif
				//Sum up the slope and y-offset values so it can be later on used for retrace.
					sumofslopesfitted_tr+=w_coef[1]; sumofoffsetsfitted_tr+=w_coef[0]
				//Substract the currently line fit constantly from the modified wave until it becomes "good"
					defl_tr_co=defl_tr_co-w_coef[1]*disp_tr-W_coef[0]
					if(towd==1)
						defl_towd_co=defl_towd_co-w_coef[1]*disp_towd-w_coef[0]
					endif
				//Increase the later offset setwise by 2% in direction of max piezo contraction.
					laterbasepercentoffset+=0.02
				while(slopebreaker!=1)
				//Force waves have to be newly calculated!
				duplicate/O defl_tr_co, $forcecurvecut+"Force_ext_co"
				wave force_ext_co=$forcecurvecut+"Force_ext_co"
				force_ext_co*=invols_g*springconst_g*1e-9		
				if(towd==1)
					duplicate /o defl_towd_co, $forcecurvecut+"Force_towd_c"
					wave force_towd_co=$forcecurvecut+"Force_towd_c"
					force_towd_co*=invols_g*springconst_g*1e-9
				endif
			endif	
		//Trace modification is done. Now retrace.
		//In case Jump-to contact is selected. which somehow does more equal the force of adhesion... well still works in a way.
			variable fitstart
			if(jumpto==1)
			//The "exact" baseline length is known, the point of adhesive failure (V_minrowloc from wave stats), and from that the baseline percentage is taken
				fitstart=V_minrowloc+(1-baselinepercent)*((numpnts(defl_re)-1)-V_minrowloc)
		//In case jump-to is not selected: as above assume 20% of the curve be contact and then take baseline percent of the rest as fit start.
			else
				fitstart=0.2*(numpnts(defl_re)-1)+(1-baselinepercent)*0.8*(numpnts(defl_re)-1)
			endif
		//Check how much the mean baseline value of trace and retrace differ. 
		//The construct with pnt2x() is need so it works with the mean command.	
			variable meanbasetrace=mean(defl_tr,pnt2x(defl_tr,0),pnt2x(defl_tr,0.05*numpnts(defl_tr))), meanbaseretrace=mean(defl_re,pnt2x(defl_re,numpnts(defl_re)-1),pnt2x(defl_re,round(0.995*numpnts(defl_re))-1))
		//In case there is a difference in the average deflection of more than 0.1V, which is quiet big, one has to assume that something went wrong while retracting.
		//E.g. the cantilever never got out of contact during retraction. To still have a "corrected" retrace just use the same treatment as for trace
			if(meanbasetrace-meanbaseretrace>0.1&&sumofslopesfitted_tr!=0)	//average of uncorrected trace could produces problems with very tilted FD curves
			//The point order in retrace has to be flipped to properly do the line fit.
				reverse defl_re_co, defl_re, disp_re
				defl_re_co=defl_re-sumofslopesfitted_tr*disp_re-sumofoffsetsfitted_tr
			//Flipped backwards to standard point order in wave.
				reverse defl_re_co, defl_re, disp_re
		//Otherwise do the similar evaluation as for trace
			else
			//make a first linefit of the retrace.
				CurveFit/NTHR=0/Q line Defl_re[fitstart,(numpnts(defl_re)-1)] /X=Disp_re
			//Make the first correction, 	
				defl_re_co=defl_re-w_coef[1]*disp_re-w_coef[0]	
				line_fit="fit_"+forcecurve+"Deflv_ret"
				line_fit=line_fit[0,30]
				
				slopebreaker=0
			//Make a next of set in the lateral baseline direction of 2% for the next fit.
				variable laterbasepercentoffset_re=0.02	
			//Adjust the new fit start.		
				fitstart=round(0.2*(numpnts(defl_re)-1)+(1-baselinepercent+laterbasepercentoffset_re)*0.8*(numpnts(defl_re)-1))
				do
					slopeerror1st=W_sigma[1]
					CurveFit/NTHR=0/Q line Defl_re_co[fitstart,(numpnts(defl_re)-1)] /X=Disp_re
//original					if((abs(w_coef[1])<slopelooper_criterium&&slopeerror1st<w_sigma[1]&&w_sigma[1]<errorVirtualDefl_g)||(abs(w_coef[1])<200&&abs(disp_re[fitstart]-disp_re[numpnts(disp_re)-1])<3e-7))
//edited while using JPK-files
				//1. breaking argument as for trace. 2nd: a jump-to-break argument when reaching the end of the baseline, having a rather low slope but not meeting the 1. criterium.
					if((abs(w_coef[1])<slopelooper_criterium&&slopeerror1st<w_sigma[1]&&w_sigma[0]<1)||(abs(w_coef[1])<200&&abs(disp_re[fitstart]-disp_re[numpnts(disp_re)-1])<3e-7))

						slopebreaker=1
						break
				//See trace
					elseif(abs(w_coef[1])>slopelooper_criterium&&slopeerror1st<w_sigma[1])
						slopebreaker=0
					elseif(abs(w_coef[1])>slopelooper_criterium&&slopeerror1st>w_sigma[1])
						slopebreaker=0
					endif
				//When here the baseline could be improved. Modify the "old" corrected deflection by the current line fit.
					defl_re_co=defl_re_co-w_coef[1]*disp_re-W_coef[0]
				//In case less then 0.5% of points where left to be fitted in the last do-run stop the do-loop			
					if((1-baselinepercent+laterbasepercentoffset_re)>0.995)
						break
					endif
				//In case more than 90% of all points are still available to fit decrease the range for 5% else only 2%
					if(1-baselinepercent+laterbasepercentoffset_re<0.90)
						laterbasepercentoffset_re+=0.02
					else
						laterbasepercentoffset_re+=0.005
					endif
				//Change the fit start point accordingly.
					fitstart=round(0.2*(numpnts(defl_re)-1)+(1-baselinepercent+laterbasepercentoffset_re)*0.8*(numpnts(defl_re)-1))
				while(slopebreaker!=1)
			endif	
			//Force waves have to be newly calculated!
			duplicate/O defl_re_co, $forcecurvecut+"Force_ret_co"
			wave force_ret_co=$forcecurvecut+"Force_ret_co"
			force_ret_co*=invols_g*springconst_g*1e-9
		//In case you want to save the final baseline fit waves decommentize that section.	
	//////////////////////////////////////////////////Block To Save Baselinefit////////////////////////////////		
			//removefromgraph $line_fit
		//	wave fit_wave=$line_fit
		//	baseline=forcecurve+"baseDR"
		//	if(waveexists($baseline)==1)
		//		killwaves $baseline
		//	endif
		//	rename fit_wave, $baseline
	///////////////////////////////////////////////End of Saveblock//////////////////////////////////////////////

		//	wave fit_wave=$line_fit
		//	baseline=forcecurve+"baseDE"
		//	if(waveexists($baseline)==1)
		//		killwaves $baseline
		//	endif
		//	rename fit_wave, $baseline
		endif
	endif
end

//Function to determine the adhesion force. No work of adhesion here.
function AdhesionAlone(forcecurve,jumpout,baselinepercent)
	string forcecurve
	variable jumpout, baselinepercent
//Load some input variables and strings.
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_G
	setdatafolder $folderstring_g
//check which types of the force curve are already calculated.
	string content=checkfoldercontent(forcecurve)
//In case any delfection volt wave
	if(numberbykey("DeflVCo",content,":",";")==1||numberbykey("DeflV",content,":",";")==1)//old stuff &&jumpout==1)
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			wave deflV_re_co=$forcecurvecut+"DeflV_ret_co"
		else
			wave deflV_re_co=$forcecurve+"DeflV_ret"
		endif
	//Point of adhesion force is simple taken as lowest deflection value in the retrace. Minimum is determined by wavestats.
		wavestats/Q deflv_re_co
	//A new wave is created to hold the results in terms of voltage.
		make/N=2/O $forcecurve+"AdhV"
		wave adhesion=$forcecurve+"AdhV"
	//Save the point position.
		adhesion[1]=V_minrowloc
	//In case no correction was yet done a rough mean value of the baseline is determined and used as a deflection offset(reference point)		
		variable adhesionoffset=mean(deflv_re_co,abs((v_npnts-v_minrowloc)*(1-baselinepercent)+V_minrowloc),V_npnts)
	//Save the adhesion voltage.
		adhesion[0]=abs(deflv_re_co[V_minrowloc]-adhesionoffset)
	endif
//Do the same stuff for force-waves in case they are already present.
	if(numberbykey("ForceCo",content,":",";")==1||numberbykey("Force",content,":",";")==1&&jumpout==1)
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurve=forcecurve[3,strlen(forcecurve)]
			endif
			wave force_re_co=$forcecurve+"Force_Ret_co"
		else
			wave force_re_co=$forcecurve+"Force_Ret"
		endif
		wavestats/Q force_re_co
		make/N=2/O $forcecurve+"AdhF"
		wave adhesionF=$forcecurve+"AdhF"
		adhesionF[1]=V_minrowloc
		variable adhesionoffsetF=mean(force_re_co,abs((V_npnts-v_minrowloc)*(1-baselinepercent)+V_minrowloc),V_npnts)
		adhesionF[0]=abs(force_re_co[V_minrowloc]-adhesionoffsetF)
	endif	
end

//Function to calc the work of adhesion based on JKR or DMT model. + The area between retrace&Zero-Force including leaveing out unstabel parts.
function WorkofAdhesionAlone(forcecurve,baselinepercent,contacttolerance,proberadius,fitmodel)
//Loading input variables and strings
	string forcecurve
//Baselinepercent: how many point% are baseline; contacttolerance: allowed tolerance in deflection search.
	variable baselinepercent, contacttolerance
//Probe size; fitmodel: chosen from the drop down menu	
	variable proberadius, fitmodel	
//Basename of the force curve
	string forcecurvecut=forcecurve
//Checkbox variable: if active (=1) a new pop-up window asks for user confirmation of found points.
	NVAR check_woa_points_g=root:panelcontrol:singlefcpanel:check_woa_points_g
//Which number correspondes to force-curve name in listofbasenames.
	NVAR numforcecurves_g=root:panelcontrol:singlefcpanel:numforcecurves_g
	NVar springconst_g=root:panelcontrol:singlefcpanel:springconst_g
//Redimension of values to be in SI units.
	contacttolerance*=1e-9; proberadius*=1e-6; baselinepercent/=100
//In which folder is the force curve stored.
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_G
	setdatafolder $folderstring_g
//Check which type of waves already exist for the force-curve.
	string content=checkfoldercontent(forcecurve)
//Check if force-waves are present. If not this function doesnt make sense to be done.
	if(numberbykey("ForceCo",content,":",";")==1||numberbykey("Force",content,":",";")==1)//&&jumpout==1)
		if(numberbykey("ForceCo",content,":",";")==1)
		//Cut the basename in case it is longer than 20 letters.
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
		//Include baseline corrected waves if they are there
			wave force_re_co=$forcecurvecut+"Force_Ret_co"
			wave force_tr_co=$forcecurvecut+"force_ext_co"
			wave defl_tr_co=$forcecurvecut+"deflV_ext_co"
			wave defl_re_co=$forcecurvecut+"deflv_ret_co"
	//In case no baseline modification was done before you the unmodified waves. (not recommended)
		else
			wave force_re_co=$forcecurve+"Force_Ret"
			wave force_ext_co=$forcecurve+"force_ext"
			wave defl_tr_co=$forcecurve+"Deflv_ext_co"
			wave defl_re_co=$forcecurve+"deflv_ret_co"
		endif
	//Include the deformation waves. Could result in an error, in case typical way of evaluation is not done.
		wave defor_ext=$forcecurve+"Defor_ext"
		wave defor_ret=$forcecurve+"Defor_ret"
	//Fitmodel==1 : JKR; ==2 : DMT -> adjust the endings of the adhesion and Work Of ADHesion waves. *Sing are the WoA-values for the single segments determined.
		if(fitmodel==1)// ???||fitmodel==2)???
			make/N=5/O $forcecurve+"AdhFJKR"
			wave adhesionF=$forcecurve+"AdhFJKR"
			make/N=2/O $forcecurve+"WoAdhF"
			wave workADHF=$forcecurve+"WoAdhF"
			make/N=0/O $forcecurve+"WoAdhFSing"
			wave workADHFSing=$forcecurve+"WoAdhfSing"
		elseif(fitmodel==2) //was earlier set to 3???
			make/N=5/O $forcecurve+"AdhFDMT"
			wave adhesionF=$forcecurve+"AdhFDMT"
			make/N=2/O $forcecurve+"WoAdhFDMT"
			wave workADHF=$forcecurve+"WoAdhFDMT"
			make/N=0/O $forcecurve+"WoAdhFDMTSing"
			wave workADHFSing=$forcecurve+"WoAdhfDMtSing"
		endif	
	//Variables holding the point value of zero-force-in-contact of retrace+ 1. zero value after last jump-out of contact.
		variable zeroretracecontact, zerobaselinejumpout
	//Meanvalue of the trace baseline is calced and the very last deflection of the retrace are put in variables.
		variable meanbasetrace=mean(defl_tr_co,pnt2x(defl_tr_co,0),pnt2x(defl_tr_co,0.05*numpnts(defl_tr_co))), lastpointretrace=defl_re_co[numpnts(defl_re_co)-1]
	//In case the baseline of trace and retrace are far off each other do different evaluation.
		if((meanbasetrace>lastpointretrace&&meanbasetrace-lastpointretrace>0.1))
		//Search for the 1. Zero-value with in contact tolerance in the retrace-force-wave.
			findvalue/V=(0)/T=(contacttolerance) force_re_co
		//This position is saved in zero-retrace-contact.
			zeroretracecontact=V_value
		//Since no proper baseline can be assumed the zero-value-at-jump-out is taken as the last point of the retrace.
			zerobaselinejumpout=numpnts(force_re_co)-1
	//In case the trace&retrace baselines are similar, as it should be, a more elaborate search can be performed.
		else
		//Reversing the point-flow of the retrace-force makes the thinking in the search protocol easier. Is reflipped later.
			reverse force_re_CO
		//Just some varialbes involved in the search.
			variable meanvalueBASE, baseend=round((1-0.2)*(numpnts(force_re_CO)-1)*baselinepercent), varianceBASE, test1, test2
		//The mean value of the retrace-force-baseline is calced as a reference for noise.
			meanvalueBASE=mean(force_re_CO,pnt2x(force_re_CO,0),pnt2x(force_re_CO,baseend))
		//Also the variance.
			variancebase=(variance(force_re_CO,pnt2x(force_re_CO,0),pnt2x(force_re_CO,baseend)))^0.5*2
			reverse force_re_CO
		//Search beginning from maximum contact the mean value in the baseline.
			findvalue/V=(meanvalueBASE)/T=(contacttolerance) force_re_CO
		//Search result should be the point of zero-force-in-contact.
			zeroretracecontact=v_value
		//Also stored in adhesion-wave to use it outside of this funciton. (e.g. for displaying)
			adhesionF[3]=V_value
		//Wavestats of the force-retrace should give the point of maximum adhesion as global minimum. also saved.
			wavestats/Q force_re_co
			adhesionF[2]=V_minrowloc	
			variable adhesionoffsetF=meanvalueBASE
		//The determined adhesion force is also saved including the offset due to the average baseline value.
			adhesionF[0]=abs(force_re_co[V_minrowloc]-adhesionoffsetF)		//Adehsionforce without offset from baseline
		//Begining from the point of maximum adhesion the next point close to the meanvalue of baseline is searched. = jump-out-of contact.+ save
			findvalue/S=(V_minrowloc)/V=(meanvalueBASE)/T=(contacttolerance) force_re_co
			zerobaselinejumpout=v_value
			adhesionF[4]=V_value
		endif	
	//Do uptade to show the determined points in the graph when the user-check option is active.
		doupdate
	//The average distance between to points in the deformation wave are determined just after the jump-out.
		variable averagespacing_baseline=mean(defor_ret,zerobaselinejumpout+40,zerobaselinejumpout+40*2)
	//The part of the force and defromation wave are duplicate which are interesting for work of adhesion are duplicate to new waves.
		duplicate/O/R=[zeroretracecontact,zerobaselinejumpout] force_re_co, $Forcecurvecut+"IntegralF",$Forcecurvecut+"Integral", $forcecurvecut+"DerviF", $forcecurvecut+"Dervi"
		duplicate/O/R=[zeroretracecontact,zerobaselinejumpout] defor_ret, $Forcecurvecut+"IntegralD",$forcecurvecut+"DerviD"
	//The duplicate waves are introduced to the function.
		wave integral=$forcecurvecut+"integral"
		wave integralF=$forcecurvecut+"integralF"
		wave integralD=$Forcecurvecut+"IntegralD"
		wave derviF=$forcecurvecut+"DerviF"
		wave derviD=$forcecurvecut+"DerviD"
		wave dervi=$forcecurvecut+"dervi"
	//The integral of force vs deformation in ther range of jump-out to zero-force-in-contact is calced. This area equals the WoA WITHOUT area normalization.
		integrate/T integralF /X=integralD /D=integral	
	//checking for multiple rip-offs; during rip-off the cantilever instability shows as line with slope = -springconst
	//Slope between 2 points can be determined by differentiation.
		differentiate /EP=1 derviF /X=derviD /D=Dervi
	//Make new waves storeing the beginning and end of stable adhesion parts.	
		make/O/n=1 $forcecurvecut+"WoA_start"
		make/o/N=0 $forcecurvecut+"WoA_end"
		wave range_start=$forcecurvecut+"WoA_start"
		wave range_end=$forcecurvecut+"WoA_end"
		range_start=0
		variable i, averageslopeof3points, rangecounter, springconst_tolerance=0.02 //this tolerance seems like a random number... May more an accuracy issue...
	//Go trough all points in the deviation wave point by point.	
		for(i=0;i<numpnts(dervi)-1;i+=1)
		//The average lope between 3 points is actually taken, because between 2 noise and jumps can interfere very strongly.
		//At least I thought so... Currently only 2 points are used....
			averageslopeof3points=(dervi[i])//+dervi[i+1]+dervi[i+2])/3
		//The if is activated in case there is an instability in the force constant
		//1. condition: slope needs to be negative and equal to the negative spring constant within the tolerance.
		//or 2. condition: the slope is within 2*tolerance AND the deformation distance between the current and the next point is bigger than 3times the average in the baseline.	
			if((averageslopeof3points>-springconst_g-springconst_tolerance&&averageslopeof3points<-springconst_g+springconst_tolerance)||(averageslopeof3points>-springconst_g-springconst_tolerance*2&&averageslopeof3points<-springconst_g+springconst_tolerance*2&&derviD[i+1]-derviD[i]>3*averagespacing_baseline))
			//An end is found and that position is saved in the wave.
				insertpoints rangecounter, 1,  range_end
				range_end[rangecounter]=i
			//just a counting variable to not override the same position in the range-waves.
				rangecounter+=1
			//Since a instability was found go through the next points until again a stabel regions is found(defined in the while-argument)	
				do
					i+=1
					averageslopeof3points=(dervi[i])//+dervi[i+1]+dervi[i+2])/3
				//In case the end of the overall adhesion region is reach stop searching.
					if(i==numpnts(dervi)-1)
						break
					endif
			//Same conditions as for the if above. -> run until this is FALSE.
				while((averageslopeof3points>-springconst_g-springconst_tolerance&&averageslopeof3points<-springconst_g+springconst_tolerance)||(averageslopeof3points>-springconst_g-springconst_tolerance*2&&averageslopeof3points<-springconst_g+springconst_tolerance*2&&derviD[i+1]-derviD[i]>3*averagespacing_baseline))
				// Slope needs to be negative and cannt become too much negative; has to return close to 0 or positive for new stretching
			//	while((averageslopeof3points<-springconst_g+springconst_tolerance)||i<numpnts(dervi)-2)
			//In case we are not at the end of the adhesion range a new starting point is set.	
				if(i!=numpnts(dervi)-1)
					i+=1
					insertpoints rangecounter, 1, range_start
					range_start[rangecounter]=i
				endif
			endif
		//Continue until the adhesion region is checked.
		endfor
	//In the end the last point is inserted in the range end wave which then is the point-distance between zero-force-in-contact and the jump-out point.
		insertpoints numpnts(range_end),1, range_end
		range_end[numpnts(range_end)-1]=zerobaselinejumpout-zeroretracecontact
	//In case the user check is activated->start the check_woa_range function.	
		if(check_woa_points_g==1)
			zerobaselinejumpout=check_woa_range(zeroretracecontact,zerobaselinejumpout,adhesionF)
		endif
	//Save the jump-out point in the adhesion result wave.
		adhesionf[4]=zerobaselinejumpout
	//WoA result waves is set to 0 at position 0(which it should be anyway already)
		workadhf[0]=0
	//Sum up all partial integral values in the stable contact regions determined above.
		for(i=0;i<numpnts(range_start);i+=1)
		//In case there are more than 1 stable contact region -> add the up-counting integral value to the already existing one and save the partial values seperatly.
			if(numpnts(range_start)>1)
				workadhf[0]+=abs(integral[range_end[i]])-abs(integral[range_start[i]])
				insertpoints numpnts(workadhfsing),1,workadhfsing
				workadhfSing[i]=abs(integral[range_end[i]])-abs(integral[range_start[i]])
			elseif(numpnts(range_start)==1)
				workadhf[0]=abs(integral[range_end[i]])-abs(integral[range_start[i]])
			endif
		endfor
	//To the found point numbers the zero-force-in-contact-point is added
	//Thereby they point numbers match the correct points in the unshrunk, complet retrace wave, which is always used to be display in the GUI-graph.
		range_start+=zeroretracecontact
		range_end+=zeroretracecontact
				//This way to calc adhesion force should be wrong since WoA has the wrong dimensions... 
				//170320 Now no calc of adhesion force. AdhF is used to calc WoA
	//Depending on the model-used recalc the force of adhesion to the work of adhesion.
	//A new calculation of adhesion force based on WoA (without area normalisation) done by integrating is not meaningful.
		if(fitmodel==1)
			adhesionf[1]=0
			workadhf[1]=adhesionf[0]/1.5/pi/proberadius
		elseif(fitmodel==2)
			adhesionf[1]=0
			workadhf[1]=adhesionf[0]/2/pi/proberadius
		endif
		if(check_woa_points_g==1)
			doupdate
		endif
	endif	
end

//Determine the contact point based on the positiv deviation of deflection from the baseline (max-separtion -> contact)
function contactpointBASEalone(forcecurve,invols,derivationbase,baselinepercent)
//Load input variables& strings.
	string forcecurve
	variable invols, derivationbase, baselinepercent
	baselinepercent/=100
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	setdatafolder $folderstring_g
	invols*=1e-9
	derivationbase*=1e-9
//Check for all types of waves availabe for this force curve.
	string content=checkfoldercontent(forcecurve)
//Use Zsnsr, if there before, using raw of the piezo movement.
	if(numberbykey("raw",content,":",";")==1)
		wave disp_re=$forcecurve+"raw_ret"
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_re=$forcecurve+"zsnsr_ret"
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
//If at least one piezo wave is there check also for deflection waves. == Is really a force curve there do it.
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name
	//Take baseline correct deflection before taking the unmodified curve.
		if(numberbykey("DeflVCo",content,":",";")==1)
		//Shorten the basename in case it is to long.
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
		//In case retraceonly is chosen the contact point for both is calced based on the retrace. Or the other way around.
			if(retraceonly_g==0)
				y_name=forcecurvecut+"DeflV_Ext_co"
			else	
				y_name=forcecurvecut+"DeflV_ret_co"
			endif	
		else
			if(retraceonly_g==0)
				y_name=forcecurve+"DeflV_Ext"
			else	
				y_name=forcecurve+"DeflV_ret"
			endif	
		endif
	//state the deflection wave to use as wave in the function.
		wave y_axis=$y_name
	//In case of retrace, reverse the point order of deflection and displacement so the search algorithms work for both trace&retrace
		if(retraceonly_g==1)
			reverse y_axis, disp_re
		endif
	//findcontact and startsearch seem redundant = point number of baselinepercent. Numberintervals sets the number of intervales in which the differentiation of the deflection is summed up.
	//Idea is in the baseline this sum should be small because slope is always close to 0. When the interval is partialy baseline&contact or only contact it's higher.
		variable findcontact=round(baselinepercent*(numpnts(y_axis)-1)), numberintervals=10
	//Differentiate the deflection wave and name it "diff_name"
		string diff_name="Diff_name"
		differentiate y_axis /D=$diff_name
		wave diff_wave=$diff_name
	//Point scaleing of the diff- wave needs to be adjusted to start at 0 and delta 1. Needed for an more convenient search codeing.
		setscale /P x, 0,1,"", diff_wave
	//A first wave with a rough interval structure is created to find the coarse transition from baseline to contact 
		string name_interval="firstinterval"
		make/N=(numberintervals)/O $name_interval	//check here
		wave firstinterval=$name_interval
		variable startsearch=findcontact
	//Intervalsearch is the number of points which are represented by one interval. 
		variable intervalsearch=round((numpnts(y_axis)-1-startsearch)/numberintervals)
		variable doloop=0
	//Calc the sum of deflection volt values within the coarse intervales and save them in the firstinterval wave.
		For(doloop=0;doloop<numberintervals;doloop+=1)
			firstinterval[doloop]=sum($diff_name,startsearch+intervalsearch*(doloop),startsearch+(doloop+1)*intervalsearch)
		endfor
	//Wavestats of this interval wave gives the average value of all intervals.
		wavestats/Q firstinterval
		doloop=0
		variable loopbreak=1
	//This loop searches for the first value within the intervals which is bigger than the average (since in the average the small baseline defl values are included)
		do
			for(doloop=0;doloop<numberintervals;doloop+=1)
				variable V_valuerep
				if(firstinterval[doloop]>V_avg)
				//V_valuerep is the found point number in the intervals which should include the contact region.
					V_valuerep=doloop
					break
				endif
			endfor
		while(loopbreak<1)
	//Now a "local" linear baseline fit is performed to get a line equation from which the measured curve then deviates to positiv values.
	//The fit length is set to 6 point% of all measured points.
		variable fitstart=(V_valuerep-2)*intervalsearch+findcontact, fitend=fitstart+round(0.06*(numpnts(y_axis)-1))
	//Make the line fit for trace and retrace, respectivly.
		if(retraceonly_g==0)
			curvefit/NTHR=0/Q line y_axis[fitstart,fitend] /X=disp_tr /D	
		else
			curvefit/NTHR=0/Q line y_axis[fitstart,fitend] /X=disp_re /D	
		endif
		string line_fit="fit_"+y_name
		line_fit=line_fit[0,30]
	//W_coef contains the line slope and y-offset.
		wave w_coef
	//Forbreak is just to be able to make a break-command within a for-loop.
	//Findcontact=initial search start; PntInCurve = initial searchstart + found intergral position * 5% of all points.
	//This *5% seems not logical right now...
//		variable forbreak=1, PntInCurve=(V_Valuerep-1)*round(0.05*(numpnts(y_axis)-1))+findcontact, defl_differ_baseline

//171108 edited: Now the fine search starts one interval before the average interval value was exceeded. (Note V_valuerep starts at 0)
		variable forbreak=1, PntInCurve=(V_Valuerep)*intervalsearch+findcontact, defl_differ_baseline
	//In case the jump-in selction was chosen, all this was useless, but it's anyway rather rarely used by me...
		controlinfo DeforCalcChoice
		if(V_value==1)
		//When jump-in/max adhesion should be set to contact point, make wave stats to find minimum.
			wavestats/Q y_axis
		//Save the contact point position [1] and displacement [2] in a result wave.
			if(retraceonly_g==0)
				make/N=4/O $forcecurve+"cont_tr"
				wave contact=$Forcecurve+"cont_tr"
				contact[2]=disp_tr[v_minrowloc+1]
				contact[1]=V_minrowloc+1	
			else	
				make/N=4/O $forcecurve+"Cont_re"
				wave contact=$Forcecurve+"cont_re"
				contact[2]=disp_re[v_minrowloc+1]
				contact[1]=numpnts(y_axis)-V_minrowloc+1	
			endif	
		//The deflection Volt at contact point [0] and the "mode" of determination [3] is saved.
			contact[0]=y_axis[V_minrowloc+1]
			contact[3]=1									
		else		
	//In case no jump-in/out is used and it is really determined by deviation:
			do
			string contactname
			//Go through all points in deflection starting at PntInCurve defined above
				for(PntInCurve=PntinCurve;Pntincurve<numpnts(y_axis);pntincurve+=1)
				//Calc the deflection difference between the current deflection and the expected baseline defleciton based on the line fit above.(2nd term important for tilted baselines)
					if(retraceonly_g==0)
						defl_differ_baseline=y_axis[pntincurve]-w_coef[1]*disp_tr[pntincurve]-w_coef[0]
						contactname=forcecurve+"cont_tr"
					else
						defl_differ_baseline=y_axis[pntincurve]-w_coef[1]*disp_re[pntincurve]-w_coef[0]	
						contactname=forcecurve+"cont_re"
					endif
				//If the deflection in meter (volt*InvOLS) is bigger than the allowed in the GUI the contact point is found
					if(defl_differ_baseline*InvOLS>derivationbase)
					//Create the save wave.
						make/N=4/O $contactname
						wave contact=$contactname
					//Make wavestats and check menu settings in gui.
						wavestats/Q y_axis
						controlinfo DeforCalcChoice
					//CAN NOT HAPPEN because if v_value==1 the function never comes here... But does do anything bad...
						if(abs(V_minrowloc-PntIncurve)<0.05*V_npnts&&V_value==1)
							contact[0]=y_axis[V_minrowloc+1]
							
							if(retraceonly_g==0)
								contact[2]=disp_tr[v_minrowloc+1]
								contact[1]=V_minrowloc+1		
							else
								contact[2]=disp_re[v_minrowloc+1]	
								contact[1]=numpnts(y_axis)-V_minrowloc+1	
							endif
							contact[3]=1		
					//So function always goes to this part.
						else
						//save the contact point infromation in the contact result wave.
							contact[0]=y_axis[pntincurve]
							
							if(retraceonly_g==0)
								contact[2]=disp_tr[pntincurve]
								contact[1]=Pntincurve
							else
								contact[2]=disp_re[pntincurve]
								contact[1]=numpnts(y_axis)-Pntincurve
							endif
							contact[3]=0
						endif
						break
					endif
				endfor
			while(forbreak<1)
		endif
	//In case the retrace is treated it was flipped in the very beginning and is now reflipped so it stays unaltered.
		If(retraceonly_g==1)
			reverse y_axis, disp_re
		endif
	//Delete the wave created and not needed anymore.
		killwaves $diff_name, firstinterval
//In case no force curve for this basename is available print an error message.
	else
		print "Please Include Deflection Waves for "+forcecurve+" to the current datafolder!"
	endif
end

//Function was intended to determining the contact point based on line fits of baseline and contact regime by their crossing point.
//Somehow it was modified over time that it at best serves to recalc the invols from the contact part. In the very end contactpointMaxDefl2BASEalone is called.
//So basically everything calced here is "overturned" by the contactpointMaxDefl2BASEalone. 
//For now I leave it that way....
function contactpointBaseContFit(forcecurve,invols,derivationbase,percentcontfit)
//Load input variables&strings like for other functions.
	string forcecurve
	variable invols, derivationbase, percentcontfit
	percentcontfit/=100
	string forcecurvecut=forcecurve
	NVAR baselinepercent_G=root:panelcontrol:singlefcPanel:baselinepercent_g
	NVAR springconstant_g=root:panelcontrol:singleFCPanel:springconst_g
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	NVAR contacttolerance=root:panelcontrol:singlefcpanel:contacttolerance_g
//Percentage of the contact part which is fitted. Fit from preliminary contact point till X% of conatct.
	NVAR percentcontfitoffset_g=root:panelcontrol:singlefcpanel:percentcontfitoffset_g
	variable baselinepercent=baselinepercent_g/100, percentcontfitoffset=percentcontfitoffset_g/100
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	setdatafolder $folderstring_g
//Set GUI graph in front and active
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay
//Get all traces from graph and remove them. Otherwise could lead to fit problems.
	getwindow mechanicspanel#mechdisplay, wavelist
	wave/T w_wavelist
	variable numberoftrace=0
	do
		string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
		if(strlen(tracesongraph)>0)
			removefromgraph $stringfromlist(0,tracesongraph,";")
		endif
	while(strlen(tracesongraph)>0)
//Recalc input values to SI units.
	invols*=1e-9
	derivationbase*=1e-9
//Check the folder which types of the force curve are present and select the piezo movement to use.
	string content=checkfoldercontent(forcecurve)
	if(numberbykey("raw",content,":",";")==1)
		wave disp_re=$forcecurve+"raw_ret"
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_re=$forcecurve+"zsnsr_ret"
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
//Check if there are deflection volt waves,too
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name
	//Use the baseline correct deflection waves if available.
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			if(retraceonly_g==0)
				y_name=forcecurvecut+"DeflV_Ext_co"
			else
				y_name=forcecurvecut+"DeflV_ret_co"
			endif		
		else
			if(retraceonly_g==0)
				y_name=forcecurve+"DeflV_Ext"
			else
				y_name=forcecurve+"DeflV_ret"	
			endif	
		endif
		wave y_axis=$y_name
///From here till next comment the same function as for contactpointBASEalone (see above for comments)
		if(retraceonly_g==1)
			reverse y_axis, disp_re
		endif
		variable findcontact=round(0.5*(numpnts(y_axis)-1)), numberintervals=10
		string diff_name="Diff_name"
		differentiate y_axis /D=$diff_name
		wave diff_wave=$diff_name
		setscale /P x, 0,1,"", diff_wave
		if(retraceonly_g==1)
			reverse diff_wave
		endif
		string name_interval="firstinterval"
		make/N=(numberintervals)/O $name_interval
		wave firstinterval=$name_interval
		variable startsearch=findcontact
		variable intervalsearch=round((numpnts(y_axis)-1-startsearch)/numberintervals)
		variable doloop=0
		For(doloop=0;doloop<numberintervals;doloop+=1)
			firstinterval[doloop]=sum($diff_name,startsearch+intervalsearch*(doloop),startsearch+(doloop+1)*intervalsearch)
		endfor
		wavestats/Q firstinterval
		doloop=0
		variable loopbreak=1
		do
		for(doloop=0;doloop<numberintervals;doloop+=1)
			variable V_valuerep
			if(firstinterval[doloop]>V_avg)
				V_valuerep=doloop
				break
			endif
		endfor
		while(loopbreak<1)
		variable fitstart=(V_valuerep-2)*intervalsearch+findcontact, fitend=fitstart+round(0.06*(numpnts(y_axis)-1))
		if(retraceonly_g==0)
			curvefit/NTHR=0/Q line y_axis[fitstart,fitend] /X=disp_tr /D	
		else
			curvefit/NTHR=0/Q line y_axis[fitstart,fitend] /X=disp_re /D	
		endif
		string line_fit="fit_"+y_name
		line_fit=line_fit[0,30]
		wave w_coef
		variable forbreak=1, PntInCurve=(V_Valuerep-1)*round(0.05*(numpnts(y_axis)-1))+findcontact, defl_differ_baseline
		if(retraceonly_g==0)
			make/N=4/O $forcecurve+"cont_tr"
			wave contact=$Forcecurve+"cont_tr"
		else
			make/N=4/O $forcecurve+"Cont_re"
			wave contact=$Forcecurve+"cont_re"
		endif
		controlinfo usecursor_defor
		variable cursordefor=V_Value
		do
		for(PntInCurve=PntinCurve;Pntincurve<numpnts(y_axis);pntincurve+=1)
			if(retraceonly_g==0)
				defl_differ_baseline=y_axis[pntincurve]-w_coef[1]*disp_tr[pntincurve]-w_coef[0]
			else
				defl_differ_baseline=y_axis[pntincurve]-w_coef[1]*disp_re[pntincurve]-w_coef[0]
			endif	
			if(defl_differ_baseline*InvOLS>derivationbase)
				wavestats/Q y_axis
				if(abs(V_minrowloc-PntIncurve)<0.05*V_npnts)
					contact[0]=y_axis[V_minrowloc+1]
					if(retraceonly_g==0)
						contact[1]=V_minrowloc+1
						contact[2]=disp_tr[v_minrowloc+1]	
					else
						contact[1]=numpnts(y_axis)-V_minrowloc+1
						contact[2]=disp_re[v_minrowloc+1]	
					endif		
					contact[3]=1		
				else
					contact[0]=y_axis[pntincurve]
					if(retraceonly_g==0)
						contact[1]=Pntincurve
						contact[2]=disp_tr[pntincurve]
						if(cursordefor>=4&&retraceonly_g==1)
							contact[1]=V_minrowloc
						endif
					else
						contact[1]=numpnts(y_axis)-Pntincurve
						contact[2]=disp_re[pntincurve]
						if(cursordefor>=4&&retraceonly_g==1)
							contact[1]=V_minrowloc
						endif
					endif
					contact[3]=0
				endif
				variable contactpoint_pre=contact[1]
				break
			endif
		endfor
		while(forbreak<1)
///End of contactpointBASEalone code. Know the baseline line equation close to contact is know.
	//Fitcontactstart is determined based on the preliminary contact point found and the percentage to be left out.		
		variable percentcontactfit=percentcontfit, fitcontactstart=numpnts(y_axis)-round(percentcontactfit*(numpnts(y_axis)-contactpoint_pre))	//new
	//Dont recall why this is in...
		if(contactpoint_pre<0.8*numpnts(y_axis)) //if no clear jump out fitstart would be on baseline. Try to fix that.
			fitcontactstart=numpnts(y_axis)*(1-0.2*percentcontfit)
		endif
	//Contact part of trace or retraces is fitted from preliminary contact point till percentcont% of contact.
		if(retraceonly_g==0)
			curvefit/X=1/nthr=0/Q line y_axis[fitcontactstart,numpnts(y_axis)-(numpnts(y_axis)-contactpoint_pre)*percentcontfitoffset]/X=disp_tr/D
		else
			curvefit/X=1/nthr=0/Q line y_axis[fitcontactstart,numpnts(y_axis)-(numpnts(y_axis)-contactpoint_pre)*percentcontfitoffset]/X=disp_re/D
		endif		
	//The fit results and the fit name are stored in variables.
		variable contactlineslope=w_coef[1], contactlineoffset=w_coef[0]			//new
		string contactfit=y_name+"ContFit"
	//The currently selected contactpoint mode is read out.
		controlinfo usecursor_defor
		cursordefor=V_Value
		variable invols_out=0
	//In case 4 or 5 is selected the newly calced InvOLS are used to recalc the force-waves.
		if((cursordefor==5||cursordefor==4)&&retraceonly_g==0)
			contact[3]=0
		//New InvOLS are calced as inverse line-slope, multiped by 1e9 to get it in nm/V
			invols_out=1/w_coef[1]*1e9
		//All force-waves are deleted when they exist.
			if(waveexists($forcecurvecut+"Force_ext")==1)
				killwaves $forcecurvecut+"Force_ext"
			endif
			if(waveexists($forcecurvecut+"Force_ext_co")==1)	
				killwaves $forcecurvecut+"Force_ext_co"
			endif
			if(waveexists($forcecurvecut+"Force_ret")==1)
				killwaves $forcecurvecut+"force_ret"
			endif
			if(waveexists($forcecurvecut+"Force_ret_co")==1)	
				killwaves $forcecurvecut+"force_ret_co"
			endif
		//The deflection volt waves are duplicate, named *force and recalced by volt*invols*spring constant.
		//Could result in an error, when there is no corrected deflection.
			wave deflv_ext=$forcecurve+"deflV_ext", deflv_ext_co=$forcecurvecut+"DeflV_ext_co"
			duplicate deflv_ext, $forcecurvecut+"Force_ext", $forcecurvecut+"Force_ext_co"
			wave force_ext=$forcecurvecut+"force_ext", force_ext_co=$forcecurvecut+"force_ext_co"
			force_ext=deflv_ext/w_coef[1]*springconstant_g; force_ext_co=deflv_ext_co/w_coef[1]*springconstant_g
			wave deflv_ret=$forcecurve+"DeflV_ret", deflv_ret_co=$forcecurvecut+"DeflV_ret_co"
			duplicate deflv_ret, $forcecurvecut+"Force_ret", $forcecurvecut+"Force_ret_co"
			wave force_ret=$forcecurvecut+"Force_ret", force_ret_co=$forcecurvecut+"Force_ret_co"
			force_ret=deflv_ret*springconstant_g/W_coef[1]; force_ret_co=deflv_ret_co/w_coef[1]*springconstant_g
	//In case new invols should be used and only retrace should be treated.
		elseif((cursordefor==5||cursordefor==4)&&retraceonly_g==1)
			contact[3]=0
			invols_out=1/w_coef[1]*1e9
			if(waveexists($forcecurvecut+"Force_ret")==1)
				killwaves $forcecurvecut+"force_ret"
			endif
			if(waveexists($forcecurvecut+"Force_ret_co")==1)	
				killwaves $forcecurvecut+"force_ret_co"
			endif
			wave deflv_ret=$forcecurve+"DeflV_ret", deflv_ret_co=$forcecurvecut+"DeflV_ret_co"
			duplicate deflv_ret, $forcecurvecut+"Force_ret", $forcecurvecut+"Force_ret_co"
			wave force_ret=$forcecurvecut+"Force_ret", force_ret_co=$forcecurvecut+"Force_ret_co"
			force_ret=deflv_ret*springconstant_g/W_coef[1]; force_ret_co=deflv_ret_co/w_coef[1]*springconstant_g
			reverse force_ret, force_ret_co	//reversed deflV is duplicated
	//In case no new invols should be used, just give back the old invols value.
		elseif(cursordefor==7||cursordefor==6)
			invols_out=invols*1e9
		endif
	//The fit name is created, the wave introduced and removed from the graph if there.
		wave Fit=$Line_fit
		string contactfit_name=y_name
		if(strlen(contactfit_name)>26)
			contactfit_name=contactfit_name[0,25]
		endif
		contactfit=contactfit_name+"ContFit"
		contactfit=contactfit[0,30]
		wave oldfit=$contactfit
		if(waveexists(oldfit)==1)// Warum? &&strlen(contactfit)!=strlen(y_name))
			killwaves $contactfit
		endif
		rename fit, $contactfit
	//Also the baseline is fitted again. Seems to be able later on to append those fit to graph and check them...
		variable fitstart_baseline=0, fitend_baseline=round(baselinepercent*PntInCurve)
		if(retraceonly_g==0)
			curvefit/X=1/nthr=0/Q line y_axis[fitstart_baseline,fitend_baseline] /X=disp_tr/D
		else
			curvefit/X=1/nthr=0/Q line y_axis[fitstart_baseline,fitend_baseline] /X=disp_re/D
		endif
		variable baseline_slope=w_coef[1], baseline_offset=W_coef[0]	//new
		contactfit=contactfit_name+"BaseFit"
		contactfit=contactfit[0,30]
		wave BaseFit=$Line_fit
		if(waveexists($contactfit)==1)// Warum??? &&strlen(contactfit)!=strlen(y_name))
			killwaves $contactfit
		endif
		rename BaseFit ,$contactfit
	//Save the contact point based on the crossing point of baseline- and contact-fit.
		Contact[2]=(contactlineoffset-baseline_offset)/(baseline_slope-contactlineslope)		//new
	//Delete 2 unneeded waves.
		killwaves diff_wave, firstinterval
	//Back flip the retrace waves if only treated.		
		if(retraceonly_g==1)
			reverse y_axis, disp_re//, force_ret, force_ret_co
		endif
		derivationbase/=1e-9
		baselinepercent*=100
	//Call a second contact point determining function... Also in my opinion the best one....
		contactpointMaxDefl2BASEalone(forcecurve,invols_out,derivationbase,baselinepercent,contacttolerance)
	else
		print "Please Include Deflection Waves for "+forcecurve+" to the current datafolder!"
	endif
//Hand back the now valid invols, so they can be displayed in gui and saved.
	return invols_out
end

//Most simple function to determine the contact point by just placing the cursor on the graph. 
//Drawback: only capable to treat one curve at a time.
function contactpointcursor(forcecurve,invols)
//Load input variables&strings
	string forcecurve
	variable invols
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	setdatafolder $folderstring_g
	invols*=1e-9
//Check which type of waves are available for the current force-curve.
	string content=checkfoldercontent(forcecurve)
//Choose one of the possible piezo displacement waves.
	if(numberbykey("raw",content,":",";")==1)
		wave disp_re=$forcecurve+"raw_ret"
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_re=$forcecurve+"zsnsr_ret"
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
//Check for the cantilever deflection waves.
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			if(retraceonly_g==0)
				y_name=forcecurvecut+"DeflV_Ext_co"
			else
				y_name=forcecurvecut+"DeflV_ret_co"
			endif
		else
			if(retraceonly_g==0)
				y_name=forcecurve+"DeflV_Ext"
			else
				y_name=forcecurve+"DeflV_ret"
			endif
		endif
	//This variable controlls which cursor should be used as CP
		variable cursortouse		//=0 for A; =1 for B
	//Which to use is determined by a series of value checks for the 2 standard cursors A&B. Only one on the graph is allowed.
		do
		if(strlen(csrinfo(a,"Mechanicspanel#mechdisplay"))!=0)
			if(strlen(csrinfo(b,"Mechanicspanel#mechdisplay"))!=0)
				print "Put only ONE marker on the graph!!!"
				break
			else
				cursortouse=0
			endif
		else
			if(strlen(csrinfo(b,"Mechanicspanel#mechdisplay"))!=0)
				cursortouse=1
			else
				print "Put a cursor on the graph!"
				break
			endif
		endif
	//Create the contact-point results containg wave.
		wave y_axis=$y_name
		if(retraceonly_g==0)
			make/N=4/O $forcecurve+"Cont_tr"
			wave contact=$Forcecurve+"cont_tr"
		else
			make/N=4/O $forcecurve+"Cont_re"
			wave contact=$Forcecurve+"cont_re"
		endif
	//If cursor A should be used.
		if(cursortouse==0)
		//Read out the deflection voltage value
			contact[0]=y_axis[pcsr(a,"mechanicspanel#mechdisplay")+1]
		//Point number
			contact[1]=pcsr(a,"mechanicspanel#mechdisplay")+1
		//Piezo-displacement value.
			if(retraceonly_g==0)
				contact[2]=disp_tr[pcsr(a,"mechanicspanel#mechdisplay")+1]	
			else
				contact[2]=disp_re[pcsr(a,"mechanicspanel#mechdisplay")+1]	
			endif	
		//Just a value to see later on which kind of CP-evaluation was used.
			contact[3]=0		
		else
			contact[0]=y_axis[pcsr(B,"mechanicspanel#mechdisplay")]
			contact[1]=pcsr(B,"mechanicspanel#mechdisplay")
			if(retraceonly_g==0)
				contact[2]=disp_tr[pcsr(b,"mechanicspanel#mechdisplay")]	
			else
				contact[2]=disp_re[pcsr(b,"mechanicspanel#mechdisplay")]	
			endif	
			contact[3]=0
		endif
		while(cursortouse<-1)
	endif
end

//Function calcing the contact point by search from maximium contact the first value equal to the baseline value.
//Currently my most favorite CP-function.
function contactpointMaxDefl2BASEalone(forcecurve,invols,derivationbase,baselinepercent,contacttolerance)
//Load input variables&strings.
	string forcecurve
	variable invols, derivationbase, baselinepercent, contacttolerance
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	setdatafolder $folderstring_g
	contacttolerance*=1e-9
	invols*=1e-9
	derivationbase*=1e-9
	baselinepercent/=100
//Check folder which types of waves for the current force curve are there.
	string content=checkfoldercontent(forcecurve)
	if(numberbykey("raw",content,":",";")==1)
		wave disp_re=$forcecurve+"raw_ret"
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_re=$forcecurve+"zsnsr_ret"
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
//Check for the deflection waves availabel.
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name_tr, y_name_re
	//Use baseline corrected defleciton waves if possible.
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name_tr=forcecurvecut+"DeflV_Ext_co"
			y_name_re=forcecurvecut+"DeflV_ret_co"
		else
			y_name_tr=forcecurve+"DeflV_Ext"
			y_name_re=forcecurve+"DeflV_ret"
		endif
	//In case only the trace should be treated-> search and calculation needs to be a little different since trace and retrace are in different point order.
		if(retraceonly_g==0)
			wave y_axis=$y_name_tr
		//Variables containing the mean value of the baseline, the baseend (based on the input baselinepercent), variance (and to test var. to check while debugging)
			variable meanvalueBASE, baseend=round((1-0.2)*(numpnts(y_axis)-1)*baselinepercent), varianceBASE, test1, test2
			test1=pnt2x(y_axis,0)
			test2=pnt2x(y_axis,baseend)
		//Average value of the baseline
			meanvalueBASE=mean(y_axis,pnt2x(y_axis,0),pnt2x(y_axis,baseend))
		//Variance of the baseline, giving feedback of the noise in the curve.
			variancebase=(variance(y_axis,pnt2x(y_axis,0),pnt2x(y_axis,baseend)))^0.5*2
		//Reverse the point order in retrace to better search for the correct point.
			reverse y_axis
		//Target value is the derivation in volts(input as nm) with the volt-tolerance(input also as nm) which are recalced with the invol.
			findvalue/V=(derivationbase/invols)/T=(contacttolerance/invols) y_axis
		//The cp-results are saved
			make/N=4/O $forcecurve+"Cont_TR"
			wave contact=$Forcecurve+"cont_TR"
			contact[2]=disp_tr[numpnts(y_axis)-V_value]
			contact[0]=y_axis[V_value]
			contact[1]=numpnts(y_axis)-V_value
			contact[3]=0
			reverse y_axis
		endif
	//Do the same evalution as above for the retrace.
		wave y_axis=$y_name_re
		reverse y_axis, disp_re
		baseend=round((1-0.2)*(numpnts(y_axis)-1)*baselinepercent)
		test1=pnt2x(y_axis,0)
		test2=pnt2x(y_axis,baseend)
		meanvalueBASE=mean(y_axis,pnt2x(y_axis,0),pnt2x(y_axis,baseend))
		variancebase=(variance(y_axis,pnt2x(y_axis,0),pnt2x(y_axis,baseend)))^0.5*2
		reverse y_axis
	//Since for the retrace there could be a different deflection point spaceing as for trace (typically bigger) the contacttolerance is stepwise increased if no point was found.
		do
			findvalue/V=(derivationbase/invols)/T=(contacttolerance/invols) y_axis
			if(v_value==-1)
				contacttolerance+=0.05e-9
			endif
			if(contacttolerance>6e-9)
				break
			endif
		while(V_Value==-1)
		make/N=4/O $forcecurve+"Cont_re"
		wave contact=$Forcecurve+"cont_re"
		contact[2]=disp_re[numpnts(y_axis)-V_value]
		contact[0]=y_axis[V_value]
		contact[1]=numpnts(y_axis)-V_value
		contact[3]=0
		reverse disp_re
		else
		print "Please Include Deflection Waves for "+forcecurve+" to the current datafolder!"
	endif
end

//Function calculating the deformation based on the determined contact-point and the InvOLS.
function DeformationAlone(forcecurve,invols)
//Load input variables&strings.
	string forcecurve
	variable invols
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	setdatafolder $folderstring_g
	invols*=1e-9
//Check folder for available wave types for the current force-curve.
	string content=checkfoldercontent(forcecurve)
//Load the piezo-movement.
	if(numberbykey("raw",content,":",";")==1)
		wave disp_re=$forcecurve+"raw_ret"
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_re=$forcecurve+"zsnsr_ret"
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
	variable towd
	if(numberbykey("Towd",content,":",";")==1)
		towd=1
		if(error1==0)
			wave disp_towd=$forcecurve+"Raw_Towd"
		elseif(error2==0)
			wave disp_towd=$forcecurve+"ZSnsr_Towd"
		endif
	endif
//check for deflection waves. Take baseline corrected ones if there.
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name_tr, y_name_re, y_name_to
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name_tr=forcecurvecut+"DeflV_Ext_co"
			y_name_re=forcecurvecut+"DeflV_Ret_co"
			if(towd==1)
				y_name_to=Forcecurvecut+"DeflV_Towd_c"
				wave y_axis_to=$y_name_to
			endif
		else
			y_name_tr=forcecurve+"DeflV_Ext"
			y_name_re=forcecurve+"DeflV_Ret"
			if(towd==1)
				y_name_to=Forcecurve+"DeflV_Towd_c"
				wave y_axis_to=$y_name_to
			endif
		endif
		wave y_axis_tr=$y_name_tr
		wave y_axis_re=$y_name_re
	//Create the name for the deformation waves.
		string defor_tr=forcecurve+"Defor_Ext"
		string defor_re=forcecurve+"Defor_Ret"
		if(towd==1)
			string defor_to=Forcecurvecut+"Defor_Towd"
		endif
	//In case not only retrace is selected both are treated. The piezo-displacement wave is duplicated and named *defor
		if(retraceonly_g==0)
			duplicate/O disp_tr, $defor_tr
			if(towd==1)
				duplicate /O disp_towd, $defor_to
				wave deforW_to=$Defor_to
			endif
		endif
	//In all cases the retrace displacement is dulicated and named *defor.
		duplicate/O disp_re, $defor_re
		wave deforW_tr=$defor_tr
		wave deforW_re=$defor_re
	//In case trace is also treated take the contact point from trace (since while retracting the sample could be further stretched)
		if(retraceonly_g==0)
			wave contact=$forcecurve+"cont_TR"
		else
			wave contact=$forcecurve+"cont_re"
		endif
	//Contact[3] is set to 1 in case the jump-in or jump-out point is choosen for cp-calc.
		if(contact[3]==1)
		//Make a wavestats to find the wave minimum.
			if(retraceonly_G==0)
				wavestats/Q y_axis_tr
			else
				wavestats/Q y_axis_re
			endif
		//in case the minimum is the very first point take the 1. point.
			if(deforW_tr[V_minrowloc]==0) //happens practically never
				deforW_tr-=deforW_tr[V_minrowloc+1]
				deforW_re-=deforW_re[V_minrowloc+1]
				if(towd==1)
					deforW_to-=deforW_tr[V_minrowloc+1]
				endif
			endif
		//Calc the deformation by substracting the cantilever deflection from the piezo movement.
			if(retraceonly_g==0)
				deforW_tr-=y_axis_tr*InvOLS
				if(towd==1)
					deforW_to-=y_axis_to*InvOLS
				endif
			endif
			deforW_re-=y_axis_re*InvOLS
			variable secondshift
		//Since this can lead to small offsets, due to non-zero deflection at the contact point a second shifting of the deformation values is performed.
		//At the minimum of the deflection curve 0 deformation is intended. Therefore, the deformation at this point is again substracted from the deformation setting it really to 0.
			if(retraceonly_g==0)
				secondshift=deforW_tr[V_minrowloc]
			else
				secondshift=deforW_re[V_minrowloc]
			endif
			if(retraceonly_g==0)
				deforW_tr-=secondshift
				if(towd==1)
					deforW_to-=secondshift
				endif
			endif	
			deforW_re-=secondshift
	//In case not the minimum should be taken.
		else
			if(retraceonly_g==0)
			//In contact[1] the contact point number is saved. If it is not zero actually a contact point was found.
				if(deforW_tr[contact[1]]!=0)
				//Contact[2] contains the piezo-movement position where the contact point was found.
				//This value is substracted from the deformation wave (which is until now the raw duplicate piezo-displacement wave) so it is 0 at this point.
					deforW_tr-=contact[2]
					deforW_re-=contact[2]
					if(towd==1)
						deforW_to-=contact[2]
					endif	
				endif
			else
				if(deforW_re[contact[1]]!=0)
					deforW_re-=contact[2]
				endif
			endif
		//Now the cantilever deflection is substracted from the deformation wave.
			if(retraceonly_g!=1)
				deforW_tr-=y_axis_tr*InvOLS
				if(towd==1)
					deforW_to-=y_axis_to*Invols
				endif
			endif
			deforW_re-=y_axis_re*InvOLS
		endif
	endif	
end

//Function calculating the power-low exponent of the contact part of the force-curve. Can be used in mechanical characterisation to rule out some models.
function contactexponentalone(forcecurve,contacttolerance,exponentoffset,fitmaximum,absolutvalue,reduceddisplay)
//Load input varialbes&strings.
	string forcecurve
//Cont.toler. sets the search tolerance; Expoff: the offset inwards the contact part; 
//Fitmax & absolutevalue depend on from which function this one is called. 
	variable contacttolerance, exponentoffset, fitmaximum, absolutvalue, reduceddisplay
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	setdatafolder $folderstring_g
//Relict from the past, is not any more called that way but I leave it here, just in case...
	if(exponentoffset<1)		//is typically the lowerlimit fit value from hertzfitting
		exponentoffset*=1e-9
	endif	
//These values are handed in from hertz-fit function. In case absolutevalue =1 fitmaximum holds a the upperfit limit in nm. Since it is befor divided by 100 it is multipled with 100*1e-9
	contacttolerance*=1e-9; fitmaximum/=100
	if(absolutvalue==1&&fitmaximum<1)
		fitmaximum*=100e-9
	endif
//Check which types of wave for the current force curve are available. Force and Deformation are needed.
	string content=checkfoldercontent(forcecurve)
	if(numberbykey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=Forcecurvecut+"Force_Ext_co"
		else
			y_name=forcecurve+"Force_Ext"
		endif
		wave y_axis=$y_name
		wave defor_tr=$forcecurve+"Defor_Ext"
	//Include the contact-point result wave
		wave contact=$forcecurve+"cont_TR"
		variable offsetdefor
	//Check which mechanical model was chosen to fit and if a deformation offset was allowed in the fit.
		controlinfo/W=MechanicsPanel#FitPanelEMod FitFunctionChoiceAl
		variable fittype=V_value
		controlinfo/W=MechanicsPanel#FitPanelEMod HertzFitOffset
		variable offset_on=V_value
	//If there is already a Hertz-result wave take the fitted deformation offset.
		if(waveexists($forcecurve+"Hertz")==1&&offset_on==1)
			wave hertzvalues=$Forcecurve+"Hertz"
			offsetdefor=hertzvalues[4]
		endif
	//In the second case also the reissner model could be chosen -> read deformation offset out of reissner result wave
		if(fittype==5&&offset_on==1)
			wave reissnervalues=$forcecurve+"Reis"
			offsetdefor=reissnervalues[4]
		endif
		variable fitoffset
	//As above the first if should never be hit.
		if(exponentoffset<1)
			findvalue/S=(contact[1])/T=(contacttolerance)/V=(exponentoffset) defor_tr
			fitoffset=V_Value
	//Store the deformation from which the acutal fit starts.
		else
			fitoffset=exponentoffset
		endif
	//Define some more variables and the name of the log(deformation) and log(force)	
		variable endpntfit, deformationdepth2fit
		string defor_log="log_"+forcecurve+"Defor"
		string force_log="log_"+forcecurve+"For"
	//Reduced display was before to dis/allow a separate graph for the log-log-plot.
		//if(reduceddisplay==0)
		//Check all open windows and delete all which have "Force_log0" in their names.
			string openwindows=winlist("*",";","win:1")
			if(stringmatch(openwindows,"*"+force_log+"0*")==1)//||stringmatch(openwindows,"*"+force_log+"2*")==1)
				killwindow $force_log+"0"
			//	killwindow $force_log+"20"
			endif
		//endif
	//Kill the log(force) waves which will be created later if present.
		if(waveexists($force_log)==1)
			killwaves $force_log
		endif
		if(waveexists($force_log+"2")==1)
			killwaves $force_log+"2"
		endif
	//Duplicate deformation and force wave in from contact-point till maximum deformation.
		if(waveexists($force_log)==1&&waveexists($force_log+"2")==0)
			duplicate/O/R=[contact[1],numpnts(y_axis)-1] defor_tr, $defor_log+"2"
			duplicate/O/R=[contact[1],numpnts(y_axis)-1] y_axis, $force_log+"2"		
			wave deforW_log=$defor_log+"2", forceW_log=$force_log+"2"
			force_log=force_log+"2"
		elseif(waveexists($force_log)==0&&waveexists($force_log+"2")==0)
			duplicate/O/R=[contact[1],numpnts(y_axis)-1] defor_tr, $defor_log
			duplicate/O/R=[contact[1],numpnts(y_axis)-1] y_axis, $force_log	
			wave deforW_log=$defor_log, forceW_log=$force_log
		endif
		variable negDeflCheck, corstartPosi=0
	//Check which is upperlimit from the mechanical fitting, which is also the limit for the contact-exponent fitting.
		if(fitmaximum==1)
			endpntfit=numpnts(y_axis)-1
		elseif(fitmaximum*100>100)	//This is for the handleing from Emod fits. Above it was /100 now it's remultiplied.
			endpntfit=fitmaximum*100
		elseif(absolutvalue!=1)
			deformationdepth2fit=fitmaximum*defor_tr[numpnts(y_axis)-1]
			findvalue/S=(fitoffset)/T=(1.5e-9)/V=(deformationdepth2fit) defor_tr
			endpntfit=V_Value
		elseif(absolutvalue==1)
			deformationdepth2fit=fitmaximum
			findvalue/S=(fitoffset)/T=(1.5e-9)/V=(deformationdepth2fit) defor_tr
			endpntfit=V_Value
		endif
	//It is possible that the first points in the force-wave are negative. But negative values in log() created errors.
	//Check for negative values, delete them and set a counter of these events so lower-upperlimitfit are still correct in terms of point-number.
		if(forceW_log[numpnts(forceW_log)-numpnts(y_axis)+fitoffset]<0)
			do
				if(forceW_log[0]<0)
					deletepoints 0,1, forceW_log, deforW_log
					negdeflcheck=-1
					corstartposi+=1
				else
					negdeflcheck=1
				endif
			while(negdeflcheck<0)
		else
			//deletepoints 0,(numpnts(forceW_log)-numpnts(y_axis)+fitoffset-1), forceW_log, deforW_log //useless because number of points to delete = 0 bzw -1
		endif
	//Transform the deformation and force to log values.
		deforW_log=log(deforW_log-offsetdefor)
		forceW_log=log(forceW_log)
		variable deletedpoints
	//Again delete all points in deformation and which are now NaN. 
		do
			deletepoints 0,1, deforW_log, forcew_log
			deletedpoints+=1
		while(numtype(deforW_log[0])==2)
	//Define, create and include a wave storing the contact exponent results.
		string expo=forcecurve+"expo"
		make/O/N=3 $expo
		wave expoW=$expo
	//Check the fit range of the force for still existing NaNs since this would cause wrong values.
		wavestats/Q/R=[fitoffset-deletedpoints-contact[1],endpntfit-deletedpoints-contact[1]] forceW_log
	//In case no NaNs are found and an endpoint was defined above. make a line fit of the log-log in the concerned region.
		if(V_numnans<1&&endpntfit>0)
			curvefit/NTHR=0/Q line forceW_log[fitoffset-deletedpoints-contact[1],endpntfit-deletedpoints-contact[1]] /X=deforW_log/D
		endif
		wave w_coef, w_sigma
	//Store the concact exponent, it's standard deviation, and Chis square value.
		expoW[0]=w_coef[1]
		expoW[1]=w_sigma[1]
		expoW[2]=V_chisq
	//If not the reduce display is selected make a log-log graph + fit and textbox of the results.
		if(reduceddisplay==0)
			string fit_name="Fit_"+force_log
			display/N=$force_log forceW_log vs deforW_log
			Modifygraph mode($force_log)=3
			appendtograph $fit_name
			modifygraph lsize($fit_name)=2, rgb($fit_name)=(0,0,52224)
			TextBox/C/N=text0/A=LT "Slope : "+num2str(w_coef[1])+" ± "+num2str(w_sigma[1])+"\rV_chisq = "+num2str(V_chisq)
		endif
	endif
end

//Function setting the frame for Hertz-Model fitting
Function EModulusHertzAlone(forcecurve, emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
//Load input variables&strings.	
	string forcecurve
//Important to explain:
//Emoduloffset: deformation offset from the contactpoint in nm; Percentcontactfit: % of the max. deformation which is fitted.
//depthcontactfit: absolut nm value to be used as upper fit limit. fitlength: length of the fit in nm.
	variable emoduloffset, percentcontactfit, contacttolerance,EModulGuess, SphereRadius, PossionRatio, usecursorvar, sampleradius,depthcontactfit_g, fitlength_g
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g, showlog_g=root:panelcontrol:singlefcpanel:showlog_g
//Checkbox value: if selected it is supposed to search for the best hertz-model fit range. Doesnt work to good though.
	nvar searchfit=root:panelcontrol:fit_panel:searchfit_g
	setdatafolder $folderstring_g
//Set all variables to SI-units.
	emoduloffset*=1e-9; percentcontactfit/=100; SphereRadius*=1e-6; contacttolerance*=1e-9; sampleradius*=1e-6; depthcontactfit_g*=1e-9; fitlength_g*=1e-9
//Define some varialbes&strings used in the processes of fitting.
	variable  checkcontactPnt, correctionPnts=0, chosenModel
	variable lowerlimitfit, upperlimitfit, doloop=0
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	string contactPnts="ContactPntsFM", hertz_fit, hertz_fit_name, force_trace, contactexpo="ContactExponent"
//Check folder for which types of waves are present for the force-curve.
	string content=checkfoldercontent(forcecurve)
//Check if deformation and force waves are present, bcs they are needed for hertz-fitting.	
	if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
	//Take baseline corrected force-waves if present.
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=Forcecurvecut+"Force_Ext_co"
		else
			y_name=forcecurve+"Force_Ext"
		endif
	//Load the contact-point result wave.
		string contactstr=Forcecurve+"cont_TR"
		wave contact=$contactstr
	//Transfer the contact-point point-number to this variable
		checkContactPnt=contact[1]
		do	//just to be able to perform a break-command
	//In case no contact point was found before a mechanical fitting doesnt make sense.	
		if(checkContactPnt>0)
			wave defor_tr=$forcecurve+"Defor_Ext"
			wave y_axis=$y_name
			variable fitmaximum, absolutvalue
		//In case no special fit-range-searching is intended, as by now recommened since this search does work to well.
			if(searchfit==0)
			//Usecursorvar is the checkbox-control-variable which turns 1 if selected to use a cursor from the graph.
				if(usecursorvar==0)
				//Differentiate the 3 different ways to select the upper (highest deformation) limit of the fit
				//1. percentcontactfit =1 ==100% => take the last point of the deformation wave.
					if(percentcontactfit==1)
						upperlimitfit=numpnts(defor_tr)-1
				//2. percentcontactfit is not 0 and no explicit fit-depth is chosen.
					elseif(percentcontactfit!=0&&depthcontactfit_g==0)
					//Deformation value which should be used to fit is calced by X% of maximum deformation
						variable deformationdepth2fit=percentContactFit*(defor_tr[numpnts(defor_tr)-1])
					//Corresponding point-number of this deformation is search.
						findvalue/S=(contact[1]+round(0.05*(numpnts(defor_tr)-1-contact[1])))/T=(1.5e-9)/V=(deformationdepth2fit) defor_tr
						upperlimitfit=V_Value
					//If V_value==-1 no value was found. To not produce an error the upper limit is set to maximum deformation so at least the fit works.
						if(upperlimitfit==-1)
							upperlimitfit=numpnts(defor_tr)-1
						endif
					//Fitmax and absolutvalue are set, which will later be used to determine the contact exponent.
						fitmaximum=percentcontactfit*100
						absolutvalue=0
				//3. Percent = 0 and a contact depth to fit is set.
					elseif(percentcontactfit==0&&depthcontactfit_g!=0)
					//Search this contact-depth in the deformation wave
						findvalue/S=(contact[1]+round(0.05*(numpnts(defor_tr)-1-contact[1])))/T=(1.5e-9)/V=(depthcontactfit_g) defor_tr
					//see case 2
						upperlimitfit=V_Value
						if(upperlimitfit==-1)
							upperlimitfit=numpnts(defor_tr)-1
						endif
						fitmaximum=depthcontactfit_g*1e9
						absolutvalue=1
					endif
				//3 ways to find the fit start called lowerlimitfit
				//1. no offset and fitlength are selected
					if(emoduloffset==0&&fitlength_g==0)
					//Use the contact point.
						lowerlimitfit=contact[1]
				//2. a fit-offset is chosen and no specified fit length
					elseif(emoduloffset!=0&&fitlength_g==0)
					//search for the offset value.
						findvalue/S=(contact[1])/T=(5e-9)/V=(emoduloffset) defor_tr
						lowerlimitfit=V_Value
				//3. A specific fitlength is chosen but no emoduloffset
					elseif(fitlength_g!=0)
					//Use the upperlimit determined above and substract the length to find the fit start.
						findvalue/S=(contact[1])/T=(5e-9)/V=(defor_tr[upperlimitfit]-fitlength_g) defor_tr
						lowerlimitfit=V_Value
					endif
			//The A&B cursors should be used as fitrange. Just determine which cursor is the upper&lower one.
				else
					if(pcsr(A,"mechanicspanel#mechdisplay")>pcsr(B,"mechanicspanel#mechdisplay"))
						upperlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
					else
						upperlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
					endif
				
				endif
			//In case either no lower or upper value was found the fit doesnt work so stop function here.
				if(lowerlimitfit==-1||upperlimitfit==-1)
					break
				endif
			//Make a wave to store the results from the hertz fit.
				Make/N=5/O $forcecurve+"Hertz"
				wave Hertz=$forcecurve+"Hertz"
				hertz[4]=0	//The deformation offset fitted is set to 0, in case the hertz-wave already existed.
//Here the fit-search stuff was standing, but since it does not work it's commatized.
//			else
//				wave Hertz=$forcecurve+"Hertz"
//				lowerlimitfit=hertz[2]
//				upperlimitfit=hertz[3]
			endif
		//	variable input=defor_tr[contact[1]]*1e9
//			if(searchfit==1)
//				variable newlowerlimitfit=searchfitreagion(forcecurvecut,contact[1],percentcontactfit/100)+contact[1]
//				lowerlimitfit=newlowerlimitfit
//				emoduloffset=defor_tr[newlowerlimitfit] 
//			endif
		//Check the mechanical panel, if sphere-sphere or sphere-plane geometrie is set.	
			controlinfo/W=MechanicsPanel#FitPanelEMod fitfunctiongeometery
			variable sphsph=V_Value
		//check the mechanical panel, if the fit is allowed to fit a deformation offset.
			controlinfo/W=MechanicsPanel#FitPanelEMod hertzfitoffset
			variable allowfitoffset=V_value
		//duplicate the force wave to create a residual wave.
			duplicate/O y_axis, $Forcecurve+"Res"
			wave residual=$forcecurve+"Res"
		//The force and deformation waves are duplicated in from contact-point to upper limit fitted to have waves for the "recalculated" hertz fit waves (see later)
			duplicate/O/R=[contact[1],upperlimitfit] y_axis, $Forcecurve+"HFIT_F"
			duplicate/O/R=[contact[1],upperlimitfit] defor_tr, $Forcecurve+"HFIT_D"
			wave HFIT_F=$Forcecurve+"HFIT_F", HFIT_D=$forcecurve+"HFIT_D"
		//Two Hertz-fits are present whether sphere-sphere or sphere-plane is selected.
		//1. Sphere plane
			if(sphsph==1)
			//is a deformation offset allowed in the fit
				if(allowfitoffset==0)
				//Make 2 waves for the fit result values (w_coef) and their standard-deviations (w_sigma)
					Make/D/N=3/O W_coef, W_sigma
				//Put the initial guesses in the w_coef wave so the individual fit can work
					W_coef[0] = {EModulGuess, SphereRadius, PossionRatio}
				//Run the hertz-fit; H=011 states that the sphereradius and poisson-ratio should not be fitted. only E-Modul!
					FuncFit/H="011"/NTHR=0/Q HertzModelAl W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000, 7}/R=residual /A=0
				//Hertz4= is the fit-offest determined.
					hertz[4]=0
				//Based on the fit results the according "hertz-force" from contact-point to maximum fitted deformation is recalculated.
					HFIT_F=4/3*w_coef[0]*(1/w_coef[1])^-0.5/(1-w_coef[2]^2)*HFIT_D^(3/2)
			//The fit function is allowed to shift the force-deformation curve in deformation.
				else
				//Create results and there standard deviation waves
					Make/D/N=4/O W_coef, W_sigma
				//Also make a wave holding contraints for the allowed deformation offset
					make/D/N=2/O/T T_Constraints
				//The offset is limited to negative value of the lowerlimit of the deformation (otherwise the deformation could become negative and hertz-equation is undefined) and limits it to 1.5um(which seems quiet high...)
					T_constraints[0]={"K3>-"+num2str(defor_tr[lowerlimitfit]),"K3<15e-7"}
				//As above. Initial offset is set to 5nm
					W_coef[0] = {EModulGuess, SphereRadius, PossionRatio,5e-9}
				//Make the hertz fit while the e-modul and the deformation-offset are fitted.
					FuncFit/H="0110"/NTHR=0/Q HertzModelAloffset W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000, 7}/R=residual /A=0/C=T_constraints
				//Save the resulting defor-offset, print the found offset and recalc the hertz-force
					hertz[4]=w_coef[3]
					print "Contact Point Offset :"+num2str(w_coef[3])
					HFIT_F=4/3*w_coef[0]*(1/w_coef[1])^-0.5/(1-w_coef[2]^2)*(HFIT_D-W_coef[3])^(3/2)
				endif
		//Same as the stuff above but also include the radius of the sphere which gets intended into the fit.
			elseif(sphsph==2)
				if(allowfitoffset==0)
					Make/D/N=4/o W_coef, W_sigma
					W_coef[0]={EModulGuess,SphereRadius,PossionRatio,SampleRadius}
					FuncFit/H="0111"/NTHR=0/Q HertzModelAlSphSph W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /R=residual /A=0//F={0.950000, 7}
					hertz[4]=0
					HFIT_F=4/3*w_coef[0]*(1/w_coef[1]+1/w_Coef[3])^-0.5/(1-w_coef[2]^2)*HFIT_D^(3/2)
				else
					Make/D/N=5/o W_coef, W_sigma
					make/D/N=2/O/T T_Constraints
					T_constraints[0]={"K4>-2e-7","K4<15e-7"}
					W_coef[0]={EModulGuess,SphereRadius,PossionRatio,SampleRadius,5e-9}
					FuncFit/H="01110"/NTHR=0/q HertzModelAlSphSphOffset W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /R=residual /A=0/C=T_constraints//F={0.950000, 7}
					hertz[4]=w_coef[4]
					print "Contact Point Offset :"+num2str(w_coef[4])
					HFIT_F=4/3*w_coef[0]*(1/w_coef[1]+1/w_Coef[3])^-0.5/(1-w_coef[2]^2)*(HFIT_D-W_coef[4])^(3/2)
				endif
			endif
		//Save all results in the Hertz-Wave
			Hertz[0]=W_coef[0]	//Found E-modul in Pa
			Hertz[1]=W_sigma[0]	//determined fit-deviation; often to low since only statistical
			hertz[2]=lowerlimitfit	//The fit limits
			hertz[3]=upperlimitfit
		//In case only a single curve is fitted.
			if(wholefolder_g!=1)
			//Determine the contact exponent and either make a new graph of log-log (==1) or dont make a extra graph
				if(showlog_g==1)
					contactexponentalone(forcecurve,contacttolerance*1e9,lowerlimitfit,upperlimitfit,absolutvalue,0)
				else
					contactexponentalone(forcecurve,contacttolerance*1e9,lowerlimitfit,upperlimitfit,absolutvalue,1)		
				endif
		//If the whole folder is fitted calc the contact-exponent so the expo-value can be displayed in the GUI-textbox
			else
				contactexponentalone(forcecurve,contacttolerance*1e9,lowerlimitfit,upperlimitfit,absolutvalue,1)
			endif
							
//			//input=emoduloffset*1e9
//			if(wholefolder_G!=1&&allowfitoffset==1)
//		//		contactexponentalone(forcecurve,contacttolerance*1e9,input,upperlimitfit)
//			endif
		//Define the name of the hertz fit and include it as wave
			hertz_fit="fit_"+y_name
			hertz_fit=hertz_fit[0,30]
			wave fit_wave=$hertz_fit
			Hertz_fit_name="HertzFit"+forcecurve
		//Removes all hertz-related traces from the gui-graph.
			do
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
				variable posi=strsearch(tracesongraph,"Hertz",0)
				if(posi!=-1)
					removefromgraph $stringfromlist(0,tracesongraph[posi,strlen(tracesongraph)],";")
				endif
			while(strsearch(tracesongraph,"Hertz",0)>0)
		//If there is a wave named as the current hertz fit from former fitting -> delete the old fit wave			
			if(waveexists($hertz_fit_name)==1)
				killwaves $hertz_fit_name
			endif
		//Rename the new fit-wave
			rename fit_wave, $Hertz_fit_name
		//The Invols and the spring constant are also loaded to hit of the more elaborated hertz error calculation function. The overall error is then stored in erroremodul.
			NVAR invols=root:panelcontrol:singleFCPanel:invols_g, springconstant=root:panelcontrol:singlefcpanel:springconst_g
			variable errorEmodul=errorHertzFit(forcecurve,Invols,possionratio,sphereradius,sampleradius,springconstant,allowfitoffset)
		//Load the showfit variable, which is set in the "display control" of GUI and check if there should be a graph update if only one curve is fitted.
			NVAR showfit=root:panelcontrol:singlefcpanel:showfit_g
			if(showfit==1&&wholefolder_g==0)
			//Also more a relict from the past. A simple "updatedisplayalone" would also do the trick (only more code needs to be run)
				wave exponent=$forcecurvecut+"expo"
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				TextBox/K/N=text0
				appendtograph hfit_f vs hfit_d
				appendtograph $hertz_fit_name
				ModifyGraph lsize($hertz_fit_name)=2
				ModifyGraph rgb($hertz_fit_name)=(0,12800,52224)
				Modifygraph rgb($forcecurve+"HFIT_F")=(0,0,0)
				ModifyGraph rgb($y_name)=(65280,0,0)
				SetAxis bottom -2e-08,defor_tr[upperlimitfit]
				setaxis left 0e-9,y_axis[upperlimitfit]
				TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(hertz[0])+" ± "+num2str(hertz[1])+" Pa\rContact Slope: "+num2str(exponent[0])+" ± "+num2str(exponent[1])
			if((1.45<exponent[0]&&exponent[0]<1.48)||(1.52<exponent[0]&&exponent[0]<1.55))
				TextBox/C/N=text2/B=(65280,43520,0) "        \r           "
			elseif(1.48<exponent[0]&&exponent[0]<1.52)
				TextBox/C/N=text2/B=(0,65280,0) "        \r           "
			else
				TextBox/C/N=text2/B=(65280,0,0) "        \r           "
			endif
			endif
		endif
		while(doloop<-1)
	else
		Print "No data for "+forcecurve+" could be found in current folder!"	
	endif
end

//This function calcs the real error of hertz fit based on error propagation.
function errorHertzFit(forcecurve,Invols,possionratio,sphereradius,sampleradius,springconstant,allowfitoffset)
//Load input variables&strings.
	string forcecurve						//forcecurve=basename
	variable invols, possionratio,sphereradius, sampleradius, springconstant, allowfitoffset
	invols*=1e-9
//The errors of Invols, probe radius and spring constant are set to typical values, but can be overturned later by the ones set in the errorpanel
	variable errorInvOLS=0.1*invols, errorSphereRadius=0.5e-6,  errorSpring=0.1*springconstant
	variable errorcontact, fitoffset
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g, showlog_g=root:panelcontrol:singlefcpanel:showlog_g
//The error in deformation based on the contactpiont is set to 5nm as a start.
	if(allowfitoffset==0)
		 errorContact=5e-9
		 fitoffset=0
	else
		wave hertz=$forcecurve+"Hertz"
		errorcontact=5e-9
		fitoffset=hertz[4]
	endif
//In case sphere sphere contact is selected the effectiv radius is calced.
	variable effectiveradius=sphereradius
	controlinfo/W=MechanicsPanel#FitPanelEMod FitFunctionGeometery
	if(V_value==2&&sampleradius!=0)
		effectiveradius=((1/sphereradius)+(1/sampleradius))^-1
	endif
//The error values stated in the error panel are loaded.		
	setdatafolder root:panelcontrol:fit_panel:
	NVAR error_SpringConstAbs_g, Error_Invols_g, Error_radiusSample_g, Error_radiusProbe_G, Error_contactPoint_g//, Error_shellthickness_g
	NVAR error_springConst_avg, error_invols_avg, error_effradius_avg, error_contactpoint_avg, error_fit_avg, error_total_avg, error_shellthickness_avg
	error_shellthickness_avg=0
//The next if's check if there is a hand-set error value in the error-panel or not (in that case use the standard values)
	if(error_springconstabs_g>0)
		errorspring=error_springconstabs_g
	endif
	if(error_invols_g>0)
		errorINvols=error_invols_g*1e-9
	endif
	if(error_radiusprobe_g>0&error_radiussample_g>0)
		errorsphereradius=((((sphereradius+sampleradius)*sampleradius-sampleradius*sphereradius)/(sampleradius+sphereradius)^2)^2*(error_radiusprobe_g*1e-6)^2+(((sphereradius+sampleradius)*sphereradius-sphereradius*sampleradius)/(sampleradius+sphereradius)^2)^2*(error_radiussample_g*1e-6)^2)^0.5
	elseif(error_radiusprobe_g>0&&error_radiussample_g<=0)
		errorsphereradius=error_radiusprobe_g*1e-6
	endif
	if(error_contactpoint_g>0)
		errorcontact=error_contactpoint_g*1e-9
	endif
//State the force curve
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	setdatafolder $folderstring_g
	variable lowerlimitfit, upperlimitfit
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	string contactPnts="ConcatPntsFM", hertz_fit, hertz_fit_name, force_trace, contactexpo="ContactExponent"
//Check for force-curve content in the folder.
	string content=checkfoldercontent(forcecurve)
	if(numberbykey("raw",content,":",";")==1)
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
//Check and load deflection wave; deflection allows also for incooperation of invols/spring constant errors.
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name_tr, y_name_re
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name_tr=forcecurvecut+"DeflV_Ext_co"
		else
			y_name_tr=forcecurve+"DeflV_Ext"
		endif
		wave y_axis_tr=$y_name_tr
	//load the contact point result wave, the hertz result wave and the fit residual wave
		wave contact=$forcecurve+"cont_tr"
		variable contactpoint=contact[2]
		wave hertzvalues=$forcecurve+"Hertz"
		wave residual=$forcecurve+"Res"
	//Fit limits are taken from hertz results.
		lowerlimitfit=hertzvalues[2]
		upperlimitfit=hertzvalues[3]
	//for every source of error a wave is create in which the error at every point is calced only take the specific source into account.
	//ESingle: E-modul in every single point. EERRsing: emodul error in single points (all errors together), E_kerr: spring const error to E;
	//Similar to E_kerr: inv = invols, R=effectiv radius, Cont=Contact point, EERR = not used, avgsdev = standard deviation of the average = all errors together, 
	//Fit = based on the residual of the fit, Rescalc: calced difference between measured signal and fitted hertz curve.
		duplicate/O y_axis_tr $Forcecurve+"Esingle", $forcecurve+"EERRsing", $forcecurve+"E_kerr", $Forcecurve+"E_InvErr", $forcecurve+"E_Rerr", $forcecurve+"E_contErr", $forcecurve+"E_avgsdev", $Forcecurve+"E_FitErr", $forcecurve+"ResCalc"
		wave rescalc=$forcecurve+"ResCalc"
		rescalc=y_axis_tr*invols*springconstant-4/3/(1-possionratio^2)*hertzvalues[0]*(effectiveradius)^0.5*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^1.5
	//New deformation wave is calced including the fitoffset determined (allows for easier calc later)
		duplicate/O disp_tr $Forcecurve+"DeforEMoD"
		wave deforemod=$Forcecurve+"DeforEMod"
		deforemod=disp_tr-invols*y_axis_tr-contactpoint-fitoffset
	//Include all created error waves.
		wave emodulsingle=$forcecurve+"Esingle"
		wave emodulerror=$forcecurve+"EERRsing"
		wave EKerror=$forcecurve+"E_kerr"
		wave EINVerror=$forcecurve+"E_Inverr"
		wave EcontError=$forcecurve+"E_contErr"
		wave ERerror=$forcecurve+"E_Rerr"
		wave EAvgSdev=$forcecurve+"E_AvgSdev"
		wave EFitError=$forcecurve+"E_FitErr"		
	//Calculation of the hertz-emodul for every single displacement value.
		emodulsingle=springconstant*Invols*y_axis_tr*3/4*(1-possionratio^2)*(effectiveradius)^(-0.5)*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-3/2)
	//Partial differentitation of the above equation after spring constant = error according to spring constant
		EKerror=Invols*y_axis_tr*3/4*(1-possionratio^2)*(effectiveradius)^(-0.5)*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-3/2)*errorspring
	//Differentitation after cont-point = contact point error
		Econterror=springconstant*Invols*y_axis_tr*3/4*(1-possionratio^2)*(effectiveradius)^(-0.5)*(3/2)*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-5/2)*errorContact
	// ... after effectiv radius
		ERerror=springconstant*Invols*y_axis_tr*3/4*(1-possionratio^2)*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-3/2)*(-1/2)*(effectiveradius)^(-1.5)*errorsphereradius
	//... after invols
		Einverror=springconstant*y_axis_tr*3/4*(1-possionratio^2)*(effectiveradius)^(-0.5)*(-(-invols*y_axis_tr+disp_tr-contactpoint-fitoffset)^1.5+Invols*3/2*(-invols*y_axis_tr+disp_tr-contactpoint-fitoffset)^0.5*y_axis_tr)/(-invols*y_axis_tr+disp_tr-contactpoint-fitoffset)^3*errorInvOLS
		//EFitError=3/4*(1-possionratio^2)*(effectiveradius)^(-0.5)*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-3/2)*residual
	//after the deflection signal.
		EFitError=3/4*(1-possionratio^2)*(effectiveradius)^(-0.5)*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-3/2)*rescalc
	//Weighted summation of all errors	
		Eavgsdev=(EKerror^2+Econterror^2+ERerror^2+EInverror^2+EFitError^2)^0.5
	//Duplicate calced single e moduli and averaged errors.
		duplicate/O emodulsingle $forcecurve+"EsingTot"
		duplicate/O Eavgsdev $Forcecurve+"ESdevTot"
		wave esdevtot=$forcecurve+"ESdevTot"
	//Calc again the standard deviation, now calc "tot" without the residual error.
		esdevtot=(EKerror^2+Econterror^2+ERerror^2+EInverror^2)^0.5		//Warum fehlrt EFitError hier???
	//Also duplicate the deformation so it can be plotted accordingly
		duplicate/O deforemod $forcecurve+"DefEMTot"
	//Delete all points before contact, no emodul, emodul error or deformation there since baseline.
		deletepoints 0, contact[1], $forcecurve+"EsingTot",$forcecurve+"esdevtot", $forcecurve+"DefEmtot"
	//delete all emodul and error value points before the fit started, since they arent included in the acutal fit.
		deletepoints 0, lowerlimitfit-1, emodulsingle, ekerror, econterror, einverror, ererror, Eavgsdev, EfitError, deforemod
	//Delete all points above of the upper fit limit.
		deletepoints (upperlimitfit-lowerlimitfit), numpnts(emodulsingle), emodulsingle, ekerror, econterror, einverror, ererror, eavgsdev, EfitError, deforemod
	//Check if the first values of emodul single are NaN => eliminate all points where hertz-calculation failed.
		do
		if(numtype(emodulsingle[0])==2)
			deletepoints   0, 1, emodulsingle, ekerror, econterror, einverror, ererror, Eavgsdev, EfitError, deforemod
		endif
		while(numtype(emodulsingle[0])==2)
	//Dont really know what this has to do with show_log but the singtot vs deformation wave are displayed starting from point 100.
		if(wholefolder_G!=1&&showlog_g==1)
			display $forcecurve+"EsingTot"[100,*] vs $forcecurve+"DefEmTot"[100,*]
		endif
	//Now only error values are in the wave which are part of the fit.
	//Save the mean of the single error values in variables.	
		error_springconst_avg=mean(ekerror)
		error_invols_avg=mean(einverror)
		error_effradius_avg=mean(eRerror)
		error_contactpoint_avg=mean(EConterror)
	//	error_shellthickness_avg=mean(EShellError)
		error_fit_avg=mean(EFitError)
	//Make a new wave with the weighted average, which is statistically defined.
		duplicate/O emodulsingle, weightedavg
		wave weightedavg
		weightedavg=emodulsingle/(eavgsdev^2)
		eavgsdev=1/(eavgsdev^2)
		variable sumwei=sum(weightedavg)
		variable sumsdev=sum(eavgsdev)
							//	hertzvalues[0]=(sum(weightedavg)/sum(eavgsdev))
							//	hertzvalues[1]=(1/sum(eavgsdev))^0.5
		variable weightedsdev=(1/sum(eavgsdev))^0.5
		eavgsdev=1/(eavgsdev^0.5)
	//Make a force-deformation set on this weight averaged emodul.
		duplicate/O/R=[contact[1],upperlimitfit] y_axis_tr, $Forcecurve+"FitC_F", $forcecurve+"FitC_f2" 
		duplicate/O/R=[contact[1],upperlimitfit] disp_tr, $forcecurve+"FitC_D"
		wave fitc_f=$Forcecurve+"FitC_F", fitc_d=$forcecurve+"FitC_D", fitc_f2=$forcecurve+"FitC_f2"
		fitc_F=sumwei/sumsdev*4/3/(1-possionratio^2)*(effectiveradius)^0.5*(fitc_d-invols*fitc_F-contactpoint-fitoffset)^1.5
		fitc_D=fitc_d-invols*fitc_F2-contactpoint
		killwaves fitc_F2
	//If only a single curve is display append the fit graph
		if(wholefolder_g==0)
			dowindow/F mechanicspanel
			setactivesubwindow MechanicsPanel#Mechdisplay
		
			appendtograph fitc_F vs fitc_D
			ModifyGraph mode=0,rgb($forcecurve+"FitC_F")=(0,52224,0)
		endif
	//Bring the error panel to front and display the error and a colorcode of the error significance.
		DoWindow/F MechanicsPanel
		setactivesubwindow MechanicsPanel#ShowErrorPanel 
		variable eavg=mean(emodulsingle)
		valdisplay vd7, limits={0.05*hertzvalues[0],hertzvalues[0],0.5*hertzvalues[0]}
		setactivesubwindow ##
	//calc the mean of the average standard deviation	
		variable meanEError=mean(eavgsdev)
		hertzvalues[1]=meanEError
//		variable eavg=mean(emodulsingle)
	//	hertzvalues[0]=eavg
	//EError is the statistical error of e
		eavgsdev=eavgsdev^2
		variable EError=(sum(eavgsdev)/(numpnts(eavgsdev)^2))^0.5
		error_total_avg=meanEError
//EError could also be saved if wanted.
	//	hertzvalues[1]=EError
		eavgsdev=eavgsdev^0.5
	//	hertzvalues[0]=eavg
	//	hertzvalues[1]=EError	
	endif
	return EERror
end

//Function determineing the mechanical and adhesive properties based on the maugis theory in the approximation of Carpick.
function Maugis_Approximation(forcecurve, emoduloffset,percentcontactFit,contacttolerance, SphereRadius, PoissonRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
//Load input variables&strings.
	string forcecurve
	variable emoduloffset, percentcontactfit, contacttolerance, sphereradius, poissonratio, usecursorvar, sampleradius, depthcontactfit_g, fitlength_g
	string forcecurvecut=forcecurve
	svar folderstring=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g
//Fixadhesion: checkbox if adhesion should be a fit variable or fixed. Useworkadh: checkbox if the workofadhesion should be hold or fitted.
	NVAR fixadhesion_G=root:panelcontrol:fit_panel:fixadhesion_g, useworkadh_g=root:panelcontrol:fit_panel:useworkadh_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
//Recalc_jkr_with_rips: checkbox if only one break-out should be used for WoA or all.
	NVAR sampleradius_g=root:panelcontrol:fit_panel:sampleradius_g, searchfit=root:panelcontrol:fit_panel:searchfit_g, recalc_jkr_with_rips=root:panelcontrol:singlefcpanel:recalc_jkr_with_rips_g
//Load the deformation offset for fitting/calculation.
	NVAR hertzfitoffset_g=root:panelcontrol:fit_panel:hertzfitoffset_g
	setdatafolder $folderstring
//Set all values SI units.
	emoduloffset*=1e-9; percentcontactfit/=100; sphereradius*=1e-6; contacttolerance*=1e-9; sampleradius*=1e-6; depthcontactfit_g*=1e-9; fitlength_g*=1e-9
//Some new variables needed below.
	variable checkcontactpnt, chosenmodel, lowerlimitfit, upperlimitfit, doloop=0
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
//Names of other waves which should be inclueded later.
	string contactpnts="ContactPntsFM", jkr_fit, JKR_fit_name, force_trace, contactexpo="ContactExponent"
//check the folder which type of waves exists for the current force curve.
	string content=checkfoldercontent(forcecurve)
//Check for Deformation and Force-waves, since they are requiered.
	if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
	//Take the baseline corrected force-waves if present.
	//For Maugis only retrace waves are of interest and traces are not loaded.
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=forcecurvecut+"Force_Ret_co"
		else
			y_name=forcecurve+"Force_ret"
		endif
	//Load the contact point wave. Right now only trace infos are loaded, no comparison with retrace. Actually not so important.
		string contactstr=Forcecurve+"cont_tr"
		wave contact=$contactstr
	//Load the adhesion info wave already calced.
		wave adhesioninfo=$forcecurvecut+"AdhF"
	//Check if a contact point was found. Actually rather unness. check since without no deformation is existsing...
		checkContactPnt=contact[1]
		if(checkContactPnt>0)
		do
		//Include deformation and force retrace-wave.
			wave defor_tr=$forcecurve+"Defor_ret"
			wave y_axis=$y_name
			if(numtype(y_axis[0])==2)
				break
			endif
		//Determine the effectiv radius of contact based on indenter and sample radius.	
			variable effectiv_radius
			if(sampleradius!=0)
				effectiv_radius=(1/sphereradius+1/sampleradius)^-1
			else
				effectiv_radius=sphereradius
			endif
		//Duplicate the deformation wave which will be recalced to hold the radius of the contact area.
			duplicate/o defor_tr $forcecurve+"ContRad_ret"
			wave contact_radius=$forcecurve+"contrad_ret"
			
		//Do step 1 of Carpick, ogletree, salmeron
		//The Force-wave is duplicate with the appendix "CR" for Contact Radius to have a own wave for this type of fitting and calculation.
			duplicate/O y_axis $forcecurve+"Force_ret_CR"
			wave force_CR=$forcecurve+"force_ret_cr"
		//Sometimes the point of adhesion is not the first minimum. For this kind of evaluation one of the first rip off is needed to make a reliable offset for the contact radius.
			wave maxdeformation=$"maxdeformation"
			if(maxdeformation[numforcecurve_g]*1.01<abs(defor_tr[adhesioninfo[1]]-defor_tr[0]))		//*3 is just random for now. defortr[0] for an potential uncorrected offset in defor on the retrace---_
				findvalue/S=0/T=0.1e-9/V=0 force_cr
				v_value+=2
				variable firstminsearch=-1, intervalsize=10
				do
					firstminsearch+=1
				while(abs(mean(force_cr,pnt2x(force_cr,v_value+firstminsearch*intervalsize),pnt2x(force_cr,v_value+(firstminsearch+1)*intervalsize)))<abs(mean(force_cr,pnt2x(force_cr,v_value+(firstminsearch+1)*intervalsize),pnt2x(force_cr,v_value+(firstminsearch+2)*intervalsize))))
				wavestats/Q/r=[v_value,v_value+intervalsize*(firstminsearch+2)] force_cr
			//offset the contact radius to be 0 deformation at the point of maximum adhesion.
				contact_radius-=defor_tr[v_minrowloc]
			//The contact radius in every point is calced based on the geometry of an effectiv sphere indenting a flat surface.
				contact_radius=(effectiv_radius^2-(effectiv_radius-contact_radius)^2)^0.5
				deletepoints v_minrowloc+1, numpnts(force_cr), force_cr, contact_radius
			else
			//offset the contact radius to be 0 deformation at the point of maximum adhesion.
				contact_radius-=defor_tr[adhesioninfo[1]]
			//The contact radius in every point is calced based on the geometry of an effectiv sphere indenting a flat surface.
				contact_radius=(effectiv_radius^2-(effectiv_radius-contact_radius)^2)^0.5
			//Delete all points from point of adhesion force to end of baseline, since unneccassary here and could cause math errors.
				deletepoints adhesioninfo[1]+1, numpnts(force_cr), force_cr, contact_radius
			endif
		//The set contact tolerance is transfered for one search for the upper fit limit. Needed since it may be varied during search and should be the same start for the lower fit limit.	
			variable contacttolerance_up=contacttolerance
		//Searchfit ==0 should be used for the first run. In case ==1 the same fit regions as before is used.
			if(searchfit==0)
			//Usecursorvar==0 : do not take cursors on the graph as fit limits.
				if(usecursorvar==0)
				//Percent contact fit = % of the whole contact regime ==1 ==100% -> take last point
					if(percentcontactfit==1)
					//upperlimitfit=0 since we are treating retrace waves.
						upperlimitfit=0
				//If the contact % is not 0 or 100% and no other type of upper limit is set:
					elseif(percentcontactfit!=0&&depthcontactfit_g==0&&fitlength_g==0)
					//Wavestats of the contact radius wave to find maximum value. Should be at pnt 0 but this way also other points are possible.
						wavestats/Q contact_radius
						variable maxdefor=V_max
					//Wavestats of the force wave to find the minimum position since this frames the fit region.
						wavestats/Q y_axis
					//The actual deformation value of x% contact is calced by % of the range from max to min deformation.
						variable deformationdepth2fit=(percentContactFit)*(maxdefor-contact_radius[v_minrowloc])
					//The corresponding point of deformationdepth2fit is search in contact-radius. In case the value is not found the tolerance is increased by 0.05nm until it is found.
						do
							findvalue/S=(0)/T=(contacttolerance_up)/V=(deformationdepth2fit+contact_radius[v_minrowloc]) contact_radius
							if(V_value==-1)
								contacttolerance_up+=0.05e-9
							endif
						while(V_value==-1)
						upperlimitfit=V_Value
				//The contact% is 0 and a specific deformation value is stated.
					elseif(percentcontactfit==0&&depthcontactfit_g!=0&&fitlength_g==0)
					//Same as above but the search value is already known.
						do
							findvalue/S=(0)/T=(contacttolerance_up)/V=(depthcontactfit_g) contact_radius
							if(V_value==-1)
								contacttolerance_up+=0.05e-9
							endif
						while(V_value==-1)
						upperlimitfit=V_Value
				//Last case: a given fit length is forced.
					elseif(percentcontactfit==0&&depthcontactfit_g==0&&fitlength_g!=0)
					//Same as above but the target value is given by the deformation offset + the fit length.
						do
							findvalue/S=(0)/T=(contacttolerance_up)/V=(emoduloffset+fitlength_g) contact_radius
							if(V_value==-1)
								contacttolerance_up+=0.05e-9
							endif
						while(V_value==-1)
						upperlimitfit=V_Value
					endif
				//The upper end of the fit is now determined-> search for the fit start.
				//Use the initial search tolerance.
					variable contacttolerance_low=contacttolerance
				//In case there is no offset an the fitlength = 0(what has that to do with the fitstart?)
					if(emoduloffset==0)//&&fitlength_g==0)
					//Take the point of the force of adhesion as start point.
						lowerlimitfit=adhesioninfo[1]
	//170726				elseif(emoduloffset!=0&&fitlength_g==0&&searchfit==0)
				//In case an offset is stated.
					elseif(emoduloffset!=0)
					//Make a search for the offset stated. Check-variable is only for debugging reasons. Rest as above.
						do
							variable check=contact_radius[adhesioninfo[1]]+emoduloffset
							//findvalue/S=0/T=(contacttolerance)/V=(contact_radius[adhesioninfo[1]]+emoduloffset) contact_radius
							findvalue/S=0/T=(contacttolerance_low)/V=(emoduloffset) contact_radius
								if(V_value==-1)
								contacttolerance_low+=0.05e-9
							endif
						while(V_value==-1)
						lowerlimitfit=V_Value
					endif	
			//In case the A&B cursors should be used as fit limits: check which cursors is the upper/lower and take ther point positions on the wave.
				else
					if(pcsr(A,"mechanicspanel#mechdisplay")<pcsr(B,"mechanicspanel#mechdisplay"))
						upperlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
					else
						upperlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
					endif
				endif
			//Check if the fit start and end was found. In case one is not determined stop the function since it would cause errors.
				if(lowerlimitfit==-1||upperlimitfit==-1)
					break
				endif
			//Create a wave containg the all maugis results and infos.
				make/o/N=13 $Forcecurve+"Maugis"
				wave maugis=$forcecurve+"maugis"
		//In case searchfit ==1 load the previously created maugis result wave and take the fit limits from the old fit.
			else
				wave maugis=$forcecurve+"maugis"
				lowerlimitfit=maugis[9]
				upperlimitfit=maugis[10]
			//In case the Maugis-wave only contains 11 pnts (meaning no multiple rip off were involved) add 2 more points which could hold the multiple rips in case.
				if(numpnts(maugis)==11)		//for 1st transition
					insertpoints 12,2,maugis
				endif
			endif	

		//Create the coefficent and constrain waves for the maugis fit.
			make/N=3/o w_coef
			make/N=4/o/T T_constraints
		//In case the force at the fit start is bigger than zero. 
		//K0: contact radius at zero load. Is constrained between 0 and the sphereradius(since it cant be bigger)
		//K1: Carpick parameter alpha, which is physically limited betwenn 0 and 1. the extrems 0/1 are limited out.
		//K2: is the force of adhesion in the positive sense.
		//1.if K2 needs to be smaller than 0 otherwise math error in fit.
			if(force_cr[lowerlimitfit]>0)
				t_constraints[0]={"0<K0<"+num2str(sphereradius),"0.01<K1","k1<0.98","0>K2"}
				W_coef[0]={2e-6,0.5,-1e-9}	//before K0=4e-7
		//2. if the force at the begining is negativ K2 needs to be smaller than the fit start; again math error in the square root in the fit.
			else
				t_constraints[0]={"0<K0<"+num2str(sphereradius),"0.01<K1","K1<0.98","K2<"+num2str(force_cr[lowerlimitfit])}
				W_coef[0]={2e-6,0.5,force_cr[lowerlimitfit]-1e-9}
			endif
		//The adhesion force for the fitting can also be fixed. Here the constrains hold it within +-5% of the predetermined values.
			if(fixadhesion_g==1)
				insertpoints 4,1, T_constraints
				wave adhesionF=$forcecurve+"adhf"
				t_constraints[3]={"k2<"+num2str(-0.95*adhesionF[0]),"K2>"+num2str(-1.05*adhesionf[0])}
			endif
		//Depending if a deformation (here contact radius) offset is allowed the regarding fit is started.
			if(hertzfitoffset_g==0)
				FuncFit/Q Carpick_7 W_coef contact_radius[upperlimitfit,lowerlimitfit] /X=force_cr /D  /C=T_constraints
			else
				FuncFit/Q Carpick_7_offset W_coef contact_radius[upperlimitfit,lowerlimitfit] /X=force_cr /D  /C=T_constraints
			endif
		//The resulting fit is name as this string.
			string fit_name="fit_"+forcecurve+"contrad_ret"
		//It will be in any case only 30 letters long, so it gets shrunk.
			fit_name=fit_name[0,30]
		//The already point-reduced force_cr wave gets duplicated to 3 new waves. These will hold the recalculated (based on the fit model):
		//"DRecalc" contact radius, "FRecalc" force, "DeforR" contact radius retransfered to deformation.
			duplicate/O force_cr $forcecurve+"MD_DRecalc", $forcecurve+"MD_FRecalc", $forcecurve+"MD_DeforR"
			wave md_drecalc=$forcecurve+"MD_dRecalc", md_frecalc=$forcecurve+"MD_Frecalc", md_deforR=$forcecurve+"MD_DeforR"
		//The recalced force is set to have a equal force-spacing regarding its points (divided by the number of points multiplied by the point-number)
		//Force_cr[0]-w_coef[2] = total length of forces; +w_coef[2] makes the offset where force should start.
			md_frecalc=(force_cr[0]-w_coef[2])/(numpnts(force_cr)-1)*P+w_coef[2]
		//Resets the internal scale of the md_drecalc wave to fit the one of md_frecalc.
			SetScale/P x w_coef[2],(force_cr[0]-w_coef[2])/numpnts(force_cr),"", md_drecalc
		//Depending on the offset: recalc the contact radius depending on the input force and the fit results.
			if(hertzfitoffset_G==0)
				md_dRecalc=((w_coef[1]+(1-md_frecalc/w_coef[2])^0.5)/(1+w_coef[1]))^(2/3)*w_coef[0]
			else
				md_dRecalc=((w_coef[1]+(1-md_frecalc/w_coef[2])^0.5)/(1+w_coef[1]))^(2/3)*w_coef[0]+(w_coef[1]/(1+w_coef[1]))^(2/3)*w_coef[0]
			endif
		//Recalc the deformation based on geometry and the recalced contact-radius (like above but the way back)
			md_deforR=effectiv_radius-(effectiv_radius^2-md_drecalc^2)^0.5+defor_tr[adhesioninfo[1]]
		//Determine the integral of force vs deformation to get area under the curve.
			integrate/T md_frecalc /X=md_deforR /D=$forcecurve+"MD_Integral"
			wave md_int=$forcecurve+"MD_integral"
		//The area under the curve is defined by the minium value of the intergral. Double check this for positive part of forces.
		//But in the way the force and deformation are created they start at max negative force. Therefore the integral is build up from adhesion to max contact
		//-> when the force becomes positive the integral becomes bigger (but still negativ) and that point is V_min
			wavestats/Q md_int
			variable areaundercurve=-V_min
		//The Maugis_fit wave is stated so it can be appended to the graph.
			wave fit_wave=$fit_name
			string maugis_name=forcecurve+"_MD_Fit"
		//Set the gui-graph to active: remove all Maugis related curves from the graph
			do
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
				variable posi=strsearch(tracesongraph,"MD",0)					
				if(posi!=-1)
					variable semi1=strsearch(tracesongraph,";",0)
					variable semi2=strsearch(tracesongraph,";",semi1+1)
					variable semi3=strsearch(tracesongraph,";",semi2+1)
					if(posi<semi1)
						removefromgraph $stringfromlist(0,tracesongraph,";")
					elseif(posi>semi1&&posi<semi2)
						removefromgraph $stringfromlist(1,tracesongraph,";")
					elseif(posi>semi2&&posi<semi3)
						removefromgraph $stringfromlist(2,tracesongraph,";")
					endif
				endif
			while(strsearch(tracesongraph,"MD",0)>0)	
		//The new maugis fit could already exists from former fits. If so kill the old wave.	
			if(waveexists($maugis_name)==1)
				killwaves $maugis_name
			endif
		//Rename the standard fit-wave to the desired name.
			rename fit_wave, $maugis_name
		//Save all maugis results in the result wave. Behind the results the variable in the Carpick paper is stated.			
			maugis[0]=w_coef[0]	//a0
			maugis[1]=w_coef[1] //alpha
			maugis[2]=w_coef[2]  //Lc or Force of adhesion
		
		//step 3 of Carpick paper. The limit of 0.98 is given in the paper, but since the fit is limited to 0.98 the limit here is chosen to be 0.97 which is the JKR limit.
			if(maugis[1]>0.97)
				maugis[3]=inf		//lambda
				maugis[4]=-3/2		//L_c (lambda)
				maugis[6]=1.54+0.279		//a_0 bar
		//Below 0.97 it's the Maugis regime down to 0 (=DMT)
			else	
				maugis[3]=-0.924*ln(1-1.02*maugis[1])	//lambda == maugis parameter
				maugis[4]=-7/4+1/4*(4.04*maugis[3]^1.4-1)/(4.04*maugis[3]^1.4+1)  //Lc bar
				maugis[6]=1.54+0.279*(2.28*maugis[3]^1.3-1)/(2.28*maugis[3]^1.3+1)   //a0 bar
			endif
		//step 4: from the results 3 4 6 determine the work of adhesion.
			maugis[5]=maugis[2]/pi/effectiv_radius/maugis[4]					// gamma == work of adhesion
		//step 5: The e-modul can also be determined based on the above values.
			maugis[7]=(maugis[6]^3/maugis[0]^3*pi*maugis[5]*effectiv_radius^2*3/4/(1-poissonratio^2))		//E Modul
		//In case of an offset this fitted offset is saved in maugis[8]
			if(hertzfitoffset_g==1)
				maugis[8]=(maugis[1]/(1+maugis[1]))^(2/3)*maugis[0]				//fitted area offset
			endif
		//Fit-range, work of adhesion NOT normalized by aera [11], and by area [12] are saved.
			maugis[9]=lowerlimitfit
			maugis[10]=upperlimitfit
			maugis[11]=areaundercurve
			maugis[12]=(maugis[5]*pi/maugis[11])^-0.5			//Recalced contact radius from WoA
		while(doloop<-1)
		endif
	endif
end

//Function setting the scene for JKR fitting. Function is 95% same as for Hertz, so please look up details there.
//Difference to Hertz: Fit the retrace instead of the trace. Use the JKR fit function, here 2 are possible (2Point methode or regular).
function EModulusJKRAlone(forcecurve, emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PoissonRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g)
//Input variables and strings
	string forcecurve
	variable emoduloffset, percentcontactfit, contacttolerance, emodulGuess, sphereradius, poissonratio, usecursorvar, sampleradius, depthcontactfit_g, fitlength_g
	string forcecurvecut=forcecurve
	svar folderstring=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g
	NVAR fixadhesion_G=root:panelcontrol:fit_panel:fixadhesion_g, useworkadh_g=root:panelcontrol:fit_panel:useworkadh_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR sampleradius_g=root:panelcontrol:fit_panel:sampleradius_g, searchfit=root:panelcontrol:fit_panel:searchfit_g, recalc_jkr_with_rips=root:panelcontrol:singlefcpanel:recalc_jkr_with_rips_g
	setdatafolder $folderstring
	emoduloffset*=1e-9; percentcontactfit/=100; sphereradius*=1e-6; contacttolerance*=1e-9; sampleradius*=1e-6; depthcontactfit_g*=1e-9; fitlength_g*=1e-9
//Check if the required waves are there and which model to use.
	variable checkcontactpnt, chosenmodel, lowerlimitfit, upperlimitfit, doloop=0
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	string contactpnts="ContactPntsFM", jkr_fit, JKR_fit_name, force_trace, contactexpo="ContactExponent"
	string content=checkfoldercontent(forcecurve)
	if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=forcecurvecut+"Force_Ret_co"
		else
			y_name=forcecurve+"Force_ret"
		endif
		string contactstr=Forcecurve+"cont_tr"
		wave contact=$contactstr
		checkContactPnt=contact[1]
		if(checkContactPnt>0)
		do
			wave defor_tr=$forcecurve+"Defor_ret"
			wave y_axis=$y_name
			variable contacttolerance_up=contacttolerance
		//Search the fit start and end depending on the user input.
			if(searchfit==0)
				if(usecursorvar==0)
					if(percentcontactfit==1)
						upperlimitfit=0
					elseif(percentcontactfit!=0&&depthcontactfit_g==0&&fitlength_g==0)
						wavestats/Q defor_tr
						variable maxdefor=V_max
						wavestats/Q y_axis
						variable deformationdepth2fit=(percentContactFit)*(maxdefor-defor_tr[v_minrowloc])
						do
							findvalue/S=(0)/T=(contacttolerance_up)/V=(deformationdepth2fit+defor_tr[v_minrowloc]) defor_tr
							if(V_value==-1)
								contacttolerance_up+=0.05e-9
							endif
						while(V_value==-1)
						upperlimitfit=V_Value
					elseif(percentcontactfit==0&&depthcontactfit_g!=0&&fitlength_g==0)
						do
							findvalue/S=(0)/T=(contacttolerance_up)/V=(depthcontactfit_g) defor_tr
							if(V_value==-1)
								contacttolerance_up+=0.05e-9
							endif
						while(V_value==-1)
						upperlimitfit=V_Value
					elseif(percentcontactfit==0&&depthcontactfit_g==0&&fitlength_g!=0)
						do
							findvalue/S=(0)/T=(contacttolerance_up)/V=(emoduloffset+fitlength_g) defor_tr
							if(V_value==-1)
								contacttolerance_up+=0.05e-9
							endif
						while(V_value==-1)
						upperlimitfit=V_Value
					endif
					wave adhesioninfo=$forcecurvecut+"AdhF"
					variable contacttolerance_low=contacttolerance
					if(emoduloffset==0&&fitlength_g==0)
						lowerlimitfit=adhesioninfo[1]
					elseif(emoduloffset!=0&&searchfit==0)
						do
							variable check=defor_tr[adhesioninfo[1]]+emoduloffset
							findvalue/S=0/T=(contacttolerance_low)/V=(emoduloffset) defor_tr
	
							if(V_value==-1)
								contacttolerance_low+=0.05e-9
							endif
						while(V_value==-1)
						lowerlimitfit=V_Value
					endif	
				else
					if(pcsr(A,"mechanicspanel#mechdisplay")<pcsr(B,"mechanicspanel#mechdisplay"))
						upperlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
					else
						upperlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
					endif
				
				endif
				if(lowerlimitfit==-1||upperlimitfit==-1)
					break
				endif
				deletetolongdefor(defor_tr,y_axis)
				Make/N=6/O $forcecurve+"JKR"
				wave JKR=$forcecurve+"JKR"
					
				JKR[4]=0
			else
				wave JKR=$forcecurve+"JKR"
				lowerlimitfit=JKR[2]
				upperlimitfit=JKR[3]
			endif
			variable input=defor_tr[contact[1]]*1e9
		//Check the Panels for contact geometry, allowed offset and type of JKR fit.
			controlinfo/W=MechanicsPanel#FitPanelEMod fitfunctiongeometery
			variable sphsph=V_Value
			controlinfo/W=MechanicsPanel#FitPanelEMod hertzfitoffset
			variable allowfitoffset=V_value
			duplicate/O y_axis, $Forcecurve+"ResJ"
			wave residual=$forcecurve+"ResJ"
			setactivesubwindow MechanicsPanel#fitpanelemod
			controlinfo fitfunctionchoiceal
			variable jkr2pntmeth=V_value
			wave adhesionforce=$forcecurve+"AdhFJKR", workofadhesion=$forcecurve+"WoAdhF"
			wave adhesioninfo=$forcecurvecut+"AdhF"
			make/D/N=5/O W_coef,W_sigma
		//Introduce the constrain that E-Modul needs to be bigger than 0.
			Make/O/T/N=2 T_Constraints
			T_Constraints[0] = {"K0 > 0"}
			if(sphsph==1)
				W_coef[0]={emodulguess,-adhesioninfo[0+useworkadh_g],sphereradius,poissonratio,0}
			else
				W_coef[0]={emodulguess,-adhesionForce[0+useworkadh_g],(1/sphereradius+1/sampleradius)^-1,poissonratio,0}
			endif	
			if(useworkadh_g==0)
				W_coef[1]=-adhesioninfo[0]
			endif
			variable AdhesionInFit=0, offsetInFit=1
		//The fitted force of adhesion must be at max the same value as the lowest force fitted!
			if(y_axis[lowerlimitfit]>0)
				T_constraints[1]={"0> K1"}
			else
				T_constraints[1]={num2str(y_axis[lowerlimitfit])+"> K1"}// > "+num2str(w_coef[1])}	
			endif
			if(fixadhesion_g==1&&allowfitoffset==1&&jkr2pntmeth!=3)
				FuncFIt/H="01110" /NTHR=0/Q JKR W_coef defor_tr[lowerlimitfit,upperlimitfit] /X=y_axis /D /F={0.950000,7}/R=residual/A=0	/C=T_Constraints 	
				print W_coef[4]		
			elseif(fixadhesion_g==1&&allowfitoffset==0&&jkr2pntmeth!=3)
				FuncFIt/H="01111" /NTHR=0/Q JKR W_coef defor_tr[lowerlimitfit,upperlimitfit] /X=y_axis /D /F={0.950000,7}/R=residual/A=0	/C=T_Constraints 	
			elseif(fixadhesion_g==0&&allowfitoffset==1&&jkr2pntmeth!=3)
				FuncFIt/H="00110" /NTHR=0/Q JKR W_coef defor_tr[lowerlimitfit,upperlimitfit] /X=y_axis /D /F={0.950000,7}/R=residual/A=0	/C=T_Constraints 	
				print W_coef[4]	
			elseif(fixadhesion_g==0&&allowfitoffset==0&&jkr2pntmeth!=3)
				FuncFIt/H="00111" /NTHR=0/Q JKR W_coef defor_tr[lowerlimitfit,upperlimitfit] /X=y_axis /D /F={0.950000,7}/R=residual/A=0/C=T_Constraints 			
			endif
		//Save the fit-results			
			JKR[0]=W_coef[0]	//E-Modul
			JKR[1]=W_sigma[0]	//E-modul fit error
			JKR[2]=lowerlimitfit	//fit start
			JKR[3]=upperlimitfit	//fit end
			JKR[4]=W_coef[1]	//Adhesion force found/used in the fit
			JKR[5]=w_coef[4]	//Deformation offset found/used in the fit.
		//2 point method: It is assumed that JKR is valid, then the complete behavior is describe by the point of zero load and maximum adhseion.
			if(jkr2pntmeth==3)
				variable pntvalueP3		//P3 equals max retraction force
				variable pntvalueP0		//P0 equals zero force retrace in contact
				pntvalueP3=adhesioninfo[1]
				do
					findvalue/S=(0)/T=(contacttolerance)/V=(0) y_axis
					if(V_value==-1)
						contacttolerance+=0.05e-9
					endif
				while(V_value==-1)
				pntvalueP0=V_value
				variable emodul=3*(1-poissonratio^2)/4*((1+16^(1/3))/3)^(3/2)*(-1)*y_axis[pntvalueP3]/((sphereradius*(defor_tr[pntvalueP0]-defor_tr[pntvalueP3])^3)^0.5)
				JKR[0]=emodul
				wave deflV_ret=$forcecurvecut+"DeflV_ret_co"
				variable deflVP3=deflv_ret[pntvalueP3]
				JKR[1]=JKR2PointMethError(y_axis[pntvalueP3],defor_tr[pntvalueP3],defor_tr[pntvalueP0],sphereradius, poissonratio,deflvP3)
				JKR[2]=pntvalueP0
				JKR[3]=pntvalueP3
				W_coef[0]=emodul
				FuncFIt/H="11110" /NTHR=0/Q JKR W_coef defor_tr[lowerlimitfit,upperlimitfit] /X=y_axis /D /F={0.950000,7}/R=residual/A=0			
			endif				
			input=emoduloffset*1e9
			JKR_fit="fit_"+forcecurve+"Defor_ret"
			JKR_fit=JKR_fit[0,30]
			wave fit_wave=$JKR_fit
			duplicate/O fit_wave, $Forcecurve+"JKRFIT_F", $Forcecurve+"JKRFIT_D"
			wave JFIT_F=$Forcecurve+"JKRFIT_F", JFIT_D=$forcecurve+"JKRFIT_D"
			JFIT_F=x			
			JKR_fit_name="JKRFit"+forcecurve
			do
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
				variable posi=strsearch(tracesongraph,"JKR",0)							//Hertz durch JKR ersetzt. funktioniert?
				if(posi!=-1)
					variable semi1=strsearch(tracesongraph,";",0)
					variable semi2=strsearch(tracesongraph,";",semi1+1)
					variable semi3=strsearch(tracesongraph,";",semi2+1)
					if(posi<semi1)
						removefromgraph $stringfromlist(0,tracesongraph,";")
					elseif(posi>semi1&&posi<semi2)
						removefromgraph $stringfromlist(1,tracesongraph,";")
					elseif(posi>semi2&&posi<semi3)
						removefromgraph $stringfromlist(2,tracesongraph,";")
					endif
				endif
			while(strsearch(tracesongraph,"JKR",0)>0)									//siehe oben
			if(waveexists($JKR_fit_name)==1)
				killwaves $JKR_fit_name
			endif
			rename fit_wave, $JKR_fit_name
			NVAR showfit=root:panelcontrol:singlefcpanel:showfit_g
			NVAR invols=root:panelcontrol:singleFCPanel:invols_g, springconstant=root:panelcontrol:singlefcpanel:springconst_g
		//	variable errorEmodul=errorHertzFit(forcecurve,Invols,possionratio,sphereradius,sampleradius,springconstant,allowfitoffset)
			if(showfit==1&&wholefolder_g==0)
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				TextBox/K/N=text0
				appendtograph jfit_f vs jfit_d
				Modifygraph rgb($forcecurvecut+"JKRFIT_F")=(0,0,0)
				ModifyGraph rgb($y_name)=(65280,0,0)
				SetAxis bottom -2e-08,defor_tr[upperlimitfit]
				setaxis left 0e-9,y_axis[upperlimitfit]
				TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(jkr[0])+" ± "+num2str(jkr[1])+" Pa"
			endif
			if(recalc_jkr_with_rips!=0)
				wave workADH_perArea_list, ADhF_List=$forcecurve+"adhfJKR"
				W_coef[1]=workadh_perarea_list[numforcecurve_g]*3/2*pi*sphereradius
				duplicate/o w_coef, wc
				make/o/N=128 $forcecurve+"JKRRips_f", $forcecurve+"JKRRips_D"
				wave Rips_f=$forcecurve+"JKRRips_f", rips_d=$forcecurve+"JKRRips_D"
				rips_f=-x*(workadh_perarea_list[numforcecurve_g]*3/2*pi*sphereradius/128)
				rips_d= ((3/4)*(1-WC[3]^2)*(WC[2])*(rips_f+2*(-wc[1])+2*(rips_f*(-wc[1])+(-wc[1])^2)^(0.5))/(wc[0]))^(2/3)/(WC[2])-(4/3)^(1/3)*(1-WC[3]^2)^(2/3)*((-wc[1])/((WC[2])*wc[0]))^(0.5)*((WC[2])*(rips_f+2*(-wc[1])+2*(rips_f*(-wc[1])+(-wc[1])^2)^(0.5))/(wc[0]))^(1/6)+wc[4]
			endif
		while(doloop<-1)
		endif
	else
		Print "No data for "+forcecurve+" could be found in current folder!"	
	endif
end

//Just outsourced math equation determineing the e-modul from the JKR two point mehtode.
function JKR2PointMethError(forceP3,deforP3,deforP0,sphereradius, poissonratio,deflvP3)
	variable forceP3, deforP3, deforP0, sphereradius, poissonratio, deflvP3
	variable constante=3*(1-poissonratio^2)/4*((1+16^(1/3)/3))^(3/2)
	NVAR springconst=root:panelcontrol:singlefcpanel:springconst_g
	NVAR Invols=root:panelcontrol:singlefcpanel:invols_G
	variable errorspring=0.15, errorinvols=0.1, errorradius=0.5e-6, errordeformation=0.5e-9
	variable dEafterdP=1/(sphereradius*(deforP0-deforP3)^3)^0.5
	variable dEafterdR=forceP3*(0.5)*sphereradius^(-3/2)/((deforP0-deforP3)^(3/2))
	variable dEafterddefor=forceP3/sphereradius^0.5*1.5*(deforP0-deforP3)^(-5/2)
	variable erroremodul=constante*((dEafterdP*invols*1e-9*deflvP3)^2*(errorspring*springconst)^2+(dEafterdP*springconst*deflvp3)^2*(errorinvols*invols*1e-9)^2+dEafterdR^2*errorradius^2+2*dEafterddefor^2*errordeformation^2)^0.5
	return erroremodul
end

//Function setting the frame for DMT fitting. 95% identical to Hertz, so see there for details.
function EModulusDMTAlone(forcecurve, emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,depthcontactfit_g)
	string forcecurve
	variable emoduloffset, percentcontactfit, contacttolerance, emodulGuess, sphereradius, possionratio, usecursorvar, depthcontactfit_g
	string forcecurvecut=forcecurve
	svar folderstring=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g, searchfit_g=root:Panelcontrol:fit_panel:searchfit_g
	NVAR fixadhesion_G=root:panelcontrol:fit_panel:fixadhesion_g, useworkadh_g=root:panelcontrol:fit_panel:useworkadh_g
	setdatafolder $folderstring
	emoduloffset*=1e-9; percentcontactfit/=100; sphereradius*=1e-6; contacttolerance*=1e-9;depthcontactfit_g*=1e-9
	variable checkcontactpnt, chosenmodel, lowerlimitfit, upperlimitfit, doloop=0
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	string contactpnts="ContactPntsFM", DMT_fit, DMT_fit_name, force_trace, contactexpo="ContactExponent"
	string content=checkfoldercontent(forcecurve)
	if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=Forcecurvecut+"Force_ret_co"
		else
			y_name=forcecurve+"Force_ret"
		endif
		string contactstr=Forcecurve+"cont_re"
		wave contact=$contactstr
		checkContactPnt=contact[1]
		if(checkContactPnt>0)
		do
			wave defor_tr=$forcecurve+"Defor_ret"
			wave y_axis=$y_name
			reverse defor_tr, y_axis
			contact[1]=numpnts(y_axis)-contact[1]
			if(searchfit_g==0)
				if(usecursorvar==0)
					if(percentcontactfit==1)
						upperlimitfit=numpnts(defor_tr)-1
					elseif(percentcontactfit!=0&&depthcontactfit_g==0)
						variable deformationdepth2fit=percentContactFit*(defor_tr[numpnts(defor_tr)-1])
						findvalue/S=(contact[1]+round(0.05*(numpnts(defor_tr)-1-contact[1])))/T=(1.5e-9)/V=(deformationdepth2fit) defor_tr
						upperlimitfit=V_Value
					elseif(percentcontactfit==0&&depthcontactfit_g!=0)
						findvalue/S=(contact[1]+round(0.05*(numpnts(defor_tr)-1-contact[1])))/T=(1.5e-9)/V=(depthcontactfit_g) defor_tr
						upperlimitfit=V_Value
					endif
					if(emoduloffset==0)
						lowerlimitfit=contact[1]
					else
						findvalue/S=(contact[1])/T=(1.5e-9)/V=(emoduloffset) defor_tr
						lowerlimitfit=V_Value
					endif
				else
					if(pcsr(A,"mechanicspanel#mechdisplay")>pcsr(B,"mechanicspanel#mechdisplay"))
						upperlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
					else
						upperlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
					endif
				endif
				if(lowerlimitfit==-1||upperlimitfit==-1)
					reverse defor_tr, y_axis
					break
				endif
				Make/N=6/O $forcecurve+"DMT"
				wave DMT=$forcecurve+"DMT"
				DMT[4]=0
			else
				wave DMT=$forcecurve+"DMT"
				upperlimitfit=DMT[3]
				lowerlimitfit=DMT[2]
			endif
			variable input=defor_tr[contact[1]]*1e9
			NVAR searchfit=root:panelcontrol:fit_panel:searchfit_g
			if(searchfit==1)
				variable newlowerlimitfit=searchfitreagion(forcecurvecut,contact[1],upperlimitfit)+contact[1]
				lowerlimitfit=newlowerlimitfit
				emoduloffset=defor_tr[newlowerlimitfit] 
			endif
			controlinfo/W=MechanicsPanel#FitPanelEMod hertzfitoffset
			variable allowfitoffset=V_value
			duplicate/O y_axis, $Forcecurve+"ResDMT"
			wave residual=$forcecurve+"ResDMT"
			wave adhesionforce=$forcecurve+"AdhFDMT", workofadhesion=$forcecurve+"WoAdhFDMT"
			make/D/N=5/O W_coef,W_sigma
			W_coef[0]={emodulguess,-adhesionForce[0+useworkadh_g],sphereradius,possionratio,0}
			variable AdhesionInFit=0, offsetInFit=1
			if(fixadhesion_g==1&&allowfitoffset==1)
				FuncFIt/H="01110" /NTHR=0/Q DMT W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000,7}/R=residual/A=0			
			elseif(fixadhesion_g==1&&allowfitoffset==0)
				FuncFIt/H="01111" /NTHR=0/Q DMT W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000,7}/R=residual/A=0		
			elseif(fixadhesion_g==0&&allowfitoffset==1)
				FuncFIt/H="00110" /NTHR=0/Q DMT W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000,7}/R=residual/A=0			
			elseif(fixadhesion_g==0&&allowfitoffset==0)
				FuncFIt/H="00111" /NTHR=0/Q DMT W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000,7}/R=residual/A=0			
			endif
			DMT[0]=W_coef[0]
			DMT[1]=W_sigma[0]
			DMT[2]=lowerlimitfit
			DMT[3]=upperlimitfit
			DMT[4]=w_Coef[1]
			duplicate/O/R=[contact[1],numpnts(y_axis)-1] y_axis, $forcecurvecut+"DMT_ForCalc"
			duplicate/O/R=[contact[1],numpnts(y_axis)-1] defor_tr, $forcecurvecut+"DMT_DefCalc"
			wave defor_DMT_calc=$forcecurvecut+"DMT_DefCalc"
			wave force_DMT_calc=$forcecurvecut+"DMT_ForCalc"
			force_dmt_calc=4/3*w_coef[2]^0.5*w_coef[0]*defor_dmt_calc^(3/2)/(1-w_coef[3]^2)-w_coef[1]						
			input=emoduloffset*1e9			
			DMT_fit="fit_"+forcecurve+"Force_ret_co"
			DMT_fit=DMT_fit[0,30]
			wave fit_wave=$DMT_fit
			DMT_fit_name="DMTFit"+forcecurve
			do
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
				variable posi=strsearch(tracesongraph,"DMT",0)							//Hertz durch JKR ersetzt. funktioniert?
				if(posi!=-1)
					variable semi1=strsearch(tracesongraph,";",0)
					variable semi2=strsearch(tracesongraph,";",semi1+1)
					variable semi3=strsearch(tracesongraph,";",semi2+1)
					if(posi<semi1)
						removefromgraph $stringfromlist(0,tracesongraph,";")
					elseif(posi>semi1&&posi<semi2)
						removefromgraph $stringfromlist(1,tracesongraph,";")
					elseif(posi>semi2&&posi<semi3)
						removefromgraph $stringfromlist(2,tracesongraph,";")
					endif
				endif
			while(strsearch(tracesongraph,"DMT",0)>0)									//siehe oben	
			if(waveexists($DMT_fit_name)==1)
				killwaves $DMT_fit_name
			endif
			rename fit_wave, $DMT_fit_name
			NVAR showfit=root:panelcontrol:singlefcpanel:showfit_g
			NVAR invols=root:panelcontrol:singleFCPanel:invols_g, springconstant=root:panelcontrol:singlefcpanel:springconst_g
			if(showfit==1&&wholefolder_g==0)
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				TextBox/K/N=text0
				appendtograph force_dmt_calc vs defor_dmt_calc
				appendtograph $DMT_fit_name
				ModifyGraph lsize($DMT_fit_name)=2
				ModifyGraph rgb($DMT_fit_name)=(0,12800,52224)
				Modifygraph rgb($forcecurvecut+"DMT_forCalc")=(0,0,0)
				ModifyGraph rgb($y_name)=(65280,0,0)
				SetAxis bottom -2e-08,defor_tr[upperlimitfit]
				setaxis left 0e-9,y_axis[upperlimitfit]
				TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(DMT[0])+" ± "+num2str(DMT[1])+" Pa"
			endif
			reverse defor_tr, y_axis, residual, defor_DMT_calc, force_DMT_calc
			contact[1]=numpnts(y_axis)-contact[1]
		while(doloop<-1)
		endif
	else
		Print "No data for "+forcecurve+" could be found in current folder!"	
	endif

end

//Again same structure for Reissner fitting as for Hertz, so see above. Difference is that the shell thickness is needed as an aditional parameter and ofc another fit function is called.
Function EModulusReissnerAlone(forcecurve, emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,Sampleradius,depthcontactfit_g,fitlength_g,shellthickness_g)
	string forcecurve
	variable emoduloffset, percentcontactfit, contacttolerance,EModulGuess, SphereRadius, PossionRatio, usecursorvar, sampleradius,depthcontactfit_g, fitlength_g, shellthickness_g
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g, searchfit_g=root:panelcontrol:fit_panel:searchfit_g
	variable doloop1=1
	do
		if(shellthickness_g==0)
			break
		endif
	while(doloop1<0)
	variable sphereradius_intern
	setdatafolder $folderstring_g
	emoduloffset*=1e-9; percentcontactfit/=100; sphereradius_intern=SphereRadius*1e-6; contacttolerance*=1e-9; sampleradius*=1e-6; depthcontactfit_g*=1e-9; fitlength_g*=1e-9; shellthickness_g*=1e-9
	variable  checkcontactPnt, correctionPnts=0, chosenModel
	variable lowerlimitfit, upperlimitfit, doloop=0
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	string contactPnts="ContactPntsFM", reissner_fit, reissner_fit_name, force_trace, contactexpo="ContactExponent"
	string content=checkfoldercontent(forcecurve)
	if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=Forcecurvecut+"Force_Ext_co"
		else
			y_name=forcecurve+"Force_Ext"
		endif
		string contactstr=Forcecurve+"cont_tr"
		wave contact=$contactstr
		checkContactPnt=contact[1]
		do
		if(checkContactPnt>0)
			wave defor_tr=$forcecurve+"Defor_Ext"
			wave y_axis=$y_name
			variable fitmaximum, absolutvalue
			if(searchfit_g==0)
				if(usecursorvar==0)
					if(percentcontactfit==1)
						upperlimitfit=numpnts(defor_tr)-1
					elseif(percentcontactfit!=0&&depthcontactfit_g==0)
						variable deformationdepth2fit=percentContactFit*(defor_tr[numpnts(defor_tr)-1])
						findvalue/S=(contact[1]+round(0.05*(numpnts(defor_tr)-1-contact[1])))/T=(contacttolerance)/V=(deformationdepth2fit) defor_tr
						upperlimitfit=V_Value
						if(upperlimitfit==-1)
							upperlimitfit=numpnts(defor_tr)-1
						endif
						fitmaximum=percentcontactfit*100
						absolutvalue=0
					elseif(percentcontactfit==0&&depthcontactfit_g!=0)
						findvalue/S=(contact[1]+round(0.05*(numpnts(defor_tr)-1-contact[1])))/T=(contacttolerance)/V=(depthcontactfit_g) defor_tr
						upperlimitfit=V_Value
						if(upperlimitfit==-1)
							upperlimitfit=numpnts(defor_tr)-1
						endif
						fitmaximum=depthcontactfit_g*1e9
						absolutvalue=1
					endif
					if(emoduloffset==0&&fitlength_g==0)
						lowerlimitfit=contact[1]
					elseif(emoduloffset!=0&&fitlength_g==0)
						findvalue/S=(contact[1])/T=(5e-9)/V=(emoduloffset) defor_tr
						lowerlimitfit=V_Value
					elseif(fitlength_g!=0)
						findvalue/S=(contact[1])/T=(5e-9)/V=(defor_tr[upperlimitfit]-fitlength_g) defor_tr
						lowerlimitfit=V_Value
					endif
				else
					if(pcsr(A,"mechanicspanel#mechdisplay")>pcsr(B,"mechanicspanel#mechdisplay"))
						upperlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
					else
						upperlimitfit=pcsr(B,"mechanicspanel#mechdisplay")
						lowerlimitfit=pcsr(A,"mechanicspanel#mechdisplay")
					endif
				endif
				if(lowerlimitfit==-1||upperlimitfit==-1)
					break
				endif
				Make/N=5/O $forcecurve+"Reis"
				wave Reissner=$forcecurve+"Reis"
				Reissner[4]=0
			else
				wave reissner=$forcecurve+"reis"
				lowerlimitfit=reissner[2]
				upperlimitfit=reissner[3]
			endif
			controlinfo/W=MechanicsPanel#FitPanelEMod fitfunctiongeometery
			variable sphsph=V_Value
			controlinfo/W=MechanicsPanel#FitPanelEMod hertzfitoffset
			variable allowfitoffset=V_value
			duplicate/O y_axis, $Forcecurve+"Res"
			wave residual=$forcecurve+"Res"
			duplicate/O/R=[contact[1],upperlimitfit] y_axis, $Forcecurve+"RFIT_F"
			duplicate/O/R=[contact[1],upperlimitfit] defor_tr, $Forcecurve+"RFIT_D"
			wave RFIT_F=$Forcecurve+"RFIT_F", RFIT_D=$forcecurve+"RFIT_D"
			if(sphsph==2)
				sphereradius_intern=(1/sphereradius_intern+1/sampleradius)^-1
			endif
			if(allowfitoffset==0)
				Make/D/N=4/O W_coef, W_sigma
				W_coef[0] = {EModulGuess, SphereRadius_intern, shellthickness_g, PossionRatio}
				FuncFit/H="0111"/NTHR=0/Q ReissnerModelAl W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000, 7}/R=residual /A=0
				Reissner[4]=0
				RFIT_F=4*w_coef[0]*w_coef[2]^2/(3*(1-w_coef[3]^2))^0.5/w_coef[1]*RFIT_D
			else
				Make/D/N=5/O W_coef, W_sigma
				make/D/N=2/O/T T_Constraints
				T_constraints[0]={"K4>-"+num2str(defor_tr[lowerlimitfit]),"K4<15e-7"}
				W_coef[0] = {EModulGuess, SphereRadius_intern, shellthickness_g,PossionRatio,5e-9}
				FuncFit/H="01110"/NTHR=0/Q ReissnerModelAloffset W_coef y_axis[lowerlimitfit,upperlimitfit] /X=defor_tr /D /F={0.950000, 7}/R=residual /A=0/C=T_constraints
				Reissner[4]=w_coef[4]
				print "Contact Point Offset :"+num2str(w_coef[4])
				RFIT_F=4*w_coef[0]*w_coef[2]^2/(3*(1-w_coef[3]^2))^0.5/w_coef[1]*(RFIT_D-w_coef[4])				
			endif
			Reissner[0]=W_coef[0]
			Reissner[1]=W_sigma[0]
			Reissner[2]=lowerlimitfit
			Reissner[3]=upperlimitfit
			if(wholefolder_g!=1)
				contactexponentalone(forcecurve,contacttolerance*1e9,lowerlimitfit,upperlimitfit,absolutvalue,0)
			else
				contactexponentalone(forcecurve,contacttolerance*1e9,lowerlimitfit,upperlimitfit,absolutvalue,1)
			endif
		//Can be activated to show log-log plots of force vs deformation if only one curve is treated.
			if(wholefolder_G!=1&&allowfitoffset==1)
		//		contactexponentalone(forcecurve,contacttolerance*1e9,input,upperlimitfit)
			endif
			Reissner_fit="fit_"+y_name
			Reissner_fit=Reissner_fit[0,30]
			wave fit_wave=$Reissner_fit
			Reissner_fit_name="ReissnerFit"+forcecurve
			do
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				string tracesongraph=tracenamelist("mechanicspanel#mechdisplay",";",1)
				variable posi=strsearch(tracesongraph,"Reis",0)
				if(posi!=-1)
					removefromgraph $stringfromlist(0,tracesongraph[posi,strlen(tracesongraph)],";")
				endif
			while(strsearch(tracesongraph,"Reis",0)>0)
			if(waveexists($Reissner_fit_name)==1)
				killwaves $Reissner_fit_name
			endif
			rename fit_wave, $Reissner_fit_name
			NVAR showfit=root:panelcontrol:singlefcpanel:showfit_g
			NVAR invols=root:panelcontrol:singleFCPanel:invols_g, springconstant=root:panelcontrol:singlefcpanel:springconst_g
			variable errorEmodul=errorReissnerFit(forcecurve,Invols,possionratio,sphereradius,sampleradius,springconstant,allowfitoffset,shellthickness_g)
			if(showfit==1&&wholefolder_g==0)
				wave exponent=$forcecurvecut+"expo"
				DoWindow/F MechanicsPanel
				setactivesubwindow MechanicsPanel#Mechdisplay
				TextBox/K/N=text0
				if(strsearch(tracenamelist("mechanicspanel#mechdisplay",";",1),"RFIT",0)!=-1)
					removefromgraph $forcecurve+"RFit_F"
				endif
				appendtograph RFIT_f vs RFIT_d
				appendtograph $Reissner_fit_name
				ModifyGraph lsize($Reissner_fit_name)=2
				ModifyGraph rgb($Reissner_fit_name)=(0,12800,52224)
				Modifygraph rgb($forcecurve+"RFIT_F")=(0,0,0)
				ModifyGraph rgb($y_name)=(65280,0,0)
				SetAxis bottom -2e-08,defor_tr[upperlimitfit]
				setaxis left 0e-9,y_axis[upperlimitfit]
				TextBox/C/N=text0/A=LT "Force curve: "+Forcecurve+" \rCalculated E-Modul: "+num2str(Reissner[0])+" ± "+num2str(Reissner[1])+" Pa\rContact Slope: "+num2str(exponent[0])+" ± "+num2str(exponent[1])
			if((0.95<exponent[0]&&exponent[0]<0.98)||(1.03<exponent[0]&&exponent[0]<1.05))
				TextBox/C/N=text2/B=(65280,43520,0) "        \r           "
			elseif(0.98<exponent[0]&&exponent[0]<1.02)
				TextBox/C/N=text2/B=(0,65280,0) "        \r           "
			else
				TextBox/C/N=text2/B=(65280,0,0) "        \r           "
			endif
			endif
		endif
		while(doloop<-1)
	else
		Print "No data for "+forcecurve+" could be found in current folder!"	
	endif
end

//Similar to the errorHertz, the E-modul error coming with Reissner is determined based on error propagation. For more details see "errorHertzfit"
function errorReissnerFit(forcecurve,Invols,possionratio,sphereradius,sampleradius,springconstant,allowfitoffset, shellthickness)
	string forcecurve						//forcecurve=basename
	variable invols, possionratio,sphereradius, sampleradius, springconstant, allowfitoffset, shellthickness
	invols*=1e-9
	variable errorInvOLS=0.1*invols, errorSphereRadius=0.5e-6,  errorSpring=0.1*springconstant, errorshell=0.2*shellthickness
	variable errorcontact, fitoffset
	NVAR wholefolder_g=root:panelcontrol:singlefcpanel:wholefolder_g
	wave reissner=$forcecurve+"reis"
	if(allowfitoffset==0)
		 errorContact=5e-9
		 fitoffset=0
	else
		errorcontact=5e-9
		fitoffset=reissner[4]
	endif
	variable effectiveradius=sphereradius
	controlinfo/W=MechanicsPanel#FitPanelEMod FitFunctionGeometery
	if(V_value==2&&sampleradius!=0)
		effectiveradius=((1/sphereradius)+(1/sampleradius))^-1
	endif
	setdatafolder root:panelcontrol:fit_panel:
	NVAR error_SpringConstAbs_g, Error_Invols_g, Error_radiusSample_g, Error_radiusProbe_G, Error_contactPoint_g, Error_shellthickness_g
	NVAR error_springConst_avg, error_invols_avg, error_effradius_avg, error_contactpoint_avg, error_shellthickness_avg, error_fit_avg, error_total_avg
	if(error_springconstabs_g>0)
		errorspring=error_springconstabs_g
	endif
	if(error_invols_g>0)
		errorINvols=error_invols_g*1e-9
	endif
	if(error_radiusprobe_g>0&error_radiussample_g>0)
		errorsphereradius=((((sphereradius+sampleradius)*sampleradius-sampleradius*sphereradius)/(sampleradius+sphereradius)^2)^2*(error_radiusprobe_g*1e-6)^2+(((sphereradius+sampleradius)*sphereradius-sphereradius*sampleradius)/(sampleradius+sphereradius)^2)^2*(error_radiussample_g*1e-6)^2)^0.5
	elseif(error_radiusprobe_g>0&&error_radiussample_g<=0)
		errorsphereradius=error_radiusprobe_g*1e-6
	endif
	if(error_shellthickness_g>0)
		errorshell=error_shellthickness_g*1e-6
	endif
	if(error_contactpoint_g>0)
		errorcontact=error_contactpoint_g*1e-9
	endif
	string forcecurvecut=forcecurve
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	setdatafolder $folderstring_g
	variable lowerlimitfit, upperlimitfit
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	string contactPnts="ConcatPntsFM", reissner_fit, reissner_fit_name, force_trace, contactexpo="ContactExponent"
	string content=checkfoldercontent(forcecurve)
	if(numberbykey("raw",content,":",";")==1)
		wave disp_tr=$forcecurve+"raw_ext"
	else
		variable error1=1
	endif
	if(numberbykey("ZSnsr",content,":",";")==1)
		wave disp_tr=$forcecurve+"zsnsr_ext"
	else
		variable error2=1
	endif
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&error1+error2!=2)
		string y_name_tr, y_name_re
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name_tr=forcecurvecut+"DeflV_Ext_co"
		else
			y_name_tr=forcecurve+"DeflV_Ext"
		endif
		wave y_axis_tr=$y_name_tr
		wave contact=$forcecurve+"cont_tr"
		variable contactpoint=contact[2]
	
		wave residual=$forcecurve+"Res"
		lowerlimitfit=reissner[2]
		upperlimitfit=reissner[3]
		duplicate/O y_axis_tr $Forcecurve+"Esingle", $forcecurve+"EERRsing", $forcecurve+"E_kerr", $Forcecurve+"E_InvErr", $forcecurve+"E_Rerr", $forcecurve+"E_avgsdev", $Forcecurve+"E_FitErr", $forcecurve+"ResCalc", $Forcecurve+"E_ShellErr", $forcecurve+"E_Cont"
//		wave rescalc=$forcecurve+"ResCalc"
//		rescalc=y_axis_tr*invols*springconstant-4*reissner[0]*shellthickness^2*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)/effectiveradius/(3*(1-possionratio^2))^0.5
		duplicate/O $forcecurve+"res" $forcecurve+"rescalc"
		wave rescalc=$forcecurve+"rescalc"
		duplicate/O disp_tr $Forcecurve+"DeforEMoD"
		wave deforemod=$Forcecurve+"DeforEMod"
		deforemod=disp_tr-invols*y_axis_tr-contactpoint-fitoffset
		wave emodulsingle=$forcecurve+"Esingle"
		wave emodulerror=$forcecurve+"EERRsing"
		wave EKerror=$forcecurve+"E_kerr"
		wave EINVerror=$forcecurve+"E_Inverr"
		wave ERerror=$forcecurve+"E_Rerr"
		wave EAvgSdev=$forcecurve+"E_AvgSdev"
		wave EFitError=$forcecurve+"E_FitErr"	
		wave EShellerror=$forcecurve+"E_ShellErr"	
		wave EConterror=$forcecurve+"E_Cont"
		emodulsingle=springconstant*Invols*y_axis_tr/4*(3*(1-possionratio^2))^0.5*(effectiveradius)/shellthickness^2*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-1)
		EKerror=Invols*y_axis_tr/4*(3*(1-possionratio^2))^0.5*(effectiveradius)/shellthickness^2*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-1)*errorspring		
		ERerror=springconstant*Invols*y_axis_tr/4*(3*(1-possionratio^2))^0.5/shellthickness^2*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-1)*errorsphereradius
		EInvError=springconstant*y_axis_tr/4*(3*(1-possionratio^2))^0.5*(effectiveradius)/shellthickness^2*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-2)*(disp_tr-contactpoint-fitoffset)*errorinvols
		EShellerror=2*springconstant*Invols*y_axis_tr/4*(3*(1-possionratio^2))^0.5*(effectiveradius)/shellthickness^3*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-1)*errorshell
		EFitError=(3*(1-possionratio^2))^0.5/4*(effectiveradius)/shellthickness^2*(disp_tr-invols*y_axis_tr-contactpoint-fitoffset)^(-1)*rescalc
		EConterror=invols*springconstant*y_axis_tr/4*(3*(1-possionratio^2))^0.5*(effectiveradius)/shellthickness^2/contactpoint^2*errorcontact
		Eavgsdev=(EKerror^2+Eshellerror^2+ERerror^2+EInverror^2+EFitError^2+EConterror^2)^0.5
		duplicate/O emodulsingle $forcecurve+"EsingTot"
		duplicate/O Eavgsdev $Forcecurve+"ESdevTot"
		wave esdevtot=$forcecurve+"ESdevTot"
		esdevtot=(EKerror^2+Eshellerror^2+ERerror^2+EInverror^2+EFitError^2+EConterror^2)^0.5		//Fit und Contact haben erst gefehlt... y?
		duplicate/O deforemod $forcecurve+"DefEMTot"
		deletepoints 0, contact[1], $forcecurve+"EsingTot",$forcecurve+"esdevtot", $forcecurve+"DefEmtot"
		deletepoints 0, lowerlimitfit-1, emodulsingle, ekerror, eshellerror, einverror, ererror, Eavgsdev, EfitError, deforemod, econterror
		deletepoints (upperlimitfit-lowerlimitfit), numpnts(emodulsingle), emodulsingle, ekerror, eshellerror, einverror, ererror, eavgsdev, EfitError, deforemod, econterror
		error_springconst_avg=mean(ekerror)
		error_invols_avg=mean(einverror)
		error_effradius_avg=mean(eRerror)
		error_contactpoint_avg=mean(EConterror)
		error_shellthickness_avg=mean(EShellError)
		error_fit_avg=mean(EFitError)
		do
		if(numtype(emodulsingle[0])==2)
			deletepoints   0, 1, emodulsingle, ekerror, eshellerror, einverror, ererror, Eavgsdev, EfitError, deforemod
		endif
		while(numtype(emodulsingle[0])==2)
		if(wholefolder_G!=1)
			display $forcecurve+"EsingTot"[100,*] vs $forcecurve+"DefEmTot"[100,*]
		endif
		duplicate/O emodulsingle, weightedavg
		wave weightedavg
		weightedavg=emodulsingle/(eavgsdev^2)
		eavgsdev=1/(eavgsdev^2)
		variable sumwei=sum(weightedavg)
		variable sumsdev=sum(eavgsdev)
		variable weightedsdev=(1/sum(eavgsdev))^0.5
		eavgsdev=1/(eavgsdev^0.5)
		duplicate/O/R=[contact[1],upperlimitfit] y_axis_tr, $Forcecurve+"FitC_F", $forcecurve+"FitC_f2" 
		duplicate/O/R=[contact[1],upperlimitfit] disp_tr, $forcecurve+"FitC_D"
		wave fitc_f=$Forcecurve+"FitC_F", fitc_d=$forcecurve+"FitC_D", fitc_f2=$forcecurve+"FitC_f2"
		fitc_F=sumwei/sumsdev*4*shellthickness^2*(fitc_d-invols*fitc_F-contactpoint-fitoffset)/effectiveradius/(3*(1-possionratio^2))^0.5
		fitc_D=fitc_d-invols*fitc_F2-contactpoint//-fitoffset
		killwaves fitc_F2
		if(wholefolder_g==0)
			DoWindow/F MechanicsPanel		
			setactivesubwindow MechanicsPanel#Mechdisplay					
			if(strsearch(tracenamelist("mechanicspanel#mechdisplay",";",1),"FitC",0)!=-1)
				removefromgraph $forcecurve+"FitC_F"
			endif
			dowindow/F mechanicspanel
			setactivesubwindow MechanicsPanel#Mechdisplay
			appendtograph fitc_F vs fitc_D
			ModifyGraph mode=0,rgb($forcecurve+"FitC_F")=(0,52224,0)
		endif	
		DoWindow/F MechanicsPanel
		setactivesubwindow MechanicsPanel#ShowErrorPanel 
		variable eavg=mean(emodulsingle)
		valdisplay vd7, limits={0.05*reissner[0],reissner[0],0.5*reissner[0]}
		setactivesubwindow ##
		variable meanEError=mean(eavgsdev)
		reissner[1]=meanEError
	//	variable eavg=mean(emodulsingle)
	//	hertzvalues[0]=eavg
		eavgsdev=eavgsdev^2
		error_total_avg=meanEError
		variable EError=(sum(eavgsdev)/(numpnts(eavgsdev)^2))^0.5
	//	hertzvalues[1]=EError
		eavgsdev=eavgsdev^0.5
	//	hertzvalues[0]=eavg
	//	hertzvalues[1]=EError	
	endif
	return EERror
end

//This function was intended in the past to find the best fit region where Hertz-theory is valid. Never really worked though, been abandoned and might be revived at some point.
function searchfitreagion(forcecurve,startpoint,percentage)
	string forcecurve
	variable startpoint, percentage
	string forcelogstr="Log_"+forcecurve+"For", deforlogstr="Log_"+forcecurve+"defor",deforstr=forcecurve+"defor_ext"
	wave forcelog=$forcelogstr, deforlog=$deforlogstr, defor_tr=$deforstr
	percentage*=100
	variable contactpoint=10^deforlog[0]
	variable endpntfit
	if(percentage==100)
		endpntfit=numpnts(defor_tr)-1
	elseif(percentage>100)
		endpntfit=percentage	
	else
		variable deformationdepth2fit=percentage*defor_tr[numpnts(defor_tr)-1]
		findvalue/S=(Contactpoint)/T=(1.5e-9)/V=(deformationdepth2fit) defor_tr
		endpntfit=V_Value
	endif
	variable offsetfit,loopinger,offsetfitnm
	do	
		curvefit/NTHR=0/Q line forcelog[offsetfit,numpnts(forcelog)-numpnts(defor_tr)+endpntfit] /X=deforlog/D
		if(V_chisq>0.2)
			findvalue/S=(contactpoint)/T=(1.5e-9)/V=(offsetfitnm+20e-9) defor_tr
			offsetfit=V_value-startpoint
			offsetfitnm+=20e-9
		endif
		loopinger+=1
	while(V_chisq>0.2||loopinger<50||offsetfit>numpnts(forcelog)-numpnts(defor_tr)+endpntfit)
	variable test=10^deforlog[offsetfit]
	print "Calculated Fit Start: "+num2str(offsetfitnm)
	return offsetfit
end
//same as for hertz, never come far...
function searchfitregionJKR(forcecurve)
	string forcecurve
	wave force_re=$forcecurve+"force_ret_co", defor_re=$forcecurve+"defor_ret"
	wave adhesinoF=$forcecurve+"adhf"
	NVAR EModoffset=Root:panelcontrol:fitpanel:emodoffset_g
	emodoffset*=1e-9
end

//Function to read all wave-names in the datafolder and put them in a string-wave. Started with "Graph Force Curve" button.
Function GrabFolderContent()
//All wavenames are put in the string "listofwaves" with ";" spaceing.
	string listofwaves =  wavelist("*",";","")
//Awave is just a dummy string which will hold single wavenames at a time to be checked if it is not a wavename coming from the contant-checking itself.
	string awave 
//Run-variables.
	variable i, startdelete, notused=0
//Create "wavelistinfolder" with set length of 3000(should not be exceeded in most experiments. To much points will be deleted in the end.
	make/O/N=3000/T WavelistInFolder
	wave/T WavelistinFolder
//i as run-variable in the for-loop to check the positions in listofwaves and setting the point-number in wavelistinfolder
	for(i=0;i<3000;i+=1)
	//Put the i-th string of listofwaves in awave
	 	awave =  stringfromlist(i, listofwaves, ";")	
	 //Check that "awave" is not empty, does not start with "wavet" (??? not wavel???) and does not contain "info"
	 	if(stringmatch(awave,"!")!=0&&stringmatch(awave,"wavet*")==0&&stringmatch(awave,"*info*")==0)
	 	//If so put the current string in the wavelistinfolder, increase the delete start.
	 		WavelistInfolder[i-notused]=awave
	 		startdelete+=1
	 //In case any of the three conditions is met increase the notused variable.
	 	else
	 		notused+=1
	 	endif
	endfor	
//Delete all not used points in wavelistinfolder
	deletepoints startdelete, notused+1, wavelistinfolder
//Sort the wave alphabetically. Needed possibly for the next function to delete multiple wave endings per basename.
	sort/A wavelistinfolder, wavelistinfolder			
//Note: now for every force curve all single wave for deflection and displacement are in this list!						
End

//Function to determine the separation waves for a given force curve.
function calcseparation(forcecurve,percentcontfit)
//Input variables&strings.
	string forcecurve
	variable percentcontfit 
	percentcontfit/=100
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g	
//Check folder content. Delfection wave and deformation wave is needed. (Deformation is needed bcs you either need the contact point or to directly recalc sepa from defor.)
	string content=checkfoldercontent(forcecurve), forcecurvecut=forcecurve
	if(numberbykey("DeflV",content,":",";")==1||numberbykey("DeflVCo",content,":",";")==1&&numberbykey("Defor",content,":",";")==1)
		string y_name_tr, y_name_re
	//Load the baseline corrected deflection if present.
		if(numberbykey("DeflVCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name_tr=forcecurvecut+"DeflV_Ext_co"
			y_name_re=forcecurvecut+"DeflV_Ret_co"
		else
			y_name_tr=forcecurve+"DeflV_Ext"
			y_name_re=forcecurve+"DeflV_Ret"
		endif
	//Reduce basename length if too long.
		if(strlen(forcecurve)>19)
			forcecurvecut=forcecurve[3,strlen(forcecurve)]
		endif
		wave y_axis_tr=$y_name_tr
		wave y_axis_re=$y_name_re
		wave x_defor_tr=$Forcecurve+"Defor_Ext"
		wave x_defor_re=$forcecurve+"Defor_Ret"
	//Create the Separation (sepa) waves as duplicates of deformation waves.
		duplicate/O x_defor_tr, $forcecurve+"Sepa_ext"
		duplicate/O x_defor_re, $forcecurve+"Sepa_ret"
		wave x_sepa_tr=$forcecurve+"sepa_ext"
		wave x_sepa_re=$forcecurve+"sepa_ret"
	//Deformation and separation are typically directly linked to each other since they, for most curves, only differ in the sign of values by *-1
		x_sepa_tr*=-1
		x_sepa_re*=-1
	//Check "deformation Calc" drop down menu what is chosen.
		controlinfo usecursor_defor
	//In case any "line-fit" is chosen one assumes to be in constant compliance in the end. This means that a absolute zero in separation is available.
	//Then the contact point is not zero but where the substrate is.
		if(V_value>=4)
		//The contact-point result wave is loaded.
			wave contact=$forcecurve+"cont_tr"
		//Determine the contact part fit start, here for trace only.
			variable fitstart=numpnts(x_sepa_tr)-round(percentcontfit*(numpnts(x_sepa_tr)-contact[1]))
		//Repeat the line fit of the constant compliance section. Which is for some reasons not used....
			curvefit/X=1/nthr=0/Q line y_axis_tr[fitstart,numpnts(y_axis_tr)]/X=x_defor_tr/D	
			wave w_coef
		//The mean deformation values in the stated constant compliance regime is determined.
			variable sepa_offset_tr=mean(x_defor_tr, fitstart, numpnts(x_defor_tr))
			variable sepa_offset_re=mean(x_defor_re, 0, (numpnts(x_defor_re)-fitstart))
		//These mean values are added to the already made separation wave. This sets this section to 0.
			x_sepa_tr+=sepa_offset_TR
			x_sepa_re+=sepa_offset_tr
		endif
	else
		print "Please first calculate deformation waves!"
	endif
end

//This function reduces the "wavelistfolder" to "listofbasenames" which holds the basic names of the force curves without the re-/trace endings.
//Dont know why I made it that complicated, but it works now this way.
Function CleanForBasename()
//Load the wavelistinfolder (create by Grapfoldercontent()) and duplicate it to a new wave.
	wave/T WavelistinFolder
	duplicate/O/T WaveListInFolder, ListOfBaseNames
	wave/T ListOfBaseNames
	variable i, deletedpoints=0
//2 strings, 1 containing the name of the past and 1 containing the current string of the row looked at.
	string strpastrow, strcurrentrow
//Loop through the complete length of wavelistinfolder to check and reduce it to the basenames.
	for(i=1;i<numpnts(Wavelistinfolder);i+=1)
	//Put the string from 1 before i of wavelist into the past-row-string.
		strpastrow=wavelistinfolder[i-1]
	//Delete the last 4 (since strings positions also start counting at 0) characters which are for "_ext" or "_ret"
		strpastrow=strpastrow[0,strlen(strpastrow)-5]
	//Make the same treatment for the i-th row of wavelistinfolder.
		strcurrentrow=wavelistinfolder[i]
		strcurrentrow=strcurrentrow[0,strlen(strcurrentrow)-5]
	//Check if the two strings match. True: a match of re-/trace was found. 
		if(Stringmatch(strpastrow,strcurrentrow)==1)
		//Delete the former content of wavelist and listofbasenames.
			deletepoints i-1,1, wavelistinfolder, ListOfBaseNames
		//Put the reduced string in the i-1 position of listofbasenames.
			ListOfBaseNames[i-1]=strcurrentrow
			deletedpoints+=1		//not used...
			i-=1	//makes the function double check the same input. Actually only needed when there are 3 endings for the same type.(eg dwell)
		endif
	endfor
end

//Name is missleading. Here the pre-reduced listofbasenames is further shrunken to only hold the basenames, without any ending.
function CreateListOfBasenames()
//Load the listofbasenames created earlier.
	wave/T ListOfBaseNames
//Make a string which holds the name of the backup for the listofbasenames.
	string listofbasenames_backuplocal="listofbasenames_backuplocal"
//some variables used later.
	variable i, typeOfWaves=0, zsnsrexists, rawexists,forceexists, deflexists, nonmatch=0
	NVAR limitsdisplay_g=root:panelcontrol:singlefcpanel:limitsdisplay_g
	string currentrow
//This for loop checks the first 7 items of listofbasenames for the type of force-curves present in the folder.
//More than these types is not usefull to load any ways. 
//This check is also not really usefull here since it is not used in any way, but well...
	for(i=0;i<7;i+=1)
		nonmatch+=1
		if(stringmatch(ListOfBaseNames[i],"*ZSnsr")==1&&zsnsrexists==0)
			typeofWaves+=1
			zsnsrexists=1
			nonmatch-=1
		endif
		if(stringmatch(ListOfBaseNames[i],"*Raw")==1&&rawexists==0)
			typeofWaves+=1
			rawexists=1
			nonmatch-=1
		endif
		if(Stringmatch(ListOfBaseNames[i],"*DeflV")==1&&deflexists==0)
			typeofWaves+=1
			deflexists=1
			nonmatch-=1
		endif
		if(stringmatch(ListOfBaseNames[i],"*Force")==1&&forceexists==0)
			typeofWaves+=1
			forceexists=1
			nonmatch-=1
		endif
	endfor
//go through every entry of list of basename.
	for(i=0;i<numpnts(ListOfBasenames);i+=1)
	//the content of the current (i-th) row is loaded to a string.
		currentrow=listofbasenames[i]
	//The current local (not the one in the wave) is reduced in length till there is a number at the end.
	//This is specified for AR force curve since the always end with a 4 digit suffix. 
	//For force-curve from other AFM this may needs to be adjusted.
		do
		//In case the last character of the current string is "Not A Number" (so a letter) delete the last char.
			if(numtype(str2num(currentrow[strlen(currentrow)-1]))==2)
				currentrow=currentrow[0,strlen(currentrow)-2]
			endif
	//Do it as long as there is a letter at the end of the string.
		while(numtype(str2num(currentrow[strlen(currentrow)-1]))==2)
	//Check the upcoming contents of listofbasename if they have the same basename.
		do
		//Check if the next (i+1) row is already out of the point-length of listofbasename (the end of list).
			if(i+1>numpnts(listofbasenames)-1)
			//Stop the do-loop since there is nothing more to delete or check.
				break
			endif
		//Put the content of the next row of listofbasenames in a local string
			string nextrow=listofbasenames[i+1]
		//Compare the current basename (without type and re-/trace) with nextrow of the same string length == basename of the next.
			if(stringmatch(currentrow,nextrow[0,strlen(currentrow)-1])==1)
			//In case they match delete the next entry.
				deletepoints i+1, 1, listofbasenames
			endif
	//Repeat this in case there was a match and the i+1 point was delete. 
		while(stringmatch(currentrow,nextrow[0,strlen(currentrow)-1])==1)
	//Since listofbasenames was alphabetically sorted all wave belonging to was basename are in order. 
	//At this point all but one entry in listofbasename with the same basename are deleted.
	//The basename which was check above is writen into the wave.
		listofbasenames[i]=currentrow
	endfor
//Limitsdisplay is a global variable limiting the "force curve number" to be displayed in the GUI graph and set to the length of listofbasename.
	limitsdisplay_g=numpnts(listofbasenames)-1
//In case there is already a listofbasename wave in the panel folder (which it self is only a backup) duplicate the old to be the Back-backup.
	if(waveexists(root:panelcontrol:singlefcpanel:listofbasenames_g)==1)
		duplicate/O root:panelcontrol:singlefcPanel:listofbasenames_g, root:panelcontrol:singlefcPanel:listofbasenames_backup
	endif 
//Duplicate the newly created list to be the new backup in the panel-folder.
	duplicate/O ListofBasenames, root:panelcontrol:singlefcpanel:listofbasenames_g
//in case there is no backup in the actual force-curve folder of the list of basenames create one. (seems not always to work or to be deleted at some point)	
	if(waveexists($listofbasenames_backuplocal)!=1)
		duplicate/O ListOfBaseNames, $listofbasenames_backuplocal
	endif
end

//Attempt to do all the force-curve treatment with only starting one function. May work but is a rather bad way to do it.
//Better to handel it step-by-step with the gui.
function DoForceEvaluation()
//Set all varialbes otherwise set in the GUI.
	variable invols=405.28 //  nm/V
	variable baselinePercent=60 	// percent
	variable jumpto=0			// No Jump-To
	variable derivationbase=0.4		// nm
	variable contacttolerance=0.8	//nm
	variable exponentoffset=100	//nm
	variable fitmaximum=80		//percent
	variable emoduloffset=100		//nm
	variable percentcontactFit=80	//percent
	variable EModulGuess=50000	// Pa
	variable SphereRadius=17.7	//µm
	variable PossionRatio=0.22
	variable usecursorvar
	variable sampleradius
	variable depthoffset
	variable fitlength_g
	wave/T ListOfBaseNames
//Check if there is a list of basename: true use that; false make a new one.
	if(waveexists(Listofbasenames)==1)
		print "Used old List of Force Curves in Folder"
	else
		GrabFolderContent()
		CleanForBasename()
		CreateListOfBasenames()
	endif
	variable i
//Make for all force curves the baseline correction, contact point determination, deformation calc, contact exponent and Hertz-fitting.
	for(i=0;i<numpnts(listofbasenames);i+=1)
		VirtualDeflectionAlone(listofbasenames[i],baselinePercent,jumpto)
		contactpointBASEalone(listofbasenames[i],invols,derivationbase,baselinepercent)
		DeformationAlone(listofbasenames[i],invols)
		contactexponentalone(listofbasenames[i],contacttolerance,exponentoffset,fitmaximum,0,1)
		EModulusHertzAlone(listofbasenames[i], emoduloffset,percentcontactFit,contacttolerance,EModulGuess, SphereRadius, PossionRatio,usecursorvar,sampleradius,depthoffset, fitlength_g)
	endfor
end

//Fit function of Hertz model without offset.
Function HertzModelAl(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = 2/3*E*Radius^0.5*(1-possion^2)*x^2/3
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = Radius
	//CurveFitDialog/ w[2] = possion
	return 4/3*w[0]*w[1]^0.5/(1-w[2]^2)*x^(3/2)
End
//Fit function of Hertz model with deformation offset allowed.
Function HertzModelAlOFFSET(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = 2/3*E*Radius^0.5*(1-possion^2)*x^2/3
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = Radius
	//CurveFitDialog/ w[2] = possion
	//CurveFitDialog/ w[3] = deformation_offset
	return 4/3*w[0]*w[1]^0.5/(1-w[2]^2)*(x-w[3])^(3/2)
End
//Fit function of Hertz model with sphere sphere contact and both radii as function parameters.
Function HertzModelAlSphSph(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = 2/3*E*Radius^0.5*(1-possion^2)*x^2/3
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = Radius_probe
	//CurveFitDialog/ w[2] = possion
	//CurveFitDialog/ w[3] = Radius_sample
	return 4/3*w[0]*(1/w[1]+1/w[3])^-0.5/(1-w[2]^2)*x^(3/2)
End
//Fit function of Hertz model with sphere sphere contact and both radii as function parameters with deformation offset allowed.
Function HertzModelAlSphSphOFFSET(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = 2/3*E*Radius^0.5*(1-possion^2)*x^2/3
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = Radius_probe
	//CurveFitDialog/ w[2] = possion
	//CurveFitDialog/ w[3] = Radius_sample
	//curvefitdialog/ w[4] = deformation_offset
	return 4/3*w[0]*(1/w[1]+1/w[3])^-0.5/(1-w[2]^2)*(x-w[4])^(3/2)
End
//Fit function according to DMT model
Function DMT(w,delta) : FitFunc
	Wave w
	Variable delta
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(delta) = 4/3*R^(0.5)*E/((1-possion^2))*(delta-deltashift)^(3/2)-Fad
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ delta
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = Fad
	//CurveFitDialog/ w[2] = R
	//CurveFitDialog/ w[3] = possion
	//CurveFitDialog/ w[4] = deltashift
	return 4/3*w[2]^(0.5)*w[0]/((1-w[3]^2))*(delta-w[4])^(3/2)-w[1]
End
//Fit function according to JKR
Function JKR(FitCoef_JKR,F) : FitFunc						//JKR for system soft probe - hard substrate/ hard probe - soft substrate
	wave FitCoef_JKR
	variable F
	variable ProbeRadius	, Poisson						//depend on system R: Radius of the AFM probe or relative radius of probe and spherical sample, Poisson: for elastomeres 0.5 (see inputfunction)
	variable RR, adhesion									//Important: wave 'Diameter' has to be created before, see above.
	ProbeRadius=FitCoef_JKR[2]
	poisson=FitCoef_JKR[3]
	adhesion=FitCoef_JKR[1]
	return ((3/4)*(1-Poisson^2)*(ProbeRadius)*(F+2*(-adhesion)+2*(F*(-adhesion)+(-adhesion)^2)^(0.5))/(FitCoef_JKR[0]))^(2/3)/(ProbeRadius)-(4/3)^(1/3)*(1-Poisson^2)^(2/3)*((-adhesion)/((ProbeRadius)*FitCoef_JKR[0]))^(0.5)*((ProbeRadius)*(F+2*(-adhesion)+2*(F*(-adhesion)+(-adhesion)^2)^(0.5))/(FitCoef_JKR[0]))^(1/6)+FitCoef_JKR[4]
end
//Fit function according to Reissner model.
Function ReissnerModelAl(w,d) : FitFunc
	Wave w
	Variable d
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(d) = 4*E*h^2*d/(3*(1-possion^2))^0.5/R
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ d
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = R
	//CurveFitDialog/ w[2] = h
	//CurveFitDialog/ w[3] = possion
	return 4*w[0]*w[2]^2*d/(3*(1-w[3]^2))^0.5/w[1]
End
//Fit function according to Reissner model plus allowing for a deformation offset.
Function ReissnerModelAlOFFSET(w,d) : FitFunc
	Wave w
	Variable d
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(d) = 4*E*h^2*d/(3*(1-possion^2))^0.5/R
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ d
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = E
	//CurveFitDialog/ w[1] = R
	//CurveFitDialog/ w[2] = h
	//CurveFitDialog/ w[3] = possion
	//CurveFitDialog/ w[4] = deformation_offset
	return 4*w[0]*w[2]^2*(d-w[4])/(3*(1-w[3]^2))^0.5/w[1]
End
//Fit function according to the Maugis theory in the approximation of Carpick
Function Carpick_7(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = ((B+(1-(x/A))^0.5)/(1+B))^(2/3)*R+(B/(1+B))^(2/3)*R
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = R
	//CurveFitDialog/ w[1] = B
	//CurveFitDialog/ w[2] = A
	return ((w[1]+(1-(x/w[2]))^0.5)/(1+w[1]))^(2/3)*w[0]//+(w[1]/(1+w[1]))^(2/3)*w[0]
End
//Fit function according to the Maugis theory in the approximation of Carpick plus allowing for a contact-radius offset.
Function Carpick_7_offset(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = ((B+(1-(x/A))^0.5)/(1+B))^(2/3)*R+(B/(1+B))^(2/3)*R
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = R
	//CurveFitDialog/ w[1] = B
	//CurveFitDialog/ w[2] = A
	return ((w[1]+(1-(x/w[2]))^0.5)/(1+w[1]))^(2/3)*w[0]+(w[1]/(1+w[1]))^(2/3)*w[0]
End

//Function determining the contact area based on the JKR theory. Not called by any other function. Supposed as potential additional information.
//Check the math since I cant recall why it is the way it is now...
function contactarea_jkr_func(radius_sample,radius_probe,emodul_JKR,emodul_JKR_err, maxforce)
//Input variables need to be provided manually by user.
	variable radius_sample,Radius_probe, emodul_JKR, emodul_JKR_err,maxforce
	wave/T listofbasenames
//Create wave for size/geometry related values based on jkr theory.
	make/o/N=(numpnts(listofbasenames)) contactarea_JKR, contactarea_rips, contactarea_relation, contactarea_geometrical, indentation_calced_JKR, indentation_calced_rips, contarea_JKR_geo, contarea_rips_geo
	wave contactarea_jkr, contactarea_rips, contactarea_relation, contactarea_geometrical, indentation_calced_JKR, indentation_calced_rips, contarea_jkr_geo, contare_rips_geo
	make/o/n=(numpnts(listofbasenames)) contactradius_jkr, contactradius_rips, contactradius_geo, contrad_jkr_geo, contrad_rips_geo, contrad_JKR_errorE, contrad_RIPs_errorE
	wave contactradius_jkr, contactradius_rips, contactradius_geo, contrad_jkr_geo, contrad_rips_geo, contrad_rips_errorE, contrad_Jkr_errorE
//Load work of adhesion wave predetermined by the "advanced" adhesion function.
	wave workofadhesion_jkr, workadh_perarea_list
	variable i, force_input
//Go through all force curves in the folder.
	for(i=0;i<numpnts(listofbasenames);i+=1)
	//Load the respective force and deformation wave.
		wave force=$listofbasenames[i]+"force_ext_co"
		wave defor=$listofbasenames[i]+"defor_ext"
	//Select the force used in the JKR calculations. If the input force is higher than the maximum force in the actuall experiment use the later.
		if(force[numpnts(force)-1]<maxforce)
			force_input=force[numpnts(force)-1]
		else
			force_input=maxforce
		endif
	//contact area from JKR. Cant tell why the jkr_radius is multiplied by 2 and max deformation is added...
		contactarea_JKR[i]=(calc_Contactradius_JKR(radius_sample,radius_probe,workofadhesion_JKR[i], emodul_jKr, force_input)^2*2+defor[numpnts(defor)-1]^2)*pi
		contactarea_RIps[i]=(calc_Contactradius_JKR(radius_sample,radius_probe,workadh_perarea_list[i], emodul_jKr, force_input)^2*2+defor[numpnts(defor)-1]^2)*pi
		contactarea_relation[i]=calc_relContactAreaIncrease_JKR(radius_sample,radius_probe,workofadhesion_JKR[i], workadh_perarea_list[i], emodul_jKr, force_input)
		contactarea_geometrical[i]=pi*(defor[numpnts(defor)-1]^2+2*(radius_probe^2-(radius_probe-defor[numpnts(defor)-1])^2))
		contactradius_jkr[i]=calc_Contactradius_JKR(radius_sample,radius_probe,workofadhesion_JKR[i], emodul_jKr, force_input)
		contactradius_rips[i]=calc_Contactradius_JKR(radius_sample,radius_probe,workadh_perarea_list[i], emodul_jKr, force_input)
		contactradius_geo[i]=(radius_probe^2-(radius_probe-defor[numpnts(defor)-1])^2)^0.5
		indentation_calced_JKR[i]=(-4*radius_probe+(16*radius_probe^2-4*contactarea_JKR[i]/pi)^0.5)/(-2)
		indentation_calced_rips[i]=(-4*radius_probe+(16*radius_probe^2-4*contactarea_rips[i]/pi)^0.5)/(-2)
	endfor
	contarea_JKR_geo=contactarea_JKR/contactarea_geometrical
	contarea_rips_geo=contactarea_rips/contactarea_geometrical
	contrad_jkr_geo=contactradius_jkr/contactradius_geo
	contrad_rips_geo=contactradius_rips/contactradius_geo
	contrad_jkr_errorE=contactradius_JKR/3/emodul_JKR*emodul_jkr_err
	contrad_rips_errorE=contactradius_rips/3/emodul_jkr*emodul_jkr_err
end	
//Calc the contact radius based on JKR for 1 single force but E-Modul and WoA need to be provided.
function calc_Contactradius_JKR(radius_sample,radius_probe,workofadhesion, emodul_jKr, force)
	variable radius_sample, radius_probe,workofadhesion, emodul_jkr, force
	variable radius=(1/radius_sample+1/radius_probe)^-1
	variable contactradius=((radius/emodul_JKR*(force+3*pi*radius*workofadhesion+(6*pi*radius*workofadhesion*force+(3*pi*radius*workofadhesion)^2)^0.5))^(1/3))
	return contactradius
end
function calc_relContactAreaIncrease_JKR(radius_sample,radius_probe,workofadhesion_JKR, workofadhesion_rips, emodul_jKr, force)
	variable radius_sample, radius_probe,workofadhesion_JKR, workofadhesion_rips, emodul_jkr, force
	variable radius=(1/radius_sample+1/radius_probe)^-1
	variable contactarea_rips=(radius/emodul_JKR*(force+3*pi*radius*workofadhesion_rips+(6*pi*radius*workofadhesion_rips*force+(3*pi*radius*workofadhesion_rips)^2)^0.5))^(1/3)
	variable contactarea_JKR=(radius/emodul_JKR*(force+3*pi*radius*workofadhesion_JKR+(6*pi*radius*workofadhesion_JKR*force+(3*pi*radius*workofadhesion_JKR)^2)^0.5))^(1/3)
	return contactarea_rips/contactarea_JKR
end

//Usefull function to extract certain information from single waves and put them in an overview wave
function folder_info2list(wavetyp,row,savewave)
//Wavetype holds the appendix of the wave. e.g. "_cont_tr" for contact point trace information.
	string wavetyp
//Row specifies the row in the wave where the value is located.
	variable row
//Name of the overview wave where the values should be collected.
	string savewave
	wave/T listofbasenames
//Create the new overview wave.
	make/o/N=(numpnts(listofbasenames)) $savewave
	wave saveW=$savewave
//Go through all force curves in the folder.	
	variable i
	for(i=0;i<numpnts(listofbasenames);i+=1)
	//Set together the wavename where the info is stored by combining basename+ending.
		string info=listofbasenames[i]+wavetyp
		wave infowave=$info
	//Save the search value in the i-th row of the overview wave so that the value can be directly linked to the force-name in listofbasenames with the row-number.
		savew[i]=infowave[row]
	endfor
end

//Same as folder_info2list but instead of constant row value the read-row is specified in a wave.
//This allows for different read-outs for different waves.
function folder_info2wave(wavetyp,rowwave,savewave)
	string wavetyp
	wave rowwave
	string savewave
	wave/T listofbasenames
	make/o/N=(numpnts(listofbasenames)) $savewave
	wave saveW=$savewave
	variable i
	for(i=0;i<numpnts(listofbasenames);i+=1)
		string info=listofbasenames[i]+wavetyp
		wave infowave=$info
	//The row-value for the current force-curve is checked. If the values is below 0 (typically -1) or NaN -> save NaN.
		if(rowwave[i]<0||numtype(rowwave[i])==2)
			savew[i]=nan
		else
			savew[i]=infowave[rowwave[i]]
		endif
	endfor
end

//Same as folder_info2list but for 3D waves. Structure is designed to work with force-maps; basename structure lineXXXXPointYYYY+ending.
function folder_info2matrix(wavetyp,row,matrixdummy)
	string wavetyp
	variable row
	wave matrixdummy
	duplicate/O matrixdummy, $wavetyp+"matrix"
	wave matrix=$wavetyp+"matrix"
	wave/T listofbasenames
	string forcecurvename, infoname
	variable i, rownumber, colnumber
	for(i=0;i<numpnts(listofbasenames);i+=1)
		forcecurvename=listofbasenames[i]
		rownumber=str2num(forcecurvename[4,7])
		colnumber=str2num(forcecurvename[13,16])
		infoname=forcecurvename+wavetyp
		wave infowave=$infoname
		matrix[rownumber][colnumber]=infowave[row]
	endfor
//The double reverse is so that matrix can be appended to forcemap (AR).
	reverse/dim=0 matrix
	reverse/dim=1 matrix
end

//General function performing the FindValue command for a defined type of curve for the whole folder.
function folder_findvalueinwave(wavetyp,savewave,value,tolerance)
//Name of the type of curves searched in and how the overview result wave should be named.
	string wavetyp, savewave
//Search value and search tolerance.
	variable value, tolerance
	wave/T listofbasenames
//Create 2 wave for the value found and the point position where it is found.
	make/O/N=(numpnts(listofbasenames)) $savewave, $savewave+"Point"
	wave saveW=$savewave, saveWP=$savewave+"Point"
	variable i
//Check every basename of the curves saved in the folder.
	for(i=0;i<numpnts(listofbasenames);i+=1)
	//Create the actual wavename in which to search.
		string info=listofbasenames[i]+wavetyp
		wave infowave=$info
	//Standard FindValue command.
		findvalue/T=(tolerance)/V=(value) infowave
	//FindValue returns -1 if search was not successful.
		if(V_value==-1)
		//Nothing found -> save not a number.
			savew[i]=nan
			savewP[i]=nan
		else
		//Save found value and point number.
			savew[i]=infowave[v_value]
			savewP[i]=v_value
		endif
	endfor
end

//Check the current folder which types of waves are already there for the input force-curve name.
function/T checkfoldercontent(forcecurve)
//Input the basename when called.
	string forcecurve
	string forcecurvecut=forcecurve
//All list of all possible name-endings the basename can have during force curve evaluation (separation is left out here).
	wave defl_re=$forcecurve+"DeflV_Ret"
	wave defl_tr=$forcecurve+"DeflV_Ext"	
	wave force_tr=$forcecurve+"Force_Ext"
	wave force_re=$forcecurve+"Force_Ret"
	wave zsnsr_tr=$forcecurve+"ZSnsr_Ext"
	wave zsnsr_re=$forcecurve+"ZSnsr_Ret"
	wave raw_tr=$forcecurve+"Raw_Ext"
	wave raw_re=$forcecurve+"Raw_Ret"
	wave defor_tr=$forcecurve+"Defor_Ext"
	wave defor_re=$forcecurve+"Defor_Ret"
	wave defl_towd=$forcecurve+"DeflV_Towd"
	wave force_towd=$forcecurve+"Force_Towd"
	wave zsnsr_towd=$forcecurve+"Zsnsr_Towd"
	wave raw_towd=$forcecurve+"Raw_Towd"
	if(strlen(forcecurve)>19)
		forcecurvecut=forcecurve[3,strlen(forcecurve)]
	endif
	wave force_tr_co=$forcecurvecut+"Force_Ext_co"
	wave force_re_co=$Forcecurvecut+"Force_Ret_co"
	wave defl_tr_co=$forcecurvecut+"DeflV_Ext_co"
	wave defl_re_co=$Forcecurvecut+"DeflV_Ret_co"
	wave defl_towd_co=$forcecurvecut+"DeflV_Towd_c"
	wave force_towd_co=$forcecurvecut+"Force_Towd_c"
//For every type of ending a variable is created. By waveexists their existence is check, if true var=1
	variable defl_exists, force_exists, zsnsr_exists,raw_exists, force_co_exists, defl_co_exists, defor_exists, towd_exists
	if(waveexists(defl_tr)==1||waveexists(defl_re)==1)
		 defl_exists=1
	else
		 defl_exists=0
	endif
	if(waveexists(force_tr)==1||waveexists(force_re)==1)
		 force_exists=1
	else
		 force_exists=0
	endif
	if(waveexists(zsnsr_tr)==1||waveexists(zsnsr_re)==1)
		 zsnsr_exists=1
	else
		 zsnsr_exists=0
	endif
	if(waveexists(raw_tr)==1||waveexists(raw_re)==1)
		 raw_exists=1
	else
		 raw_exists=0
	endif
	if(waveexists(force_tr_co)==1||waveexists(force_re_co)==1)
		force_co_exists=1
	else
		force_co_exists=0
	endif
	if(waveexists(defl_re_co)==1||waveexists(defl_tr_co)==1)
		defl_co_exists=1
	else
		defl_co_exists=0
	endif
	if(waveexists(defor_tr)==1||waveexists(defor_re)==1)
		defor_exists=1
	else
		defor_exists=0
	endif
	if(waveexists(defl_towd)==1)
		towd_exists=1
	else
		towd_exists=0
	endif
//Create a return string, handed back to the calling function, with name of the type and the corresponding variable.
	string returnstr="DeflV:"+num2str(defl_exists)+";Force:"+num2str(force_exists)+";ZSnsr:"+num2str(zsnsr_exists)+";Raw:"+num2str(raw_exists)
	returnstr+=";ForceCo:"+num2str(force_co_exists)+";DeflVCo:"+num2str(defl_co_exists)+";Defor:"+num2str(defor_exists)+";Towd:"+Num2str(towd_exists)+";"
	return returnstr
end

//Simple function collecting the last point (maximum) of the deformation waves and saves it in an overview wave.
function readoutmaxdeformatin_folder(folderstring,listofbasename)
	string folderstring
	string listofbasename
	setdatafolder $folderstring
	wave/T listofbasenames=$listofbasename
	make/o/N=(numpnts(listofbasenames)) maxdeformation
	wave maxdefor=$"maxdeformation"
	variable i
	for(i=0;i<numpnts(listofbasenames);i+=1)
		wave defor=$listofbasenames[i]+"defor_ext"
		maxdefor[i]=defor[numpnts(defor)-1]	
	endfor
end
//Same as above but for a single curve, not the whole folder.
function readoutmaxdeformatin_single(listofbasename,number)
	string listofbasename
	variable number
	wave/T listofbasenames=$listofbasename
	if(waveexists($"maxdeformation")==0)
		make/o/N=(numpnts(listofbasenames)) maxdeformation
	endif
	wave maxdefor=$"maxdeformation"
	wave defor=$listofbasenames[number]+"defor_ext"
	maxdefor[number]=defor[numpnts(defor)-1]	
end
//Same as above but for force-waves.
function readoutmaxforce_folder(folderstring,listofbasename)
	string folderstring
	string listofbasename
	setdatafolder $folderstring
	wave/T listofbasenames=$listofbasename
	make/o/N=(numpnts(listofbasenames)) maxforce
	wave maxdefor=$"maxforce"
	variable i
	for(i=0;i<numpnts(listofbasenames);i+=1)
		wave defor=$listofbasenames[i]+"force_ext_co"
		maxdefor[i]=defor[numpnts(defor)-1]	
	endfor
end

//Calcs the integral of trace force vs deformation in contact == Energy in contact.
function totalenergyofcontact(folderstring,listofbasename)
//Input foldername and list of basenames.
	string folderstring, listofbasename
	setdatafolder $folderstring
	wave/T listofbasenames=$listofbasename
//Create the wave containing the total energy while approaching.
	make/O/N=(numpnts(listofbasenames)) totalenergyapproach
	wave totalenergyapproach
	variable i
//Go through all force curves in the folder.
	for(i=0;i<numpnts(listofbasenames);i+=1)
		string forcecurve=listofbasenames[i]
	//Check the folder content and if Deformation and Force waves are present.
		string content=checkfoldercontent(forcecurve)
		if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
			string y_name
			string forcecurvecut=forcecurve
			if(numberbykey("ForceCo",content,":",";")==1)
				if(strlen(forcecurve)>19)
					forcecurvecut=forcecurve[3,strlen(forcecurve)]
				endif
				y_name=Forcecurvecut+"Force_Ext_co"
			else
				y_name=forcecurve+"Force_Ext"
			endif
		//Name and load the force, deformation and contact-point result waves.
			string contactstr=Forcecurve+"cont_tr"
			wave y_axis=$y_name, defor_tr=$forcecurvecut+"Defor_ext"
			wave contact=$contactstr
		//Duplicate the contact part (CP-End) of force and deformation to be able to integrate them.
			duplicate/O/R=[contact[1],numpnts(y_axis)] y_axis, $Forcecurvecut+"IntegralF",$Forcecurvecut+"Integral"
			duplicate/O/R=[contact[1],numpnts(y_axis)] defor_tr, $Forcecurvecut+"IntegralD"
			wave integral=$forcecurvecut+"integral"
			wave integralF=$forcecurvecut+"integralF"
			wave integralD=$Forcecurvecut+"IntegralD"
		//Make the actuall integral
			integrate/T integralF /X=integralD /D=integral
		//Save the last point value of the integral (integral over the whole contact).
			totalenergyapproach[i]=integral[numpnts(integral)-1]
		//Delete the integral waves so not to mess up the folder.
			killwaves integral, integralF, integralD
		endif
	endfor
end

//Determines the maximal contact area while approaching based on the "real" maximum not from the last point in the deformation.
function maxcontactarea_adhesion_single(folderstring,forcecurve,proberadius,numforcecurve)
	string folderstring, forcecurve
	variable  proberadius, numforcecurve
	setdatafolder $folderstring
	wave/T listofbasenames//=$listofbasenames
	wave defor_tr=$forcecurve+"Defor_ext"
	string contact_area
//Two different "save names": In case of forcemaps call it "contactArea", in case of single curves make an appendix to the basename.
	if(stringmatch(forcecurve[0,3],"line")==1&&stringmatch(forcecurve[8,12],"point")==1)
		contact_area="ContactArea"
	else
		contact_area=forcecurve[0,strlen(forcecurve)-5]+"ContactArea"
	endif	
//Create the result wave.
	if(waveexists($contact_area)==0)
		make/N=(numpnts(listofbasenames)) $contact_area
	endif
	wave area_contact=$contact_area
//Wavestats to find the maximum in the deformation wave.
	wavestats/Q defor_tr
//Contact radidus
	area_contact[numforcecurve]=Pi*sqrt((proberadius*1e-6)^2-(proberadius*1e-6-V_max)^2)
//old code.171114 cant recall the equation	area_contact[numforcecurve]=2*pi*V_max*proberadius*1e-6
end
//Same as above but for the whole folder.
function maxcontactarea_adhesion_folder(proberadius)
	variable proberadius
	wave/T listofbasenames//=$listofbasenames
	string forcecurve=listofbasenames[0]
	string contact_area
	if(stringmatch(forcecurve[0,3],"line")==1&&stringmatch(forcecurve[8,12],"point")==1)
		contact_area="ContactArea"
	else
		contact_area=forcecurve[0,strlen(forcecurve)-5]+"ContactArea"
	endif	
	if(waveexists($contact_area)==0)
		make/N=(numpnts(listofbasenames)) $contact_area
	endif
	wave area_contact=$contact_area
	variable i
	for(i=0;i<numpnts(listofbasenames);i+=1)
		wave defor_tr=$listofbasenames[i]+"Defor_ext"
		wavestats/Q defor_tr
		area_contact[i]=Pi*sqrt((proberadius*1e-6)^2-(proberadius*1e-6-V_max)^2)
		//Old code 171114.  area_contact[i]=2*pi*V_max*proberadius*1e-6
	endfor
end

//Same as totalenergyofcontact but for single curves. Check the other function for details.
function totalenergyofconactalone(forcecurve)
	string forcecurve
	variable totalenergyapproach
	
	string content=checkfoldercontent(forcecurve)
	if(NumberByKey("Defor",content,":",";")==1&&numberbykey("Force",content,":",";")==1||numberbykey("ForceCo",content,":",";")==1)
		string y_name
		string forcecurvecut=forcecurve
		if(numberbykey("ForceCo",content,":",";")==1)
			if(strlen(forcecurve)>19)
				forcecurvecut=forcecurve[3,strlen(forcecurve)]
			endif
			y_name=Forcecurvecut+"Force_Ext_co"
		else
			y_name=forcecurve+"Force_Ext"
		endif
		string contactstr=Forcecurve+"cont_tr"
		wave y_axis=$y_name, defor_tr=$forcecurvecut+"Defor_ext"
		wave contact=$contactstr
		duplicate/O/R=[contact[1],numpnts(y_axis)] y_axis, $Forcecurvecut+"IntegralF",$Forcecurvecut+"Integral"
		duplicate/O/R=[contact[1],numpnts(y_axis)] defor_tr, $Forcecurvecut+"IntegralD"
		wave integral=$forcecurvecut+"integral"
		wave integralF=$forcecurvecut+"integralF"
		wave integralD=$Forcecurvecut+"IntegralD"
		integrate/T integralF /X=integralD /D=integral
		totalenergyapproach=integral[numpnts(integral)-1]
		killwaves integral, integralF, integralD
	endif
	return totalenergyapproach	
end

//Short-cut function for taskbar: just call the cutofcurves function with a fix value stated in line 15.
function cutofcurvesmenu(retracelengthcut)
	variable retracelengthcut
	SVAR forcecurve=root:panelcontrol:singlefcpanel:namemap_g
	cutofcurves(forcecurve,retracelengthcut)
end

//This function deletes certain part of the force curve; since sometimes the curves are messy one can delete them.
function cutofcurves(forcecurve,retracelengthcut)
//Load input force curve name and the length in nm which should be cut off.
	string forcecurve
	variable retracelengthcut
//Check if trace or retrace should be treated.
	NVAR retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
//If necessary reduce the basename length.
	if(strlen(forcecurve)>19)
		string forcecurvecut=forcecurve[3,strlen(forcecurve)]
	else
		forcecurvecut=forcecurve
	endif
//Include the rudimental force curve components deflection volt and displacement (here only zsnsr not raw allowed) (may change in future)
	wave defl_tr=$forcecurvecut+"DeflV_ext", defl_re=$forcecurvecut+"DeflV_ret", zsnsr_tr=$forcecurvecut+"Zsnsr_Ext", zsnsr_re=$forcecurvecut+"Zsnsr_ret"//, force_tr=$forcecurvecut+"Force_ext", force_re=$forcecurvecut+"Force_ret"
	variable i=1, cursortouse
	do
	//Check if only one cursor is on the graph (1/0) or both or none (2) is there.
		if(strlen(csrinfo(a,"Mechanicspanel#mechdisplay"))!=0)
			if(strlen(csrinfo(b,"Mechanicspanel#mechdisplay"))!=0)
				cursortouse=2
				break	//Break only ends this do-loop not the function.
			else
				cursortouse=0
				variable acsr=pcsr(a,"mechanicspanel#mechdisplay")
			endif
		else
			if(strlen(csrinfo(b,"Mechanicspanel#mechdisplay"))!=0)
				cursortouse=1
				variable bcsr=pcsr(b,"mechanicspanel#mechdisplay")
			else
				cursortouse=2
				break //Break only ends this do-loop not the function.
			endif
		endif
	while(i<0)
// ==0 -> cursor A is on the graph
	if(cursortouse==0)
		if(retraceonly_g!=1)
		//Delete all points from max. piezo contraction till cursor position.
			deletepoints 0, acsr,  defl_tr, Zsnsr_tr
		//Check for potential force and deformation waves and cut them too.
			if(waveexists($forcecurvecut+"Force_ext_co")==1)
				deletepoints acsr, numpnts($forcecurvecut+"Force_ext_co"), $forcecurvecut+"Force_ext_co"
			endif
			if(waveexists($forcecurvecut+"Force_ext")==1)
				deletepoints acsr, numpnts($forcecurvecut+"Force_ext"), $forcecurvecut+"Force_ext"
			endif
			if(waveexists($forcecurvecut+"Defor_ext")==1)
				deletepoints acsr, numpnts($forcecurvecut+"defor_ext"), $forcecurvecut+"Defor_ext"
			endif
	//The same for the retrace if "only retrace" is selected.
		else
		//Note that retrace is point-wise order from max piezo extension -> max contraction.
			deletepoints acsr, numpnts(defl_re), defl_re, zsnsr_re
			if(waveexists($forcecurvecut+"Force_ret_co")==1)
				deletepoints acsr, numpnts($forcecurvecut+"Force_ret_co"), $forcecurvecut+"Force_ret_co"
			endif
			if(waveexists($forcecurvecut+"Force_ret")==1)
				deletepoints acsr, numpnts($forcecurvecut+"Force_ret"), $forcecurvecut+"Force_ret"
			endif
			if(waveexists($forcecurvecut+"Defor_ret")==1)
				deletepoints acsr, numpnts($forcecurvecut+"defor_ret"), $forcecurvecut+"Defor_ret"
			endif
		endif
// ==1 -> B cursor is used; otherwise same as above
	elseif(cursortouse==1)
		if(retraceonly_g!=1)
			deletepoints 0, bcsr, defl_tr, Zsnsr_tr
			if(waveexists($forcecurvecut+"Force_ext_co")==1)
				deletepoints acsr, numpnts($forcecurvecut+"Force_ext_co"), $forcecurvecut+"Force_ext_co"
			endif
			if(waveexists($forcecurvecut+"Force_ext")==1)
				deletepoints acsr, numpnts($forcecurvecut+"Force_ext"), $forcecurvecut+"Force_ext"
			endif
			if(waveexists($forcecurvecut+"Defor_ext")==1)
				deletepoints acsr, numpnts($forcecurvecut+"defor_ext"), $forcecurvecut+"Defor_ext"
			endif
		else
			deletepoints bcsr, numpnts(defl_re), defl_re, zsnsr_re
			if(waveexists($forcecurvecut+"Force_ret_co")==1)
				deletepoints bcsr, numpnts($forcecurvecut+"Force_ret_co"), $forcecurvecut+"Force_ret_co"
			endif
			if(waveexists($forcecurvecut+"Force_ret")==1)
				deletepoints bcsr, numpnts($forcecurvecut+"Force_ret"), $forcecurvecut+"Force_ret"
			endif
			if(waveexists($forcecurvecut+"Defor_ret")==1)
				deletepoints bcsr, numpnts($forcecurvecut+"defor_ret"), $forcecurvecut+"Defor_ret"
			endif
		endif
// ==2 -> no or both cursors are on the graph -> take the distance value given to the function.
	elseif(cursortouse==2)
	//Right now only for retrace: find the point corresponding to the distance and delete the points.
		if(retraceonly_g==1)
			variable retrace_min=zsnsr_re[numpnts(zsnsr_re)-1]
			findvalue/T=5e-9/V=(retrace_min+retracelengthcut*1e-9) zsnsr_re
			deletepoints V_value, numpnts(defl_re), defl_re, zsnsr_re
			if(waveexists($forcecurvecut+"force_ret_co")==1)
				deletepoints v_value, numpnts($forcecurvecut+"force_ret_co"), $forcecurvecut+"force_ret_co"
			endif
			if(waveexists($forcecurvecut+"Force_ret")==1)
				deletepoints v_value, numpnts($forcecurvecut+"force_ret"), $forcecurvecut+"force_ret"
			endif
			if(waveexists($forcecurvecut+"Defor_ret")==1)
				deletepoints v_value, numpnts($forcecurvecut+"defor_ret"), $forcecurvecut+"Defor_ret"
			endif
		endif	
	endif
end
//Sometimes there are dwell parts in force-maps or delay while moveing to the next position is also recorded. 
//This function deletes that by cutting away a section at the end of the retrace (where the moveing is typically recorded)
function deletedewellinfmaps(retracelengthcut)
	variable retracelengthcut
	NVAr retraceonly_g=root:panelcontrol:singlefcpanel:retraceonly_g
	retraceonly_g=1
	wave/T listofbasenames
	variable i
	for(i=0;i<numpnts(listofbasenames);i+=1)
		cutofcurves(listofbasenames[i],retracelengthcut)
	endfor
end
//In case the cutting of force curves were performed "wrong" and it ends up with a length missmatch of force to deformation deformation is cut accordingly.
//Note: this function is only call by EModulbyJKR and doesnt do anything if both have the same length as they should.
function deletetolongdefor(defor_ret,force_ret)
	wave defor_ret, force_ret
	if(numpnts(defor_ret)>numpnts(force_ret))
		deletepoints numpnts(force_ret), numpnts(defor_ret), defor_ret
	endif
end

//Opens a panel handling the manual saving of value corresponding to A&B cursors on the graph.
//This is usefull when first time checking force curve for some feature without writing a own procedure.
function cursorinfoPanel(ctrlname) :buttoncontrol
	string ctrlname
	setdatafolder root:
	setdatafolder root:panelcontrol
	if(datafolderexists("CursorPanel")==0)
		newdatafolder CursorPanel
		setdatafolder root:panelcontrol:cursorpanel:
		string/g xValuewavename_g, yvaluewavename_g, nameoftraces_g, dxvaluewavename_g, dyvaluewavename_g
		variable/G threshold_g
	endif
	setdatafolder root:PanelControl:cursorpanel
	DoWindow/F MechanicsPanel
	NewPanel/K=1/Ext=0/W=(0,245,300,150) /N=Extractcursorinfo /host=mechanicspanel as "Store Cursor Values"
	DoWindow/F Extractcursorinfo
	SetDrawEnv linefgc=(65280,0,0), linethick=3.00, fillpat=0
	DrawRect 5,5,295,240
	SetDrawEnv fstyle=1, Fsize=15
	Drawtext 87,30, "Saveing Parameters"
//The upcoming "setvariables" will hold the names of the waves the corresponding values for the cursors will be saved.
//Note all need to be filled to avoid errors. (i think)
	Setvariable xValuewavename_g, pos={15,45}, size={270,270}, value=root:panelcontrol:cursorpanel:xValuewaveName_g, Title="Name of Wave to store X"
	Setvariable dxValuewavename_g, pos={15,70}, size={270,270}, value=root:panelcontrol:cursorpanel:dxValuewaveName_g, Title="Name of Wave to store dX"
	Setvariable yValuewavename_g, pos={15,95}, size={270,270}, value=root:panelcontrol:cursorpanel:yValuewaveName_g, Title="Name of Wave to store Y"
	Setvariable dyValuewavename_g, pos={15,120}, size={270,270}, value=root:panelcontrol:cursorpanel:dyValuewaveName_g, Title="Name of Wave to store dY"
	setvariable nameoftraces_g, pos={15,145}, size={270,270}, value=root:panelcontrol:cursorpanel:nameoftraces_g, Title="Textwave of Tracenames"
	popupmenu cursoron_trace, pos={50,170}, size={154,154},  value="A;B;Both", title="Which Cursor to Use"
//the do it button just starts the read out of the cursor-infos.
	button doit, pos={90,205}, size={50,20}, title="Do It", proc=cursorinfotowave
end

//This function serves just as short-cut function for the taskbar menu (since this is not possible with buttoncontrol functions)
function cursorinfotowave2()
	cursorinfotowave("test")
	NVAR numforcecurve=root:panelcontrol:singlefcpanel:numforcecurve_g, limitsdisplay=root:panelcontrol:singlefcpanel:limitsdisplay_g
//If wanted the commented parts can be decommented than automatically the next graph is display when the current is read out.
//	if(numforcecurve<limitsdisplay)
	//	numforcecurve+=1
//	endif
//	variable forcecurvenumber=numforcecurve
//	updatedisplayAL(foldername,forcecurvenumber)
end

//Function to read-out the cursors X,Y and delta X/Y values and save them.
function CursorInfotoWave(ctrlname)	:ButtonControl
	string ctrlname
//Load Input Strings of how the save-waves should be named.
	NVAR  wholefolder_g=root:panelcontrol:SingleFCpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	svar folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	svar xValuewavename_g=root:panelcontrol:CursorPanel:xValuewaveName_g, yValuewavename_g=root:panelcontrol:cursorPanel:yValueWaveName_g
	svar dxValuewavename_g=root:panelcontrol:CursorPanel:dxValuewaveName_g, dyValuewavename_g=root:panelcontrol:cursorPanel:dyValueWaveName_g
	svar NameOfTraces_g=root:panelcontrol:cursorPanel:NameOfTraces_g
	string cursorname
//Set the cursor panel active to read out which cursors should be read.
	setactivesubwindow MechanicsPanel#Extractcursorinfo
	controlinfo cursoron_trace
	variable cursortouse=V_value
	setdatafolder $folderstring_g
//Set the graph in the GUI as active graph.
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay	
	variable avoid_wave_read_errors1, avoid_wave_read_errors2
//In case the save waves for x/y and the list holding the respective force-curve basenames is not existing and a name is set create them with 1 point.	
	if(waveexists($xValueWaveName_g)==0&&strlen(xValueWaveName_g)!=0)
		make/N=1 $xValueWaveName_g
		avoid_wave_read_errors1+=1
		avoid_wave_read_errors2+=1
	endif
	if(waveexists($yValueWaveName_g)==0&&strlen(yValueWaveName_g)!=0)
		make/n=1 $yValueWaveName_g
		avoid_wave_read_errors1+=1
		avoid_wave_read_errors2+=1
	endif
	if(waveexists($nameofTraces_g)==0&&strlen(nameoftraces_g)!=0)
		make/n=1/T $nameOfTraces_g
		avoid_wave_read_errors1+=1
		avoid_wave_read_errors2+=1
	endif
//Based on the value read out from cursoron_trace the value is translated to string of "A"/"B"
	if(CursorToUse==1)
		cursorname="a"
	elseif(cursorToUse==2)
		cursorname="b"
	elseif(cursortouse==3)
		cursorname="a"
	endif
//The above created waves are introduce to the function.
	wave/T TraceName=$nameoftraces_g
	wave xValue=$xValuewaveName_g, yValue=$yValueWaveName_g
//First part of the csrinfo return is saved as string (see csrinfo-help)
	string strtracename=stringfromlist(0,csrinfo($cursorname))
//The string is reduced to only hold the complete name of the trace where the cursor is on.(incl endings like DelfV_ext)
	strtracename=strtracename[6,strlen(strtracename)-1]
// !=3 == 2 or 1 == A or B == not both. error==3 means all waves are created (since a name input was there)
	if(cursortouse!=3&&avoid_wave_read_errors1==3)
	//Check if it is the first value to save (since waves are create with 1 point)
	//Anyways save the x&y value + the read-out trace name.
		if(numpnts(xValue)==1&&xValue[0]==0)
			xValue[0]=hcsr($cursorname,"mechanicspanel#mechdisplay")
			yValue[0]=vcsr($cursorname,"mechanicspanel#mechdisplay")
			TraceName[0]=strtracename
		else
		//In case it is the second and on-going point add a new point to the waves.
			insertpoints numpnts(xValue),1, xValue,yvalue, tracename
			xValue[numpnts(XValue)-1]=hcsr($cursorname,"mechanicspanel#mechdisplay")
			yValue[numpnts(yValue)-1]=vcsr($cursorname,"mechanicspanel#mechdisplay")
			tracename[numpnts(tracename)-1]=strtracename
		endif
//So A&B was selected meaning also the delta X and Y waves should be created.
	else
	//Check if delta waves are already there and there name is specified.
		if(waveexists($dxValueWaveName_g)==0&&strlen(dxValueWaveName_g)!=0)
			make/N=1 $dxValueWaveName_g
			avoid_wave_read_errors2+=1
		endif
		if(waveexists($DyValueWaveName_g)==0&&strlen(dyValueWaveName_g)!=0)
			make/N=1 $dyValueWaveName_g
			avoid_wave_read_errors2+=1
		endif
		if(waveexists($nameoftraces_g+"D")==0&&strlen(nameoftraces_g)!=0)
			make/N=1/T $nameoftraces_g+"D"
			avoid_wave_read_errors2+=1
		endif
		
		wave dxValueWave=$dxValueWaveName_g
		wave dyValueWave=$dyValueWaveName_g
		wave/T tracenameD=$nameoftraces_g+"D"
	//Check if it is the first point in deltas or not and if the waves are created properly.
		if(numpnts(dxValueWave)==1&&dxValueWave[0]==0&&avoid_wave_read_errors2==5)
		//Save the delta values and the corresponding name of the trace they are read from.
			dxValueWave[0]=hcsr(a,"mechanicspanel#mechdisplay")-hcsr(b,"mechanicspanel#mechdisplay")
			dyValueWave[0]=vcsr(a,"mechanicspanel#mechdisplay")-vcsr(b,"mechanicspanel#mechdisplay")
			tracenamed[0]=strtracename
	//Do the same 2nd and ongoing times.
		elseif(avoid_wave_read_errors2==5)
			insertpoints numpnts(dxValueWave),1,dxValueWave,dyValueWave,Tracenamed
			dxValueWave[numpnts(dxValueWave)-1]=hcsr(a,"mechanicspanel#mechdisplay")-hcsr(b,"mechanicspanel#mechdisplay")
			dyValueWave[numpnts(dyValueWave)-1]=vcsr(a,"mechanicspanel#mechdisplay")-vcsr(b,"mechanicspanel#mechdisplay")
			tracenamed[numpnts(tracenamed)-1]=strtracename
		endif	
	//Like for single cursors save the x&y values for the cursors; Also 1. A then B.
		if(numpnts(xValue)==1&&xValue[0]==0&&avoid_wave_read_errors1==3)
			insertpoints 0,1, xValue,yvalue,tracename	//one more point needs to be added since 2 values are saved per step.
			xValue[0]=hcsr(a,"mechanicspanel#mechdisplay")
			yValue[0]=vcsr(a,"mechanicspanel#mechdisplay")
			xValue[1]=hcsr(b,"mechanicspanel#mechdisplay")
			yValue[1]=vcsr(b,"mechanicspanel#mechdisplay")
			TraceName[0]=strtracename
			TraceName[1]=strtracename
		elseif(avoid_wave_read_errors1==3)
			insertpoints numpnts(xValue),2, xValue,yvalue, tracename
			xValue[numpnts(XValue)-1]=hcsr(b,"mechanicspanel#mechdisplay")
			yValue[numpnts(yValue)-1]=vcsr(b,"mechanicspanel#mechdisplay")
			xValue[numpnts(XValue)-2]=hcsr(a,"mechanicspanel#mechdisplay")
			yValue[numpnts(yValue)-2]=vcsr(a,"mechanicspanel#mechdisplay")
			tracename[numpnts(tracename)-1]=strtracename
			tracename[numpnts(tracename)-2]=strtracename
		endif
	endif
end

//Collects the adhesion force infos from all force-curves in the folder. Pre-function before foler_info2list was writen.
function collectadhesiondata(listoffoldercontent)
	wave/T listoffoldercontent
	make/O/N=(numpnts(listoffoldercontent)) Adhesion
	wave adhesion=Adhesion
	variable i=0
	for(i=0;i<numpnts(listoffoldercontent);i+=1)
		wave adhesionwave=$listoffoldercontent[i]+"Adhf"
		adhesion[i]=adhesionwave[0]
	endfor
end

//Function to kill all force-deformation log-log plots. Can become messy if fitting the whole folder and having tons of log-log graph open.
function killalllogs()
	do
	//make a list of all graph windows there are.
		string openwindows=winlist("*",";","win:1")
	//In case the graph name contains "log_" it's pretty sure that it belongs to the contactexponent function.
		if(stringmatch(openwindows,"*log_*")==1)
			string graph=stringbykey("*log_*",openwindows,";")
		//kill (close) that graph
			killwindow $graph
		endif
	//update the open window list and redo it over in case there are still graph containing log in their name.
		openwindows=winlist("*",";","win:1")
	while(stringmatch(openwindows,"*log_*")==1)
end

//Function to kick off force-curve evaluation. It calls all the funciton necessary to collect the list of basename wave.
function Grabdata(ctrlname) : Buttoncontrol
	string ctrlname
//Load all global strings and variables and set them to 0 == fresh start (since this function is called when starting in a new folder for the first time)
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR limitsdisplay_g=root:panelcontrol:singlefcpanel:limitsdisplay_g, showdeflcor_g=root:panelcontrol:singlefcpanel:showdeflcor_g, showfit_g=root:panelcontrol:singlefcpanel:showfit_g
	NVAR showdefor_g=root:panelcontrol:singlefcpanel:showdefor_g, showforce_g=root:panelcontroL:singlefcpanel:showforce_g, showlog_g=root:panelcontrol:singlefcpanel:showlog_g
	NVAR showsepa_g=root:panelcontrol:singlefcpanel:showsepa_g, highlight_adh_g=root:panelcontrol:singlefcpanel:highlight_adh_g, showdwell_g=root:panelcontrol:singlefcpanel:showdwell_g
	showdeflcor_g=0; showfit_g=0; showdefor_g=0; showforce_g=0; showlog_g=0; showsepa_g=0; highlight_adh_g=0; showdwell_g=0
	setdatafolder $folderstring_g
	wave/T listofbasenames
//In case there is already a wave called "listofbasename" this function is called on "error" and in only updates the backup of listofbasenames in the panelfolder.
	if(waveexists(listofbasenames)==1)
		duplicate/O listofbasenames, root:panelcontrol:singlefcpanel:listofbasenames_g
		limitsdisplay_g=numpnts(listofbasenames)
	else
	//In case the folder is really new go through the 3 functions setting up the list of basename wave.
		GrabFolderContent()
		CleanForBasename()
		CreateListOfBasenames()
		DoWindow/F MechanicsPanel
	//Adjust the maximum number allow in the graph-scroll variable to the length of listofbasenames.
		SetVariable numforcecurve_g limits={0,limitsdisplay_g,1}
	endif
//Update the displayed graph.
	updateforcecurve1()
end

//This is the button controlled function which starts the spliting of adhesion ramps (see later).
Function AdhesionRampButtonAlone(ctrlname):Buttoncontrol
	string ctrlname
	adhesion_ramp_evaluation()
end
Function AdhesionButtonAlone2scroll(sva) :setvariablecontrol
	STRUCT WMSetvariableaction &sva
	SVAR foldername=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR forcecurvenumber=root:panelcontrol:singlefcpanel:numforcecurve_g
	string test=""
	adhesionbuttonalone(test)
	updatedisplayAL(foldername,forcecurvenumber)
end

//Function started by the "Calc Adhesion" button in the Adhesion panel.
//Does the "most advanced" adhesion evaluation in here.
function AdhesionbuttonAlone(ctrlname) :Buttoncontrol
	string ctrlname
//Load input variables&strings.
	NVAR baselinePercent=root:panelcontrol:SingleFCpanel:baselinepercentadh_g, wholefolder_g=root:panelcontrol:SingleFCpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR contacttolerance_G=root:panelcontrol:singlefcPanel:contacttoleranceadh_g, sphereradius_g=root:panelcontrol:singlefcpanel:sphereradiusadh_g, sampleradius_g=root:panelcontrol:singlefcpanel:sampleradiusadh_g
	NVAR onlyadhforce=root:panelcontrol:singlefcpanel:onlyadhforce_g, check_woa_points_g=root:panelcontrol:singlefcpanel:check_woa_points_g
	SVAR Folderstring_g=Root:panelcontrol:SingleFCPanel:folderstring_g
//Read the drop-down menu if the jump-to contact point should be used or not.
	controlinfo DeforCalcChoice
	variable jumpto=V_value
	variable jumpout=V_Value
	variable proberadius
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_g
	variable mechmodel, geometry
	string basename=listofbasename[0]
	string contact_area_str
//The basename of the first curve is determined without the number suffix.
	basename=basename[0,strlen(basename)-5]
//Read out if the JKR or DMT model should be used.	
	controlinfo/W=mechanicspanel#fitpanelAdhesion FitModelChoice
	mechmodel=V_value
//Set the names of how the resulting wave should be named.
	string adhesion_folder="adhesion_list"
	String work_folder="workofadhesion_list"
	string work_norm_folder="workADH_perArea_list"
//in case non existing create all the result waves.
	if(waveexists($adhesion_folder)==0)
		make/O/N=(numpnts(listofbasename)) $adhesion_folder, $work_folder, totalenergyapproach, $work_norm_folder
		if(mechmodel==1)
			make/N=(numpnts(listofbasename)) $"workofadhesion_JKR"
		else
			make/N=(numpnts(listofbasename)) $"workofadhesion_DMT"
		endif
	endif
	wave adhesion=$adhesion_folder, work=$work_folder, totalenergyapproach, work_norm=$work_norm_folder
//In case the contact-area wave already exists include it.
	if(Waveexists($basename+"contactArea")==1||waveexists($"ContactArea")==1)
	//Different nameing for force-maps and single force-curves.
		if(stringmatch(basename[0,3],"line")==1&&stringmatch(basename[8,12],"point")==1)
			contact_area_str="ContactArea"
		else
			contact_area_str=basename[0,strlen(basename)-5]+"ContactArea"
		endif	
		wave contact_area=$contact_area_str
	endif
	if(mechmodel==1)
		wave workmodel=$"workofadhesion_JKR"
	else
		wave workmodel=$"Workofadhesion_DMT"
	endif
//Read out the contact geometry and calc the effectiv radius.
	controlinfo/W=mechanicspanel#fitpaneladhesion FitFunctionGeometery
	geometry=V_value	
	if(sampleradius_g!=0&&geometry==2)
		proberadius=(1/sampleradius_g+1/sphereradius_g)^-1
	else
		proberadius=sphereradius_g
	endif
	setdatafolder $Folderstring_g
//Decide if the whole folder should be treated or only a single curve.
	if(wholefolder_g==1)
		variable i
	//Go through all curves in the folder.
		for(numforcecurve_g=0;numforcecurve_g<numpnts(listofbasename);numforcecurve_g+=1)
			i=numforcecurve_g
		//Update the graph (also can be commentized since one basically cant see anything).
			updateforcecurve1()
			doupdate
		//Determine the force of adhesion like done when hitting the corr. deflection button.
			AdhesionAlone(listofbasename[i],1,baselinepercent)
		//If chosen in the adhesion panel to only calc adhesion forces dont do the following.
			if(onlyadhforce==0)
			//Determine the maximum conatct area for the current curve and the maximum deformation.
				maxcontactarea_adhesion_single(folderstring_g,listofbasename[i],proberadius,i)
				readoutmaxdeformatin_single("listofbasenames",i)
				if(stringmatch(basename[0,3],"line")==1&&stringmatch(basename[8,12],"point")==1)
					contact_area_str="ContactArea"
				else
					contact_area_str=basename[0,strlen(basename)-5]+"ContactArea"
				endif
			//In case no contact area curve exists create one.
				If(waveexists($contact_area_str)==0)
					make/N=(numpnts(listofbasename)) $contact_area_str
				endif	
				wave contact_area=$contact_area_str
			//Determine the work of adhesion.
				WorkofAdhesionAlone(listofbasename[i],baselinepercent,contacttolerance_g,proberadius,mechmodel)
			//Include here the results from the workofadhesionalone function and transfer their results for single curve to the overview wave.
				wave adh_content=$listofbasename[i]+"AdhFJKR"
				adhesion[i]=adh_content[0]	//Adhesion force
				wave woa_content=$listofbasename[i]+"WoAdhF"
				work[i]=woa_content[0] //"Work of adhesion" as the result from integrateing the area under the force-curve
				work_norm[i]=woa_content[0]/contact_area[i]	//"normalize" the work-of-adhesion (integral) by the calced max contact area. J/m^2
				workmodel[i]=woa_content[1]	//Work-of-adhesion calced based on the model and the force of adhesion (no fitting)
				totalenergyapproach[i]=totalenergyofconactalone(listofbasename[i]) //calc integral of force deformation for trace in contact.
			endif
		endfor
	else
	//Same as above but for single curves.
		AdhesionAlone(listofbasename[numforcecurve_g],1,baselinepercent)
		if(onlyadhforce==0)
			maxcontactarea_adhesion_single(folderstring_g,listofbasename[numforcecurve_g],proberadius,numforcecurve_g)
			readoutmaxdeformatin_single("listofbasenames",numforcecurve_g)
			if(stringmatch(basename[0,3],"line")==1&&stringmatch(basename[8,12],"point")==1)
				contact_area_str="ContactArea"
			else
				contact_area_str=basename[0,strlen(basename)-5]+"ContactArea"
			endif
			If(waveexists($contact_area_str)==0)
				make/N=(numpnts(listofbasename)) $contact_area_str
			endif	
			wave contact_area=$contact_area_str
			WorkofAdhesionAlone(listofbasename[numforcecurve_g],baselinepercent,contacttolerance_g,proberadius,mechmodel)
			wave adh_content=$listofbasename[numforcecurve_g]+"AdhFJKR"
			adhesion[numforcecurve_g]=adh_content[0]
			wave woa_content=$listofbasename[numforcecurve_g]+"WoAdhF"
			work[numforcecurve_g]=woa_content[0]
			work_norm[numforcecurve_g]=woa_content[0]/contact_area[numforcecurve_g]
			workmodel[numforcecurve_g]=woa_content[1]
			totalenergyapproach[numforcecurve_g]=totalenergyofconactalone(listofbasename[numforcecurve_g])
		endif
	endif
//Update the GUI-graph.
	updatedisplayAL(folderstring_g,numforcecurve_g)
end

//Function to split up the overview adhesion waves when they were measured in a ramp fashion, with different dwell-times and load-forces.
function adhesion_ramp_evaluation()
	do	//Just do be able to make a break within the function.
//Load input variables&strings.	
	SVAR folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	NVAR E_modul_adhesion=root:panelcontrol:singlefcpanel:E_modul_adhesion_g
	setdatafolder $folderstring_G
//Check the panel-menu which kind of adhesion model was used.
	controlinfo/W=mechanicspanel#fitpanelAdhesion FitModelChoice
	variable	mechmodeladh=V_value
	controlinfo/W=mechanicspanel#fitpanelEmod fitfunctionchoiceal
	variable	mechmodelE=V_value
//Define the foldername where the new data should be stored, based on the model.
	string newfoldername
	if(mechmodelE==6)
		newfoldername="adhesion_data_MD"
		if(datafolderexists("adhesion_data_MD")==0)
			newdatafolder $newfoldername
		endif
	elseif(mechmodeladh==1)
		newfoldername="adhesion_data_JKR"
		if(datafolderexists("adhesion_data_JKR")==0)
			newdatafolder $newfoldername
		endif
	elseif(mechmodeladh==2)
		newfoldername="adhesion_data_DMT"
		if(datafolderexists("adhesion_data_DMT")==0)
			newdatafolder $newfoldername
		endif
	endif
//The ramp settings are asked from the user in a prompt window.
	variable ramp_length, looper=1, number_forces, repetitions=1
	prompt ramp_length, "Number of Measurements per ramp?"
	Prompt number_forces, "Number of different Forces?"
	Prompt repetitions, "How many continuous force curves?"
	doprompt "Ramp Length Input", ramp_length, number_forces, repetitions
//In case the user cancels the prompt V_Flag=1 and everything is aborted.
	if(V_Flag==1)
		break		
	endif
//The used dwell times are extracted directly from the force-curve header and saved in a overview wave
	extract_dwell_time(newfoldername)
//Based on the prompt-input the adhesion overview waves are split in single waves of constant dwell and constant force.
	split_adhesion_ramps(ramp_length,number_forces,repetitions,newfoldername)
	while(looper<-1)
end

//Function serving the adhesion_ramp_evaluation function. In creates two waves holding the force-curves dwell-time and maximum load force, respectively.
function extract_dwell_time(newfoldername)
//The new foldername and the listofbasenames are loaded in the function.
	string newfoldername
	wave/T listofbasenames
//In case there are no overview dwell or maximum_load_force waves create them.
	if(waveexists($"dwell_times")==0)
		make/N=(numpnts(listofbasenames)) dwell_times, max_load_force
	endif
	wave dwell_times, max_load_force
	variable i
//Go through all force curves of the folder.
	for(i=0;i<numpnts(listofbasenames);i+=1)
	//Load the Deflection volt raw curve, since its header (only for AR files) holds also the dwell infromation.
		string currentwave=listofbasenames[i]+"DeflV_ext"
	//The header of the deflection wave is extracted to a string.
		string header=note($currentwave)
	//The dwell-time for the force-curve is extracted by the numberbykey command from the header-string.
		dwell_times[i]=numberbykey("DwellTime",header,":","\r")
	//The force wave is loaded (requiering the baseline corrected wave is present).
		wave force_ext=$listofbasenames[i]+"Force_ext_co"
	//Save the last, by measureing definition, highest force point of the trace.
		max_load_force[i]=force_ext[numpnts(force_ext)-1]
	endfor
//The created and filled overview waves are also duplicated to the folder holding the split adhesion ramp info.
	duplicate/o max_load_force, $":"+newfoldername+":max_load_force"
	duplicate/o dwell_times, $":"+newfoldername+":dwell_times"
end

//Function serving the adhesion-ramp-evaluation by spliting the adhesion overview waves to single one of constant dwell or constant load force.
function split_adhesion_ramps(ramp_length,number_forces,repetitions,newfoldername)
//Load input variables and strings.
	variable ramp_length, number_forces, repetitions
	string newfoldername
//Offset allows for force-curves in the beginning of the result waves to be not used, e.g. when before a ramp a test-measurement was made.
	variable looper=1, offset=0
	do	//Just to be able to abort the function in case of wrong input.
//Check for the adhesion_list (adhesion overview wave)-
	if(waveexists($"adhesion_list")==0)
		break
	endif
//Include the adhesion, dwell, and max-force overview waves.
	wave adhesion_list, dwell_times, max_load_force
	duplicate/o adhesion_list, $":"+newfoldername+":adhesion_list"
//Check the GUI-panels for the setting of model to be used.
	controlinfo/W=mechanicspanel#fitpanelEmod fitfunctionchoiceal	
	variable	mechmodelE=V_value
	controlinfo/W=mechanicspanel#fitpanelAdhesion FitModelChoice
	variable	mechmodel=V_value
//Check for a work of adhesion overview wave.
	if(waveexists($"workofadhesion_list")==1)
		variable WOA=1
	//Duplicate the Work of adhesion overview wave (also the one per area) both created by the workofadhesion function.
		wave workofadhesion_list
		duplicate/o workofadhesion_list, $":"+newfoldername+":workofadhesion_list"
		wave workadh_perArea_list
		duplicate/o workadh_perarea_list, $":"+newfoldername+":workadh_perArea_list"
		string model
	//Depending on the model also the WoA waves only calced by the adhesion force are duplicated to the ramp-folder.
		if(mechmodel==1&&mechmodelE!=6)
			wave workmodel=$"workofadhesion_JKR"
			duplicate/O workmodel, $":"+newfoldername+":workofadhesion_JKR"
			model="JKR"
		elseif(mechmodel==2&&mechmodelE!=6)
			wave workmodel=$"workofadhesion_DMT"
			duplicate/O workmodel, $":"+newfoldername+":workofadhesion_DMT"
			model="DMT"
	//In case of the Maugis model also other waves are transfered, which are/can be of interest.		
		elseif(mechmodelE==6)
			wave workmodel=$"workofadhesion_MD"
			duplicate/O workmodel, $":"+newfoldername+":workofadhesion_MD"
			model="MD"
			wave maugis_adhesionf, maugis_alpha, maugis_areaundercurve, emodul_by_maugis, workadhf_md_rips
			duplicate/O maugis_adhesionF, $":"+newfoldername+":maugis_adhesionF"
			duplicate/O maugis_alpha, $":"+newfoldername+":maugis_alpha"
			duplicate/o maugis_areaundercurve, $":"+newfoldername+":maugis_areaundercurve"
			duplicate/o emodul_by_maugis, $":"+newfoldername+":Emodul_by_maugis"
			duplicate/o workadhf_md_rips, $":"+newfoldername+":workadhf_md_rips"
		endif
		
	endif
	setdatafolder $newfoldername
//3 variables handling the flow of the 3-for-loops to go through all combination of dwell and load force.
	variable i,j,m
//1. Go through the curves in the way they were recorded (=chronological); namewise it is intended that the dwell-time is changed during ramping.
	for(i=0;i<((numpnts(adhesion_list)-offset)/(ramp_length*repetitions));i+=1)
	//Make overview waves for the i-th ramp measured.
		make/O/N=(ramp_length*repetitions) $"adhesion_ramp"+num2str(i), $"dwell_ramp"+num2str(i),$"force_ramp"+num2str(i)
		wave adh_ramp=$"adhesion_ramp"+num2str(i), dwell_ramp=$"dwell_ramp"+num2str(i), force_ramp=$"force_ramp"+num2str(i)
	//Include Work of Adhesion data.
		if(woa==1)
			make/O/N=(ramp_length*repetitions) $"workofadhe_ramp"+num2str(i), $"WorkADH_area_ramp"+num2str(i), $"Work_"+model+"_ramp"+num2str(i)
			wave woa_ramp=$"workofadhe_ramp"+num2str(i)
			wave woa_Area_ramp=$"workADH_area_ramp"+num2str(i)
			wave woa_model_ramp=$"Work_"+model+"_ramp"+num2str(i)
		endif
	//In case Maugis model is used
		if(mechmodelE==6)
			make/O/N=(ramp_length*repetitions) $"maugis_adhesionF_ramp"+num2str(i), $"maugis_alpha_ramp"+num2str(i), $"maugis_ArUnCu_ramp"+num2str(i), $"E_modul_by_maugis_ramp"+num2str(i), $"workadhf_md_rips_ramp"+num2str(i)
			wave md_adhf=$"maugis_adhesionF_ramp"+num2str(i), md_alpha=$"maugis_alpha_ramp"+num2str(i), md_ArUnCr=$"maugis_ArUnCu_ramp"+num2str(i), md_emod=$"E_modul_by_maugis_ramp"+num2str(i)
			wave woa_md_rips=$"workadhf_md_rips_ramp"+num2str(i)
		endif

	//Count through the main-waves from the 0 position of the i-th ramp to the end (how many different sets were measured * the repetitions)
		for(j=0;j<ramp_length*repetitions;j+=1)
//				if(i==0&&j>2)
//			offset=1
//		else
//			offset=0
//		endif
			adh_ramp[j]=adhesion_list[j+i*ramp_length*repetitions+offset]
			dwell_ramp[j]=dwell_times[j+i*ramp_length*repetitions+offset]
			force_ramp[j]=max_load_force[j+i*ramp_length*repetitions+offset]
			if(woa==1)
				woa_ramp[j]=workofadhesion_list[j+i*ramp_length*repetitions+offset]
				woa_area_ramp[j]=workadh_perArea_list[j+i*ramp_length*repetitions+offset]
				woa_model_ramp[j]=workmodel[j+i*ramp_length*repetitions+offset]
			endif
			if(mechmodelE==6)
				md_adhf[j]=maugis_adhesionf[j+i*ramp_length*repetitions+offset]
				md_alpha[j]=maugis_alpha[j+i*ramp_length*repetitions+offset]
				md_aruncr[j]=maugis_areaundercurve[j+i*ramp_length*repetitions+offset]
				md_emod[j]=emodul_by_maugis[j+i*ramp_length*repetitions+offset]
				woa_md_rips[j]=workadhf_md_rips[j+i*ramp_length*repetitions+offset]
			endif
		endfor
	endfor
//2. Split the overview waves up to have overview-waves where the ramp-parameter is constant. Rest as above.
	for(i=0;i<((numpnts(adhesion_list)-offset)/(number_forces*repetitions));I+=1)
		make/o/N=(number_forces*repetitions)  $"adh_at_constdwell"+num2str(i), $"const_dwell"+num2str(i), $"force_at_constdwell"+num2str(i)
		wave  adh_dwell=$"adh_at_constdwell"+num2str(i), const_dwell=$"const_dwell"+num2str(i), force_dwell=$"force_at_constdwell"+num2str(i)
		if(woa==1)
			make/o/N=(number_forces*repetitions) $"woa_at_constdwell"+num2str(i), $"Woa_pA_constdwell"+num2str(i), $"Work_"+model+"_constdwell"+num2str(i)
			wave woa_dwell=$"woa_at_constdwell"+num2str(i)
			wave woa_pA_dwell=$"woa_pA_constdwell"+num2str(i)
			wave woa_model_dwell=$"work_"+model+"_constdwell"+num2str(i)
		endif
		if(mechmodelE==6)
			make/O/N=(number_forces*repetitions) $"maugis_adhesionF_cdwel"+num2str(i), $"maugis_alpha_cdwel"+num2str(i), $"maugis_ArUnCu_cdwel"+num2str(i), $"E_modul_by_maugis_cdwel"+num2str(i), $"workadhf_md_rips_cdwel"+num2str(i)
			wave md_adhf=$"maugis_adhesionF_cdwel"+num2str(i), md_alpha=$"maugis_alpha_cdwel"+num2str(i), md_ArUnCr=$"maugis_ArUnCu_cdwel"+num2str(i), md_emod=$"E_modul_by_maugis_cdwel"+num2str(i), woa_md_rips=$"workadhf_md_rips_cdwel"+num2str(i)
		endif

		variable repetitions_counter
	//Number-forces is in the way the number of how many ramps have been done. E.g. varying load forces
		for(m=0;m<number_forces;m+=1)
		//In case force-curves which the very identical set were take = repetitions.
//		if(i==0&&m>2)
//			offset=1
//		else
//			offset=0
//		endif
			for(repetitions_counter=0;repetitions_counter<repetitions;repetitions_counter+=1)
				adh_dwell[repetitions_counter+m*repetitions]=adhesion_list[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
				const_dwell[repetitions_counter+m*repetitions]=dwell_times[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
				force_dwell[repetitions_counter+m*repetitions]=max_load_force[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
				if(woa==1)
					woa_dwell[repetitions_counter+m*repetitions]=workofadhesion_list[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
					woa_pa_dwell[repetitions_counter+m*repetitions]=workadh_perArea_list[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
					woa_model_dwell[repetitions_counter+m*repetitions]=workmodel[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
				endif
				if(mechmodelE==6)
					md_adhf[repetitions_counter+m*repetitions]=maugis_adhesionf[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
					md_alpha[repetitions_counter+m*repetitions]=maugis_alpha[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
					md_aruncr[repetitions_counter+m*repetitions]=maugis_areaundercurve[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
					md_emod[repetitions_counter+m*repetitions]=emodul_by_maugis[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
					woa_md_rips[repetitions_counter+m*repetitions]=workadhf_md_rips[i*repetitions+m*ramp_length*repetitions+repetitions_counter+offset]
				endif
			endfor	
		endfor
	endfor
	while(looper<-1)
end

//Small function called during Work-of-adhesion evaluation, when the "check-WoA-Range" is selceted. 
//This funtions only asks the user to set a cursor at the jump-out point of the curve, and gives that position back to the main function.
function check_woa_range(zeroretracecontact,zerobaselinejumpout,adhesioninfowave)
	variable zeroretracecontact, zerobaselinejumpout
	wave adhesioninfowave
	NVAR highlight_adh_g=root:panelcontrol:singlefcpanel:highlight_adh_g
	NVAR check_woa_choice_g=root:panelcontrol:singlefcpanel:check_woa_choice_g
	highlight_adh_g=1
	updateforcecurve1()
	UserManuallyAdding3("MechanicsPanel#Mechdisplay",180)
	if(check_woa_choice_g==1)
		if(pcsr(A,"mechanicspanel#mechdisplay")!=0&&pcsr(B,"mechanicspanel#mechdisplay")!=0)
			print "Only use one curosr!!!"
		elseif(pcsr(A,"mechanicspanel#mechdisplay")!=0)
			zerobaselinejumpout=pcsr(A,"mechanicspanel#mechdisplay")
		elseif(pcsr(B,"mechanicspanel#mechdisplay")!=0)
			zerobaselinejumpout=pcsr(B,"mechanicspanel#mechdisplay")
		endif
	elseif(check_woa_choice_g==3)
		zerobaselinejumpout=adhesioninfowave[2]
	endif
	return zerobaselinejumpout
end

//This function cleans up the Igor-Experiment-folder. It holds the collection of all waves possibly created during evaluation, which are in the end
//not necessary to re-show the graphs, or to read out the results. Activated by the "Finish Force Map"-button.
function clearwaves(list)
	wave/T list
	variable i
	string whattolookfor
	for(i=0;i<numpnts(list);i+=1)
		whattolookfor="fit_"+list[i]+"DeflV_ext_co"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		whattolookfor="Fit_"+list[i]+"DeflV_ret_co"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		whattolookfor="Fit_"+list[i]+"Force_ret_co"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		whattolookfor="Fit_"+list[i]+"force_ext_co"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		
		whattolookfor="fit_log_"+list[i]+"For"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		whattolookfor=list[i]+"baseDE"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		whattolookfor=list[i]+"baseDR"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"DefEmTot"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"EERRsing"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"EsdevTot"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"E_contErr"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"E_fitErr"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"E_InvErr"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"E_kerr"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"E_rerr"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"Res"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor=list[i]+"ResCalc"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="log_"+list[i]+"For"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="log_"+list[i]+"defor"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="LC_"+list[i]+"Force_ext_cor"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="LC_"+list[i]+"Defor_ret"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif
		whattolookfor="LP_"+list[i]+"Force_ext_cor"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="UP_"+list[i]+"Force_ext_cor"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif					
		whattolookfor="UC_"+list[i]+"Force_ext_cor"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif		
		whattolookfor="LP_"+list[i]+"Defor_ret"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="UP_"+list[i]+"Defor_ret"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif					
		whattolookfor="UC_"+list[i]+"Defor_ret"
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
		whattolookfor="JKRFIT"+list[i]
		whattolookfor=whattolookfor[0,30]
		if(waveexists($whattolookfor)==1)
			killwaves $whattolookfor
		endif	
	endfor
end

//This function basically converts a date and time (with a reference date) to the secondes elapsed since that date.
//This is used (i guess) to read out automatically the force-curve corresponding temperature from the heater graph.
function correlateTempAndTime(extractedTime,measuredTime,MeasuredTemp,year,month,day)
	wave extractedtime, measuredtime,measuredtemp
	variable year, month, day
	variable i
	make/o/N=(numpnts(extractedtime)) CorrelatedTemperature
	wave correlatedtemperature
	duplicate/O measuredtime, convertedmeasuredtime
	wave convertedmeasuredtime
	convertedmeasuredtime-=date2secs(year,month,day)
	variable secs=date2secs(year,month,day)
	for(i=0;i<numpnts(extractedtime);i+=1)
	//	if(wavetype(measuredtime,1)==2)
			findvalue/T=5 /V=(extractedtime[i]) convertedmeasuredtime
	//	elseif(wavetype(measuredtime,1)==1)
		//	findvalue/T=5/V=(time3secs4numwaves(extractedtime[i])) convertedmeasuredtime
	//		findvalue/T=5/V=(time3secs4numwaves(extractedtime,i)) convertedmeasuredtime

	//	endif
		if(V_Value==-1)
			break
		endif
		correlatedtemperature[i]=measuredtemp[v_value]	
	endfor
	killwaves convertedmeasuredtime
end

function correlateTempAndTime4TextWaves(extractedTime,measuredTime,MeasuredTemp,year,month,day)
	wave/T extractedtime
	wave measuredtime,measuredtemp
	variable year, month, day
	variable i
	make/o/N=(numpnts(extractedtime)) CorrelatedTemperature
	wave correlatedtemperature
	duplicate/O measuredtime, convertedmeasuredtime
	wave convertedmeasuredtime
	convertedmeasuredtime-=date2secs(year,month,day)
	variable secs=date2secs(year,month,day)
	for(i=0;i<numpnts(extractedtime);i+=1)
		variable testt=(time3secs(extractedtime[i])) 
		findvalue/T=0.2 /V=(time3secs(extractedtime[i])) convertedmeasuredtime
		if(V_Value==-1)
			break
		endif
		correlatedtemperature[i]=measuredtemp[v_value]	
	endfor
//	killwaves convertedmeasuredtime
end
//simple return function converting a time text in AM/PM to secondes passed since midnight
function time3secs(timestring)
	string timestring
	variable offset
	if(stringmatch(timestring,"*PM")==1&&str2num(stringfromlist(0,timestring,":"))!=12)
		offset=11*60*60+59*60+59
	else
		offset=0
	endif
	timestring=timestring[0,strlen(timestring)-4]
	variable secs=str2num(stringfromlist(0,timestring,":"))*60*60+str2num(stringfromlist(1,timestring,":"))*60+str2num(stringfromlist(2,timestring,":"))
	return secs+offset
end


//Small function increasing the numforcecurve -> changing the displayed graph.
function nextcurve(test)
	string test
	NVAR numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	numforcecurve_g+=1
end

//3 simple button funtions to open panels with a button.
function EmodulButtonOpenal(ctrlname) :Buttoncontrol
	string ctrlname
	UserPanelFitting_EModulal ()
end
function ShowerrorButtonOpenAL(ctrlname) :Buttoncontrol
	string ctrlname
	UserPanelShowErrorOpenAL()
end
function UserPanelAdhesionbutton(ctrlname) :Buttoncontrol
	string ctrlname
	UserPaneladhesionproperties()
end
function AdGButtonOpenal(ctrlname) :Buttoncontrol
	string ctrlname
	UserPanelFitting_AdGal ()
end
function MFButtonOpenAL(ctrlname) : Buttoncontrol
	string ctrlname
	UserPanelFitting_MeanFieldAL()
end
function updateforcecurve(sva) :setvariablecontrol
	STRUCT WMSetvariableaction &sva
	updateforcecurve1()
end

//Function called by others, when after finishing their operation to just automatically to the next force-curve.
function nextfunc(ctrlname) :buttoncontrol
	string ctrlname
	NVAR currentnum=root:panelcontrol:singlefcpanel:numforcecurve_g, limitnum=root:panelcontrol:singlefcpanel:limitsdisplay_G
	if(currentnum+1<=limitnum)
		currentnum+=1
	endif
end

function getnumforcecurve()
	NVAR numforcecurves_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	return numforcecurves_G
end

//Cant recall when I used this function but the structure is very simple so use it if you want. There is another, better function further below.
function folder_tempfromHeaterLive(Allnames,folder,AllTemperatures)
	wave/T allnames
	string folder
	wave alltemperatures
	setdatafolder $folder
	wave/T listofbasenames
	make/O/N=(numpnts(listofbasenames)) temperature
	wave temperature
	variable i, spot, m
	for(i=0;i<numpnts(listofbasenames);i+=1)
		for(m=0;m<numpnts(allnames);m+=1)
			if(stringmatch(allnames[m],listofbasenames[i])==1)
				temperature[i]=alltemperatures[m]
			endif
		endfor
	endfor
end
//Transfers a text-wave to a string holding all the wave's content.
function/T textWave2str(textwave)
	wave/T textwave
	variable i
	string returnstring
	for(i=0;i<numpnts(textwave);i+=1)
		returnstring+=textwave[i]+";"
	endfor
	return returnstring
end

///Some Button functions and pop-up windows interacting with user. Basically copy&paste from help files.
Function UserCursorAdjust(graphName,autoAbortSecs)
	String graphName
	Variable autoAbortSecs
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay						// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewPanel /K=2 /W=(187,368,437,531) as "Pause for Approvement"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=MechanicsPanel	// Put panel near the graph
	DrawText 21,20,"Is the displayed Point OK?"
	Button button0,pos={80,38},size={92,20},title="Keep Value"
	Button button0,proc=UserCursorAdjust_ContButtonPro1
	button Button1, title="Discard Value",pos={80,58},size={92,20}
	Button button1, proc=UserCursorAdjust_ContButtonPro0
	Variable didAbort= 0
	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,MechanicsPanel
	else
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				if( td <= 10 )
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
			PauseForUser/C tmp_PauseforCursor,MechanicsPanel
		while(V_flag)
	endif
	return didAbort
End
Function UserManuallyAdding3(graphName,autoAbortSecs)
	String graphName
	Variable autoAbortSecs
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay						// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewPanel /K=2 /W=(187,368,437,531) as "Work of adhesion range correct?" ///ext=0/HOST=mechanicsPanel
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=0/R=MechanicsPanel	// Put panel near the graph
	DrawText 21,20,"Do you want to change jump-off point?"
	Button button0,pos={80,38},size={92,30},title="Change!"
	Button button0,proc=UserManuallyAddPro5
	button Button1, title="It's ok!",pos={80,68},size={92,30}
	Button button1, proc=UserManuallyAddPro6
	button button2, title="Take \r force minimum!", pos={80,98}, size={92,30}
	button button2, proc=UserManuallyAddPro7
	Variable didAbort= 0
	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,MechanicsPanel
	else
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				if( td <= 10 )
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
			PauseForUser/C tmp_PauseforCursor,MechanicsPanel
		while(V_flag)
	endif
	return didAbort
End
Function UserManuallyAddPro5(ctrlName) : ButtonControl
	String ctrlName
	NVAR check_woa_choice_g=root:panelcontrol:singlefcpanel:check_woa_choice_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	check_woa_choice_g=1
End
Function UserManuallyAddPro6(ctrlName) : ButtonControl
	String ctrlName
	NVAR check_woa_choice_g=root:panelcontrol:singlefcpanel:check_woa_choice_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	check_woa_choice_g=2
End
Function UserManuallyAddPro7(ctrlName) : ButtonControl
	String ctrlName
	NVAR check_woa_choice_g=root:panelcontrol:singlefcpanel:check_woa_choice_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	check_woa_choice_g=3
End
///END OF BUTTON FUNCTIONS.

///Function below belong to the "find drop events" panel. Very special stuff not commonly used, so I dont comment this.
//So magic this button :) 
function MagicButton(ctrlname)	:ButtonControl
	string ctrlname
	NVAR  wholefolder_g=root:panelcontrol:SingleFCpanel:wholefolder_g, numforcecurve_g=root:panelcontrol:singlefcpanel:numforcecurve_g
	NVAR numberofmaxima_g=root:panelcontrol:singlefcpanel:numberofmaxima_g, amountofpnts_g=Root:panelcontrol:singlefcpanel:amountofpnts_g, threshold_g=root:panelcontrol:singlefcpanel:threshold_g
	NVAR boxsize_g=root:panelcontrol:singlefcpanel:boxsize_g, MoreEvents_g=Root:panelcontrol:singlefcpanel:moreevents_g
	svar folderstring_g=root:panelcontrol:singlefcpanel:folderstring_g
	variable maxminvar
	setdatafolder $folderstring_g
	string trace
	wave/T listofbasename=root:panelcontrol:singlefcpanel:listofbasenames_G
	if(wholefolder_g==1)
		variable i
		for(i=0;i<numpnts(listofbasename);i+=1)
			wave contactwave=$listofbasename[i]+"cont_tr"
			pointdensitypersum(listofbasename[i],contactwave[1],boxsize_g)
			wave ydif=$listofbasename[i]+"F200", xdif=$listofbasename[i]+"Defor_cut"
			string differentiatewave=listofbasename[i]+"F200_Dif"
			differentiate/MEth=0 ydif /X=xdif/D=$differentiatewave
			maxminvar=0
			findminima(differentiatewave,threshold_g,numberofmaxima_g,amountofpnts_g,contactwave[1],boxsize_g)
			wave minposi=$listofbasename[i]+"MinPosi", minval=$listofbasename[i]+"MinVal"
			wave maxposi=$listofbasename[i]+"MaxPos", maxval=$listofbasename[i]+"MaxVal", maxdefo=$listofbasename[i]+"MaxDefo"
			trace=listofbasename[i]+"Force_ext_co"
			maxminvar=1
			takeorleaveit(minposi,minval,maxdefo,trace,contactwave[1],maxminvar)
			manuallyAddMaxima(maxposi,maxval,maxdefo,trace)
		endfor
	else
		wave contactwave=$listofbasename[numforcecurve_g]+"cont_tr"
		//pointdensitypersum(listofbasename[numforcecurve_g],contactwave[1],boxsize_g)	//for deformation
		pointdensitypersum(listofbasename[numforcecurve_g],0,boxsize_g)
		wave ydif2=$listofbasename[numforcecurve_g]+"F200", xdif2=$listofbasename[numforcecurve_g]+"D200"
		string differentiatewaveS=listofbasename[numforcecurve_g]+"F200_Dif"
		differentiate/MEth=0 ydif2 /X=xdif2/D=$differentiatewaves
		
		//findminima(listofbasename[numforcecurve_g],threshold_g,numberofmaxima_g,amountofpnts_g,contactwave[1],boxsize_g)	//for deformation
		findminima(listofbasename[numforcecurve_g],threshold_g,numberofmaxima_g,amountofpnts_g,0,boxsize_g)
		wave minposi=$listofbasename[numforcecurve_g]+"MinPos", minval=$listofbasename[numforcecurve_g]+"MinVal"
		trace=listofbasename[numforcecurve_g]+"Force_ext_co"
		maxminvar=0
		//takeorleaveit(minposi,minval,minposi,trace,contactwave[1],maxminvar) //for deformation
		takeorleaveit(minposi,minval,minposi,trace,0,maxminvar)
		wave maxposi=$listofbasename[numforcecurve_g]+"MaxPos", maxval=$listofbasename[numforcecurve_g]+"MaxVal", maxdefo=$listofbasename[numforcecurve_g]+"MaxDefo"
		maxminvar=1
		//	takeorleaveit(maxposi,maxval,maxdefo,trace,contactwave[1],maxminvar) 	//for deformation
		takeorleaveit(maxposi,maxval,maxdefo,trace,0,maxminvar) 
		manuallyAddMaxima(maxposi,maxval,maxdefo,trace)
		correlationlenght(maxval,maxdefo,listofbasename[numforcecurve_g],folderstring_g)
	endif
end

function pointdensitypersum(forcecurve,startpoint,boxsize)
	string forcecurve
	variable startpoint,boxsize
	wave curveF=$forcecurve+"Force_ext_co"
	wave curveD=$forcecurve+"Defor_ext"
//	make/o/N=(numpnts(curveF)-startpoint) $forcecurve+"F10", $forcecurve+"F20", $forcecurve+"F50", $forcecurve+"F100",  $forcecurve+"D10", $forcecurve+"D20", $forcecurve+"D50", $forcecurve+"D100"

//	make/o/N=(numpnts(curveF)-startpoint) $forcecurve+"F200", $forcecurve+"D200"
	make/O/N=0 $forcecurve+"F200", $forcecurve+"D200", $forcecurve+"test"
//	wave curveF10=$forcecurve+"F10", curveD10=$forcecurve+"D10", curveF20=$forcecurve+"F20", curveD20=$Forcecurve+"D20", curveF50=$Forcecurve+"F50", curveD50=$forcecurve+"D50", curveF100=$forcecurve+"F100", curveD100=$forcecurve+"D100"
	wave curveF200=$forcecurve+"f200", curveD200=$forcecurve+"D200", test=$forcecurve+"test"
	duplicate/O/R=[startpoint,numpnts(curveD)] curveD, $forcecurve+"Defor_cut"
	variable i,u=0
	for(i=round(startpoint+boxsize/2);i<numpnts(curveF);i+=1)
//		curveF10[i-startpoint]=sum(curveF, pnt2x(curveF,i), pnt2x(curveF,i+10))-sum(curveF, pnt2x(curveF,i-10), pnt2x(curveF,i))
//		curveD10[i-startpoint]=sum(curveD, pnt2x(curveD,i), pnt2x(curveD,i+10))-sum(curveD, pnt2x(curveD,i-10), pnt2x(curveD,i))
//		curveF20[i-startpoint]=sum(curveF, pnt2x(curveF,i), pnt2x(curveF,i+20))-sum(curveF,pnt2x(curveF,i-20), pnt2x(curveF,i))
//		curveD20[i-startpoint]=sum(curveD,pnt2x(curveD,i), pnt2x(curveD,i+20))-sum(curveD,pnt2x(curveD,i-20), pnt2x(curveD,i))
//		curveF50[i-startpoint]=sum(curveF,pnt2x(curveF,i), pnt2x(curveF,i+50))-sum(curveF,pnt2x(curveF,i-50), pnt2x(curveF,i))
//		curveD50[i-startpoint]=sum(curveD,pnt2x(curveD,i), pnt2x(curveD,i+50))-sum(curveD,pnt2x(curveD,i-50), pnt2x(curveD,i))
//		curveF100[i-startpoint]=sum(curveF,pnt2x(curveF,i), pnt2x(curveF,i+100))-sum(curveF,pnt2x(curveF,i-100), pnt2x(curveF,i))
//		curveD100[i-startpoint]=sum(curveD,pnt2x(curveD,i), pnt2x(curveD,i+100))-sum(curveD,pnt2x(curveD,i-100), pnt2x(curveD,i))
		//curveF200[i-startpoint]=sum(curveF,pnt2x(curveF,i), pnt2x(curveF,i+boxsize/2))-sum(curveF,pnt2x(curveF,i-boxsize/2), pnt2x(curveF,i))
		//curveD200[i-startpoint]=sum(curveD,pnt2x(curveD,i), pnt2x(curveD,i+boxsize/2))-sum(curveD,pnt2x(curveD,i-boxsize/2), pnt2x(curveD,i))
		insertpoints u,1, curvef200, curved200, test
		//curveF200[u]=(sum(curveF,pnt2x(curveF,i), pnt2x(curveF,i+boxsize/2))-sum(curveF,pnt2x(curveF,i-boxsize/2), pnt2x(curveF,i)))/boxsize
		curveF200[u]=(sum(curveF,pnt2x(curveF,i+boxsize/2), pnt2x(curvef,i-boxsize/2)))/(boxsize+1)
		curveD200[u]=(sum(curveD,pnt2x(curveD,i+boxsize/2), pnt2x(curveD,i-boxsize/2)))/(boxsize+1)
		test[u]=((variance(curveF, pnt2x(curveF,i-boxsize/2),pnt2x(curvef,i+Boxsize/2))))
		//curveD200[u]=(sum(curveD,pnt2x(curveD,i), pnt2x(curveD,i+boxsize/2))-sum(curveD,pnt2x(curveD,i-boxsize/2), pnt2x(curveD,i)))/(boxsize+1)
		//curveD200[u]=(sum(curveD,pnt2x(curveD,i+boxsize/2), pnt2x(curveD,i-boxsize/2)))/(curveD[i+boxsize/2]-curveD[i-boxsize/2])
		//test[u]=(boxsize+1)/(curveD[i+boxsize/2]-curveD[i-boxsize/2])
		
		i+=boxsize
		u+=1
	endfor
	if(startpoint>0)
	endif
end

function findminima(difcurve,threshold,numberofminima,amountofpnts,startpunkt,boxsize)
	string difcurve
	variable threshold, numberofminima,amountofpnts,startpunkt,boxsize
	wave difcurveW=$difcurve+"F200_Dif"
	wave forceW=$difcurve+"Force_ext_co"
	wave deforW=$difcurve+"Defor_ext"
	wave summationwave=$difcurve+"F200"
	make/N=1/O $difcurve+"MinPos", $difcurve+"MinVal", $difcurve+"MaxPos", $difcurve+"MaxVal", $difcurve+"MaxDefo"
	wave MinPosi=$difcurve+"MinPos", MinVal=$difcurve+"MinVal", maxposi=$difcurve+"MaxPos", maxval=$difcurve+"MaxVal", maxdefo=$difcurve+"maxdefo"
	variable i, punkt, maxpunkt
	for(i=1;i<numpnts(difcurveW)-1;i+=1)
		//findvalue/S=(i)/V=0/T=(threshold) difcurveW
		//if(difcurveW[i]<threshold&&difcurvew[i]>-threshold)
		if((difcurveW[i-1]>0&&difcurveW[i+1]<0)||(difcurveW[i-1]<0&&difcurveW[i+1]>0))//&&(abs(difcurvew[i-1])+abs(difcurveW[i+1])>0.004))
	
		//if(difcurveW[V_value-1]<difcurveW[V_value+1])
		//	duplicate/O/R=[V_value-amountofpnts/2,V_value+amountofpnts/2] summationwave, wavestatswave
			//duplicate/O/R=[startpunkt+round((V_value)*(boxsize+1))-amountofpnts/2,startpunkt+round((V_value)*(boxsize+1))+amountofpnts/2] forceW, wavestatswave
			duplicate/O/R=[startpunkt+round((i)*(boxsize+1))-amountofpnts/2,startpunkt+round((i)*(boxsize+1))+amountofpnts/2] forceW, wavestatswave
			wavestats/Q wavestatswave
			punkt=numpnts(minposi)
			if(V_minrowloc>0.05*amountofpnts&&V_minrowloc<0.95*amountofpnts&&(difcurveW[i-1]<0&&difcurveW[i+1]>0))
			if(punkt==1)
				MinPosi[0]=(V_minRowLoc+i*(boxsize+1)-amountofpnts/2)+startpunkt
				MinVal[0]=forceW[(V_minRowloc+i*(boxsize+1)-amountofpnts/2)+startpunkt]
			else
				MinPosi[punkt-1]=(V_minRowloc+i*(boxsize+1)-amountofpnts/2)+startpunkt
				MinVal[punkt-1]=forceW[(V_minRowloc+i*(boxsize+1)-amountofpnts/2)+startpunkt]
			endif
			
			insertpoints punkt,1,MinPosi,MinVal
			endif
			maxpunkt=numpnts(maxposi)
			if(V_maxrowloc>0.05*amountofpnts&&V_maxrowloc<0.95*amountofpnts&&(difcurveW[i-1]>0&&difcurveW[i+1]<0))
				if(maxpunkt==1)
					maxval[0]=forceW[startpunkt+round((i)*(boxsize+1))-amountofpnts/2+V_maxrowloc]
					maxposi[0]=startpunkt+round((i)*(boxsize+1))-amountofpnts/2+V_maxrowloc
					maxdefo[0]=deforW[startpunkt+round((i)*(boxsize+1))-amountofpnts/2+V_maxrowloc]
				else
					maxval[maxpunkt-1]=forceW[startpunkt+round((i)*(boxsize+1))-amountofpnts/2+V_maxrowloc]
					maxposi[maxpunkt-1]=startpunkt+round((i)*(boxsize+1))-amountofpnts/2+V_maxrowloc
					maxdefo[maxpunkt-1]=deforW[startpunkt+round((i)*(boxsize+1))-amountofpnts/2+V_maxrowloc]
				endif
				insertpoints maxpunkt,1, maxposi, maxval, maxdefo
			endif
			i+=2
		//endif
//		if(V_value==-1)
//			i=numpnts(difcurveW)
//		else
//			i=V_value+amountofpnts/2
//			if(i>numpnts(difcurveW))
//				i=numpnts(difcurveW)
//			endif
//		endif
		//endif
		endif
	endfor
	sort MinVal, MinVal, minposi
	sort/R maxval, maxval, maxposi, maxdefo
	
	deletepoints numberofminima, numpnts(MinVal), minval, minposi
	deletepoints numberofminima, numpnts(maxval), maxval, maxposi, maxdefo
end

function takeorleaveit(posiwave,valuewave,deforwave,forcecurvetrace,startpunkt,maxminvar)
	wave posiwave,valuewave, deforwave
	string forcecurvetrace
	variable startpunkt, maxminvar
	NVAR maximaincurve_g=root:panelcontrol:singlefcpanel:maximaInCurve_g
	DoWindow/F MechanicsPanel
	Setactivesubwindow mechanicsPanel#mechdisplay
	cursor/K A
	cursor/K B
	variable i=0, deletecount=0
	for(i=0;i<numpnts(posiwave);i+=1)
		DoWindow/F MechanicsPanel
		Setactivesubwindow mechanicsPanel#mechdisplay
		if(maxminvar==0)
			cursor/a=1/P A $forcecurvetrace posiwave[i]
		elseif(maxminvar==1)
			cursor/a=1/P B $forcecurvetrace posiwave[i]
		endif
		UserCursorAdjust("MechanicsPanel#Mechdisplay",9999)
		if(maximaincurve_g==0)
			deletepoints (i),1, posiwave,valuewave, deforwave
			//deletecount+=1
			i-=1
		endif
	endfor	
end

function manuallyAddMaxima(posiwave,valuewave,maxdefo,forcecurvetrace)
	wave posiwave, valuewave, maxdefo
	string forcecurvetrace
	wave forcecurve=$forcecurvetrace
	NVAR moreevents_g=root:panelcontrol:singlefcpanel:moreevents_g
	DoWindow/F MechanicsPanel
	Setactivesubwindow mechanicsPanel#mechdisplay
	cursor/K A
	cursor/K B
	variable moreornot, addmore,i
	UserManuallyAdding("MechanicsPanel#Mechdisplay",9999)
	if(moreevents_G==1)
		edit posiwave,valuewave
		if(numpnts(posiwave)!=0)
			cursor/A=1 A $forcecurvetrace pnt2x($forcecurvetrace, posiwave[0])
		else
			showinfo
		endif
		make/N=(numpnts(valuewave),2)/O arrowwave
		arrowwave[*][0]=60
		arrowwave[*][1]=-1.57
		Appendtograph valuewave vs maxdefo
		ModifyGraph mode($nameofwave(valuewave))=3, arrowmarker($nameofwave(valuewave))={arrowwave,1,10,0.5,2}
		ModifyGraph rgb($nameofwave(valuewave))=(0,39168,0)
		do	
			addmore=usermanuallyadding2("MechanicsPanel#Mechdisplay",9999)
			if(moreevents_g==2)
				break
			endif
			insertpoints numpnts(posiwave),1, posiwave, valuewave, maxdefo, arrowwave
			arrowwave[*][0]=60
			arrowwave[*][1]=-1.57
			posiwave[numpnts(posiwave)-1]=pcsr(A)
			valuewave[numpnts(posiwave)-1]=vcsr(A)
			maxdefo[numpnts(posiwave)-1]=Hcsr(A)
		while(moreevents_g>0)
	endif
	sort maxdefo, valuewave, posiwave, maxdefo
end

function correlationlenght(valuewave,deforwave,fdname,foldername)
	wave valuewave, deforwave
	string fdname, foldername
	setdatafolder $foldername
	variable startcorrelation, correlationrange, correlationrunnumber
	if(waveexists($foldername+"DeStats1st")==0)
		make/n=0 $foldername+"DeStats1st",$foldername+"DeStats2nd",$foldername+"DeStats3rd", $foldername+"DeStats4th"
	endif
	wave statswave1st=$foldername+"DeStats1st", statswave2nd=$foldername+"DeStats2nd", statswave3rd=$foldername+"DeStats3rd", statswave4th=$foldername+"DeStats4th"
	make/O/N=(numpnts(valuewave)-1) $Fdname+"1stOrderForce", $Fdname+"1stOrderDefor"
	wave force1st=$FDname+"1stOrderForce", defor1st=$fdname+"1stOrderDefor"
	if(numpnts(valuewave)>2)
		make/O/N=(numpnts(valuewave)-2) $Fdname+"2ndOrderForce", $Fdname+"2ndOrderDefor"
		wave force2nd=$Fdname+"2ndOrderForce", defor2nd=$Fdname+"2ndOrderDefor"
	endif
	if(numpnts(valuewave)>3)
		make/O/N=(numpnts(valuewave)-3) $Fdname+"3rdOrderForce", $Fdname+"3rdOrderDefor"
		wave force3rd=$Fdname+"3rdOrderForce", defor3rd=$Fdname+"3rdOrderDefor"
	endif
	if(numpnts(valuewave)>4)
		make/O/N=(numpnts(valuewave)-4) $Fdname+"4thOrderForce", $Fdname+"4thOrderDefor"
		wave force4th=$Fdname+"4thOrderForce", defor4th=$Fdname+"4thOrderDefor"
	endif
	for(startcorrelation=0;startcorrelation<numpnts(valuewave)-1;startcorrelation+=1)			//ende der schleife -1????
		if(startcorrelation<=numpnts(valuewave)-5)
			Make/O/N=4 $Fdname+"ForC"+num2str(startcorrelation), $Fdname+"DeforC"+num2str(startcorrelation)
		elseif(startcorrelation==numpnts(valuewave)-4)
			Make/O/N=3 $Fdname+"ForC"+num2str(startcorrelation), $Fdname+"DeforC"+num2str(startcorrelation)
		elseif(startcorrelation==numpnts(valuewave)-3)
			Make/O/N=2 $Fdname+"ForC"+num2str(startcorrelation), $Fdname+"DeforC"+num2str(startcorrelation)
		elseif(startcorrelation==numpnts(valuewave)-2)
			Make/O/N=1 $Fdname+"ForC"+num2str(startcorrelation), $Fdname+"DeforC"+num2str(startcorrelation)			
		endif
		wave forcecorrelation=$Fdname+"ForC"+num2str(startcorrelation), deforcorrelation=$Fdname+"DeforC"+num2str(startcorrelation)
		for(correlationrunnumber=1;correlationrunnumber<numpnts(forcecorrelation)+1;correlationrunnumber+=1)
			forcecorrelation[correlationrunnumber-1]=valuewave[correlationrunnumber+startcorrelation]-valuewave[startcorrelation]
			deforcorrelation[correlationrunnumber-1]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
			if(correlationrunnumber==1)
				force1st[startcorrelation]=valuewave[correlationrunnumber+startcorrelation]-valuewave[startcorrelation]
				defor1st[startcorrelation]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
				insertpoints numpnts(statswave1st),1, statswave1st
				statswave1st[numpnts(statswave1st)-1]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
			elseif(correlationrunnumber==2)
				force2nd[startcorrelation]=valuewave[correlationrunnumber+startcorrelation]-valuewave[startcorrelation]
				defor2nd[startcorrelation]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
				insertpoints numpnts(statswave2nd),1, statswave2nd
				statswave2nd[numpnts(statswave2nd)-1]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
			elseif(correlationrunnumber==3)
				force3rd[startcorrelation]=valuewave[correlationrunnumber+startcorrelation]-valuewave[startcorrelation]
				defor3rd[startcorrelation]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
				insertpoints numpnts(statswave3rd),1, statswave3rd
				statswave3rd[numpnts(statswave3rd)-1]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
			elseif(correlationrunnumber==4)
				force4th[startcorrelation]=valuewave[correlationrunnumber+startcorrelation]-valuewave[startcorrelation]
				defor4th[startcorrelation]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]
				insertpoints numpnts(statswave4th),1, statswave4th
				statswave4th[numpnts(statswave4th)-1]=deforwave[correlationrunnumber+startcorrelation]-deforwave[startcorrelation]				
			endif
		endfor	
	endfor
end

function calclocalstiffness(valuewave,deforwave,posiwave,fdname,foldername)
	wave valuewave, deforwave, posiwave
	string fdname, foldername
	wave forcecurve=$fdname+"Force_ext_co"
	variable/G root:panelcontrol:singlefcpanel:stiffnesscalcvalue_g
	NVAR stiffnesscalcvalue_g=root:panelcontrol:singlefcpanel:stiffnesscalcvalue_g
	DoWindow/F MechanicsPanel
	Setactivesubwindow mechanicsPanel#mechdisplay
	cursor/K A
	cursor/K B
	make/N=(numpnts(valuewave),2)/O arrowwave
	arrowwave[*][0]=60
	arrowwave[*][1]=-1.57
	Appendtograph valuewave vs deforwave
	ModifyGraph mode($nameofwave(valuewave))=3, arrowmarker($nameofwave(valuewave))={arrowwave,1,10,0.5,2}
	ModifyGraph rgb($nameofwave(valuewave))=(0,39168,0)
	duplicate/O valuewave, $Fdname+"StiffMax", $Fdname+"StiffMin", $Fdname+"LocalStiff", $Fdname+"localStiffErr"
	duplicate/O deforwave, $Fdname+"DeforMax", $FDname+"DeforMin"
	wave maxStiff=$FDname+"stiffMax", minstiff=$Fdname+"stiffMin", maxdefor=$Fdname+"DeforMax", mindefor=$fdname+"DeforMin", localstiff=$FdName+"localstiff", localstifferr=$fdname+"localstifferr"
	variable selectstiffness=0, correctionvalue=0
	string fitname
	for(selectstiffness=0;selectstiffness<numpnts(valuewave);selectstiffness+=1)
		cursor/A=1 B $FDname+"Force_ext_co" pnt2x($FDname+"Force_ext_co", posiwave[selectstiffness])
		stiffnesswindow("MechanicsPanel#Mechdisplay",9999)
		if(stiffnesscalcvalue_g==1)
			maxStiff[selectstiffness-correctionvalue]=valuewave[selectstiffness]
			maxdefor[selectstiffness-correctionvalue]=deforwave[selectstiffness]
			minstiff[selectstiffness-correctionvalue]=Vcsr(A)
			mindefor[selectstiffness-correctionvalue]=Hcsr(A)
			CurveFit/Q/NTHR=0 line  forcecurve[pcsr(A),pcsr(B)] /X=$fdname+"defor_ext" /D 
			wave w_coef, w_sigma
			fitname="Fit_"+fdname+"force_ext_co"
			fitname=fitname[0,30]
			localstiff[selectstiffness-correctionvalue]=w_coef[1]
			localstifferr[selectstiffness-correctionvalue]=w_sigma[1]
			removefromgraph $fitname
			killwaves $fitname
		else
			deletepoints selectstiffness-correctionvalue, 1, maxstiff, maxdefor, minstiff, mindefor, localstiff, localstifferr
			correctionvalue+=1
		endif
	endfor
	edit localstiff, localstifferr
//	deletepoints numpnts(maxdefor), correctionvalue, localstiff
//	localstiff=(maxstiff-minstiff)/(maxdefor-mindefor)
end

Function stiffnesswindow(graphName,autoAbortSecs)
	String graphName
	Variable autoAbortSecs
	NVAR stiffnesscalcvalue_g=root:panelcontrol:singlefcpanel:stiffnesscalcvalue_g
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay						// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewPanel /K=2 /W=(187,368,437,531) as "Determine local 'stiffness'"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=MechanicsPanel	// Put panel near the graph
	DrawText 21,20,"Select Start Points of Calculation"
	Button button0,pos={80,38},size={92,20},title="Set Startpoint"
	Button button0,proc=UserStiff1
	button Button1, title="Skip this one",pos={80,58},size={92,20}
	Button button1, proc=UserStiff0
	Variable didAbort= 0
	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,MechanicsPanel
	else
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				if( td <= 10 )
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
			PauseForUser/C tmp_PauseforCursor,MechanicsPanel
		while(V_flag)
	endif
	return didAbort
End

Function UserStiff0(ctrlName) : ButtonControl
	String ctrlName
		NVAR stiffnesscalcvalue_g=root:panelcontrol:singlefcpanel:stiffnesscalcvalue_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	stiffnesscalcvalue_g=0
End

Function UserStiff1(ctrlName) : ButtonControl
	String ctrlName
	NVAR stiffnesscalcvalue_g=root:panelcontrol:singlefcpanel:stiffnesscalcvalue_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	stiffnesscalcvalue_g=1
End

Function UserCursorAdjust_ContButtonPro0(ctrlName) : ButtonControl
	String ctrlName
	variable/G root:panelcontrol:singleFCPanel:MaximainCurve_g=0
	DoWindow/K tmp_PauseforCursor				// Kill self
End

Function UserCursorAdjust_ContButtonPro1(ctrlName) : ButtonControl
	String ctrlName
	variable/G root:panelcontrol:singleFCPanel:MaximainCurve_g=1
	DoWindow/K tmp_PauseforCursor				// Kill self
End

Function UserManuallyAdding(graphName,autoAbortSecs)
	String graphName
	Variable autoAbortSecs
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay						// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewPanel /K=2 /W=(187,368,437,531) as "Adding more Maximia?"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=MechanicsPanel	// Put panel near the graph
	DrawText 21,20,"Do you want to add more points to Maxima waves?"
	Button button0,pos={80,38},size={92,20},title="Add More!"
	Button button0,proc=UserManuallyAddPro1
	button Button1, title="Everything is fine!",pos={80,58},size={92,20}
	Button button1, proc=UserManuallyAddPro0
	Variable didAbort= 0
	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,MechanicsPanel
	else
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				if( td <= 10 )
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
			PauseForUser/C tmp_PauseforCursor,MechanicsPanel
		while(V_flag)
	endif
	return didAbort
End

Function UserManuallyAddPro0(ctrlName) : ButtonControl
	String ctrlName
	NVar moreevents_g=root:panelcontrol:singlefcpanel:moreevents_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	moreevents_g=0
End

Function UserManuallyAddPro1(ctrlName) : ButtonControl
	String ctrlName
	NVar moreevents_g=root:panelcontrol:singlefcpanel:moreevents_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	moreevents_g=1
End

Function UserManuallyAdding2(graphName,autoAbortSecs)
	String graphName
	Variable autoAbortSecs
	DoWindow/F MechanicsPanel
	setactivesubwindow MechanicsPanel#Mechdisplay						// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	NewPanel /K=2 /W=(187,368,437,531) as "Adding more Maximia?"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=MechanicsPanel	// Put panel near the graph
	DrawText 21,20,"Do you want to add more points to Maxima waves?"
	Button button0,pos={80,38},size={92,20},title="Add this and More!"
	Button button0,proc=UserManuallyAddPro3
	button Button1, title="Add this and Quit!",pos={80,58},size={92,20}
	Button button1, proc=UserManuallyAddPro2
	button button2, title="Quit now!", pos={80,78}, size={92,20}
	button button2, proc=UserManuallyAddPro4
	Variable didAbort= 0
	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,MechanicsPanel
	else
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				if( td <= 10 )
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
			PauseForUser/C tmp_PauseforCursor,MechanicsPanel
		while(V_flag)
	endif
	return didAbort
End

Function UserManuallyAddPro2(ctrlName) : ButtonControl
	String ctrlName
	NVar moreevents_g=root:panelcontrol:singlefcpanel:moreevents_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	moreevents_g=0
End

Function UserManuallyAddPro3(ctrlName) : ButtonControl
	String ctrlName
	NVar moreevents_g=root:panelcontrol:singlefcpanel:moreevents_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	moreevents_g=1
End

Function UserManuallyAddPro4(ctrlName) : ButtonControl
	String ctrlName
	NVar moreevents_g=root:panelcontrol:singlefcpanel:moreevents_g
	DoWindow/K tmp_PauseforCursor				// Kill self
	moreevents_g=2
End