//(S)TEM-Automated 3D ED Acquisition v3.4, S. Plana Ruiz, Universitat Rovira i Virgili, TU-Darmstadt, JGU-Mainz & UB, April 2024.

// Global variables ----------------------------------------------------------------------------

number testEval=0, procValue=3, binValue=1, delta, origin, scaleCali, currentAngle, initialXBeam, initialYBeam, stepAcquisition=0 
number magImage, briImage, xbsImage, ybsImage, focusImage, magDiff, briDiff, focusDiff, checkImg=0, checkDiff=0, calMagBeamSize
number initialXposition, initialYposition, widthCam, heightCam, cameraLength ,index=1, checkCamL=0, diffSettingCheck=0
number xshiftProj, yshiftProj, pyTEMServerState, toInitializePyModules, scanCamLenDiff, scanDiffProjX, scanDiffProjY
number t_label, l_label, b_label, r_label, t_oval, l_oval, b_oval, r_oval, scanCamLenImg, scanImgProjX, scanImgProjY
image refDSimg
string path, unitsString, unitsStringRef, msgPyTEMserv, msgForPyTEMserv, Manufacturer, magNeeded, pixelCaliBeamSize, nameDPs="Frame"
TagGroup checkBB, stoPath, temCheck, stemCheck
component theroi = NewGroupAnnotation()

//Lines to define the path to read/save data, references and pyJEM scripts -------------

string drivestring = "X:"
string folderstring = "S-TEMADT_Storage"
string pathPDW = pathconcatenate(drivestring,folderstring)
string storagePath = pathPDW
string pyTEMserverLocation = pathconcatenate(pathPDW,"pyTEMserver")

//Read of Config text file -------------------------------------------------------------

try {
	string dirConfi = pathConcatenate(pathPDW, "config.txt")
	number fileRefConfi = openFileForReading(dirConfi)		
	number nonUsedOne = readFileLine(fileRefConfi, Manufacturer)
	nonUsedOne = readFileLine(fileRefConfi,magNeeded)
	nonUsedOne = readFileLine(fileRefConfi, pixelCaliBeamSize)
	calMagBeamSize = val(pixelCaliBeamSize)
	closeFile(fileRefConfi)																	
} catch {
	showAlert("The configuration file is not created or available.",2)
}

//Get Active Camera ID and Camera size ------------------------------------------------

object camera = CM_GetCurrentCamera()
number camID = CameraGetActiveCameraID()
CM_CCD_GetSize(camera, widthCam, heightCam )
object viewParams = CM_GetCameraAcquisitionParameterSet( camera, "Imaging", "View", "Search", 1)

//--------------------------------------------------------------------------------------

//Thread object which sets the beam positioning (executed in the background)
Class Positioning:Thread{
	
 	Object StartSignal
 	Object StopSignal
 	number DialogID, m_DataListenerID
 	image m_img

	// initialize Boolean constants and signals
	object init( object self ){
		StartSignal = NewSignal(0)
		StopSignal = NewSignal(0)
		return self
	}

	// The stop signal for the thread
	void Stop( object self ){
		StopSignal.SetSignal()
	}
				
	// A function which the dialog calls to pass in its ID to the thread. Once the thread has the dialog's ID
	// it can find and access to the dialog object
	void LinkToDialog(object self, number ID){
		DialogID=ID
	}

	// Starts the thread to do the counting
	void Start( object self ){
		number roi_top, roi_bottom, roi_left, roi_right, currentX, currentY, do_break=0
		number origin, scaleCali, shiftX, shiftY, id, waitforstopsignal=0.05
		string calibrationPartX, calibrationPartY, rotationAngle, unitsString
		image refImg := getFrontImage()
		ImageGetDimensionCalibration(refImg, 0, origin, scaleCali, unitsString, 1)
		object Called_Dialog=GetScriptObjectFromID(DialogID)
		
		//Read the Beam Shift Calibration
		string directoryCalibration = pathConcatenate(pathPDW, "BeamShiftCalibration.txt")
		number fileReference = openFileForReading(directoryCalibration)		
		number Line1 = readFileLine(fileReference, calibrationPartX)
		number Line2 = readFileLine(fileReference, calibrationPartY)
		number Line3 = readFileLine(fileReference, rotationAngle)
		number calibrationX = val(right(calibrationPartX,len(calibrationPartX)-15))
		number calibrationY = val(right(calibrationPartY,len(calibrationPartY)-15))
		number rotAngle = val(right(rotationAngle,len(rotationAngle)-30))
		closeFile(fileReference)
		
		// Loop the thread until a stop signal is encountered
		while( 1 ){
			try {
				while( 1 ){
					StartSignal.WaitOnSignal(waitforstopsignal, StopSignal) // wait <interval> second for stop signal	
			
					try{
						id=Called_Dialog.ScriptObjectGetID()
					} catch {
						do_break = 1
						Break
					}
										
					theroi.ComponentGetBoundingRect(roi_top, roi_left, roi_bottom, roi_right)
					currentX = roi_left + (r_label-l_label)+((r_oval-l_oval)/2)
					currentY = roi_top + (b_label-t_label)+((b_oval-t_oval)/2)
					shiftX = ((cos(rotAngle*pi()/180)*(currentX-initialXBeam)) + (sin(rotAngle*pi()/180)*(-(currentY-initialYBeam))))*calibrationX*scaleCali
					shiftY = ((-sin(rotAngle*pi()/180)*(currentX-initialXBeam)) + (cos(rotAngle*pi()/180)*(-(currentY-initialYBeam))))*calibrationY*scaleCali
					EMSetBeamShift(initialXposition+shiftX, initialYposition+shiftY)
					//Result("ShiftX: "+shiftX+" ShiftY: "+shiftY+"\n")
					//Result("Y:"+"\t"+(roi_top+((roi_bottom-roi_top)/2))+"\t"+"X:"+"\t"+(roi_left+((roi_right-roi_left)/2))+"\n")
				}
			} catch {
				do_break = 1
				Break
			}
						
			try {
				If(do_break) break
				StartSignal.ResetSignal()
			} catch exit(0)
				
		}
	}

	
	void DataChanged(object self, number change, Image img){
	}
	

	void BeamDiamForDiff(object self){
		m_img := getFrontImage()
		m_dataListenerID = m_img.ImageAddEventListener(self, "data_value_changed:DataChanged")
		while(ImageCountImageDisplays(m_img)>0){
			ImageSetDimensionCalibration(m_img, 0, 0, calMagBeamSize, "nm", 1)
			ImageSetDimensionCalibration(m_img, 1, 0, calMagBeamSize, "nm", 1)
			sleep(0.1)
		}
		m_img.ImageRemoveEventListener(m_dataListenerID)
	}

}

// GUI: Dialogs and their functions
class ADTAcquisitionDialog:UIFrame{

number ScanIsOn
object Positioning

//Creation of Dialog components for the GUI
TagGroup MakeButtons(object self){

	//----------------------------------------------------------------------------------
	//(S)TEM-ADT: PARAMETERS SETUP
	//----------------------------------------------------------------------------------
	
	TagGroup boxSCOPE_items
	TagGroup boxSCOPE=DLGCreateBox("Parameters Setup", boxSCOPE_items)
	
	//TEM & STEM checkbox
	
	stemCheck = DLGCreateCheckbox("STEM",0,"stemOpt")
	stemCheck.DLGidentifier("stemOption")
	temCheck = DLGCreateCheckbox("TEM",1, "temOpt")
	temCheck.DLGidentifier("temOption")
	TagGroup groupingCheckings = DLGGroupItems(temCheck, stemCheck)
	groupingCheckings.DLGTableLayout(2,1,0)
	boxSCOPE_items.dlgaddelement(groupingCheckings)		
	
	//INITIAL ANGLE---------------------------------------------------------------------

	TagGroup labelInitial = DLGCreateLabel("Initial Angle (°):")	
	TagGroup realfieldInitialAngle = DLGCreateRealField(0, 5, 3).dlgidentifier("initialAngleCall")
	dlgvalue(realfieldInitialAngle,0)

	TagGroup labelboxIniAngle=dlggroupitems(labelInitial, realfieldInitialAngle)
	labelboxIniAngle.dlgtablelayout(2,1,0)

	//FINAL ANGLE-----------------------------------------------------------------------

	TagGroup label1 = DLGCreateLabel("Final Angle (°):")
	TagGroup realfield1 = DLGCreateRealField(0, 5, 3).dlgidentifier("finalAngleCall")	
	dlgvalue(realfield1,0)

	TagGroup labelbox1=dlggroupitems(label1, realfield1)
	labelbox1.dlgtablelayout(2,1,0)
	taggroup anglesBoxTot = dlggroupitems(labelboxIniAngle,labelbox1).dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(anglesBoxTot)
	
	//STEP ANGLE -------------------------------------------------------------------------

	TagGroup stepTag = DLGCreateLabel("Tilt Step (°):")
	TagGroup stepfield = DLGCreateRealField(1, 6,3).dlgidentifier("stepCall")
	dlgvalue(stepfield,1).dlgenabled(1)

	TagGroup labelboxStep=dlggroupitems(stepTag, stepfield)
	labelboxStep.dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(labelboxStep)
	
	//GO TO -----------------------------------------------------------------------------
	
	TagGroup gotoTag=dlgcreatepushbutton("Go to (°):", "gotoAngle").dlgexternalpadding(2,0)
	TagGroup goAngle = DLGCreateRealField(0, 6, 3).dlgidentifier("gotoValue")
	dlgvalue(goAngle,0).dlgexternalpadding(2,0)
	TagGroup undoTag=dlgcreatepushbutton("Undo", "undoAngle")
	undoTag.dlgexternalpadding(2,0).dlgenabled(0).dlgidentifier("undoAngle")
		
	TagGroup gotoBox = dlggroupitems(gotoTag, goAngle, undoTag)
	gotoBox.dlgtablelayout(3,1,0)
	boxSCOPE_items.dlgaddelement(gotoBox)

	//EXPOSURE TIME DP-------------------------------------------------------------------
	
	TagGroup labelExpo = DLGCreateLabel("Exposure Diff (s):")
	labelExpo.dlgexternalpadding(3,0)
	TagGroup valorExposicio = DLGCreateRealField(1, 6, 3).dlgidentifier("exposure").dlgexternalpadding(2,0)
	dlgvalue(valorExposicio,0.1)
		
	TagGroup caixa = dlggroupitems(labelExpo, valorExposicio)
	caixa.dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(caixa)	

	//EXPOSURE TIME IMG------------------------------------------------------------------
	
	TagGroup labelExpo2 = DLGCreateLabel("Exposure Img (s):")
	labelExpo2.dlgexternalpadding(3,0)
	TagGroup valorExposicio2 = DLGCreateRealField(4, 6, 3).dlgidentifier("exposureImg").dlgexternalpadding(2,0)
	dlgvalue(valorExposicio2,1)
		
	TagGroup caixa2 = dlggroupitems(labelExpo2, valorExposicio2)
	caixa2.dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(caixa2)		
	
	//BINNING----------------------------------------------------------------------------
		
	TagGroup labelBin = DLGCreateLabel("Binning: ")
	labelBin.dlgexternalpadding(15,0)		
	TagGroup binningSelect_items
	TagGroup binningSelect = DLGCreatePopup(binningSelect_items, 1,"binningSelected")
	binningSelect_items.DLGAddPopupItemEntry("1");
	binningSelect_items.DLGAddPopupItemEntry("2");
	binningSelect_items.DLGAddPopupItemEntry("4");
	binningSelect_items.DLGAddPopupItemEntry("8");

	TagGroup BinCaixa = dlggroupitems(labelBin, binningSelect)
	BinCaixa.dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(BinCaixa)
		
	//PROCESSING-------------------------------------------------------------------------

	TagGroup labelProcessing = DLGCreateLabel("Processing:")
	labelProcessing.dlgexternalpadding(10,0)
		
	TagGroup processingSelect_items
	TagGroup processingSelect = DLGCreatePopup(processingSelect_items, 1,"processingSelected")
	processingSelect_items.DLGAddPopupItemEntry("Gain Normalized");
	processingSelect_items.DLGAddPopupItemEntry("Dark Correction");
	processingSelect_items.DLGAddPopupItemEntry("Unprocessed");
	
	TagGroup procBox = dlggroupitems(labelProcessing, processingSelect)
	procBox.dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(procBox)	
	
	//DIFFRACTION ACQUISITION -----------------------------------------------------------
		
	TagGroup acqImg=dlgcreatepushbutton("Acquire DP", "acqDiffraction").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	
	//IMAGE ACQUISITION -----------------------------------------------------------------
		
	TagGroup acqImg2=dlgcreatepushbutton("Acquire Img", "acqImage").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	TagGroup acquisitionBox = dlggroupitems(acqImg, acqImg2).dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(acquisitionBox)
	
	//STEM Detectors --------------------------------------------------------------------
	
	TagGroup STEMdetect_items
	TagGroup STEMdetect=DLGCreateBox("STEM Detectors", STEMdetect_items)
	
	TagGroup insDFbutt=dlgcreatepushbutton("Insert DF", "insDFdet").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	insDFbutt.dlgidentifier("insDF").dlgenabled(0)
	TagGroup retDFbutt=dlgcreatepushbutton("Retract DF", "retDFdet").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	retDFbutt.dlgidentifier("retDF").dlgenabled(0)
	TagGroup insBFbutt=dlgcreatepushbutton("Insert BF", "insBFdet").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	insBFbutt.dlgidentifier("insBF").dlgenabled(0)
	TagGroup retBFbutt=dlgcreatepushbutton("Retract BF", "retBFdet").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	retBFbutt.dlgidentifier("retBF").dlgenabled(0)
	TagGroup DFgroup = dlggroupitems(insDFbutt,retDFbutt,insBFbutt,retBFbutt).dlgtablelayout(2,2,0)
	STEMdetect_items.dlgaddelement(DFgroup)
	boxSCOPE_items.dlgaddelement(STEMdetect)
	
	//-----------------------------------------------------------------------------------

	//IMAGE ACQUISITION -----------------------------------------------------------------
	
	TagGroup scrUpBut=dlgcreatepushbutton("Screen Up", "scrUpFunc").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	TagGroup scrDownBut=dlgcreatepushbutton("Screen Down", "scrDownFunc").dlginternalpadding(4,0).dlgexternalpadding(2,0)
	TagGroup screenBox = dlggroupitems(scrUpBut, scrDownBut).dlgtablelayout(2,1,0)
	boxSCOPE_items.dlgaddelement(screenBox)
	
	//-----------------------------------------------------------------------------------
	//BEAM SHIFT CALIBRATION
	//-----------------------------------------------------------------------------------
	TagGroup acquireCali_items
	TagGroup acquireCali=dlgcreatebox("Beam Shift Calibration", acquireCali_items)

	//SHIFT VALUE------------------------------------------------------------------------

	TagGroup labelshift = DLGCreateLabel("Shift Value:")
	labelshift.dlgexternalpadding(2,0)
		
	taggroup etiqueta = DLGCreateRealField(3000, 8, 3).dlgidentifier("shiftValor").dlgexternalpadding(4,0)	
	dlgvalue(etiqueta,3000)

	TagGroup labelboxShift=dlggroupitems(labelshift, etiqueta)
	labelboxShift.dlgtablelayout(2,1,0)
	acquireCali_items.dlgaddelement(labelboxShift)
		
	//TEST SHIFT VALUE ------------------------------------------------------------------
		
	TagGroup test=dlgcreatepushbutton("Test Shift Value", "testBeamShift")
	test.dlgexternalpadding(9,0).dlginternalpadding(9,0).dlgtablelayout(1,1,0).dlgIdentifier("testShiftButton")
	acquireCali_items.dlgaddelement(test)
			
	//ACQUIRE CALIBRATION IMAGES --------------------------------------------------------

	TagGroup cali=dlgcreatepushbutton("Calibrate", "caliBeamShift")
	cali.dlgexternalpadding(9,0).dlginternalpadding(9,0).dlgtablelayout(1,1,0).dlgIdentifier("calibrateButton")
	acquireCali_items.dlgaddelement(cali)

	//-----------------------------------------------------------------------------------
	//IMAGING OPTICS 
	//-----------------------------------------------------------------------------------
	TagGroup imgOptics_items
	TagGroup imgOptics=dlgcreatebox("Projector System Mode", imgOptics_items)
	//------------------------------------------------------------------------------------
	TagGroup toImgMode=dlgcreatepushbutton("-> to Img", "toImgModebut")
	toImgMode.dlgexternalpadding(2,0).dlginternalpadding(5,0).dlgIdentifier("toImgModebut")
	
	TagGroup toDiffMode=dlgcreatepushbutton("-> to Diff", "toDiffModebut")
	toDiffMode.dlgexternalpadding(2,0).dlginternalpadding(5,0).dlgIdentifier("toDiffModebut")
	
	TagGroup imagingOpticsGroup = DLGgroupitems(toImgMode,toDiffMode)
	imagingOpticsGroup.dlgtablelayout(2,1,0)
	imgOptics_items.dlgaddelement(imagingOpticsGroup)
	
	
	//-----------------------------------------------------------------------------------
	//BEAM SETTING
	//-----------------------------------------------------------------------------------
	TagGroup beamset_items
	TagGroup beamsetting=dlgcreatebox("Beam Settings", beamset_items)
	//------------------------------------------------------------------------------------
	
	//TEXTS ------------------------------------------------------------------------------

	TagGroup labelimage = DLGCreateLabel("   Imaging")
	labelimage.dlgexternalpadding(12,0)
	
	TagGroup labeldiff = DLGCreateLabel("Diffraction")
	labeldiff.dlgexternalpadding(12,0)

	TagGroup labelboxTexts=dlggroupitems(labelimage, labeldiff)
	labelboxTexts.dlgtablelayout(2,1,0)
	beamset_items.dlgaddelement(labelboxTexts)
	
	//GET BUTTONS ------------------------------------------------------------------------
	
	TagGroup getimage=dlgcreatepushbutton("Get", "getimagesetting")
	getimage.dlgexternalpadding(2,0).dlginternalpadding(15,0)
	
	TagGroup getdiff=dlgcreatepushbutton("Get", "getdiffsetting")
	getdiff.dlgexternalpadding(2,0).dlginternalpadding(15,0)
	
	TagGroup labelboxGets=dlggroupitems(getimage, getdiff)
	labelboxGets.dlgtablelayout(2,1,0)
	beamset_items.dlgaddelement(labelboxGets)
	
	//GET BUTTONS ------------------------------------------------------------------------
	
	Taggroup setimage=dlgcreatepushbutton("Set", "setimagesetting")
	setimage.dlgexternalpadding(2,0).dlginternalpadding(15,0).dlgenabled(0).dlgidentifier("setImg")
	
	Taggroup setdiff=dlgcreatepushbutton("Set", "setdiffsetting")
	setdiff.dlgexternalpadding(2,0).dlginternalpadding(15,0).dlgenabled(0).dlgidentifier("setDiff")
	
	TagGroup labelboxSets=dlggroupitems(setimage, setdiff)
	labelboxsets.dlgtablelayout(2,1,0)
	beamset_items.dlgaddelement(labelboxsets)
	
	//BEAM BLANK CHECK ------------------------------------------------------------------
	
	checkBB = DLGCreateCheckbox("Beam Blanking",0, "checkBeBl")
	checkBB.DLGidentifier("checkBeamBlank")
	beamset_items.dlgaddelement(checkBB)	
	
	//------------------------------------------------------------------------------------
	
	//-----------------------------------------------------------------------------------
	//ACQUISITION
	//-----------------------------------------------------------------------------------
	TagGroup acquisitionADT_items
	TagGroup acquisitionADT=dlgcreatebox("Acquisition", acquisitionADT_items)
	//------------------------------------------------------------------------------------
	
	//CHECK DIFFRACTION IN ILLUMINATED AREA ----------------------------------------------
	
	TagGroup checkDiffAreaBut = DLGCreatePushButton("Check DPs in current area","diffCheckArea")
	checkDiffAreaBut.dlgexternalpadding(2,0).dlginternalpadding(8,0).dlgidentifier("diffCheckButton")
	acquisitionADT_items.dlgaddelement(checkDiffAreaBut)
	
	TagGroup stopCheckButton = DLGCreatePushButton("Stop checking ...","diffCheckStop")
	stopCheckButton.dlgexternalpadding(2,0).dlginternalpadding(8,0).dlgidentifier("stopdiffCheckButton").dlgenabled(0)
	acquisitionADT_items.dlgaddelement(stopCheckButton)
	
	//STORAGE PATH -----------------------------------------------------------------------
	
	TagGroup selpath=dlgcreatepushbutton("Data Name and Storage Directory", "selpath")
	selpath.dlgexternalpadding(2,0).dlginternalpadding(8,0)
	acquisitionADT_items.dlgaddelement(selpath)
	
	stoPath = DLGCreateStringField(storagePath,35).dlgidentifier("stoPath").dlgexternalpadding(2,0).dlgenabled(0)
	acquisitionADT_items.dlgaddelement(stoPath)
	//------------------------------------------------------------------------------------
	
	//BUTTONS ----------------------------------------------------------------------------
	
	TagGroup startSADTbutton = dlgcreatepushbutton("START", "startSADP")
	startSADTbutton.dlgexternalpadding(2,0).dlginternalpadding(8,0).dlgidentifier("startRef")
	TagGroup nextSADTbutton = dlgcreatepushbutton("Acquire", "nextSADP")
	nextSADTbutton.dlgexternalpadding(2,0).dlginternalpadding(4,0).dlgenabled(0).dlgidentifier("nextRef")
	
	TagGroup labelboxStartAcquisition=dlggroupitems(startSADTbutton, nextSADTbutton)
	labelboxStartAcquisition.dlgtablelayout(2,1,0)
	acquisitionADT_items.dlgaddelement(labelboxStartAcquisition)
	
	TagGroup stopbutton=dlgcreatepushbutton("STOP", "stopSADP")
	stopbutton.dlgexternalpadding(2,0).dlginternalpadding(8,0).dlgidentifier("stopRef").dlgenabled(0)
	TagGroup reacq=dlgcreatepushbutton("Re-acq. Ref. Img.", "reacquire")
	reacq.dlgexternalpadding(2,0).dlginternalpadding(4,0).dlgidentifier("reacqRef").dlgenabled(0)
	taggroup somecrazyshit=dlggroupitems(stopbutton, reacq)
	somecrazyshit.dlgtablelayout(2,1,0)
	acquisitionADT_items.dlgaddelement(somecrazyshit)
	
	//------------------------------------------------------------------------------------
	
	//FINAL AGGLOMERATION OF TAG GROUPS
	TagGroup boxoutput = dlggroupitems(boxSCOPE,beamsetting, imgOptics)
	TagGroup boxoutput2 = dlggroupitems(boxoutput, acquireCali, acquisitionADT)
	return boxoutput2
	//------------------------------------------------------------------------------------

}


// Initialise function
void init( object self, number ID ){
	// Create the thread and pass in the ID of the dialog, so that the thread can access the dialog's functions		
	Positioning = Alloc(Positioning)
	Positioning.LinkToDialog(ID)
	return
}

// Function to start the thread
void start( object self ){
	Positioning.init().StartThread("Start")
	return
}
	
// Function to stop the thread
void stop( object self ){
	Positioning.Stop()
	return
}	


void temOpt( object self, TagGroup tg ){

	if (DLGgetValue(temCheck) == 0){
		
		stemCheck.DLGValue(1)
		self.SetElementIsEnabled("shiftValor",0)
		self.SetElementIsEnabled("testShiftButton",0)
		self.SetElementIsEnabled("calibrateButton",0)
		self.SetElementIsEnabled("exposureImg",0)
		self.SetElementIsEnabled("insDF",1)
		self.SetElementIsEnabled("retDF",1)
		self.SetElementIsEnabled("insBF",1)
		self.SetElementIsEnabled("retBF",1)
		self.SetElementIsEnabled("diffCheckButton",0)
		self.SetElementIsEnabled("toImgModebut",0)
		self.SetElementIsEnabled("toDiffModebut",0)
	
	} else {
	
		stemCheck.DLGValue(0)
		self.SetElementIsEnabled("shiftValor",1)
		self.SetElementIsEnabled("testShiftButton",1)
		self.SetElementIsEnabled("calibrateButton",1)
		self.SetElementIsEnabled("exposureImg",1)
		self.SetElementIsEnabled("insDF",0)
		self.SetElementIsEnabled("retDF",0)
		self.SetElementIsEnabled("insBF",0)
		self.SetElementIsEnabled("retBF",0)
		self.SetElementIsEnabled("diffCheckButton",1)
		self.SetElementIsEnabled("toImgModebut",1)
		self.SetElementIsEnabled("toDiffModebut",1)
	
	}

}


void stemOpt( object self, TagGroup tg ){
	
	if (DLGgetValue(stemCheck) == 0) {
	
		temCheck.DLGValue(1)
		self.SetElementIsEnabled("shiftValor",1)
		self.SetElementIsEnabled("testShiftButton",1)
		self.SetElementIsEnabled("calibrateButton",1)
		self.SetElementIsEnabled("exposureImg",1)
		self.SetElementIsEnabled("insDF",0)
		self.SetElementIsEnabled("retDF",0)
		self.SetElementIsEnabled("insBF",0)
		self.SetElementIsEnabled("retBF",0)
		self.SetElementIsEnabled("diffCheckButton",1)
		self.SetElementIsEnabled("toImgModebut",1)
		self.SetElementIsEnabled("toDiffModebut",1)
		
	} else {
	
		temCheck.DLGValue(0)
		self.SetElementIsEnabled("shiftValor",0)
		self.SetElementIsEnabled("testShiftButton",0)
		self.SetElementIsEnabled("calibrateButton",0)
		self.SetElementIsEnabled("exposureImg",0)
		self.SetElementIsEnabled("insDF",1)
		self.SetElementIsEnabled("retDF",1)
		self.SetElementIsEnabled("insBF",1)
		self.SetElementIsEnabled("retBF",1)
		self.SetElementIsEnabled("diffCheckButton",0)
		self.SetElementIsEnabled("toImgModebut",0)
		self.SetElementIsEnabled("toDiffModebut",0)
	
	}

}


void gotoAngle( object self){
	
	currentAngle = EMGetStageAlpha()
	number moveToAngle = DLGgetValue(self.LookUpElement("gotoValue")) 
	if(moveToAngle < 70.1 && moveToAngle > -70.1){
		if(currentAngle > moveToAngle) {
			EMSetStageAlpha(moveToAngle-1)
		} else {
			EMSetStageAlpha(moveToAngle+1)
		}
		EMWaitUntilReady()
		EMSetStageAlpha(moveToAngle)
		self.SetElementisEnabled("undoAngle",1)
	} else {
		showAlert("The angle is too high or too low for this stage!",1)
	}

}


void undoAngle(object self){

	EMSetStageAlpha(currentAngle)
	number currentUndoValue = EMGetStageAlpha()
	if(currentAngle > currentUndoValue) {
		EMSetStageAlpha(currentAngle+1)
	} else {
		EMSetStageAlpha(currentAngle-1)
	}
	EMWaitUntilReady()
	EMSetStageAlpha(currentAngle)
	
	self.SetElementisEnabled("undoAngle",0)

}


void binningSelected( object self, TagGroup tg ){
	
	binValue = (2**(val(DLGgetStringValue(tg))-1))

}


void processingSelected( object self,  TagGroup tg){

	procValue = val(DLGgetStringValue(tg)) + (2*(2-val(DLGgetStringValue(tg))))

}


void acqDiffraction( object self){
	
	CM_StopCurrentCameraViewer( 1 )
	CameraPrepareForAcquire(camID)
	image acquiredImage := CameraAcquire(camID, DLGgetValue(self.LookUpElement("exposure")), binValue, binValue, procValue)
	setName(acquiredImage,"Diffraction pattern")
	showimage(acquiredImage)
	
}


void acqImage( object self){
	
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
	
		CM_StopCurrentCameraViewer( 1 )
		CameraPrepareForAcquire(camID)
		image acquiredImage := CameraAcquire(camID, DLGgetValue(self.LookUpElement("exposureImg")), binValue, binValue, procValue)
		setName(acquiredImage,"Image")
		showimage(acquiredImage)
		
	} else {
		
		DSInvokeButton(1)
		if (DSIsAcquisitionActive()  == 1) {
			DSInvokeButton(1)
			DSWaitUntilFinished( )
		}
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		DSInvokeButton(5,1)
		DSWaitUntilFinished( )
	
	}
	
}


void checkBeBl( object self, TagGroup tg){
	
	if (DLGgetValue(checkBB) == 0){
	
		EMSetBeamBlanked(0)
		Result("\nBeam restored.\n\n")
		Result("----------------------------------------------------------------------------------------------"+"\n")		

	} else {
	
		EMSetBeamBlanked(1)
		Result("\nBeam blanked.\n\n")
		Result("----------------------------------------------------------------------------------------------"+"\n")
		
	}

}

void initializepyTEMserver(object self){
	msgForPyTEMserv = "cmd.exe /cpython "
	msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"initiallize.py")
	LaunchExternalProcess(msgForPyTEMserv)
	setpersistentnumbernote("PyModuleInitialization",1)
}

void insDFdet(object self){
	getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
	if (toInitializePyModules==0){
		self.initializepyTEMserver()
	}
	msgForPyTEMserv = "cmd.exe /cpython "
	msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"DF_insert.py")
	LaunchExternalProcess(msgForPyTEMserv)
}


void retDFdet(object self){
	getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
	if (toInitializePyModules==0){
		self.initializepyTEMserver()
	}
	msgForPyTEMserv = "cmd.exe /cpython "
	msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"DF_retract.py")
	LaunchExternalProcess(msgForPyTEMserv)
}


void insBFdet(object self){
	getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
	if (toInitializePyModules==0){
		self.initializepyTEMserver()
	}
	msgForPyTEMserv = "cmd.exe /cpython "
	msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"BF_insert.py")
	LaunchExternalProcess(msgForPyTEMserv)
}


void retBFdet(object self){
	getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
	if (toInitializePyModules==0){
		self.initializepyTEMserver()
	}
	msgForPyTEMserv = "cmd.exe /cpython "
	msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"BF_retract.py")
	LaunchExternalProcess(msgForPyTEMserv)
}


void toImgModebut(object self){
	EMSetImagingOpticsMode("MAG1")
}


void toDiffModebut(object self){
	EMSetImagingOpticsMode("DIFF")
}


void scrUpFunc(object self){
	EMSetScreenPosition(2)
}

void scrDownFunc(object self){
	EMSetScreenPosition(0)
}


void testBeamShift (object self){
	
	number zerox, zeroy
	if (testEval == 0) {

		delta = DLGgetValue(self.LookUpElement("shiftValor"))	
		showAlert("Start the image preview and shift the beam at the center of the camera.\nThen, click again the 'Test Shift Value' Button",2)
		testEval = 1
		
	} else {
	
		EMGetBeamShift(zerox, zeroy)
		EMSetBeamShift(zerox+delta,zeroy)
		showAlert("Postive X-Beam Shift",2)
		EMSetBeamShift(zerox-delta,zeroy)
		showAlert("Negative X-Beam Shift",2)
		EMSetBeamShift(zerox,zeroy+delta)
		showAlert("Positive Y-Beam Shift",2)
		EMSetBeamShift(zerox, zeroy-delta)
		showAlert("Negative Y-Beam Shift",2)
		EMSetBeamShift(zerox,zeroy)
		showAlert("If the beam goes out of the field of view, reduce the 'Shift Value' parameter.",2)
		testEval = 0

	}
	
}


void caliBeamShift (object self){
	
	number answer = TwoButtonDialog("Shift the beam at the center of the fluorescent screen (avoid over saturation!)\nThen, you can press 'Ok' to start the Beam Shift Calibration.","Ok","Cancel")
		
	if(answer==1){
	
		number i, xsize, ysize, xfinal, yfinal, xinitial, yinitial, xpos3, ypos3, xpos4, ypos4, zerox, zeroy
		delta = DLGgetValue(self.LookUpElement("shiftValor"))
		number exposure = DLGgetValue(self.LookUpElement("exposure"))
		image Beam1, Beam2, Beam3, Beam4, Beam5, img
		imagedocument imgDoc
		
		checkBB.DLGValue(0)
		EMSetScreenPosition(2)
		CM_StopCurrentCameraViewer( 1 )
		EMWaitUntilReady()

		number shown=CountImageDocuments(WorkspaceGetActive()) 
		for(i=0; i<shown; ++i){
			
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0)
				
		}
		
		CameraPrepareForAcquire(camID)	
		Result("\nBeam Shift Calibration\n\n")
		EMGetBeamShift(zerox, zeroy)

		Beam1 := CameraAcquire(camID, 0.1, 1, 1, procValue)
		setName(Beam1,"Beam1")
		Result("1/5 Acquired Images: Non-shifted Beam.\n")
			
		EMSetBeamShift(zerox+delta,zeroy)
		EMWaitUntilReady()
		Beam2 := CameraAcquire(camID, 0.1, 1, 1, procValue)
		setName(Beam2,"Beam2")
		Result("2/5 Acquired Images: Positive X-Shifted Beam.\n")
			
		EMSetBeamShift(zerox-delta,zeroy)
		EMWaitUntilReady()
		Beam3 := CameraAcquire(camID, 0.1, 1, 1, procValue)
		setName(Beam3,"Beam3")		
		Result("3/5 Acquired Images: Negative X-Shifted Beam.\n")
			
		EMSetBeamShift(zerox,zeroy+delta)
		EMWaitUntilReady()
		Beam4 := CameraAcquire(camID, 0.1, 1, 1, procValue)
		setName(Beam4,"Beam4")
		Result("4/5 Acquired Images: Positive Y-Shifted Beam.\n")
					
		EMSetBeamShift(zerox,zeroy-delta)
		EMWaitUntilReady()	
		Beam5 := CameraAcquire(camID, 0.1, 1, 1, procValue)
		setName(Beam5,"Beam5")		
		Result("5/5 Acquired Images: Negative Y-Shifted Beam.\n\n")
			
		unitsStringRef = imagegetdimensionunitstring(Beam5,0)
		ImageGetDimensionCalibration(Beam5, 0, origin, scaleCali, unitsString, 1)
		
		checkBB.DLGValue(1)
		EMSetScreenPosition(0)
		EMSetBeamShift(zerox, zeroy)
		EMWaitUntilReady()
		
		//Cross-Correlations
		getSize(Beam1,xsize,ysize)
			
		image crosscorrimg = crossCorrelate(Beam1, Beam2)
		max(crosscorrimg, xfinal, yfinal)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xfinal, yfinal, 1)
		xfinal=-xfinal
		yfinal=-yfinal
			
		crosscorrimg = crossCorrelate(Beam1, Beam3)
		max(crosscorrimg, xinitial, yinitial)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xinitial, yinitial, 1)
		xinitial = -xinitial
		yinitial = -yinitial
		
		crosscorrimg = crossCorrelate(Beam1, Beam4)
		max(crosscorrimg, xpos3, ypos3)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xpos3, ypos3, 1)
		xpos3 = -xpos3
		ypos3 = -ypos3
		
		crosscorrimg = crossCorrelate(Beam1, Beam5)
		max(crosscorrimg, xpos4, ypos4)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xpos4, ypos4, 1)
		xpos4 = - xpos4
		ypos4 = - ypos4
			
		image sumImage = Beam1+Beam2+Beam3+Beam4+Beam5
		showImage(sumImage)
		imageDisplay vectordisp=sumImage.imageGetImageDisplay(0)
			
		//Arrow Draws from the X-corr of the acquired images
		component arrow=newarrowannotation(ysize/2, xsize/2, (yfinal+(ysize/2)), (xfinal+(xsize/2)))
		arrow.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow)
		Result("Positive X-Shifted Beam: ---> X-position: \t"+ xfinal + "\tY-position: \t"+yfinal+"\t"+"\n")

		component arrow2=newarrowannotation(ysize/2, xsize/2, (yinitial+(ysize/2)), (xinitial+(xsize/2)))
		arrow2.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow2)
		Result("Negative X-Shifted Beam: ---> X-position: \t"+ xinitial + "\tY-position: \t"+yinitial+"\t"+"\n")

		component arrow3=newarrowannotation(ysize/2, xsize/2, (ypos3+(ysize/2)), (xpos3+(xsize/2)))
		arrow3.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow3)
		Result("Positive Y-Shifted Beam: ---> X-position: \t"+ xpos3 + "\tY-position: \t"+ypos3+"\t"+"\n")

		component arrow4=newarrowannotation(ysize/2, xsize/2, (ypos4+(ysize/2)), (xpos4+(xsize/2)))
		arrow4.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow4)
		Result("Negative Y-Shifted Beam: ---> X-position: \t"+ xpos4 + "\tY-position: \t"+ypos4+"\t"+"\n\n")

		updateimage(sumImage)
		setName(sumImage,"Beam Shift Calibration")
		
		//Calculation of the two axes lengths and the angle between the horizontal and the positive x direction
		number modulLineX = sqrt( ((xinitial-xfinal)**2)+((yinitial-yfinal)**2) )
		number modulLineY = sqrt( ((xpos4-xpos3)**2)+((ypos4-ypos3)**2) )
	
		number calibrationX = ((2*delta)/modulLineX)/scaleCali
		number calibrationY = ((2*delta)/modulLineY)/scaleCali
		
		Result("Calibration in X-direction:\t"+(calibrationX)+" a.u./"+unitsStringRef+"\n")
		Result("Calibration in Y-direction:\t"+(calibrationY)+" a.u./"+unitsStringRef+"\n")

		number aveModu = (modulLineX + modulLineY)/2
		Result("Average Calibration:\t"+(((2*delta)/aveModu)/scaleCali)+" a.u./"+unitsStringRef+"\n\n")
			
		number rotAngle = (atan(abs(yfinal-yinitial)/abs(xfinal-xinitial)))*180/pi()
		Result("Angle\t" + rotAngle + "\n")
			
		if(xfinal>xinitial){
			
			if(yfinal>yinitial){
				
				rotAngle = 360 - rotAngle
					
			}
				
		} else {
			
			if(yfinal>yinitial){
			
				rotAngle = 180 + rotAngle
				
			} else {
			
				rotAngle = 180 - rotAngle
				
			}
			
		}
			
		Result("Real Angle:\t" + rotAngle + "\n\n")
			
		documentwindow textFile=NewScriptWindow("Beam Shift Calibrations", 50,50,150,450)
		editorWindowAddText(textFile,"Calibration X: "+format(calibrationX,"%3.4f")+"\n"+"Calibration Y: "+format(calibrationY,"%3.4f")+"\n"+"Angle for FrameWork Rotation: "+format(rotAngle, "%3.4f")+"\n")
		editorWindowAddText(textFile,"Calibration Scale: "+format(scaleCali,"%3.8f"))
		editorWindowSaveToFile(textFile,pathconcatenate(pathPDW,"BeamShiftCalibration.txt"))
		windowClose(textFile,0)
			
		showAlert("Beam Shift Calibration finalized.",2)
		Result("Beam Shift Calibration finalized.\n\n")
		Result("----------------------------------------------------------------------------------------------\n\n")
			
	} 

}


void getimagesetting (object self) {
	
	getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
	if (toInitializePyModules==0){
		self.initializepyTEMserver()
	}
	
	Result("Beam Setting for Imaging:\n")
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
	
		magImage = EMGetMagnification()
		EMWaitUntilReady()
		briImage = EMGetBrightness()
		EMWaitUntilReady()
		EMGetBeamShift(xbsImage, ybsImage)
		EMWaitUntilReady()
		self.SetElementisEnabled("setImg",1)
		
		Result("Magnification: "+magImage+"\n")
		Result("Intensity: "+briImage+"\n")
		Result("X-Shift: "+xbsImage+"\tY-Shift: "+ybsImage+"\n")		
	
	} else {
	
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"getCL2_img.py")
		LaunchExternalProcess(msgForPyTEMserv)
		scanCamLenImg = EMGetCameraLength()
		EMGetProjectorShift(scanImgProjX, scanImgProjY)
		EMWaitUntilReady()
		Result("CL2 value stored\n")
		Result("Camera Length: "+scanCamLenImg+"\n")
		Result("Projector shifts: "+scanImgProjX + "\t"+scanImgProjY+"\n")
		self.SetElementisEnabled("setImg",1)
	
	}
	
	Result("\n----------------------------------------------------------------------------------------------\n\n")
	checkImg = 1

}


void getdiffsetting (object self) {
	
	getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
	if (toInitializePyModules==0){
		self.initializepyTEMserver()
	}
	
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
	
		if (checkCamL == 0) {
		
			magDiff = EMGetMagnification()
			EMWaitUntilReady()
			briDiff = EMGetBrightness()
			EMWaitUntilReady()
			EMGetBeamShift(initialXposition, initialYposition)
			EMWaitUntilReady()
			
			Result("Beam setting for fiffraction:"+"\n\n")
			Result("Magnification: "+magDiff+"\n")
			Result("Intensity: "+briDiff+"\n")
			Result("X-Shift: "+initialXposition+"\t"+"Y-Shift: "+initialYposition+"\n")
			
			EMSetImagingOpticsMode("DIFF")
			showAlert("Select the camera length that you want to use in Diffraction mode and center the primary beam.\nSubsequently, press the 'Get' button again.",2)
			checkCamL = 1
		
		} else {
		
			cameraLength = EMGetMagIndex()
			EMWaitUntilReady()
			EMGetProjectorShift(xshiftProj,yshiftProj)
			EMWaitUntilReady()
			Result("Camera length: "+EMGetCameraLength()+"\n")
			Result("Projector shifts: "+xshiftProj+" "+yshiftProj+"\n") 
			Result("\n----------------------------------------------------------------------------------------------\n\n")
			checkCamL = 0
			checkDiff = 1
			EMSetImagingOpticsMode("MAG1")
			self.SetElementisEnabled("setDiff",1)
			
		}																														
	
	} else {
		
		initialXposition = 0
		initialYposition = 0
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"getCL2_diff.py")
		LaunchExternalProcess(msgForPyTEMserv)
		scanCamLenDiff = EMGetCameraLength()
		EMGetProjectorShift(scanDiffProjX, scanDiffProjY)
		EMWaitUntilReady()
		self.SetElementisEnabled("setDiff",1)
		diffSettingCheck = 0
		checkDiff = 1
		Result("Beam Setting for Diffraction:\n")
		Result("CL2 value stored\n")
		Result("Camera Length: "+scanCamLenDiff+"\n")
		Result("Projector shifts: "+scanDiffProjX + "\t"+scanDiffProjY+"\n")
		Result("----------------------------------------------------------------------------------------------\n\n")
		self.SetElementisEnabled("setDiff",1)
	
	}
}


void setimagesetting (object self){
	
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
	
		EMSetMagnification(magImage)
		EMWaitUntilReady()
		EMSetBrightness(briImage)
		EMWaitUntilReady()
		EMSetBeamShift(xbsImage, ybsImage)
		EMSetScreenPosition(2)
				
	} else {
		
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"insertDF_setCL2_img.py")
		LaunchExternalProcess(msgForPyTEMserv)
		EMSetCameraLength(scanCamLenImg)
		EMSetProjectorShift(scanImgProjX, scanImgProjY)
		EMWaitUntilReady()
		EMSetScreenPosition(0)
	
	}
	
}


void setdiffsetting (object self) {
	
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
		
		if (EMGetImagingOpticsMode() == "MAG1") {
			EMSetMagnification(magDiff)
			EMSetBrightness(briDiff)
			EMWaitUntilReady()
			EMSetBeamShift(initialXposition, initialYposition)
		} else {
		
			EMSetMagIndex(cameraLength)
			EMWaitUntilReady()
			EMSetProjectorShift(xshiftProj,yshiftProj)
		}
		EMSetScreenPosition(2)
		
	} else {
		
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"retractDF_setCL2_diff.py")
		LaunchExternalProcess(msgForPyTEMserv)
		EMSetCameraLength(scanCamLenDiff)
		EMSetProjectorShift(scanDiffProjX, scanDiffProjY)
		EMSetScreenPosition(2)
		
	}
	EMWaitUntilReady()

}


void selpath (object self) {

	string openpath

	if(SaveAsDialog("Select the Directory and RootName","Frame",openpath)){
	
		storagePath = pathextractdirectory(openpath, 0)
		nameDPs = PathExtractFilename(openpath,0)
		DLGValue(stoPath ,storagePath)
		Result("The storage path is:\t"+storagePath+"\n")
		Result("The rootname for the saved data is: "+nameDPs+"\n\n")
		Result("----------------------------------------------------------------------------------------------\n\n")
		
	} else {
	
	}	

}


void diffCheckArea (object self) {
	
	number exposureDiff = DLGgetValue(self.LookUpElement("exposure"))
	
	checkBB.DLGValue(0)
	CM_StopCurrentCameraViewer(1)
					 
	if (checkImg == 1 && checkDiff == 1) { 
		
		EMSetScreenPosition(2)
			
		//Close all displayed images
		number workspaceID = WorkspaceGetActive()
		number shown=CountImageDocuments(workspaceID)
		imagedocument imgDoc
		image img	
		for(number i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0)
		}
		
		//Image acquisition of the crystal at the initial tilt angle
		EMSetImagingOpticsMode("MAG1")
		EMWaitUntilReady()
		setimagesetting(self)
		image beamPositioningImage := CameraAcquire(camID, DLGgetValue(self.LookUpElement("exposureImg")), binValue, binValue, procValue)
		setName(beamPositioningImage,"Crystal Imaging")
		showimage(beamPositioningImage)
		Result("Reference area acquired\n")
		
		//Setting for diffraction and beam retrieval from camera as reference
		setdiffsetting(self)
		image checkDiffBeamPos := CameraAcquire(camID, 0.2, binValue, binValue, procValue)
		EMGetBeamShift(initialXposition, initialYposition)
		number xsize, ysize
		number imgSum = sum(checkDiffBeamPos)
		getsize(checkDiffBeamPos,xsize,ysize)
		image xproj = RealImage("",4,xsize,1)
		xproj[icol,0]+=checkDiffBeamPos
		image invImg = RealImage("",4,ysize,xsize)
		invImg = checkDiffBeamPos[irow,icol]
		image yproj = RealImage("",4,ysize,1)
		yproj[icol,0]+=invImg
		yproj=yproj*(icol+1)
		xproj=xproj*(icol+1)
		initialXBeam=sum(xproj)
		initialYBeam=sum(yproj)
		initialXBeam=(initialXBeam/imgSum)-1
		initialYBeam=(initialYBeam/imgSum)-1
		
		component ovalTheRoi = NewOvalAnnotation(initialYBeam-50, initialXBeam-50, initialYBeam+50, initialXBeam+50)
		ovalTheRoi.ComponentSetSelectable(0)
		ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
		component labelTheRoi = NewTextAnnotation( 0,0, "Beam", 75)
		labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
		labelTheRoi.ComponentSetForeGroundColor( 1, 0.0, 0.0 )
		labelTheRoi.ComponentSetSelectable(0)
		labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
		labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
		theroi = NewGroupAnnotation()
		theroi.ComponentAddChildAtEnd(ovalTheRoi)
		theroi.ComponentAddChildAtEnd(labelTheRoi)
		imagedisplay imgdisp = beamPositioningImage.ImageGetImageDisplay(0)
		imgdisp.ComponentAddChildAtEnd(theroi)

		scanison=1
		self.start()
			
		EMSetImagingOpticsMode("DIFF")
		EMWaitUntilReady()
		setdiffsetting(self)
		
		CM_StartCameraViewer(camera, viewParams, 1, 1)
		
		number isViewImgDisplayed=CountImageDocuments(workspaceID)
		while(isViewImgDisplayed == 1){
			isViewImgDisplayed=CountImageDocuments(workspaceID)
		}
		WorkspaceArrange(workspaceID,0,0)
		self.SetElementisEnabled("diffCheckButton",0)
		self.SetElementisEnabled("stopdiffCheckButton",1)
		self.SetElementisEnabled("startRef",0)
		Result("Detector ready for diffraction check ...\n")
		
	} else {
		
		showAlert("You have to get the beam settings for Imaging and Diffraction before using this option.",1)
		
	}
	
}


void diffCheckStop (object self) {
	
	//Close all displayed images
	number shown=CountImageDocuments(WorkspaceGetActive())
	imagedocument imgDoc
	image img	
	for(number i=0; i<shown; ++i){
		imgDoc=getImageDocument(0)
		img:=getFrontImage()
		imageDocumentClose(imgdoc,0)
	}
	
	EMSetImagingOpticsMode("MAG1")
	EMWaitUntilReady()
	scanison=0
	self.stop() //To stop the beam registration
	setimagesetting(self)
	self.SetElementisEnabled("diffCheckButton",1)
	self.SetElementisEnabled("stopdiffCheckButton",0)
	self.SetElementisEnabled("startRef",1)
	Result("\n----------------------------------------------------------------------------------------------\n\n")
	
}


void startSADP (object self) {
	
	checkBB.DLGValue(0)
	CM_StopCurrentCameraViewer(1)
	
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
		
		//TEM mode
		if (checkImg == 1 && checkDiff == 1) { 
		
			EMSetScreenPosition(2)
			Result("TEM-ADT Acquisition Started ..." + "\n\n")
			
			//Close all displayed images
			number workspaceID = WorkspaceGetActive()
			number shown=CountImageDocuments(workspaceID)
			imagedocument imgDoc
			image img	
			for(number i=0; i<shown; ++i){
				imgDoc=getImageDocument(0)
				img:=getFrontImage()
				imageDocumentClose(imgdoc,0)
			}
			
			//Image acquisition of the crystal at the initial tilt angle
			EMSetStageAlpha(DLGgetValue(self.LookUpElement("initialAngleCall")))
			EMWaitUntilReady()
			EMSetImagingOpticsMode("MAG1")
			EMWaitUntilReady()
			self.setimagesetting()
			image beamPositioningImage := CameraAcquire(camID, DLGgetValue(self.LookUpElement("exposureImg")), binValue, binValue, procValue)
			setName(beamPositioningImage,"Crystal Imaging")
			showimage(beamPositioningImage)
			Result("Crystal image 1 acquired\n")
			
			//Setting for diffraction and beam retrieval from camera as reference
			setdiffsetting(self)
			image checkDiffBeamPos := CameraAcquire(camID, 0.2, binValue, binValue, procValue)
			EMGetBeamShift(initialXposition, initialYposition)
			number xsize, ysize
			number imgSum = sum(checkDiffBeamPos)
			getsize(checkDiffBeamPos,xsize,ysize)
			image xproj = RealImage("",4,xsize,1)
			xproj[icol,0]+=checkDiffBeamPos
			image invImg = RealImage("",4,ysize,xsize)
			invImg = checkDiffBeamPos[irow,icol]
			image yproj = RealImage("",4,ysize,1)
			yproj[icol,0]+=invImg
			yproj=yproj*(icol+1)
			xproj=xproj*(icol+1)
			initialXBeam=sum(xproj)
			initialYBeam=sum(yproj)
			initialXBeam=(initialXBeam/imgSum)-1
			initialYBeam=(initialYBeam/imgSum)-1
			
			component ovalTheRoi = NewOvalAnnotation(initialYBeam-50, initialXBeam-50, initialYBeam+50, initialXBeam+50)
			ovalTheRoi.ComponentSetSelectable(0)
			ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
			component labelTheRoi = NewTextAnnotation( 0,0, "Beam", 75)
			labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
			labelTheRoi.ComponentSetForeGroundColor( 1, 0.0, 0.0 )
			labelTheRoi.ComponentSetSelectable(0)
			labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
			labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
			theroi = NewGroupAnnotation()
			theroi.ComponentAddChildAtEnd(ovalTheRoi)
			theroi.ComponentAddChildAtEnd(labelTheRoi)
			imagedisplay imgdisp = beamPositioningImage.ImageGetImageDisplay(0)
			imgdisp.ComponentAddChildAtEnd(theroi)

			scanison=1
			self.start()
			
			EMSetImagingOpticsMode("DIFF")
			EMWaitUntilReady()
			self.setdiffsetting()
			Result("Detector ready for DP acquisition ...\n")
					
			showAlert("Position the ROI cercle from where you want to acquire the DP. Subsequently press the 'Acquire' button.",2)	
			
			stepAcquisition = 1
			self.SetElementisEnabled("reacqRef",1)
			self.SetElementisEnabled("startRef",0)
			self.SetElementisEnabled("nextRef",1)
			self.SetElementisEnabled("stopRef",1)
			self.SetElementIsEnabled("temOption",0)
			self.SetElementIsEnabled("temOption",0)
			self.SetElementisEnabled("reacqRef",1)
			
		} else {
		
			showAlert("You have to get the beam settings for Imaging and Diffraction before starting an acquisition.",1)
		
		}
	
	//STEM mode
	} else {

		if (checkImg == 1 && checkDiff == 1) {
			
			EMSetScreenPosition(0)
			Result("STEM-ADT Acquisition started\n\n")
			
			//Close all displayed images
			number shown=CountImageDocuments(WorkspaceGetActive()) 
			imagedocument imgDoc
			image img	
			for(number i=0; i<shown; ++i){
				imgDoc=getImageDocument(0)
				img:=getFrontImage()
				imageDocumentClose(imgdoc,0)
			}
			
			EMSetStageAlpha(DLGgetValue(self.LookUpElement("initialAngleCall")))
			self.setimagesetting()
			roi circleroi = NewROI()
			
			DSInvokeButton(1)
			if (DSIsAcquisitionActive()  == 1) {
				DSInvokeButton(1)
				DSWaitUntilFinished( )
			}
			DSInvokeButton(3)
			DSWaitUntilFinished( )
			DSInvokeButton(5,1)
			DSWaitUntilFinished( )
			
			refDSImg := getFrontImage()
			setName(refDSImg,"Frame 1: Drag the ROI to the targeted diffractive area")
			roisetcircle(circleroi,256,256,15)
			imagedisplay imgdisp = refDSimg.ImageGetImageDisplay(0)
			imgdisp.ImageDisplayAddRoi(circleroi)
			imageDisplaySetRoiSelected(imgdisp, circleroi,1)
			showAlert("Drag the circle ROI to the desired diffractive area.\nSubsequently press the 'Acquire' button\n\nCaution: The labelled beam ROI is the current position of the beam.",2)
			
			self.SetElementisEnabled("startRef",0)
			self.SetElementisEnabled("nextRef",1)
			self.SetElementisEnabled("stopRef",1)
			self.SetElementIsEnabled("temOption",0)
			self.SetElementIsEnabled("stemOption",0)
			self.SetElementisEnabled("reacqRef",1)
			stepAcquisition = 1	
		
		} else {
		
			showAlert("You have to get the beam settings for Imaging and Diffraction before starting an acquisition.",1)
		
		}

	}

}


void nextSADP (object self) {

	number shown, currentAngle, i, yDSposition, xDSposition
	number startingAngle = DLGgetValue(self.LookUpElement("initialAngleCall"))
	number tiltStep = DLGgetValue(self.LookUpElement("stepCall"))
	number endAngle = DLGgetValue(self.LookUpElement("finalAngleCall"))
	number exposureImage = DLGgetValue(self.LookUpElement("exposureImg"))
	number exposureDiff = DLGgetValue(self.LookUpElement("exposure"))
	image img
	image beamPositioningImage := IntegerImage("Image - Beam Positioning", 4, 0, widthCam/binValue, heightCam/binValue)
	image checkDiffBeamPos := IntegerImage("", 4, 0, widthCam/binValue, heightCam/binValue)
	image DP := IntegerImage("FastADT Data", 4, 0, widthCam/binValue, heightCam/binValue)
	string currentDPname
	imagedocument imgDoc	

	CM_StopCurrentCameraViewer(1)
	
	//TEM mode
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
	
		if (stepAcquisition == 1){
			
			scanison=0
			self.stop()
			
			shown=CountImageDocuments(WorkspaceGetActive())
			for(i=0; i<shown; ++i){
				imgDoc=getImageDocument(0)
				img:=getFrontImage()
				imageDocumentClose(imgdoc,0)	
			}

			DP := CameraAcquire(camID, exposureDiff, binValue, binValue, procValue)
			showimage(DP)
			currentDPname = nameDPs + "_" + index
			setName(DP,currentDPname)
			saveasgatan3(DP,pathconcatenate(storagePath,currentDPname))
			
			EMSetImagingOpticsMode("MAG1")
			EMWaitUntilReady()
			self.setimagesetting()
			
			currentAngle = EMGetStageAlpha()
			Result(index+"/"+(((endAngle-startingAngle)/tiltStep)+1)+" - "+currentDPname+"\tAlpha angle: "+currentAngle+"\n")
			
			if (startingAngle+(tiltStep*index) <= endAngle) {

				EMSetStageAlpha(startingAngle+(tiltStep*index))
				EMWaitUntilReady()
				index+=1
				beamPositioningImage := CameraAcquire(camID, exposureImage, binValue, binValue, procValue)
				showimage(beamPositioningImage)
				setName(beamPositioningImage,"Crystal Imaging")
				Result("Crystal Image " + index +" acquired. "+"\n")
				WorkspaceArrange(WorkspaceGetActive(),0,0)
				
				self.setdiffsetting()
				checkDiffBeamPos := CameraAcquire(camID, 0.2, binValue, binValue, procValue)
				EMGetBeamShift(initialXposition, initialYposition)
				number xsize, ysize
				number imgSum = sum(checkDiffBeamPos)
				getsize(checkDiffBeamPos,xsize,ysize)
				image xproj = RealImage("",4,xsize,1)
				xproj[icol,0]+=checkDiffBeamPos
				image invImg = RealImage("",4,ysize,xsize)
				invImg = checkDiffBeamPos[irow,icol]
				image yproj = RealImage("",4,ysize,1)
				yproj[icol,0]+=invImg
				yproj=yproj*(icol+1)
				xproj=xproj*(icol+1)
				initialXBeam=sum(xproj)
				initialYBeam=sum(yproj)
				initialXBeam=(initialXBeam/imgSum)-1
				initialYBeam=(initialYBeam/imgSum)-1
				
				component ovalTheRoi = NewOvalAnnotation(initialYBeam-50, initialXBeam-50, initialYBeam+50, initialXBeam+50)
				ovalTheRoi.ComponentSetSelectable(0)
				ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
				component labelTheRoi = NewTextAnnotation( 0,0, "Beam", 75)
				labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
				labelTheRoi.ComponentSetForeGroundColor( 1, 0.0, 0.0 )
				labelTheRoi.ComponentSetSelectable(0)
				labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
				labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
				theroi = NewGroupAnnotation()
				theroi.ComponentAddChildAtEnd(ovalTheRoi)
				theroi.ComponentAddChildAtEnd(labelTheRoi)
				imagedisplay imgdisp = beamPositioningImage.ImageGetImageDisplay(0)
				imgdisp.ComponentAddChildAtEnd(theroi)
				scanison=1
				self.start()
				
				EMSetImagingOpticsMode("DIFF")
				EMWaitUntilReady()
				self.setdiffsetting()
				Result("Detector ready for DP acquisition ..."+"\n")
				
			} else {
				
				checkBB.DLGValue(1)
				EMSetScreenPosition(0)
				showAlert("Congratulations! All your diffraction data has been acquired and saved!",2)		
				self.SetElementisEnabled("startRef",1)
				self.SetElementisEnabled("nextRef",0)
				self.SetElementisEnabled("stopRef",0)
				self.SetElementisEnabled("reacqRef",0)
				Result("\nAcquisition Finalized.\n\n")
				Result("\n----------------------------------------------------------------------------------------------\n\n")
				index = 1
				self.SetElementIsEnabled("temOption",1)
				self.SetElementIsEnabled("stemOption",1)
				stepAcquisition = 0
				
			}	
		
		}
	
	//STEM mode
	} else {

		if (stepAcquisition == 1){
			
			shown=CountImageDocuments(WorkspaceGetActive())
			image refImg, positionImg
			string evalName
			for(i=0; i < shown; i++){
				imgDoc=getImageDocument(i)
				imageDocumentShow(imgDoc)
				refImg := getFrontImage()
				getName(refImg,evalName)
				if (evalName == ("Frame "+index+": Drag the ROI to the targeted diffractive area")) {
					positionImg := refImg
				}
			}
			
			number roi_top, roi_left, roi_bottom, roi_right
			imagedisplay imgdisp=positionImg.imageGetImageDisplay(0)
			roi theroi=imgdisp.imageDisplayGetRoi(0)
			roigetoval(theroi, roi_top, roi_left, roi_bottom, roi_right)
			xDSposition = roi_left+((roi_right-roi_left)/2)
			yDSposition = roi_top+((roi_bottom-roi_top)/2)
			
			CM_StopCurrentCameraViewer( 1 )
			
			shown=CountImageDocuments(WorkspaceGetActive())
			for(i=0; i<shown; ++i){
				imgDoc=getImageDocument(0)
				img:=getFrontImage()
				imageDocumentClose(imgdoc,0)	
			}
			
			self.setdiffsetting()
			DSPositionBeam(refDSimg, xDSposition, yDSposition)
			DSWaitUntilFinished()
			DP := CameraAcquire(camID, exposureDiff, binValue, binValue, procValue)
			DSPositionBeam(refDSimg, 510, 510)
			showimage(DP)
			currentDPname = nameDPs + "_" + index
			setName(DP, currentDPname)
			saveasgatan3(DP,pathconcatenate(storagePath,currentDPname))
			currentAngle = EMGetStageAlpha()
			Result(index+"/"+(((endAngle-startingAngle)/tiltStep)+1)+" - "+currentDPname+" acquired and saved. Angle: "+currentAngle+"\n")
			self.setimagesetting()
			
			if (round(currentAngle+tiltStep) < endAngle) {
			
				roi circleroi = NewROI()
				EMSetStageAlpha(startingAngle+(tiltStep*index))
				EMWaitUntilReady()
				index+=1
				EMSetScreenPosition(0)
				EMWaitUntilReady()
				
				if (DSIsAcquisitionActive()  == 1) {
					DSInvokeButton(1)
					DSWaitUntilFinished( )
				}
				DSInvokeButton(3)
				DSWaitUntilFinished( )
				DSInvokeButton(5,1)
				DSWaitUntilFinished( )
				
				refDSImg := getFrontImage()
				setName(refDSImg,"Frame "+index+": Drag the ROI to the targeted diffractive area")
				roisetcircle(circleroi,xDSposition,yDSposition,15)
				imagedisplay imgdisp = refDSimg.ImageGetImageDisplay(0)
				imgdisp.ImageDisplayAddRoi(circleroi)
				imageDisplaySetRoiSelected(imgdisp, circleroi,1)
				WorkspaceArrange(WorkspaceGetActive(),0,0)
			

			} else {
				
				checkBB.DLGValue(1)
				EMSetScreenPosition(0)
				showAlert("Congratulations! All your diffraction data has been acquired and saved!",2)
				self.SetElementisEnabled("startRef",1)
				self.SetElementisEnabled("nextRef",0)
				self.SetElementisEnabled("stopRef",0)
				self.SetElementisEnabled("reacqRef",0)
				Result("\nAcquisition Finalized.\n")
				Result("\n----------------------------------------------------------------------------------------------\n\n")
				index = 1
				self.SetElementIsEnabled("temOption",1)
				self.SetElementIsEnabled("stemOption",1)
				stepAcquisition = 0
				
			}	

		}
 
	}

}


void reacquire (object self) {
	
	//TEM mode
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0) {
	
		scanison=0
		self.stop()
		delay(60)
		
		number shown=CountImageDocuments(WorkspaceGetActive())
		image img	
		imagedocument imgDoc
		for(number i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0) 	
		}
			
		//Acquisition of image
		EMSetImagingOpticsMode("MAG1")
		EMWaitUntilReady()
		self.setimagesetting()
		number exposureImage = DLGgetValue(self.LookUpElement("exposureImg"))
		image beamPositioningImage := CameraAcquire(camID, exposureImage, binValue, binValue, procValue)
		setName(beamPositioningImage,"Crystal Imaging")
		showimage(beamPositioningImage)
		
		//Diffraction setting and beam retrieval
		self.setdiffsetting()
		image checkDiffBeamPos := CameraAcquire(camID, 0.1, binValue, binValue, procValue)
		number xsize, ysize
		number imgSum = sum(checkDiffBeamPos)
		getsize(checkDiffBeamPos,xsize,ysize)
		image xproj = RealImage("",4,xsize,1)
		xproj[icol,0]+=checkDiffBeamPos
		image invImg = RealImage("",4,ysize,xsize)
		invImg = checkDiffBeamPos[irow,icol]
		image yproj = RealImage("",4,ysize,1)
		yproj[icol,0]+=invImg
		yproj=yproj*(icol+1)
		xproj=xproj*(icol+1)
		initialXBeam=sum(xproj)
		initialYBeam=sum(yproj)
		initialXBeam=(initialXBeam/imgSum)-1
		initialYBeam=(initialYBeam/imgSum)-1
			
		component ovalTheRoi = NewOvalAnnotation(initialYBeam-50, initialXBeam-50, initialYBeam+50, initialXBeam+50)
		ovalTheRoi.ComponentSetSelectable(0)
		ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
		component labelTheRoi = NewTextAnnotation( 0,0, "Beam", 75)
		labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
		labelTheRoi.ComponentSetForeGroundColor( 1, 0.0, 0.0 )
		labelTheRoi.ComponentSetSelectable(0)
		labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
		labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
		theroi = NewGroupAnnotation()
		theroi.ComponentAddChildAtEnd(ovalTheRoi)
		theroi.ComponentAddChildAtEnd(labelTheRoi)
		imagedisplay imgdisp = beamPositioningImage.ImageGetImageDisplay(0)
		imgdisp.ComponentAddChildAtEnd(theroi)
		
		EMSetImagingOpticsMode("DIFF")
		EMWaitUntilReady()
		EMSetMagIndex(cameraLength)
		EMSetProjectorShift(xshiftProj,yshiftProj)
		EMWaitUntilReady()
		
		scanison=1
		self.start()
	
	//STEM mode
	} else {
	
		number shown=CountImageDocuments(WorkspaceGetActive())
		image img	
		imagedocument imgDoc
		for(number i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0)
		}
		
		self.setimagesetting()
		roi circleroi = NewROI()
		
		if (DSIsAcquisitionActive()  == 1) {
			DSInvokeButton(1)
			DSWaitUntilFinished( )
		}
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		DSInvokeButton(5,1)
		DSWaitUntilFinished( )
		
		refDSImg := getFrontImage()
		setName(refDSImg,"Frame "+index+": Drag the ROI to the targeted diffractive area")
		roisetcircle(circleroi,256,256,15)
		imagedisplay imgdisp = refDSimg.ImageGetImageDisplay(0)
		imgdisp.ImageDisplayAddRoi(circleroi)
		imageDisplaySetRoiSelected(imgdisp, circleroi,1)

	}
	
}


void stopSADP (object self) {
	
	EMSetScreenPosition(0)
	if (DLGgetValue(self.LookUpElement("stemOption")) == 0){
		EMSetImagingOpticsMode("MAG1")
		EMWaitUntilReady()
		scanison=0
		self.stop()
	}
	index = 1
	self.SetElementisEnabled("startRef",1)
	self.SetElementisEnabled("stopRef",0)
	self.SetElementisEnabled("nextRef",0)
	self.SetElementisEnabled("reacqRef",0)
	self.SetElementIsEnabled("temOption",1)
	self.SetElementIsEnabled("stemOption",1)
	checkBB.DLGValue(1)

	self.setimagesetting()
	Result("\n(S)TEM-ADT Acquisition Stopped\n\n")
	Result("\n----------------------------------------------------------------------------------------------\n\n")

}

//GUI constructor
ADTAcquisitionDialog( object self ){
	ScanIsOn = 0
	self.super.init( self.MakeButtons() )
	number dialogID=self.ScriptObjectGetID()
}

//GUI destructor
~ADTAcquisitionDialog( object self ){
	getPersistentNumberNote("pyTEMserverStatus",pyTEMServerState)
	if (pyTEMServerState == 1) {
		number answerForPyTEM = OkCancelDialog("Do you want to shut down the pyTEM server?")
		if (answerForPyTEM == 1) {
			string msgForPyTEMserv = "cmd.exe /cpython "
			msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"closeServer.py")
			LaunchExternalProcess(msgForPyTEMserv)
			setPersistentNumberNote("pyTEMserverStatus",0)
			setPersistentNumbernote("PyModuleInitialization",0)
			Result("pyTEM server shut down.\n")
		}
	}
	Result("(S)TEM-ADT closed.\n")
	If( ScanIsOn ) 
	self.Stop()	// stop scan before UI destruction		
	if(self.ScriptObjectIsValid()) {
		number dialogID=self.ScriptObjectGetID()
	}
}

}

// Create the GUI
void CreateTEMADTControlDialog(){
	
	object ADTAcquisitionDialog = Alloc(ADTAcquisitionDialog)
	ADTAcquisitionDialog.Display("(S)TEM-ADT v3.4")
	number dialogID=ADTAcquisitionDialog.ScriptObjectGetID()
	ADTAcquisitionDialog.init(dialogID)	
	Return
	
}

// Open the GUI
CreateTEMADTControlDialog()
Result("\n"+"-------------------------------------------------------------------------------------------------------------------------------------\n")
Result("(S)TEM-Automated 3D ED Acquisition v3.4, S. Plana Ruiz, Universitat Rovira i Virgili, TU-Darmstadt, JGU-Mainz & UB, April 2024.\n\n")
Result("Path for Reference/Storage Files:" +"\t" + pathPDW +"\n")
Result("Size of used camera: "+widthCam+" x "+heightCam+" pixels\n")
getPersistentNumberNote("pyTEMserverStatus",pyTEMServerState)
if (pyTEMServerState == 0) {
	msgPyTEMserv = "cmd.exe /k python "
	msgPyTEMserv += pathconcatenate(pyTEMserverLocation,"createServer.py")
	LaunchExternalProcessAsync(msgPyTEMserv)
	setPersistentNumberNote("pyTEMserverStatus",1)
	setPersistentNumbernote("PyModuleInitialization",0)
	Result("pyTEM server started\n")
} else {
	Result("pyTEM server was already running\n")
}
Result("-------------------------------------------------------------------------------------------------------------------------------------\n\n")