//Fast-ADT Acquisition v3.5, S. Plana Ruiz, Universitat Rovira i Virgili, TU Darmstadt, JGU Mainz & UB, April 2024.

// Global variables ----------------------------------------------------------------------------

TagGroup crtString, checkContinuous, checkDiscrete, checkTEM, checkDS, checkBB, stopADTacq, imgIcon, diffIcon, valorExposicio, checkProjDScorr
number evalBeamShift=0, crystTrackEval, indexMiddle, totalNumberOfImages, steps, procValue=3, binValue=1, delta, origin, scaleCali, originProj 
number x_after, x_before, y_after, y_before, refTiltStep, partContinue=0, beamDiamRef=0, ProjShiftDSCounter = 0, projDSeval = 0
number caliCounter=0, evalDiffShift=0, scaleCaliReciprocal, iniPosRef=0, initialBeamPosX, initialBeamPosY 
number beamSize=0, beamScanningSize=0, stopParameter=0, initialAngleThread, lastAngleThread, velocityThread, stepAngleThread, realBeSi
number exposureThread, continuousThread, DSThread, angleAra, initialBeamPosX_2, initialBeamPosX_3, initialBeamPosY_2, initialBeamPosY_3
number bsXtemImg, bsYtemImg, bsXtemDiff, bsYtemDiff, center_x, center_y, calibrationX, calibrationY, rotAngle, deltaDiff, Xshift, Yshift 
number scaleCaliRefImages,  Xshift2, Yshift2, Xshift3, Yshift3, widthCam, heightCam, scaleCaliProj, scaleCaliProjDS, ProjShiftCounter=0
number scanCamLenImg, scanCamLenDiff, scanImgProjX, scanImgProjY, scanDiffProjX, scanDiffProjY, originDSforProjRef, scaleCaliDSforProjRef
number originProjRef, scaleCaliProjRef, pyTEMServerState, toInitializePyModules, calMagBeamSize
image refDSimg 
string path, unitsString, unitsStringRef, unitsStringReciprocal, unitsStringRefReciprocal, unitsStringProj, unitsStringRefProj
string unitsStringRefProjDS, unitsStringProjDS, unitsStringDSforProjRef, unitsStringProjRef, msgForPyTEMserv, msgPyTEMserv
string Manufacturer, magNeeded, pixelCaliBeamSize
ROI roi_before, roi_after, roiBeamPosition = newroi()

//Lines to define the path to read/save references and python/pyJEM scripts -------------------

string drivestring = "X:"
string folderstring = "FastADT_Storage"
string pathPDW = pathconcatenate(drivestring,folderstring)
image imgGreLED := openimage(pathconcatenate(pathPDW,"greenLED.jpg"))
image nonActiveLED := openimage(pathconcatenate(pathPDW,"nonActiveLED.jpg"))
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
	showAlert("The configuration file is not created or available,",2)
}

//Different Acquisition modes ----------------------------------------------------------

setPersistentNumberNote("acqMode",1)
setPersistentNumberNote("pixSel",1)
setPersistentNumberNote("tomoSel",2)

//Get Active Camera ID and Camera size ------------------------------------------------

object camera=CM_GetCurrentCamera()
number camID = CameraGetActiveCameraID()
CM_CCD_GetSize(camera, widthCam, heightCam)

//--------------------------------------------------------------------------------------

//Thread object which sets the beam positioning (executed in the background)
Class Positioning:Thread{
	
 	Object StartSignal
 	Object StopSignal
 	number DialogID, m_DataListenerID
 	image m_img

	//Initialize boolean constants and signals
	object init( object self ){
		StartSignal = NewSignal(0)
		StopSignal = NewSignal(0)
		return self
	}

	//Stop signal for the thread
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
		imagedisplay imgdisp = refImg.ImageGetImageDisplay(0)
		roiBeamPosition=imgdisp.imageDisplayGetRoi(0)
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
										
					roigetoval(roiBeamPosition, roi_top, roi_left, roi_bottom, roi_right)
					currentX = roi_left+((roi_right-roi_left)/2)
					currentY = roi_top+((roi_bottom-roi_top)/2)
					shiftX = ((cos(rotAngle*pi()/180)*(currentX-center_x)) + (sin(rotAngle*pi()/180)*(-(currentY-center_y))))*calibrationX*scaleCali
					shiftY = ((-sin(rotAngle*pi()/180)*(currentX-center_x)) + (cos(rotAngle*pi()/180)*(-(currentY-center_y))))*calibrationY*scaleCali
					EMSetBeamShift(bsXtemDiff+shiftX, bsYtemDiff+shiftY)
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

}

//Thread to change calibration of an image for beam size identification in STEM mode
Class caliImageChange:Thread{
	
	image m_img
	number m_dataListenerID, DialogID
	
	void LinkToDialog(object self, number ID){
		DialogID=ID
	}
	
	object init( object self ){
		return self
	}
	
	void DataChanged(object self, Number change, Image img){
	}

	void Start(object self){
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


//Thread for the 3D ED acquisition
Class ed3dAcqBackground:Thread{
	
	number DialogID
	
	void LinkToDialog(object self, number ID){
		DialogID=ID
	}
	
	object init( object self ){
		return self
	}
	
	void Start(object self){
	
		number referencia, evaluadorText, angularRangeEval, width, height, initialTime, stepInPixels
		number finalTime, experimentTime, initialAngleText, lastAngleText, filereference, answer, currentLastAngle
		number compX, compY, xDS, yDS, nonUsedVar, modeOfAcq, numTomos, iniTimePerDP, indMuTo=1
		number scanNum, indAcquisition, refX, refY, idxStack=0, indX, indY, scanStepX, scanStepY
		number xProjFinal, yProjFinal, xProjShift, yProjShift, xProjDSShift, yProjDSShift, rotAngleProj, rotAngleProjDS
		number calibrationProjDSX, calibrationProjDSY, calibrationProjX, calibrationProjY, dssizex, dssizey
		string calibrationPartX, calibrationPartY, rotationAngle, thisline
		image caliImg, ADTstack, updImg
		imagedocument imgdoc
		documentwindow edInfoFile

		getPersistentNumberNote("Referencia Text",referencia)
		getPersistentNumberNote("Evaluar Text",evaluadorText)
		
		if (evaluadorText == 0){
		
			OKdialog("You have to load the Crystal Tracking file before starting the experiment.")
			exit(0)
			
		}
		
		string part1 = "Are you sure that the parameters used for the creation of the Crystal Tracking file"
		string part2 = " are the same as the ones in the 'Parameters Setup' box?"
		answer = twoButtonDialog(part1+part2,"Yes","No")
		
		if(answer==1){
		
			nonUsedVar = readFileLine(referencia, thisline)
			initialAngleText=val(right(thisline,len(thisline)-14))
			nonUsedVar = readFileLine(referencia, thisline)
			lastAngleText = val(right(thisline,len(thisline)-12))
			
			CM_StopCurrentCameraViewer(1)
			EMSetScreenPosition(2)
			
			if (initialAngleThread == initialAngleText && lastAngleThread == lastAngleText){
			
				if(evaluadorText == 1){
			
					if(lastAngleThread < 71 && lastAngleThread > -71){
						
						Result("Starting...\n")
						width = widthCam/binValue
						height = heightCam/binValue
						
						CameraPrepareForAcquire(camID)
						ADTStack := CameraCreateImageForAcquire(camID, binValue, binValue, procValue)
						
						getPersistentNumberNote("acqMode",modeOfAcq)
						getPersistentNumberNote("tomoSel",numTomos)
						
						Result("FastADT - ")
						
						if (modeOfAcq == 2 && continuousThread == 0) {
							Result("Simultaneous Precession On/Off Mode"+"\n")
							ImageResize(ADTStack, 3, width, height, 2*steps)
						} else if (modeOfAcq == 4 && continuousThread == 0) {
							Result("Scanned Area Mode\n")
							getPersistentNumberNote("pixSel",scanNum)
							indAcquisition = sqrt(scanNum)
							indX = -((indAcquisition-1)/2)
							indY = indX
							ImageResize(ADTStack, 3, width, height, scanNum*steps)
							if (DSThread == 1) {
								if (unitsString == "nm") {
									stepInPixels = (realBeSi/2)/scaleCali
								} else if (unitsString == "µm") {
									stepInPixels = ((realBeSi/2)/scaleCali)/1000
								}
							} else {
								if (unitsStringRef == "nm") {
									scanStepX = calibrationX*(realBeSi)
									scanStepY = calibrationY*(realBeSi)
								} else {
									scanStepX = (calibrationX*(realBeSi))/1000
									scanStepY = (calibrationY*(realBeSi))/1000
								}
								Result("Scan Step X: "+scanStepX+"\n")
								Result("Scan Step Y: "+scanStepY+"\n\n")
							}
						} else if (modeOfAcq == 3 && continuousThread == 0) {
							Result("Multi-Tomography Sets Mode"+"\n")
							if (numTomos == 2) {
								ImageResize(ADTStack, 3, width, height, 2*steps)
								indMuTo = 2
							} else {
								ImageResize(ADTStack, 3, width, height, 3*steps) 
								indMuTo = 3
							}
						} else {
							Result("Standard Mode"+"\n")
							ImageResize(ADTStack, 3, width, height, steps)  
						}
						
						updImg := CameraCreateImageForAcquire(camID,binValue, binValue, procValue)
						showimage(updImg)
						caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
						setName(caliImg,"Acquired DP")
						number originCalix, scaleCalix
						string unitsCalix
						caliImg.ImageGetDimensionCalibration(0,originCalix, scaleCalix, unitsCalix,0)
						
						if (ProjShiftCounter + ProjShiftDSCounter == 2){
							//Read the Projector Shift Calibration
							string directoryProjCalibration = pathConcatenate(pathPDW, "ProjectorShiftCalibration.txt")
							string calibrationPartProjX, calibrationPartProjY, rotationAngleProj, scaleCaliPartProj
							number fileProjReference = openFileForReading(directoryProjCalibration)
							number ProjLine1 = readFileLine(fileProjReference, calibrationPartProjX)
							number ProjLine2 = readFileLine(fileProjReference, calibrationPartProjY)
							number ProjLine3 = readFileLine(fileProjReference, rotationAngleProj)
							number ProjLine4 = readFileLine(fileProjReference, scaleCaliPartProj)
							calibrationProjX = val(right(calibrationPartProjX,len(calibrationPartProjX)-15))
							calibrationProjY = val(right(calibrationPartProjY,len(calibrationPartProjY)-15))
							rotAngleProj = val(right(rotationAngleProj,len(rotationAngleProj)-30))
							closeFile(fileProjReference)
							
							//Read the Projector Shift-DS Calibration
							string directoryProjDSCalibration = pathConcatenate(pathPDW, "ProjectorShiftDSCalibration.txt")
							string calibrationPartProjDSX, calibrationPartProjDSY, rotationAngleProjDS, scaleCaliPartProjDS
							number fileProjDSReference = openFileForReading(directoryProjDSCalibration)
							number ProjLine1DS = readFileLine(fileProjDSReference, calibrationPartProjDSX)
							number ProjLine2DS = readFileLine(fileProjDSReference, calibrationPartProjDSY)
							number ProjLine3DS = readFileLine(fileProjDSReference, rotationAngleProjDS)
							number ProjLine4DS = readFileLine(fileProjDSReference, scaleCaliPartProjDS)
							calibrationProjDSX = val(right(calibrationPartProjDSX,len(calibrationPartProjDSX)-15))
							calibrationProjDSY = val(right(calibrationPartProjDSY,len(calibrationPartProjDSY)-15))
							rotAngleProjDS = val(right(rotationAngleProjDS,len(rotationAngleProjDS)-30))
							closeFile(fileProjDSReference)
						}
						
						//Continuous sampling
						if (continuousThread == 1){
							
							if(DSThread == 0) {
								EMBeamShift(Xshift,Yshift)
							} else {
								DSpositionBeam(refDSimg, initialBeamPosX, initialBeamPosY)
							}
							
							Result("Beam positioned on the crystal."+"\n\n")
							
							//Pre-loading beam shift values
							image shiftXValuesVector := RealImage("Shift X Vector",4,1,steps)
							image shiftYValuesVector := RealImage("Shift Y Vector",4,1,steps)
							for(number i=0;i<steps;i++){

								nonUsedVar = readFileLine(referencia, thisline)
								shiftXValuesVector[i,0,i+1,1] = val(right(thisline,len(thisline)-12))

								nonUsedVar = readFileLine(referencia, thisline)
								shiftYValuesVector[i,0,i+1,1] = val(right(thisline,len(thisline)-12))

							}
							
							if(shiftXValuesVector.GetPixel(0, 0) == 0){
								
								evaluadorText = 0
								setPersistentNumberNote("Evaluar Text",evaluadorText)
									
							}
							
							//Acquisition
							Result("\tContinuous Acquisition"+"\n\n")	
							
							//Creationg of pts file
							edInfoFile = NewScriptWindow("3D ED data information", 50,50,800,450)
							editorWindowAddText(edInfoFile,"lambda "+0.02517+"\n\n")
							editorWindowAddText(edInfoFile,"Aperpixel "+(scaleCalix/10)+"\n\n")
							editorWindowAddText(edInfoFile,"geometry continuous\nphi 0.125\n\n")
							editorWindowAddText(edInfoFile,"omega 15\n\n")
							editorWindowAddText(edInfoFile,"dstarmax 1.4\ndstarmin 0.04\n\n")
							editorWindowAddText(edInfoFile,"noiseparameters 51 8\n\n")
							editorWindowAddText(edInfoFile,"reflectionsize 40\n\n")
							editorWindowAddText(edInfoFile,"I/sigma 10\n\nbin 4\n\n")
							editorWindowAddText(edInfoFile,"imagelist\n")
							
							number InitialTiltValueADT, initialEvalTiltAngleADT = EMGetStageAlpha()
							CameraStartContinuousAcquisition( camID, exposureThread, binValue, binValue, procValue)
							CameraGetFrameInContinuousMode( camID, ADTstack.Slice2( 0,0,0, 0,width,1, 1,height,1 ), 5)
							
							//STEM mode
							if(DSThread == 1){
							
								EMSetStageAlpha(lastAngleText)
								while(EMGetStageAlpha() == initialEvalTiltAngleADT){
									Result("waiting for stage rotation in STEM mode ... \n")
								}
								InitialTiltValueADT = EMGetStageAlpha()
								initialTime = GetOSTickCount()	
								for(number i = 0; i<steps; i++){							
									CameraGetFrameInContinuousMode(camID, ADTstack.Slice2( 0,0,i, 0,width,1, 1,height,1 ), 1)
									initialBeamPosX+=shiftXValuesVector.GetPixel(0, i)
									initialBeamPosY+=shiftYValuesVector.GetPixel(0, i)
									if (projDSeval == 1){
										xProjDSShift = ((cos(rotAngleProjDS*pi()/180)*(shiftXValuesVector.GetPixel(0, i)*scaleCali/scaleCaliDSforProjRef)) + (-sin(rotAngleProjDS*pi()/180)*(-shiftYValuesVector.GetPixel(0, i)*scaleCali/scaleCaliDSforProjRef)))/(scaleCaliProjDS*calibrationProjDSX)
										yProjDSShift = ((sin(rotAngleProjDS*pi()/180)*(shiftXValuesVector.GetPixel(0, i)*scaleCali/scaleCaliDSforProjRef)) + (cos(rotAngleProjDS*pi()/180)*(-shiftYValuesVector.GetPixel(0, i)*scaleCali/scaleCaliDSforProjRef)))/(scaleCaliProjDS*calibrationProjDSY)
										xProjShift = ((cos(rotAngleProj*pi()/180)*xProjDSShift) + (sin(rotAngleProj*pi()/180)*(yProjDSShift)))*calibrationProjX*scaleCaliProj*(scaleCaliProj/scaleCaliProjRef)
										yProjShift = ((-sin(rotAngleProj*pi()/180)*xProjDSShift) + (cos(rotAngleProj*pi()/180)*(yProjDSShift)))*calibrationProjY*scaleCaliProj*(scaleCaliProj/scaleCaliProjRef)
									}
									editorWindowAddText(edInfoFile,"img\\dp_"+format((i+1),"%03d")+".tif \t"+format(EMGetStageAlpha(),"%2.4f")+"\n")
									DSpositionBeam(refDSimg, initialBeamPosX, initialBeamPosY)
									EMChangeProjectorShift(-xProjShift,-yProjShift)
									//Result((i+1)+" time ="+(CalcOSSecondsBetween(iniTimePerDP,GetOSTickCount()))+"\n")
								}
								
							//TEM mode
							} else {
								
								EMSetStageAlpha(lastAngleText)
								while(EMGetStageAlpha() == initialEvalTiltAngleADT){
									Result("waiting for stage rotation in TEM mode... \n")
								}
								InitialTiltValueADT = EMGetStageAlpha()
								initialTime = GetOSTickCount()	
								for(number i = 0; i<steps; i++){
									iniTimePerDP = GetOSTickCount()
									EMBeamShift(shiftXValuesVector.GetPixel(0, i), shiftYValuesVector.GetPixel(0, i))
									editorWindowAddText(edInfoFile,"img\\dp_"+format((i+1),"%03d")+".tif \t"+format(EMGetStageAlpha(),"%2.4f")+"\n")
									CameraGetFrameInContinuousMode( camID, ADTstack.Slice2( 0,0,i, 0,width,1, 1,height,1 ), 5)
									//Result((i+1)+" time ="+(CalcOSSecondsBetween(iniTimePerDP,GetOSTickCount()))+"\n")
								}
								
							}
							finalTime = GetOSTickCount()
							
							currentLastAngle = EMGetStageAlpha()
							editorWindowAddText(edInfoFile,"endimagelist")
							Result("\nInitial Angle: "+InitialTiltValueADT+"\n")
							editorWindowAddText(edInfoFile,"\n#Initial Angle: "+InitialTiltValueADT+"\n")
							Result("Last Angle: "+currentLastAngle)
							editorWindowAddText(edInfoFile,"#Last Angle: "+currentLastAngle+"\n")
							CameraStopContinuousAcquisition(camID)
							
						//Discrete
						} else {
							
							Result("\tDiscrete Acquisition"+"\n\n")	
							
							edInfoFile = NewScriptWindow("3D ED data information", 50,50,800,450)
							editorWindowAddText(edInfoFile,"lambda "+0.02517+"\n\n")
							editorWindowAddText(edInfoFile,"Aperpixel "+(scaleCalix/10)+"\n\n")
							editorWindowAddText(edInfoFile,"geometry precession\nphi 1.0\n\n")
							editorWindowAddText(edInfoFile,"omega 15\n\n")
							editorWindowAddText(edInfoFile,"dstarmax 1.4\ndstarmin 0.04\n\n")
							editorWindowAddText(edInfoFile,"noiseparameters 47 8\n\n")
							editorWindowAddText(edInfoFile,"reflectionsize 40\n\n")
							editorWindowAddText(edInfoFile,"I/sigma 10\n\nbin 2\n\n")
							editorWindowAddText(edInfoFile,"imagelist\n")
							
							initialTime = GetOSTickCount()
							
							//TEM mode
							if (DSThread == 0) {

								for(number i = 0; i<steps; i++){
									
									if(stopParameter == 1) break
									
									nonUsedVar = readFileLine(referencia, thisline)
									Xshift=(val(right(thisline,len(thisline)-12)))
										
									if(Xshift == 0){
									
										evaluadorText = 0
										setPersistentNumberNote("Evaluar Text",evaluadorText)
										
									}
									
									nonUsedVar = readFileLine(referencia, thisline)
									Yshift=(val(right(thisline,len(thisline)-12)))
									
									if (i > 0){
									
										EMSetStageAlpha(initialAngleThread + (stepAngleThread*i))
										
									}
									
									initialBeamPosX+=Xshift
									initialBeamPosY+=Yshift
									EMSetBeamShift(initialBeamPosX, initialBeamPosY)
									EMWaitUntilReady()
									
									if (modeOfAcq == 1) {
													
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										ADTstack[0,0,i,width,height,i+1] = caliImg
										updImg = caliImg
										updateimage(updImg)
										editorWindowAddText(edInfoFile,"img\\dp_"+format((i+1),"%03d")+".tif \t"+format(EMGetStageAlpha(),"%2.4f")+"\n")
										Result((i+1)+" DP:"+"\t"+"X-Beam Shift:"+"\t"+Xshift+"\tY-Beam Shift:\t"+Yshift+"\n")
									
									} else if (modeOfAcq == 2) {
										
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										ADTstack[0,0,(i*2),width,height,((i*2)+1)] = caliImg
										updImg = caliImg
										updateimage(updImg)
										Result((i+1)+" DP - Precession On:"+"\t"+"X-Beam Shift:"+"\t"+Xshift+"\t"+"Y-Beam Shift:"+"\t"+Yshift+"\n")
										
										//FUNCTION TO DE-ACTIVATE PRECESSION
										
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										ADTstack[0,0,((i*2)+1),width,height,((i*2)+2)] = caliImg
										updImg = caliImg
										updateimage(updImg)
										Result((i+1)+" DP - Precession OFF:"+"\t"+"X-Beam Shift:"+"\t"+Xshift+"\t"+"Y-Beam Shift:"+"\t"+Yshift+"\n")
										
										//FUNCTION TO ACTIVATE PRECESSION AGAIN

									} else if (modeOfAcq == 3) {
															
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										ADTstack[0,0,(i*indMuTo),width,height,(i*indMuTo)+1] = caliImg
										updImg = caliImg
										updateimage(updImg)
										
										Result((i+1)+" DP - 1st Cry.:"+"\t"+"X-Beam Shift:"+"\t"+Xshift+"\t"+"Y-Beam Shift:"+"\t"+Yshift+"\n")
										
										nonUsedVar = readFileLine(referencia, thisline)
										Xshift2 = (val(right(thisline,len(thisline)-12)))
										nonUsedVar = readFileLine(referencia, thisline)
										Yshift2 = (val(right(thisline,len(thisline)-12)))
										
										initialBeamPosX_2+=Xshift2
										initialBeamPosY_2+=Yshift2
										EMSetBeamShift(initialBeamPosX_2, initialBeamPosY_2)
										EMWaitUntilReady()
										
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										ADTstack[0,0,(i*indMuTo)+1,width,height,(i*indMuTo)+2] = caliImg
										updImg = caliImg
										updateimage(updImg)
										
										Result((i+1)+" DP - 2nd Cry.:"+"\t"+"X-Beam Shift:"+"\t"+Xshift2+"\t"+"Y-Beam Shift:"+"\t"+Yshift2+"\n")
										
										if (numTomos == 3) {
											
											nonUsedVar = readFileLine(referencia, thisline)
											Xshift3 = (val(right(thisline,len(thisline)-12)))
											nonUsedVar = readFileLine(referencia, thisline)
											Yshift3 = (val(right(thisline,len(thisline)-12)))
											initialBeamPosX_3+=Xshift3
											initialBeamPosY_3+=Yshift3
											EMSetBeamShift(initialBeamPosX_3, initialBeamPosY_3)
											EMWaitUntilReady()
											
											delay(30)
											caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
											ADTstack[0,0,(i*indMuTo)+2,width,height,(i*indMuTo)+3] = caliImg
											updImg = caliImg
											updateimage(updImg)
											Result((i+1)+" DP - 3rd Cry.:"+"\t"+"X-Beam Shift:"+"\t"+Xshift3+"\t"+"Y-Beam Shift:"+"\t"+Yshift3+"\n")
												
										}
									
									} else if (modeOfAcq == 4) {
																			
										idxStack = 0
										indX = -((indAcquisition-1)/2)
										indY = -((indAcquisition-1)/2)
										for (refX = 1; refX <= indAcquisition; refX++) {
										
											for (refY = 1;refY <= indAcquisition; refY++) {
												
												EMSetBeamShift(initialBeamPosX+(indX*scanStepX), initialBeamPosY+(indY*scanStepY))
												EMWaitUntilReady()
												caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
												ADTstack[0,0,(i*scanNum)+idxStack,width,height,(i*scanNum)+idxStack+1] = caliImg
												updImg = caliImg
												updateimage(updImg)
												Result((i+1)+" Angle - "+(idxStack+1)+" DP"+"\t"+"X Beam Shift:"+"\t"+(initialBeamPosX+(indX*scanStepX))+"\t"+"Y Beam Shift:"+"\t"+(initialBeamPosY+(indY*scanStepY))+"\n")
												indY += 1
												idxStack += 1
											
											}
											
											indY = -((indAcquisition-1)/2)
											indX += 1
											
										}
									
									}

								}		
							
							//STEM Mode Acquisition
							} else {
								
								for(number i = 0; i<steps; i++){
									
									if(stopParameter == 1) break
									
									nonUsedVar = readFileLine(referencia, thisline)
									Xshift = (val(right(thisline,len(thisline)-12)))
		
									if(Xshift == 0){
										
										evaluadorText = 0
										setPersistentNumberNote("Evaluar Text",evaluadorText)
										
									}

									nonUsedVar = readFileLine(referencia, thisline)
									Yshift = (val(right(thisline,len(thisline)-12)))							
									
									if (i > 0){
										
										EMSetStageAlpha(initialAngleThread + (stepAngleThread*i))
										
									}
									
									initialBeamPosX+=Xshift
									initialBeamPosY+=Yshift
									
									DSPositionBeam(refDSimg, initialBeamPosX,initialBeamPosY)		
									DSWaitUntilFinished()
									
									if (modeOfAcq == 1) {
										
										if (projDSeval == 1){
											xProjDSShift = ((cos(rotAngleProjDS*pi()/180)*(Xshift*scaleCali/scaleCaliDSforProjRef)) + (-sin(rotAngleProjDS*pi()/180)*(-Yshift*scaleCali/scaleCaliDSforProjRef)))/(scaleCaliProjDS*calibrationProjDSX)
											yProjDSShift = ((sin(rotAngleProjDS*pi()/180)*(Xshift*scaleCali/scaleCaliDSforProjRef)) + (cos(rotAngleProjDS*pi()/180)*(-Yshift*scaleCali/scaleCaliDSforProjRef)))/(scaleCaliProjDS*calibrationProjDSY)
											xProjShift = ((cos(rotAngleProj*pi()/180)*xProjDSShift) + (sin(rotAngleProj*pi()/180)*(yProjDSShift)))*calibrationProjX*scaleCaliProj*(scaleCaliProj/scaleCaliProjRef)
											yProjShift = ((-sin(rotAngleProj*pi()/180)*xProjDSShift) + (cos(rotAngleProj*pi()/180)*(yProjDSShift)))*calibrationProjY*scaleCaliProj*(scaleCaliProj/scaleCaliProjRef)
											EMChangeProjectorShift(-xProjShift,-yProjShift)
										}
										EMWaitUntilReady()				
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										DSPositionBeam(refDSimg, 1010, 1010)
										ADTstack[0,0,i,width,height,i+1] = caliImg
										updImg = caliImg
										updateimage(updImg)
										//Result((i+1)+" DP:"+"\t"+"DigiScan X-Shift:"+"\t"+format(initialBeamPosX,"%03.3f")+"\t"+"DigiScan Y-Shift:\t"+format(initialBeamPosY,"%03.3f")+"\tAngle:\t"+EMGetStageAlpha()+"\n")
										editorWindowAddText(edInfoFile,"img\\dp_"+format((i+1),"%03d")+".tif \t"+format(EMGetStageAlpha(),"%2.4f")+"\n")
										//Result("img\\dp_"+format((i+1),"%03d")+"\t"+EMGetStageAlpha()+"\n")
										
									} else if (modeOfAcq == 2) {									
										
										//FUNCTION TO ACTIVATE PRECESSION
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										DSPositionBeam(refDSimg, 1010, 1010)
										DSWaitUntilFinished()
										ADTstack[0,0,i*2,width,height,(i*2)+1] = caliImg
										updImg = caliImg
										updateimage(updImg)
										Result((i+1)+" DP - Precession On:"+"\t"+"DigiScan X-Shift:"+"\t"+initialBeamPosX+"\t"+"DigiScan Y-Shift:"+"\t"+initialBeamPosY+"\n")
										//FUNCTION TO DE-ACTIVATE PRECESSION
										DSPositionBeam(refDSimg, initialBeamPosX,initialBeamPosY)
										DSWaitUntilFinished()
										
										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										DSPositionBeam(refDSimg, 1010, 1010)
										EMWaitUntilReady()
										ADTstack[0,0,(i*2)+1,width,height,(i*2)+2] = caliImg
										updImg = caliImg
										updateimage(updImg)
										Result((i+1)+" DP - Precession Off:"+"\t"+"DigiScan X-Shift:"+"\t"+initialBeamPosX+"\t"+"DigiScan Y-Shift:"+"\t"+initialBeamPosY+"\n")									
									
									} else if (modeOfAcq == 4) {	
										
										idxStack = 0
										indX = -((indAcquisition-1)/2)
										indY = -((indAcquisition-1)/2)
										for(refX = 1; refX <= indAcquisition; refX++) {
										
											for(refY = 1;refY <= indAcquisition; refY++) {
								
												DSPositionBeam(refDSimg, initialBeamPosX+(indX*stepInPixels),initialBeamPosY+(indY*stepInPixels))
												DSWaitUntilFinished()
												
												caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
												DSPositionBeam(refDSimg, 1010, 1010)
												DSWaitUntilFinished()
												ADTstack[0,0,(i*scanNum)+idxStack,width,height,(i*scanNum)+idxStack+1] = caliImg
												updImg = caliImg
												updateimage(updImg)
												Result((i+1)+" Angle - "+(idxStack+1)+" DP"+"\t"+"DigiScan X-Shift:"+"\t"+(initialBeamPosX+(indX*stepInPixels))+"\t"+"DigiScan Y-Shift:"+"\t"+(initialBeamPosY+(indY*stepInPixels))+"\n")
												indY += 1
												idxStack += 1
											
											}
											
											indY = -((indAcquisition-1)/2)
											indX += 1
											
										}
									
									} else if (modeOfAcq == 3) {

										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										DSPositionBeam(refDSimg, 1010, 1010)
										DSWaitUntilFinished()
										ADTstack[0,0,(i*indMuTo),width,height,(i*indMuTo)+1] = caliImg
										updImg = caliImg
										updateimage(updImg)
										Result((i+1)+" DP of 1st Cry.:"+"\t"+"DigiScan X-Shift:"+"\t"+initialBeamPosX+"\t"+"DigiScan Y-Shift:"+"\t"+initialBeamPosY+"\n")
										
										nonUsedVar = readFileLine(referencia, thisline)
										Xshift2 = (val(right(thisline,len(thisline)-12)))
										initialBeamPosX_2 += Xshift2
										nonUsedVar = readFileLine(referencia, thisline)
										Yshift2 = (val(right(thisline,len(thisline)-12)))
										initialBeamPosY_2 += Yshift2
										DSPositionBeam(refDSimg, initialBeamPosX_2,initialBeamPosY_2)
										DSWaitUntilFinished()

										caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
										DSPositionBeam(refDSimg, 1010, 1010)
										DSWaitUntilFinished()
										ADTstack[0,0,(i*indMuTo)+1,width,height,(i*indMuTo)+2] = caliImg
										updImg = caliImg
										updateimage(updImg)
										Result((i+1)+" DP of 2nd Cry.:"+"\t"+"DigiScan X-Shift:"+"\t"+initialBeamPosX_2+"\t"+"DigiScan Y-Shift:"+"\t"+initialBeamPosY_2+"\n")
										
										if (numTomos == 3) {
											
											nonUsedVar = readFileLine(referencia, thisline)
											Xshift3 = (val(right(thisline,len(thisline)-12)))
											initialBeamPosX_3 += Xshift3
											nonUsedVar = readFileLine(referencia, thisline)
											Yshift3 = (val(right(thisline,len(thisline)-12)))
											initialBeamPosY_3 += Yshift3
											DSPositionBeam(refDSimg, initialBeamPosX_3,initialBeamPosY_3)
											DSWaitUntilFinished()
											
											caliImg := CameraAcquire(camID, exposureThread, binValue, binValue, procValue)
											DSPositionBeam(refDSimg, 1010, 1010)
											DSWaitUntilFinished()
											ADTstack[0,0,(i*indMuTo)+2,width,height,(i*indMuTo)+3] = caliImg
											updImg = caliImg
											updateimage(updImg)
											Result((i+1)+" DP of 3rd Cry.:"+"\t"+"DigiScan X-Shift:"+"\t"+initialBeamPosX_3+"\t"+"DigiScan Y-Shift:"+"\t"+initialBeamPosY_3+"\n")
												
										}
									
									}

								}							
								
							}
							
							finalTime = GetOSTickCount()
							editorWindowAddText(edInfoFile,"endimagelist")	
						
						}
						
						imgDoc=getImageDocument(0)
						imageDocumentClose(imgdoc,0)
						
						experimentTime = CalcOSSecondsBetween(initialTime, finalTime)
						Result("\n"+"Total Acquisition Time: "+experimentTime+" s"+"\n")	
												
						if (continuousThread == 1){
							
							Result("Total Read Out Time: " +  (experimentTime-(steps*exposureThread))+" s"+"\n")
							editorWindowAddText(edInfoFile,"#Total Read Out Time: " +  (experimentTime-(steps*exposureThread))+" s"+"\n")
							Result("Read Out Time per DP: " + ((experimentTime-(steps*exposureThread))/steps) + " s"+"\n")
							editorWindowAddText(edInfoFile,"#Read Out Time per DP: " + ((experimentTime-(steps*exposureThread))/steps) + " s")
							Result("Integrated Angular Range on each DP: "+(velocityThread*exposureThread)+" degrees"+"\n")
							
						} else {
						
							if (modeOfAcq == 2) {
								steps = 2*steps
							} else if (modeOfAcq == 3) {
								steps = steps*2
								if (numTomos == 3) {
									steps = steps*3
								}
							} else if (modeOfAcq == 4) {
								steps = scanNum*steps
							}
							
							Result("Total Read Out Time:" + "\t" + (experimentTime-(steps*exposureThread)-(steps*0.5))+" s"+"\n")
							Result("Read Out Time per DP:" + "\t" + ((experimentTime-(steps*exposureThread)-(steps*0.5))/steps) + " s"+"\n")

						}
			
						showimage(ADTstack)	
						ImageCopyCalibrationFrom(ADTstack, caliImg)
						setName(ADTstack,"3D ED dataset")
						TagGroup sourceTG = caliImg.ImageGetTagGroup()
						TagGroup gotoTG = ADTStack.ImageGetTagGroup()
						gotoTG.TagGroupCopyTagsFrom(sourceTG.TagGroupClone())
						updateimage(ADTstack)
						
						if (DSThread == 0) {
							EMSetBrightness(beamSize)
							EMWaitUntilReady()
							EMSetBeamShift(bsXtemDiff, bsYtemDiff)
							EMWaitUntilReady()
							EMSetImagingOpticsMode("MAG1")
						} else {
							refDSimg.getSize(dssizex,dssizey)
							DSpositionBeam(refDSimg, round(dssizex/2), round(dssizey/2))
							if (projDSeval == 1){
								EMSetProjectorShift(scanDiffProjX, scanDiffProjY)
							}
							//EMSetFocus(beamSize)
							EMWaitUntilReady()
						}
						
						closeFile(referencia)
						taggroup tagHowManyFiles = GetFilesInDirectory(pathPDW,1) //1 for files, 2 for folder, 3 for files + folders
						number howManyFiles = tagHowManyFiles.TagGroupCountTags()
						string pathDM3 = pathconcatenate(pathPDW,""+(howmanyfiles-6))
						string path3dEDinfo = pathconcatenate(pathPDW,""+(howmanyfiles-6)+"_processingFile.pts2")
						editorWindowSaveToFile(edInfoFile,path3dEDinfo)

						saveasgatan(ADTstack,pathDM3)
						showAlert("Congratulations! All your diffraction data has been acquired and saved",2)
						
						Result("\n"+"------------------------------------------------------------------------"+"\n")
					
					}
				
				}

			} else {

				closeFile(referencia)
				filereference=openFileForReading(path)
				setPersistentNumberNote("Referencia Text",filereference)
				nonUsedVar = readFileLine(referencia, thisline)
				nonUsedVar = readFileLine(referencia, thisline)
				
				showAlert("The angles from the Tracking File do not correspond to the ones introduced in the 'Parameters Setup' box.",1)
				Result("----------------------------------------------------------------------------------------------"+"\n\n")	

			}	
		} else {

			closeFile(referencia)
			filereference=openFileForReading(path)
			setPersistentNumberNote("Referencia Text",filereference)
			nonUsedVar = readFileLine(referencia, thisline)
			nonUsedVar = readFileLine(referencia, thisline)

		}
	
	}
}

//Creation of Dialog components for the GUI
TagGroup MakeButtons(){

	//----------------------------------------------------------------------------------
	//FAST-ADT: PARAMETERS SETUP
	//----------------------------------------------------------------------------------
	
	taggroup boxSCOPE_items
	taggroup boxSCOPE=DLGCreateBox("  Parameters Setup  ", boxSCOPE_items)
	
	//CHECKS----------------------------------------------------------------------------
	
	checkContinuous = DLGCreateCheckbox("Continuous",0, "checkContfunction")
	checkContinuous.DLGidentifier("checkingCont")
	checkDiscrete = DLGCreateCheckbox("Sequential",1,"checkDiscfunction")
	checkDiscrete.DLGidentifier("checkingDisc")
	taggroup checksBox=DLGgroupitems(checkDiscrete, checkContinuous)
	checksBox.DLGtablelayout(2,1,0)
	
	boxSCOPE_items.DLGaddelement(checksBox)
	
	//DIGISCAN-STEM CHECKBOX -------------------------------------------------------------
	
	checkTEM = DLGCreateCheckbox("TEM Imaging",1,"checkingTEM")
	checkTEM.DLGidentifier("checkTEMmode").DLGinternalpadding(4,0)	
	checkDS = DLGCreateCheckbox("STEM Imaging (DigiScan)",0, "checkDiSc")
	checkDS.DLGidentifier("checkDigiScan").DLGinternalpadding(4,0)
	DSThread = 0	
	TagGroup groupOfModes = DLGgroupitems(checkTEM,checkDS)
	groupOfModes.DLGtableLayout(2,1,0)
	boxSCOPE_items.DLGaddelement(groupOfModes)
	
	TagGroup labelPixelTime = DLGCreateLabel("PixelTime (µs):")
	TagGroup expDS = DLGCreateRealField(2, 4, 3).DLGIdentifier("expDSnumber").DLGEnabled(0)
	DLGValue(expDS,5)
	TagGroup labelImgTime = DLGCreateLabel("CTF Img Time (s):")
	TagGroup imgCamTime = DLGCreateRealField(2, 4, 3).DLGIdentifier("imgCamTime")
	DLGValue(imgCamTime,1.0)
	
	TagGroup groupingDSthings = DLGgroupitems(labelPixelTime, expDS,labelImgTime, imgCamTime)
	groupingDSthings.DLGtableLayout(4,1,0)
	boxSCOPE_items.DLGaddelement(groupingDSthings)	
	
	//INITIAL ANGLE---------------------------------------------------------------------

	TagGroup labelInitial = DLGCreateLabel("Initial Angle (°):")
	labelInitial.DLGexternalpadding(10,0)
		
	taggroup realfieldInitialAngle = DLGCreateRealField(0, 6, 3).DLGidentifier("initialAngleCall").DLGexternalpadding(8,0)	
	DLGvalue(realfieldInitialAngle,0)

	taggroup labelboxIniAngle=DLGgroupitems(labelInitial, realfieldInitialAngle)
	labelboxIniAngle.DLGtablelayout(2,1,0)
	boxSCOPE_items.DLGaddelement(labelboxIniAngle)

	//FINAL ANGLE-----------------------------------------------------------------------

	TagGroup label1 = DLGCreateLabel("Final Angle (°): ")
	label1.DLGexternalpadding(10,0)
		
	taggroup realfield1 = DLGCreateRealField(0, 6, 3).DLGidentifier("finalAngleCall").DLGexternalpadding(8,0)	
	DLGvalue(realfield1,0)

	taggroup labelbox1=DLGgroupitems(label1, realfield1)
	labelbox1.DLGtablelayout(2,1,0)
	boxSCOPE_items.DLGaddelement(labelbox1)
	
	//STEP ANGLE -------------------------------------------------------------------------

	TagGroup stepTag = DLGCreateLabel("  Tilt Step (°):  ")
	stepTag.DLGexternalpadding(13,0)
		
	taggroup stepfield = DLGCreateRealField(1, 6,3).DLGidentifier("stepCall").DLGexternalpadding(8,0)	
	DLGvalue(stepfield,1)

	taggroup labelboxStep=DLGgroupitems(stepTag, stepfield)
	labelboxStep.DLGtablelayout(2,1,0)
	boxSCOPE_items.DLGaddelement(labelboxStep)

	//VELOCITY -------------------------------------------------------------------------

	TagGroup labelVel = DLGCreateLabel(" Velocity (°/s): ")
	labelVel.DLGexternalpadding(12,0)
	taggroup realfield2 = DLGCreateRealField(1, 9,7).DLGidentifier("velocityCall").DLGexternalpadding(1,0)	
	DLGvalue(realfield2,0.5).DLGenabled(0)

	taggroup labelbox2=DLGgroupitems(labelVel, realfield2)
	labelbox2.DLGtablelayout(2,1,0)
	boxSCOPE_items.DLGaddelement(labelbox2)
	
	//GO TO -----------------------------------------------------------------------------
	
	Taggroup gotoTag=DLGcreatepushbutton("Go to (°):", "gotoAngle")
	gotoTag.DLGexternalpadding(4,0).DLGinternalpadding(2,0)
	taggroup goAngle = DLGCreateRealField(0, 6, 3).DLGidentifier("gotoValue").DLGexternalpadding(8,0)
	DLGvalue(goAngle,0)
	taggroup undoAngle = DLGcreatepushbutton("Undo","undo")
	undoAngle.DLGexternalpadding(4,0).DLGinternalpadding(2,0).DLGenabled(0).DLGidentifier("undoAngleBut")
		
	taggroup gotoBox = DLGgroupitems(gotoTag, goAngle,undoAngle)
	gotoBox.DLGtablelayout(3,1,0)
	boxSCOPE_items.DLGaddelement(gotoBox)

	//EXPOSURE TIME----------------------------------------------------------------------
	
	TagGroup camerasettings_items
	taggroup camerasettings = DLGCreateBox("Camera Settings for Diffraction", camerasettings_items)
	
	TagGroup labelExpo = DLGCreateLabel("Exposure (s):")
	labelExpo.DLGexternalpadding(3,0)
	valorExposicio = DLGCreateRealField(1, 6, 3).DLGidentifier("exposure").DLGexternalpadding(8,0)
	DLGvalue(valorExposicio,0.5)
		
	taggroup caixa = DLGgroupitems(labelExpo, valorExposicio)
	caixa.DLGtablelayout(2,1,0)
	camerasettings_items.DLGaddelement(caixa)		

	//BINNING----------------------------------------------------------------------------
		
	TagGroup labelBin = DLGCreateLabel(" Binning: ")
	labelBin.DLGexternalpadding(14,0)		
	TagGroup binningSelect_items
	TagGroup binningSelect = DLGCreatePopup(binningSelect_items, 1,"binningSelected").DLGexternalpadding(8,0)
	binningSelect_items.DLGAddPopupItemEntry("1");
	binningSelect_items.DLGAddPopupItemEntry("2");
	binningSelect_items.DLGAddPopupItemEntry("4");
	binningSelect_items.DLGAddPopupItemEntry("8");

	taggroup BinCaixa = DLGgroupitems(labelBin, binningSelect)
	BinCaixa.DLGtablelayout(2,1,0)
	camerasettings_items.DLGaddelement(BinCaixa)
		
	//PROCESSING-------------------------------------------------------------------------

	TagGroup labelProcessing = DLGCreateLabel("Processing:")
	labelProcessing.DLGexternalpadding(10,0)
		
	TagGroup processingSelect_items
	TagGroup processingSelect = DLGCreatePopup(processingSelect_items, 1,"processingSelected")
	processingSelect_items.DLGAddPopupItemEntry("Gain Normalized");
	processingSelect_items.DLGAddPopupItemEntry("Dark Correction");
	processingSelect_items.DLGAddPopupItemEntry("Unprocessed");
	
	taggroup procBox = DLGgroupitems(labelProcessing, processingSelect)
	procBox.DLGtablelayout(2,1,0)
	camerasettings_items.DLGaddelement(procBox)	
	
	//IMAGE ACQUISITION -----------------------------------------------------------------
		
	Taggroup acqImg=DLGcreatepushbutton("Acquire Image", "acqImage")
	acqImg.DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0)
	camerasettings_items.DLGaddelement(acqImg)
	boxSCOPE_items.DLGaddelement(camerasettings)
	
	//-----------------------------------------------------------------------------------
	//IMAGING OPTICS 
	//-----------------------------------------------------------------------------------
	TagGroup imgOptics_items
	TagGroup imgOptics=dlgcreatebox("Projector System", imgOptics_items)
	//------------------------------------------------------------------------------------
	TagGroup toImgMode=dlgcreatepushbutton("-> to Img", "toImgModebut")
	toImgMode.dlgexternalpadding(2,0).dlginternalpadding(5,0).DLGIdentifier("toImgBut")
	
	TagGroup toDiffMode=dlgcreatepushbutton("-> to Diff", "toDiffModebut")
	toDiffMode.dlgexternalpadding(2,0).dlginternalpadding(5,0).DLGIdentifier("toDiffBut")
	
	TagGroup imagingOpticsGroup = DLGgroupitems(toImgMode,toDiffMode)
	imagingOpticsGroup.dlgtablelayout(2,1,0)
	imgOptics_items.dlgaddelement(imagingOpticsGroup)
	
	boxSCOPE_items.DLGaddelement(imgOptics)
	
	//-----------------------------------------------------------------------------------

	//BEAM BLANK CHECK ------------------------------------------------------------------
	
	TagGroup beamsettings_items
	taggroup beamsettings = DLGCreateBox("Beam Settings", beamsettings_items)
	checkBB = DLGCreateCheckbox("Beam Blank",0, "checkBeBl")
	checkBB.DLGidentifier("checkBeamBlank")
	Taggroup beamDiam=DLGcreatepushbutton("Get Beam Settings", "getBeamDiameter")
	beamDiam.DLGexternalpadding(9,0).DLGinternalpadding(9,0)
	taggroup boxBeamSettings1 = DLGgroupitems(checkBB, beamDiam)
	boxBeamSettings1.DLGtablelayout(2,1,0)
	beamsettings_items.DLGaddelement(boxBeamSettings1)	


	//GET & SET BEAM DIAMETER -----------------------------------------------------------------
	
	imgIcon = DLGcreategraphic(22,22).DLGidentifier("imagingIcon")
	taggroup imgIconBitmap = DLGcreatebitmap(nonActiveLED)
	DLGaddbitmap(imgIcon,imgIconBitmap)
	Taggroup beamScanSet = DLGCreatePushButton("Set Img Setting","setScanBeam")
	beamScanSet.DLGinternalpadding(2,0).DLGenabled(0).DLGidentifier("ScanBeamButton")
	Taggroup beamDiffSet = DLGCreatePushButton("Set Diff Setting","setDiffBeam")
	beamDiffSet.DLGinternalpadding(2,0).DLGenabled(0).DLGidentifier("DiffBeamButton")
	diffIcon = DLGcreategraphic(22,22).DLGidentifier("diffractionIcon")
	taggroup diffIconBitmap = DLGcreatebitmap(nonActiveLED)
	DLGaddbitmap(diffIcon, diffIconBitmap)
	TagGroup settingGroup = DLGgroupitems(imgIcon,beamScanSet,beamDiffSet,diffIcon)
	settingGroup.DLGtablelayout(4,1,0)
	beamsettings_items.DLGaddelement(settingGroup)

	//-----------------------------------------------------------------------------------
	//BEAM/DIFFRACTION SHIFT CALIBRATION
	//-----------------------------------------------------------------------------------
	taggroup acquireCali_items
	taggroup acquireCali=DLGcreatebox("  Beam/Proj. Shift Calibration  ", acquireCali_items)

	//BEAM SHIFT VALUE------------------------------------------------------------------------

	TagGroup labelshift = DLGCreateLabel("Beam Shift Value:")
	labelshift.DLGexternalpadding(7,0)
		
	TagGroup etiqueta = DLGCreateRealField(500, 8, 3).DLGidentifier("beamVal").DLGexternalpadding(4,0)	
	DLGvalue(etiqueta,500) //Actual beam shift value

	TagGroup labelboxShift=DLGgroupitems(labelshift, etiqueta)
	labelboxShift.DLGtablelayout(2,1,0)
	acquireCali_items.DLGaddelement(labelboxShift)
		
	//TEST BEAM SHIFT VALUE -------------------------------------------------------------
		
	Taggroup test=DLGcreatepushbutton("Test Beam Shift Value", "testBeamShift")
	test.DLGidentifier("testBSval").DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0)
	acquireCali_items.DLGaddelement(test)

	//ACQUIRE CALIBRATION IMAGES --------------------------------------------------------

	Taggroup cali=DLGcreatepushbutton("Calibrate", "caliBeamShifts")
	cali.DLGidentifier("caliButton").DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0)
	acquireCali_items.DLGaddelement(cali)
	
	//PROJECTOR SHIFT VALUE------------------------------------------------------------------------

	TagGroup labelProjShift = DLGCreateLabel("Proj. Shift Value:")
	labelProjshift.DLGexternalpadding(7,0)
		
	TagGroup etiquetaProj = DLGCreateRealField(1000, 8, 3).DLGidentifier("ProjbeamVal").DLGexternalpadding(4,0).dlgenabled(0)	
	DLGvalue(etiquetaProj,1000) //Actual proj shift value

	TagGroup labelboxProjShift=DLGgroupitems(labelProjshift, etiquetaProj)
	labelboxProjShift.DLGtablelayout(2,1,0)
	acquireCali_items.DLGaddelement(labelboxProjShift)
		
	//TEST PROJ SHIFT VALUE -------------------------------------------------------------
		
	Taggroup testProj=DLGcreatepushbutton("Test Proj. Shift Value", "testProjShift")
	testProj.DLGidentifier("testProjval").DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0).dlgenabled(0)
	acquireCali_items.DLGaddelement(testProj)

	//ACQUIRE CALIBRATION Proj Shif IMAGES ----------------------------------------------

	Taggroup caliProj=DLGcreatepushbutton("Calibrate Proj. Shift", "caliProjShifts")
	caliProj.DLGidentifier("caliProjButton").DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0).dlgenabled(0)
	acquireCali_items.DLGaddelement(caliProj)
	
	//ACQUIRE CALIBRATION Proj Shift / DS IMAGES ----------------------------------------

	Taggroup caliProjDS=DLGcreatepushbutton("Calibrate Diff. Shift (DS)", "caliProjDSShifts")
	caliProjDS.DLGidentifier("caliProjDSButton").DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0).dlgenabled(0)
	acquireCali_items.DLGaddelement(caliProjDS)

	//-----------------------------------------------------------------------------------
	
	beamsettings_items.DLGaddelement(acquireCali)
	
	//-----------------------------------------------------------------------------------
	

	//-----------------------------------------------------------------------------------
	//CRYSTAL TRACKING SETTING
	//-----------------------------------------------------------------------------------	
	taggroup crystalTrack_items
	taggroup crystalTrack=DLGcreatebox("  Crystal Tracking File ", crystalTrack_items)
		
	//GENERATE AND ACQUIRE CRYSTAL TRACK FILE -------------------------------------------

	Taggroup geneAcq=DLGcreatepushbutton("Acquire (...)", "acquireCT").DLGidentifier("generationAcq")
	geneAcq.DLGinternalpadding(9,0)
	crystTrackEval = 0
		
	Taggroup contAcq=DLGcreatepushbutton("Process (...)", "continueCT").DLGidentifier("continueAcq")
	contAcq.DLGinternalpadding(9,0).DLGenabled(0)
		
	TagGroup acqTrackFile=DLGgroupitems(geneAcq, contAcq)
	acqTrackFile.DLGtablelayout(2,1,0)
	crystalTrack_items.DLGaddelement(acqTrackFile)
	
	//Tilt Step for Recerence Images ----------------------------------------------------------------

	TagGroup labelTSRef = DLGCreateLabel(" Tilt Step for Ref. Images (°): ")
	taggroup tiltStepRefImg = DLGCreateRealField(5, 5,0).DLGidentifier("tsRefImg")
	DLGvalue(tiltStepRefImg,5)

	taggroup boxTSRef=DLGgroupitems(labelTSRef, tiltStepRefImg)
	boxTSRef.DLGtablelayout(2,1,0)
	crystalTrack_items.DLGaddelement(boxTSRef)
	
	//RESET ACQUISITION STEPS -----------------------------------------------------------

	TagGroup resAcq=DLGcreatepushbutton("Reset Cryst. Track. Steps", "resetAcq").dlgidentifier("resetAcq")
	resAcq.DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0)
	
	crystalTrack_items.DLGaddelement(resAcq)	
		
	//GENERATE CRYSTAL TRACK FILE -------------------------------------------------------

	TagGroup gene=DLGcreatepushbutton("Generate", "generateCT").DLGidentifier("generateFile")
	gene.DLGexternalpadding(9,0).DLGinternalpadding(9,0).DLGtablelayout(1,1,0).DLGenabled(0)
	
	crystalTrack_items.DLGaddelement(gene)

	//-----------------------------------------------------------------------------------


	//-----------------------------------------------------------------------------------
	//FAST-ADT:ACQUISITION
	//-----------------------------------------------------------------------------------
	TagGroup boxTilt_items
	TagGroup boxTilt=DLGcreatebox(" Acquisition ", boxTilt_items)	
	
	//INITIAL BEAM POSITION--------------------------------------------------------------
	
	TagGroup iniProbePos=DLGCreatePushButton("Inital Beam Position","iniBeamPos")
	iniProbePos.DLGidentifier("ctIniPos").DLGinternalpadding(9,0).DLGenabled(0)

	//LOAD TRACKING FILE BUTTON----------------------------------------------------------

	TagGroup load=DLGcreatepushbutton("Load Tracking File", "loadCTFile")
	load.DLGidentifier("fileReference")
	load.DLGinternalpadding(9,0)
	
	TagGroup startPart = DLGgroupitems(load,iniProbePos)
	startPart.DLGtableLayout(2,1,0)
	boxTilt_items.DLGaddelement(startPart)

	//CRYSTAL TRACKING TEXT PART---------------------------------------------------------

	taggroup labelTrack = DLGCreateLabel("Tracking File:")
	crtString = DLGCreateStringField("Non-loaded File",30).DLGidentifier("fileNameString").DLGexternalpadding(2,0).DLGenabled(0)
	taggroup cryTrackBox = DLGgroupitems(labelTrack,crtString)
	cryTrackBox.DLGtablelayout(2,1,0)
	boxTilt_items.DLGaddelement(cryTrackBox)

	//START BUTTON-----------------------------------------------------------------------

	TagGroup start=DLGcreatepushbutton("Start", "startADT")
	start.DLGinternalpadding(9,0).DLGenabled(0).DLGidentifier("start")
	setpersistentnumbernote("Evaluar Text",0)
	
	//Stop Button
	stopADTacq = DLGcreatepushbutton("Stop", "stopADT")
	stopADTacq.DLGinternalpadding(9,0).DLGidentifier("stopAcquisition").DLGEnabled(0)
	
	TagGroup reiniciar=DLGcreatepushbutton("Load Initial Parameters", "resetParameters")
	reiniciar.DLGinternalpadding(9,0).DLGenabled(0).DLGidentifier("reiniciar")
		
	TagGroup labelboxGoOK=DLGgroupitems(start, stopADTacq, reiniciar)
	labelboxGoOK.DLGtablelayout(3,1,0)
	boxTilt_items.DLGaddelement(labelboxGoOK)
	
	//Apply Proj. Shift Correction Button
	
	checkProjDScorr = DLGCreateCheckbox(" Apply Proj. Shift correction",0, "checkProjDScorrfunction")
	checkProjDScorr.DLGidentifier("IDcheckProjDScorr").dlgenabled(0)
	boxTilt_items.DLGaddelement(checkProjDScorr)

	//------------------------------------------------------------------------------------

	
	//------------------------------------------------------------------------------------

	//FINAL AGGLOMERATION OF TAG GROUPS
	TagGroup boxoutput = DLGgroupitems(boxSCOPE, beamsettings, crystalTrack)
	TagGroup boxoutput2 = DLGgroupitems(boxoutput, boxTilt)
	return boxoutput2
	//------------------------------------------------------------------------------------

}

//Button Functions
class ADTAcquisitionDialog:uiframe{
object CaliListener, Positioning, Acquire3DEDdata

//Initialise function for thread
void init( object self, number ID ){
	// Create the thread and pass in the ID of the dialog, so that the thread can access the dialog's functions		
	CaliListener = Alloc(caliImageChange)
	CaliListener.LinkToDialog(ID)
	Positioning = Alloc(Positioning)
	Positioning.LinkToDialog(ID)
	Acquire3DEDdata = Alloc(ed3dAcqBackground)
	Acquire3DEDdata.LinkToDialog(ID)
	return
}


void checkContfunction( object self, TagGroup tg){
	
	if (DLGgetValue(checkContinuous) == 0){
	
		checkDiscrete.DLGValue(1)
		//self.SetElementisEnabled("velocityCall",0)
		self.SetElementisEnabled("stepCall",1)
		self.SetElementisEnabled("imgCamTime",1)
		self.SetElementisEnabled("tsRefImg",1)
		self.SetElementisEnabled("exposure",1)
		if (DLGgetValue(checkDS) == 1) {
			self.SetElementisEnabled("expDSnumber",1)
		} 
		
	} else {
	
		checkDiscrete.DLGValue(0)
		DLGValue(valorExposicio,0.5)
		//self.SetElementisEnabled("velocityCall",1)
		self.SetElementisEnabled("stepCall",0)
		self.SetElementisEnabled("imgCamTime",0)
		self.SetElementisEnabled("tsRefImg",0)
		self.SetElementisEnabled("exposure",0)
		if (DLGgetValue(checkDS) == 1) {
			self.SetElementisEnabled("expDSnumber",0)
		} 

	}

}


void checkDiscfunction( object self, TagGroup tg){

	if (DLGgetValue(checkDiscrete) == 0){
		checkContinuous.DLGValue(1)
		//self.SetElementisEnabled("velocityCall",1)
		self.SetElementisEnabled("stepCall",0)
	} else {
		checkContinuous.DLGValue(0)
		//self.SetElementisEnabled("velocityCall",0)
		self.SetElementisEnabled("stepCall",1)
	}

}


void checkDiSc(object self, TagGroup tg){
	
	DSThread = DLGgetValue(tg)
	//TEM Mode
	if (DSThread  == 0){
		
		self.SetElementisEnabled("expDSnumber",0)	
		self.SetElementisEnabled("beamVal",1)
		self.SetElementisEnabled("testBSval",1)
		self.SetElementisEnabled("imgCamTime",1)
		self.SetElementisEnabled("caliButton",1)
		self.SetElementisEnabled("toImgBut",1)
		self.SetElementisEnabled("toDiffBut",1)
		self.SetElementisEnabled("ProjbeamVal",0)
		self.SetElementisEnabled("testProjval",0)
		self.SetElementisEnabled("caliProjButton",0)
		self.SetElementisEnabled("caliProjDSButton",0)
		self.SetElementisEnabled("IDcheckProjDScorr",0)
		
		checkTEM.DLGValue(1)
		checkProjDScorr.DLGValue(0)
	
	//STEM Mode
	} else {
		
		self.SetElementisEnabled("beamVal",0)
		self.SetElementisEnabled("diffVal",1)
		self.SetElementisEnabled("testBSval",0)
		self.SetElementisEnabled("testDSval",1)
		self.SetElementisEnabled("velocityCall",0)
		self.SetElementisEnabled("stepCall",1)
		self.SetElementisEnabled("expDSnumber",1)
		self.SetElementisEnabled("imgCamTime",0)
		self.SetElementisEnabled("caliButton",0)
		self.SetElementisEnabled("toImgBut",0)
		self.SetElementisEnabled("toDiffBut",0)
		self.SetElementisEnabled("ProjbeamVal",1)
		self.SetElementisEnabled("testProjval",1)
		self.SetElementisEnabled("caliProjButton",1)
		self.SetElementisEnabled("caliProjDSButton",1)
		self.SetElementisEnabled("IDcheckProjDScorr",1)
		
		checkTEM.DLGValue(0)
		checkDiscrete.DLGValue(1)
		checkContinuous.DLGValue(0)
	
	}

}


void checkingTEM(object self, TagGroup tg){
	
	//TEM Mode
	if (DLGgetValue(tg) == 1){
		
		self.SetElementisEnabled("expDSnumber",0)	
		self.SetElementisEnabled("beamVal",1)
		self.SetElementisEnabled("testBSval",1)
		self.SetElementisEnabled("imgCamTime",1)
		self.SetElementisEnabled("caliButton",1)
		self.SetElementisEnabled("toImgBut",1)
		self.SetElementisEnabled("toDiffBut",1)
		self.SetElementisEnabled("ProjbeamVal",0)
		self.SetElementisEnabled("testProjval",0)
		self.SetElementisEnabled("caliProjButton",0)
		self.SetElementisEnabled("caliProjDSButton",0)
		self.SetElementisEnabled("IDcheckProjDScorr",0)
		
		checkDS.DLGValue(0)
		checkProjDScorr.DLGValue(0)
	
	//STEM Mode
	} else {
		
		self.SetElementisEnabled("beamVal",0)
		self.SetElementisEnabled("diffVal",1)
		self.SetElementisEnabled("testBSval",0)
		self.SetElementisEnabled("testDSval",1)
		self.SetElementisEnabled("velocityCall",0)
		self.SetElementisEnabled("stepCall",1)
		self.SetElementisEnabled("expDSnumber",1)
		self.SetElementisEnabled("imgCamTime",0)
		self.SetElementisEnabled("caliButton",0)
		self.SetElementisEnabled("toImgBut",0)
		self.SetElementisEnabled("toDiffBut",0)
		self.SetElementisEnabled("ProjbeamVal",1)
		self.SetElementisEnabled("testProjval",1)
		self.SetElementisEnabled("caliProjButton",1)
		self.SetElementisEnabled("caliProjDSButton",1)
		self.SetElementisEnabled("IDcheckProjDScorr",1)
		
		checkDS.DLGValue(1)
		checkDiscrete.DLGValue(1)
		checkContinuous.DLGValue(0)
	
	}

}


void gotoAngle( object self){

	number moveToAngle = DLGgetValue(self.LookUpElement("gotoValue")) 
	angleAra = EMGetStageAlpha()
	if(moveToAngle < 70.1 && moveToAngle > -70.1){
		if(angleAra > moveToAngle) {
			EMSetStageAlpha(moveToAngle-1)
		} else {
			//EMSetStageAlpha(moveToAngle+1)
		}
		EMWaitUntilReady()
		EMSetStageAlpha(moveToAngle)
		self.SetElementisEnabled("undoAngleBut",1)
	} else {
		showAlert("The introduced Angle is too high or too low for this Stage.",1)
	}
}


void undo(object self){

	number currentValue = EMGetStageAlpha()
	if(angleAra > currentValue) {
		//EMSetStageAlpha(angleAra+1)
	} else {
		EMSetStageAlpha(angleAra-1)
	}
	EMWaitUntilReady()
	EMSetStageAlpha(angleAra)
	
}


void binningSelected( object self, TagGroup tg ){
	
	binValue = (2**(val(DLGgetStringValue(tg))-1))

}


void processingSelected( object self,  TagGroup tg){

	procValue = val(DLGgetStringValue(tg)) + (2*(2-val(DLGgetStringValue(tg))))

}


void acqImage( object self){
	
	CM_StopCurrentCameraViewer(1)
	CameraPrepareForAcquire(camID)
	image acquiredImage := CameraAcquire(camID, DLGgetValue(self.LookUpElement("exposure")), binValue, binValue, procValue)
	setName(acquiredImage,"Acquired Frame")
	showimage(acquiredImage)
	
}


void checkBeBl( object self, TagGroup tg){
	
	if (DLGgetValue(checkBB) == 0){
	
		EMSetBeamBlanked(0)
		Result("\nBeam restored.\n\n")

	} else {
	
		EMSetBeamBlanked(1)
		Result("\nThe Beam is blanked.\n\n")
		
	}

}


void getBeamDiameter (object self){
	try {
		getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
		if (toInitializePyModules==0){
			msgForPyTEMserv = "cmd.exe /cpython "
			msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"initiallize.py")
			LaunchExternalProcess(msgForPyTEMserv)
			setpersistentnumbernote("PyModuleInitialization",1)
		}
		
		object view_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "View", "Search", 1)
		number modeOfAcq
		if (beamDiamRef == 0) {
			showAlert("Tune the illumination knob to set the beam for the Imaging condition.\n"+"Subsequently press again the 'Get Beam Settings' button.",2)
			beamDiamRef = 1
			CM_StartCameraViewer(camera, view_params, 1, 1)
			Result("Storing Beam Settings:\n\n")
		} else if (beamDiamRef == 1) {
			CM_StopCurrentCameraViewer(0)
			if (DSThread == 0) {
				beamScanningSize = EMGetBrightness()
				showAlert("Tune the illumination knob to set the desired beam for the Diffraction condition.\n"+"Subsequently press again the 'Get Beam Settings' button",2)
				beamDiamRef = 2
				Result("Imaging\nSaved lens value: "+beamScanningSize+"\n\n")
			} else {
				//image img := GetFrontImage()
				//beamScanningSize = EMGetFocus()
				//CaliListener.init().StartThread("Start")
				msgForPyTEMserv = "cmd.exe /cpython "
				msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"getCL2_img.py")
				LaunchExternalProcess(msgForPyTEMserv)
				scanCamLenImg = EMGetCameraLength()
				EMGetProjectorShift(scanImgProjX, scanImgProjY)
				EMWaitUntilReady()
				Result("Imaging parameters stored\n")
				msgForPyTEMserv = "cmd.exe /cpython "
				msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"DF_retract.py")
				LaunchExternalProcess(msgForPyTEMserv)
				EMSetScreenPosition(2)
				EMWaitUntilReady()
				showAlert("Tune the illumination knob to set the desired beam diameter for the Diffraction condition.\nSubsequently press again the 'Get Beam Settings' button",2)
				beamDiamRef = 4
			}
			CM_StartCameraViewer(camera, view_params, 1, 1)
		} else if (beamDiamRef == 2) {
			CM_StopCurrentCameraViewer(1)
			beamSize = EMGetBrightness()
			EMSetBrightness(beamScanningSize)
			beamDiamRef = 3
			Result("Diffraction\nSaved lens value: "+beamSize+"\n\n")
			showAlert("Center the beam with Beam Shift for the Imaging condition.\n"+"Subsequently press again the 'Get Beam Settings' button",2)
			CM_StartCameraViewer(camera, view_params, 1, 1)
		} else if (beamDiamRef ==3){
			CM_StopCurrentCameraViewer(1)
			EMGetBeamShift(bsXtemImg,bsYtemImg)
			EMSetBrightness(beamSize)
			beamDiamRef = 4
			Result("Imaging:\nBeam Shift X:\t"+bsXtemDiff+"\nBeam Shift Y:\t"+bsYtemDiff+"\n\n")
			showAlert("Center the beam with Beam Shift for the Diffraction condition.\n"+"Subsequently press again the 'Get Beam Settings' button",2)
			CM_StartCameraViewer(camera, view_params, 1, 1)
		
		} else {
			CM_StopCurrentCameraViewer(1)
			if (getPersistentNumberNote("acqMode",modeOfAcq) == 4){
				getnumber("Introduce the size of the beam for Diffraction condition (nm):", 200, realBeSi)
			}
			beamDiamRef = 0
			if (DSThread == 0) {
				showAlert("Beam settings saved."+"\n"+"Switch to Diffraction mode and adjust the focus for the Diffraction Pattern.", 2)
				EMGetBeamShift(bsXtemDiff, bsYtemDiff)
				Result("Diffraction:\nBeam Shift X:\t"+bsXtemDiff+"\nBeam Shift Y:\t"+bsYtemDiff+"\n\n")
			} else {
				msgForPyTEMserv = "cmd.exe /cpython "
				msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"getCL2_diff.py")
				LaunchExternalProcess(msgForPyTEMserv)
				scanCamLenDiff = EMGetCameraLength()
				EMGetProjectorShift(scanDiffProjX, scanDiffProjY)
				EMWaitUntilReady()
				Result("Diffraction parameters stored\n\n")
				showAlert("Beam settings saved."+"\n"+"Adjust the focus for the diffraction pattern if necessary.", 2)
				beamSize=1
			}
			self.SetElementisEnabled("ScanBeamButton",1)
			self.SetElementisEnabled("DiffBeamButton",1)
			imgIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
			diffIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
			Result("---------------------------------------------------------------------------------------\n")
			
		}
	} catch {
		beamDiamRef = 0
		Result("Something went wrong, make sure that all parameters are correct before starting to get Beam Settings.\n")
		Result("------------------------------------------------------------------------------------------------------------------\n")
	}
}


void setScanBeam (object self){
	
	if (DSThread == 0) {
		EMSetBrightness(beamScanningSize)
		EMSetBeamShift(bsXtemImg, bsYtemImg)
		EMSetScreenPosition(2)
		EMWaitUntilReady()
	} else {
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"insertDF_setCL2_img.py")
		LaunchExternalProcess(msgForPyTEMserv)
		//EMSetFocus(beamScanningSize)
		EMSetCameraLength(scanCamLenImg)
		EMSetProjectorShift(scanImgProjX, scanImgProjY)
		EMSetScreenPosition(0)
		EMWaitUntilReady()
	}
	diffIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
	imgIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
	Result("\nBeam for Imaging\n")
}


void setDiffBeam (object self){
	
	if (DSThread == 0) {
		EMSetBrightness(beamSize)
		EMWaitUntilReady()
		EMSetBeamShift(bsXtemDiff, bsYtemDiff)
		EMWaitUntilReady()
	} else {
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"retractDF_setCL2_diff.py")
		LaunchExternalProcess(msgForPyTEMserv)
		//EMSetFocus(beamSize)
		EMSetCameraLength(scanCamLenDiff)
		EMSetProjectorShift(scanDiffProjX, scanDiffProjY)
		EMSetScreenPosition(2)
		EMWaitUntilReady()
	}
	imgIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
	diffIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
	Result("\nBeam for Diffraction\n")
}


void testBeamShift (object self){

	if (evalBeamShift == 0) {

		delta = DLGgetValue(self.LookUpElement("beamVal"))	
		EMSetBrightness(beamSize)
		EMWaitUntilReady()
		imgIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
		diffIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
		showAlert("Start the image preview and shift the beam at the center of the detector.\nThen, click again the 'Test Beam Shift Value' button.",2)
		evalBeamShift = 1
		
	} else {

		EMBeamShift(delta,0)
		showAlert("Positive X-Beam Shift",2)
		EMBeamShift(-2*delta,0)
		showAlert("Negative X-Beam Shift",2)
		EMBeamShift(delta,delta)
		showAlert("Positive Y-Beam Shift",2)
		EMBeamShift(0, -2*delta)
		showAlert("Negative Y-Beam Shift",2)
		EMBeamShift(0,delta)
		showAlert("If the beam goes out of the field of view, reduce the 'Beam Shift Value' parameter.",2)
		evalBeamShift = 0

	}
	
}


void caliBeamShifts (object self){
	
	number delta, shown, i, modulLineX, modulLineY, aveModu, xsize, ysize, xfinal, yfinal
	number xinitial, yinitial, xpos3, ypos3, xpos4, ypos4, exposure
	image Beam1, Beam2, Beam3, Beam4, Beam5, img, crosscorrimg, sumImage
	imagedocument imgDoc
	documentwindow textFile
		
	delta = DLGgetValue(self.LookUpElement("beamVal"))
	//deltaDiff = DLGgetValue(self.LookUpElement("diffVal"))
	exposure = DLGgetValue(self.LookUpElement("exposure"))

	try {
		EMSetBrightness(beamSize)
		EMWaitUntilReady()
	} catch {
		showAlert("You need to set the Beam Settings before the Beam Shift Calibration.",1)
	}
	imgIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
	diffIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
	EMSetScreenPosition(2)
	CM_StopCurrentCameraViewer(1)
	
	shown=CountImageDocuments(WorkspaceGetActive())
	for(i=0; i<shown; ++i){
		imgDoc=getImageDocument(0)
		img:=getFrontImage()
		imageDocumentClose(imgdoc,0)
	}
	
	CameraPrepareForAcquire(camID)
	
	Result("\nBeam Shift Calibration\n\n")
				
	Beam1 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam1,"Beam1")
	Result("1/5 Acquired Images: Non-shifted Beam.\n")
				
	EMBeamShift(delta,0)
	EMWaitUntilReady()
	Beam2 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam2,"Beam2")
	Result("2/5 Acquired Images: Positive X-Shifted Beam.\n")
				
	EMBeamShift(-2*delta,0)
	EMWaitUntilReady()
	Beam3 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam3,"Beam3")		
	Result("3/5 Acquired Images: Negative X-Shifted Beam.\n")
				
	EMBeamShift(delta,delta)
	EMWaitUntilReady()
	Beam4 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam4,"Beam4")
	Result("4/5 Acquired Images: Positive Y-Shifted Beam.\n")
						
	EMBeamShift(0,-2*delta)
	EMWaitUntilReady()
	Beam5 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam5,"Beam5")		
	Result("5/5 Acquired Images: Negative Y-Shifted Beam.\n\n")
		
	unitsStringRef = imagegetdimensionunitstring(Beam5,0)
	ImageGetDimensionCalibration(Beam5, 0, origin, scaleCali, unitsString, 1)
				
	EMBeamShift(0,delta)
	EMWaitUntilReady()
	
	//Cross-Correlations
	getSize(Beam1,xsize,ysize)
				
	crosscorrimg = crossCorrelate(Beam1, Beam2)
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
				
	sumImage = Beam1+Beam2+Beam3+Beam4+Beam5
	showImage(sumImage)
	imageDisplay vectordisp=sumImage.imageGetImageDisplay(0)
				
	//Arrow Draws from the cross-correlation of the acquired images
	component arrow=newarrowannotation(ysize/2, xsize/2, (yfinal+(ysize/2)), (xfinal+(xsize/2)))
	arrow.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow)
	Result("Positive X-Shifted Beam: ---> X-position: \t"+ xfinal + "\tY-position: \t"+yfinal+"\n")

	component arrow2=newarrowannotation(ysize/2, xsize/2, (yinitial+(ysize/2)), (xinitial+(xsize/2)))
	arrow2.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow2)
	Result("Negative X-Shifted Beam: ---> X-position: \t"+ xinitial + "\tY-position: \t"+yinitial+"\n")

	component arrow3=newarrowannotation(ysize/2, xsize/2, (ypos3+(ysize/2)), (xpos3+(xsize/2)))
	arrow3.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow3)
	Result("Positive Y-Shifted Beam: ---> X-position: \t"+ xpos3 + "\tY-position: \t"+ypos3+"\n")

	component arrow4=newarrowannotation(ysize/2, xsize/2, (ypos4+(ysize/2)), (xpos4+(xsize/2)))
	arrow4.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow4)
	Result("Negative Y-Shifted Beam: ---> X-position: \t"+ xpos4 + "\tY-position: \t"+ypos4+"\n\n")

	updateimage(sumImage)
	setName(sumImage,"Beam Shift Calibration")
			
	//Calculation of the two axes lengths and the angle between the horizontal and the positive x direction
	modulLineX = sqrt( ((xinitial-xfinal)**2)+((yinitial-yfinal)**2) )
	modulLineY = sqrt( ((xpos4-xpos3)**2)+((ypos4-ypos3)**2) )
	
	calibrationX = ((2*delta)/modulLineX)/scaleCali
	calibrationY = ((2*delta)/modulLineY)/scaleCali
			
	Result("Calibration in X-direction:"+"\t"+(calibrationX)+" a.u./"+unitsStringRef+"\n")
	Result("Calibration in Y-direction:"+"\t"+(calibrationY)+" a.u./"+unitsStringRef+"\n")

	aveModu = (modulLineX + modulLineY)/2
	Result("Average Calibration:"+"\t"+(((2*delta)/aveModu)/scaleCali)+" a.u./"+unitsStringRef+"\n\n")
				
	rotAngle = (atan(abs(yfinal-yinitial)/abs(xfinal-xinitial)))*180/pi()
	Result("Angle" + "\t" + rotAngle + "\n")
				
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
				
	Result("Real Angle:" + "\t" + rotAngle + "\n\n")
				
	textFile=NewScriptWindow("Beam Shift Calibrations", 50,50,150,450)
	editorWindowAddText(textFile,"Calibration X: "+format(calibrationX,"%3.4f")+"\n"+"Calibration Y: "+format(calibrationY,"%3.4f")+"\n"+"Angle for FrameWork Rotation: "+format(rotAngle, "%3.4f")+"\n")
	editorWindowAddText(textFile,"Calibration Scale: "+format(scaleCali,"%3.8f"))
	editorWindowSaveToFile(textFile,pathconcatenate(pathPDW,"BeamShiftCalibration.txt"))
	windowClose(textFile,0)
			
	Result("Beam Shift Calibration finalized.\n\n")	
			
	//EMSetScreenPosition(0)
	showAlert("Beam Shift Calibration finalized.",2)
	caliCounter = 0

}


void testProjShift (object self){
	
	if (evalBeamShift == 0) {

		delta = DLGgetValue(self.LookUpElement("ProjbeamVal"))
		showAlert("Start the image preview and focus the pattern at the center of the detector.\nThen, click again the 'Test Beam Shift Value' button.",2)
		evalBeamShift = 1
		
	} else {

		EMChangeProjectorShift(delta,0)
		showAlert("Positive X-Proj Shift",2)
		EMChangeProjectorShift(-2*delta,0)
		showAlert("Negative X-Proj Shift",2)
		EMChangeProjectorShift(delta,delta)
		showAlert("Positive Y-Proj Shift",2)
		EMChangeProjectorShift(0, -2*delta)
		showAlert("Negative Y-Beam Shift",2)
		EMChangeProjectorShift(0,delta)
		showAlert("If the beam goes out of the field of view,\nreduce the 'Proj Shift Value' parameter.",2)
		evalBeamShift = 0

	}
	
}


void caliProjShifts (object self){

	number shown=CountImageDocuments(WorkspaceGetActive())
	image Beam1, Beam2, Beam3, Beam4, Beam5, img
	number deltaProj = DLGgetValue(self.LookUpElement("ProjbeamVal"))

	imagedocument imgDoc
	for(number i=0; i<shown; ++i){
		imgDoc=getImageDocument(0)
		imageDocumentClose(imgdoc,0)
	}
	
	self.setDiffBeam()
	CameraPrepareForAcquire(camID)
		
	Result("\nProjector Shift Calibration\n\n")
				
	Beam1 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam1,"Beam1")
	Result("1/5 Acquired Frames: Non-shifted Pattern.\n")
				
	EMChangeProjectorShift(deltaProj,0)
	EMWaitUntilReady()
	Beam2 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam2,"Beam2")
	Result("2/5 Acquired Frames: Positive X-Shifted Pattern.\n")
				
	EMChangeProjectorShift(-2*deltaProj,0)
	EMWaitUntilReady()
	Beam3 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam3,"Beam3")		
	Result("3/5 Acquired Frames: Negative X-Shifted Pattern.\n")
				
	EMChangeProjectorShift(deltaProj,deltaProj)
	EMWaitUntilReady()
	Beam4 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam4,"Beam4")
	Result("4/5 Acquired Frames: Positive Y-Shifted Pattern.\n")
						
	EMChangeProjectorShift(0,-2*deltaProj)
	EMWaitUntilReady()
	Beam5 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(Beam5,"Beam5")		
	Result("5/5 Acquired Frames: Negative Y-Shifted Pattern.\n\n")

	number originProj
	unitsStringRefProj = imagegetdimensionunitstring(Beam5,0)
	ImageGetDimensionCalibration(Beam5, 0, originProj, scaleCaliProj, unitsStringProj, 1)
				
	EMChangeProjectorShift(0,deltaProj)
	EMWaitUntilReady()

	//Cross-Correlations
	number xsize, ysize, xfinal, yfinal, xinitial, yinitial, xpos3, ypos3, xpos4, ypos4
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
	Result("Positive X-Proj. Shifted Beam: ---> X-position: \t"+ xfinal + "\tY-position: \t"+yfinal+"\n")
	component arrow2=newarrowannotation(ysize/2, xsize/2, (yinitial+(ysize/2)), (xinitial+(xsize/2)))
	arrow2.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow2)
	Result("Negative X-Proj. Shifted Beam: ---> X-position: \t"+ xinitial + "\tY-position: \t"+yinitial+"\n")
	component arrow3=newarrowannotation(ysize/2, xsize/2, (ypos3+(ysize/2)), (xpos3+(xsize/2)))
	arrow3.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow3)
	Result("Positive Y-Proj. Shifted Beam: ---> X-position: \t"+ xpos3 + "\tY-position: \t"+ypos3+"\n")
	component arrow4=newarrowannotation(ysize/2, xsize/2, (ypos4+(ysize/2)), (xpos4+(xsize/2)))
	arrow4.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow4)
	Result("Negative Y-Proj. Shifted Beam: ---> X-position: \t"+ xpos4 + "\tY-position: \t"+ypos4+"\n\n")
	updateimage(sumImage)
	setName(sumImage,"Projector Shift Calibration")
			
	//Calculation of the two axes lengths and the angle between the horizontal and the positive x direction
	number modulLineX = sqrt( ((xinitial-xfinal)**2)+((yinitial-yfinal)**2) )
	number modulLineY = sqrt( ((xpos4-xpos3)**2)+((ypos4-ypos3)**2) )

	number calibrationX = ((2*deltaProj)/modulLineX)/scaleCaliProj
	number calibrationY = ((2*deltaProj)/modulLineY)/scaleCaliProj
			
	Result("Calibration in X-direction:"+"\t"+(calibrationX)+" a.u./"+unitsStringRefProj+"\n")
	Result("Calibration in Y-direction:"+"\t"+(calibrationY)+" a.u./"+unitsStringRefProj+"\n")
	number aveModu = (modulLineX + modulLineY)/2
	Result("Average Calibration:"+"\t"+(((2*deltaProj)/aveModu)/scaleCaliProj)+" a.u./"+unitsStringRefProj+"\n\n")
				
	number rotAngle = (atan(abs(yfinal-yinitial)/abs(xfinal-xinitial)))*180/pi()
	Result("Angle" + "\t" + rotAngle + "\n")
					
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
				
	Result("Real Angle:" + "\t" + rotAngle + "\n\n")
				
	documentwindow textFile=NewScriptWindow("Projector Shift Calibrations", 50,50,150,450)
	editorWindowAddText(textFile,"Calibration X: "+format(calibrationX,"%3.4f")+"\n"+"Calibration Y: "+format(calibrationY,"%3.4f")+"\n"+"Angle for FrameWork Rotation: "+format(rotAngle, "%3.4f")+"\n")
	editorWindowAddText(textFile,"Calibration Scale: "+format(scaleCaliProj,"%3.8f"))
	editorWindowSaveToFile(textFile,pathconcatenate(pathPDW,"ProjectorShiftCalibration.txt"))
	windowClose(textFile,0)
				
	Result("Projector Shift Calibration finalized.\n\n")
	showAlert("Projector Shift Calibration finalized.",2)
	ProjShiftCounter = 1

}


void caliProjDSShifts (object self){

	number shown=CountImageDocuments(WorkspaceGetActive())
	image BeamProjDS1, BeamProjDS2, BeamProjDS3, BeamProjDS4, BeamProjDS5, imgRefProjDS, imgProjDS

	imagedocument imgDoc
	for(number i=0; i<shown; ++i){
		imgDoc=getImageDocument(0)
		imageDocumentClose(imgdoc,0)
	}

	Result("\n"+"Pattern Shift with respect to DigiScan Beam-Shift Calibration"+"\n\n")

	self.setScanBeam()
	CameraPrepareForAcquire(camID)

	DSInvokeButton(1)
	if (DSIsAcquisitionActive()  == 1) {
		DSInvokeButton(1)
		DSWaitUntilFinished( )
	}
	DSInvokeButton(3)
	DSWaitUntilFinished( )
	DSInvokeButton(5,1)
	DSWaitUntilFinished( )
	imgRefProjDS := getFrontImage()
	ImageGetDimensionCalibration(imgRefProjDS, 0, originDSforProjRef, scaleCaliDSforProjRef, unitsStringDSforProjRef, 1)
	DSpositionBeam(imgRefProjDS, 250, 250)
	DSWaitUntilFinished()

	self.setDiffBeam()

	BeamProjDS1 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(BeamProjDS1,"Beam1-ProjDS")
	Result("1/5 Acquired Images: Non-shifted Beam.\n")
				
	DSpositionBeam(imgRefProjDS, 450, 250)
	DSWaitUntilFinished()
	BeamProjDS2 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(BeamProjDS2,"Beam2-ProjDS")
	Result("2/5 Acquired Images: Positive X-Shifted Beam.\n")
				
	DSpositionBeam(imgRefProjDS, 50, 250)
	DSWaitUntilFinished()
	BeamProjDS3 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(BeamProjDS3,"Beam3-ProjDS")	
	Result("3/5 Acquired Images: Negative X-Shifted Beam.\n")
				
	DSpositionBeam(imgRefProjDS, 250, 450)
	DSWaitUntilFinished()
	BeamProjDS4 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(BeamProjDS4,"Beam4-ProjDS")
	Result("4/5 Acquired Images: Positive Y-Shifted Beam.\n")
						
	DSpositionBeam(imgRefProjDS, 250, 50)
	DSWaitUntilFinished()
	BeamProjDS5 := CameraAcquire(camID, 0.1, 1, 1, procValue)
	setName(BeamProjDS5,"Beam5-ProjDS")		
	Result("5/5 Acquired Images: Negative Y-Shifted Beam.\n\n")

	number originProjDS
	unitsStringRefProjDS = imagegetdimensionunitstring(BeamProjDS5,0)
	ImageGetDimensionCalibration(BeamProjDS5, 0, originProjDS, scaleCaliProjDS, unitsStringProjDS, 1)
				
	DSpositionBeam(imgRefProjDS, 512, 512)
	DSWaitUntilFinished()

	//Cross-Correlations
	number xsizeProjDS, ysizeProjDS, xfinalProjDS, yfinalProjDS, xinitialProjDS, yinitialProjDS, xpos3ProjDS, ypos3ProjDS, xpos4ProjDS, ypos4ProjDS
	getSize(BeamProjDS1,xsizeProjDS,ysizeProjDS)
				
	image crosscorrimg = crossCorrelate(BeamProjDS1, BeamProjDS2)
	max(crosscorrimg, xfinalProjDS, yfinalProjDS)
	IUImageFindMax(crosscorrimg, 0, 0, ysizeProjDS, xsizeProjDS, xfinalProjDS, yfinalProjDS, 1)
	xfinalProjDS=-xfinalProjDS
	yfinalProjDS=-yfinalProjDS
				
	crosscorrimg = crossCorrelate(BeamProjDS1, BeamProjDS3)
	max(crosscorrimg, xinitialProjDS, yinitialProjDS)
	IUImageFindMax(crosscorrimg, 0, 0, ysizeProjDS, xsizeProjDS, xinitialProjDS, yinitialProjDS, 1)
	xinitialProjDS = -xinitialProjDS
	yinitialProjDS = -yinitialProjDS
			
	crosscorrimg = crossCorrelate(BeamProjDS1, BeamProjDS4)
	max(crosscorrimg, xpos3ProjDS, ypos3ProjDS)
	IUImageFindMax(crosscorrimg, 0, 0, ysizeProjDS, xsizeProjDS, xpos3ProjDS, ypos3ProjDS, 1)
	xpos3ProjDS = -xpos3ProjDS
	ypos3ProjDS = -ypos3ProjDS
			
	crosscorrimg = crossCorrelate(BeamProjDS1, BeamProjDS5)
	max(crosscorrimg, xpos4ProjDS, ypos4ProjDS)
	IUImageFindMax(crosscorrimg, 0, 0, ysizeProjDS, xsizeProjDS, xpos4ProjDS, ypos4ProjDS, 1)
	xpos4ProjDS = - xpos4ProjDS
	ypos4ProjDS = - ypos4ProjDS
				
	image sumImageProjDS = BeamProjDS1+BeamProjDS2+BeamProjDS3+BeamProjDS4+BeamProjDS5
	showImage(sumImageProjDS)
	imageDisplay vectordisp=sumImageProjDS.imageGetImageDisplay(0)
				
	//Arrow Draws from the X-corr of the acquired images
	component arrow=newarrowannotation(ysizeProjDS/2, xsizeProjDS/2, (yfinalProjDS+(ysizeProjDS/2)), (xfinalProjDS+(xsizeProjDS/2)))
	arrow.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow)
	Result("Positive X-shifted DS: ---> X-position: "+ "\t"+ xfinalProjDS + "\t" + "Y-position: "+ "\t"+yfinalProjDS+"\t"+"\n")
	component arrow2=newarrowannotation(ysizeProjDS/2, xsizeProjDS/2, (yinitialProjDS+(ysizeProjDS/2)), (xinitialProjDS+(xsizeProjDS/2)))
	arrow2.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow2)
	Result("Negative X-shifted DS: ---> X-position: "+ "\t"+ xinitialProjDS + "\t" + "Y-position: "+ "\t"+yinitialProjDS+"\t"+"\n")
	component arrow3=newarrowannotation(ysizeProjDS/2, xsizeProjDS/2, (ypos3ProjDS+(ysizeProjDS/2)), (xpos3ProjDS+(xsizeProjDS/2)))
	arrow3.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow3)
	Result("Positive Y-shifted DS: ---> X-position: "+ "\t"+ xpos3ProjDS + "\t" + "Y-position: "+ "\t"+ypos3ProjDS+"\t"+"\n")
	component arrow4=newarrowannotation(ysizeProjDS/2, xsizeProjDS/2, (ypos4ProjDS+(ysizeProjDS/2)), (xpos4ProjDS+(xsizeProjDS/2)))
	arrow4.componentsetforegroundcolor(1,0,0)
	vectordisp.componentaddchildatend(arrow4)
	Result("Negative Y-shifted DS: ---> X-position: "+ "\t"+ xpos4ProjDS + "\t" + "Y-position: "+ "\t"+ypos4ProjDS+"\t"+"\n\n")
	updateimage(sumImageProjDS)
	setName(sumImageProjDS,"Projector Shift with respecto to DigiScan shift Calibration")
			
	//Calculation of the two axes lengths and the angle between the horizontal and the positive x direction
	number modulLineXProjDS = sqrt( ((xinitialProjDS-xfinalProjDS)**2)+((yinitialProjDS-yfinalProjDS)**2) )
	number modulLineYProjDS = sqrt( ((xpos4ProjDS-xpos3ProjDS)**2)+((ypos4ProjDS-ypos3ProjDS)**2) )

	number calibrationXProjDS = ((400)/modulLineXProjDS)/scaleCaliProjDS
	number calibrationYProjDS = ((400)/modulLineYProjDS)/scaleCaliProjDS
			
	Result("Calibration in X-direction:"+"\t"+(calibrationXProjDS)+" pixels/"+unitsStringRefProjDS+"\n")
	Result("Calibration in Y-direction:"+"\t"+(calibrationYProjDS)+" pixels/"+unitsStringRefProjDS+"\n")
	number aveModuProjDS = (modulLineXProjDS + modulLineYProjDS)/2
	Result("Average Calibration:"+"\t"+(((400)/aveModuProjDS)/scaleCaliProjDS)+" a.u./"+unitsStringRefProjDS+"\n\n")
				
	number rotAngleProjDS = (atan(abs(yfinalProjDS-yinitialProjDS)/abs(xfinalProjDS-xinitialProjDS)))*180/pi()
	Result("Angle" + "\t" + rotAngleProjDS + "\n")
					
	if(xfinalProjDS>xinitialProjDS){
				
		if(yfinalProjDS>yinitialProjDS){
			
			rotAngleProjDS = 360 - rotAngleProjDS
						
		}
					
	} else {
				
		if(yfinalProjDS>yinitialProjDS){
				
			rotAngleProjDS = 180 + rotAngleProjDS
					
		} else {
				
			rotAngleProjDS = 180 - rotAngleProjDS
					
		}
				
	}
				
	Result("Real Angle:" + "\t" + rotAngleProjDS + "\n\n")
				
	documentwindow textFile=NewScriptWindow("Projector Shift DS Calibration", 50,50,150,450)
	editorWindowAddText(textFile,"Calibration X: "+format(calibrationXProjDS,"%3.4f")+"\n"+"Calibration Y: "+format(calibrationYProjDS,"%3.4f")+"\n"+"Angle for FrameWork Rotation: "+format(rotAngleProjDS, "%3.4f")+"\n")
	editorWindowAddText(textFile,"Calibration Scale: "+format(scaleCaliDSforProjRef,"%3.8f")+"\n")
	editorWindowAddText(textFile,"Calibration Scale: "+format(scaleCaliProjDS,"%3.8f"))
	editorWindowSaveToFile(textFile,pathconcatenate(pathPDW,"ProjectorShiftDSCalibration.txt"))
	windowClose(textFile,0)
				
	Result("Pattern Shift with respect to DigiScan Beam-Shift Calibration calibration finalized."+"\n\n")
	showAlert("Pattern Shift vs DigiScan Beam-Shift Calibration finalized.",2)
	ProjShiftDSCounter = 1

}


void toImgModebut(object self){
	EMSetImagingOpticsMode("MAG1")
}


void toDiffModebut(object self){
	EMSetImagingOpticsMode("DIFF")
}


void acquireCT(object self){
		
	image crystalImg, img, temp, capturedImg, crystalBefore, crystalAfter, clonedImg
	number initialAngle, lastAngle, shown, i, totalTime, exposure, bottom, right, refImgTiltStep, currentTiltAngle
	string messagePart1, messagePart2, evalName, messagePart3
	imagedocument imgDoc
	imagedisplay imgdisp
	component squareBefore, squareAfter
	
	initialAngle = DLGgetValue(self.LookUpElement("initialAngleCall"))
	
	if (crystTrackEval == 0) {
		
		Result("Acquisiton of Tracking File\n\n")
		CM_StopCurrentCameraViewer(1)
		
		if (DLGgetValue(checkContinuous) == 1){
		
			messagePart1 = "Place your targeted crystal at the position of the camera that provides a view of the crystal for the whole Angular Range and set the Initial Angle and Final Angle on the 'Parameters Setup' box."
			messagePart2 =  "\n\nOnce all parameters are set, press the 'Acquire (...)' button."
			showAlert(messagePart1+messagePart2,2)
			
		} else {

			messagePart1 = "Place your targeted crystal at the position of the camera that provides a view of the crystal for the whole Angular Range and set the Initial Angle, the Final Angle and the Tilt Step on the 'Parameters Setup' box."
			messagePart3 = "\nThen, press again the 'Acquire (...)' button."		
			showAlert(messagePart1+messagePart3,2)	

		}
		
		crystTrackEval = 4
	
	} else {
		
		initialAngle = DLGgetValue(self.LookUpElement("initialAngleCall"))
		lastAngle = DLGgetValue(self.LookUpElement("finalAngleCall"))
		refTiltStep = DLGgetValue(self.LookUpElement("tsRefImg"))
		self.setScanBeam()
		
		number evaluator = mod((lastAngle-initialAngle),refTiltStep)
		
		if(evaluator == 0){
			
			CM_StopCurrentCameraViewer(1)
			Result("Initial Angle:"+"\t"+initialAngle+"\n")
			Result("Final Angle:"+"\t"+lastAngle+"\n")
			totalNumberOfImages = round((abs(lastAngle-initialAngle)/refTiltStep)+1)	
			
			if(totalNumberOfImages!=0){
			
				shown=CountImageDocuments(WorkspaceGetActive())
				for(i=0; i<shown; ++i){
			
					imgDoc=getImageDocument(0)
					img:=getFrontImage()
					imageDocumentClose(imgdoc,0)
				
				}
				
				//Continuous sampling
				if (DLGgetValue(checkContinuous) == 1){
					
					//Backslash minimization
					EMSetStageAlpha(initialAngle-2)
					EMWaitUntilReady()
					EMSetStageAlpha(initialAngle-1)
					
					//TEM mode
					if (DSThread == 0) {
						
						totalNumberOfImages = round((abs(lastAngle-initialAngle))+1)
						image cameraImgStack := CameraCreateImageForAcquire( camID, 1, 1, 3 )
						ImageResize( cameraImgStack, 3, cameraImgStack.ImageGetDimensionSize(0), cameraImgStack.ImageGetDimensionSize(1), totalNumberOfImages )
						SetName( cameraImgStack, "Crystal tracking images" )
						image refImageForCalibration := CameraAcquire(camID, 0.16, 1, 1, 3)
				
						self.setScanBeam()
						CameraStartContinuousAcquisition( camID, 2, 1, 1, 3)
						CameraGetFrameInContinuousMode( camID, cameraImgStack.Slice2( 0,0,0, 0,widthCam,1, 1,heightCam,1 ), 4)
						
						currentTiltAngle = EMGetStageAlpha()
						EMSetStageAlpha(lastAngle)
						while(EMGetStageAlpha() == currentTiltAngle){
							Result("waiting for the start of stage rotation ... \n")
						}
						
						number InitialTiltValue = EMGetStageAlpha()
						number initialTime = GetOSTickCount()
						Result("0 img: initial time = "+(CalcOSSecondsBetween(initialTime,GetOSTickCount()))+"\t")
						CameraGetFrameInContinuousMode( camID, CameraCreateImageForAcquire( camID, 1, 1, 3 ), 4)
						Result("final time = "+(CalcOSSecondsBetween(initialTime,GetOSTickCount()))+"\n")
						for(number i=1;i<totalNumberOfImages;i++){
							 Result(i+" img: initial time = "+(CalcOSSecondsBetween(initialTime,GetOSTickCount()))+"\t")
							 CameraGetFrameInContinuousMode( camID, cameraImgStack.Slice2( 0,0,i, 0,widthCam,1, 1,heightCam,1 ), 4)
							 Result("final time = "+(CalcOSSecondsBetween(initialTime,GetOSTickCount()))+"\n")
						}
						number finalTime = GetOSTickCount()
						number FinalTiltValue = EMGetStageAlpha()
						number finalTimeForTilt = GetOSTickCount()
						
						CameraStopContinuousAcquisition(camID)
						
						number ReadOutTotalTime = (CalcOSSecondsBetween(initialTime,finalTime)) - (totalNumberOfImages*0.5)
						number ReadOutPerFrame = ReadOutTotalTime/totalNumberOfImages
						string infoStr1 = "Total fames acquisition time (s) = "+CalcOSSecondsBetween(initialTime,finalTime)+"\n"
						string infoStr3, infoStr2 = "Total readout time (s) = "+ReadOutTotalTime+"\nReadout time (s)= "+ReadOutPerFrame				
						Result("\n"+infoStr1+infoStr2+"\n")
						Result("Time to retrieve angle from TEM: "+((finalTimeForTilt-finalTime)/1000)+"\n")
						Result("Initial Alpha: "+InitialTiltValue+"\nFinal Alpha: "+FinalTiltValue+"\n")
						Result("Tilt velocity (deg/s): "+((FinalTiltValue-InitialTiltValue)/((finalTimeForTilt-initialTime)/1000))+"\n")
						
						//Show images at workspace
						image tmpImage
						for(number i=0;i<totalNumberOfImages;i++){
							if (mod(i,5) == 0){
								showimage(cameraImgStack.Slice2( 0,0,i, 0,widthCam,1, 1,heightCam,1 ))
								tmpImage := GetFrontImage()
								ImageCopyCalibrationFrom(tmpImage, refImageForCalibration)
								SetName(tmpImage,"Crystal_Image_"+((round(i/5)+1)))
							}
						}
						
						totalNumberOfImages = round(totalNumberOfImages/5) + 1
						//totalNumberOfImages = round(totalNumberOfImages/2)

					//STEM mode
					} else {
						
						EMSetScreenPosition(0)
						EMSetScreenPosition(0)
						EMWaitUntilReady()
						self.setScanBeam()
						diffIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
						imgIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
						
						image refImageForCalibration := IntegerImage("STEM Frame", 2, 0, 512, 512)
						DSAcquireData(refImageForCalibration, 0, 2, 0, 0)
						image imgRefData := IntegerImage("STEM Frame", 2, 0, 512, 512, totalNumberOfImages)

						number signalIndex = 0
						number rotation = 0   // degree
						number pixelTime= 2   // microseconds
						number lineSync = 0   // de-activated

						number timePerFrame = (512*512*2/1000000)+(DSGetFlyBackTime()*512/1000000)
						currentTiltAngle = EMGetStageAlpha()

						EMSetStageAlpha(lastAngle)
						while(EMGetStageAlpha() == currentTiltAngle){
							Result("waiting for the start of stage rotation ... \n")
						}
						number InitialTiltValue = EMGetStageAlpha()
						number iniPerFrame, finPerFrame, initialTime = GetOSTickCount()
						for(number i=0; i < totalNumberOfImages; i++){
							Result(i+" img - angle: "+EmGetStageAlpha()+"\n")
							DSAcquireData(imgRefData[0,0,i,512,512,i+1], 0, 2, 0, 0)
							Result("waiting .")
							if (i != (totalNumberOfImages-1)){
								while(EMGetStageAlpha() < (InitialTiltValue+5*(i+1))){
									Result(" . ")
								}
							}
							Result("\n")
						}
						number finalTime = GetOSTickCount()
						number FinalTiltValue = EMGetStageAlpha()
						number finalTimeForTilt = GetOSTickCount()

						number ReadOutTotalTime = (CalcOSSecondsBetween(initialTime,finalTime)) - (totalNumberOfImages*timePerFrame)
						number ReadOutPerFrame = ReadOutTotalTime/totalNumberOfImages
						Result("\nFlyback time: "+ DSGetFlyBackTime())
						Result("\nMinimum time per frame: "+timePerFrame)
						string infoStr1 = "Total frames acquisition time (s) = "+CalcOSSecondsBetween(initialTime,finalTime)+"\n"
						string infoStr3, infoStr2 = "Total readout time (s) = "+ReadOutTotalTime+"\nReadout time (s)= "+ReadOutPerFrame				
						Result("\n"+infoStr1+infoStr2+"\n")
						Result("Initial Alpha: "+InitialTiltValue+"\nFinal Alpha: "+FinalTiltValue+"\n")
						Result("Tilt velocity (deg/s): "+((FinalTiltValue-InitialTiltValue)/((finalTimeForTilt-initialTime)/1000))+"\n")
						
						//Show images at workspace
						image tmpImage
						for(number i=0;i<totalNumberOfImages;i++){
							showimage(imgRefData.Slice2( 0,0,i, 0,512,1, 1,512,1 ))
							tmpImage := GetFrontImage()
							ImageCopyCalibrationFrom(tmpImage, refImageForCalibration)
							SetName(tmpImage,"Crystal_Image_"+(i+1))
						}

						Result("Total number of images:"+"\t"+totalNumberOfImages+"\n")
						
					}
				
				//Discrete sampling
				} else {
				
					Result("Total number of images:\t"+totalNumberOfImages+"\n")
				
					EMSetStageAlpha(initialAngle-1)		
					EMWaitUntilReady()
					CameraPrepareForAcquire(camID)
					
					//STEM mode
					if (DSThread == 1) {
						
						self.setScanBeam()
						DSInvokeButton(1)
						if (DSIsAcquisitionActive()  == 1) {
							DSInvokeButton(1)
							DSWaitUntilFinished( )
						}
						DSInvokeButton(3)
						DSWaitUntilFinished( )
						DSInvokeButton(5,1)
						DSWaitUntilFinished( )
						capturedImg := getFrontImage()
						imagedocument iniDoc = getImageDocument(0)
						imageDocumentClose(iniDoc,0)
						
						number pixelTime = DLGgetValue(self.LookUpElement("expDSnumber"))					
						for (i=1;i<totalNumberOfImages+1;i++){
						
							EMSetStageAlpha(initialAngle+((refTiltStep*(i-1))))
							EMWaitUntilReady()
							DSAcquireData(capturedImg, 0, pixelTime, 0, 0)
							clonedImg := imageclone(capturedImg)
							setName(clonedImg,"Crystal_Image_"+i)
							ShowImage(clonedImg)
							Result("Acquired:"+"\t"+"Crystal_Image_"+i+"\n")
					
						}					
					
					//TEM mode				
					} else {
					
						self.setScanBeam()

						for (i=1;i<totalNumberOfImages+1;i++){
						
							EMSetStageAlpha(initialAngle+(refTiltStep*(i-1)))
							EMWaitUntilReady()
							crystalImg := CameraAcquire(camID, DLGgetValue(self.LookUpElement("imgCamTime")), 1, 1, 3)
							setName(crystalImg,"Crystal_Image_"+i)
							showimage(crystalImg)
							Result("Acquired:"+"\t"+"Crystal_Image_"+i+"\n")
					
						}
					
					}
					
				
				}
				
				//Annotation for the subsequent cross-correlation
				indexMiddle = round(totalNumberOfImages/2)
				
				imagedocument imgdoc = getImageDocument(indexMiddle-1)
				imageDocumentShow(imgdoc)
				temp:=getFrontImage()
				imgdisp = temp.ImageGetImageDisplay(0)
			
				component square1 = newboxannotation(100 , 100, 200, 200)
				square1.componentsetforegroundcolor(1,0,0)
				ComponentSetDeletable(square1,0)
				imgdisp.componentaddchildatend(square1)
				
				number modeOfAcq
				getPersistentNumberNote("acqMode",modeOfAcq)
				
				if (modeOfAcq == 3) {
					component square2 = newboxannotation(200, 200, 300, 300)
					square2.componentsetforegroundcolor(0,1,0)
					ComponentSetDeletable(square2,0)
					imgdisp.componentaddchildatend(square2)
						
					number numTomos
					getPersistentNumberNote("tomoSel",numTomos)
					if (numTomos == 3) {
						component square3 = newboxannotation(300 , 300, 400, 400)
						square3.componentsetforegroundcolor(0,0,1)
						ComponentSetDeletable(square3,0)
						imgdisp.componentaddchildatend(square3)
					}
				}
			
				self.SetElementisEnabled("continueAcq",1);
				showalert("Shift the red ROI to select the taregeted crystalline domain.\n(Press the ALT key while modifying the size if you want to keep a square)\n\nClick the 'Process (...)' button when you finish.",2)
				
			
			} else {
		
				showalert("There is not an angular range for the crystal tracking procedure.\n\nWrite a 'Final Angle' different from the current tilt angle.",1)
			
			}

			crystTrackEval = 0

		} else {
		
			showAlert("The angular range divided by the tilt step must be an integer number. Choose the 'Tilt Step for Ref. Images' accordingly and press again the 'Acquire' button.",1)
		
		}

	}
	
}


void continueCT(object self){

	number lastAngle, stepAngle, initialAngle, numSquares, top, bottom, right, left, ysize, xsize, i 
	number xpos, ypos, currentImageIndex, shown, strlen, answer, velocity, exposure, xinitialPos, yinitialPos
	number modeOfAcq, top2, bottom2, right2, left2, top3, bottom3, right3, left3, xsize2, ysize2, xsize3, ysize3
	number xinitialPos2, yinitialPos2, xinitialPos3, yinitialPos3, numTomos, originNonUsed, widthImgX, heightImgX
	string nom, nomTemplate, nomImatgeActual, calibrationPart, rotationAngle, directoryCalibration, messageGenerateCT 
	string messageGenerateCT2, messageGenerateCT3, xcorrname, refPositionsName
	image front, template, temp, crosscorrimg, closeImg
	imagedisplay imgdisp
	documentwindow textFile, textFile2
	imagedocument imgdoc, img
	component squareToAdd, squareToAdd2, squareToAdd3

	initialAngle = DLGgetValue(self.LookUpElement("initialAngleCall"))
	lastAngle = DLGgetValue(self.LookUpElement("finalAngleCall"))
	velocity = DLGgetValue(self.LookUpElement("velocityCall"))
	getPersistentNumberNote("acqMode",modeOfAcq)
	getPersistentNumberNote("tomoSel",numTomos)
	
	//Cross correlation 
	if(partContinue==0){
		
		front:=getFrontImage()
		nomTemplate = getName(front)
		ImageGetDimensionCalibration(front, 0, originNonUsed, scaleCaliRefImages, unitsString, 1)
		imgdisp=front.imageGetImageDisplay(0)
		numSquares=ComponentCountChildren(imgdisp)
		string dirMiddleImage = pathconcatenate(pathPDW,"ref_middleCrystalImage")
		saveasgatan(front,dirMiddleImage)
	
		if(numSquares==0){
	
			beep()
			showalert("There is no ROI on the image.\nDraw a ROI to continue.",1)
			Result("ROI deleted.\n")
			Result("----------------------------------------------------------------------------------------------\n")
		
		} else {
			
			//Get the reference area for the Cross-Correlation
			component square1 = ComponentGetChild( imgdisp, 0 )
			ComponentGetRect(square1, top, left, bottom, right)
			ysize = bottom-top
			xsize = right-left
			xinitialPos = left+(xsize/4)
			yinitialPos = top+(ysize/4)
			
			if (modeOfAcq == 3) {
			
				component square2 = ComponentGetChild( imgdisp, 1 )
				ComponentGetRect(square2, top2, left2, bottom2, right2)
				ysize2 = bottom2-top2
				xsize2 = right2-left2
				xinitialPos2 = left2+(xsize2/4)
				yinitialPos2 = top2+(ysize2/4)
				
				if (numTomos == 3) {
				
					component square3 = ComponentGetChild( imgdisp, 2 )
					ComponentGetRect(square3, top3, left3, bottom3, right3)
					ysize3 = bottom3-top3
					xsize3 = right3-left3
					xinitialPos3 = left3+(xsize3/4)
					yinitialPos3 = top3+(ysize3/4)
					
				}
			}
		
			textFile=NewScriptWindow("Cross-Correlation", 50,50,150,450)
			editorWindowAddText(textFile,"Initial Angle: "+ initialAngle + "\nLast Angle: " + lastAngle + "\n")
			Result("\nCross-Correlation Calculation:\n\n")
			
			//Cross-Correlation for the reference images
			for (i=1;i<totalNumberOfImages+1;i++){
				
				if(i!=indexMiddle){
				
					imgdoc = getImageDocument(totalNumberOfImages-1)
					imageDocumentShow(imgdoc)
					temp:=getFrontimage()
					temp.GetSize(widthImgX, heightImgX)
					nom = getName(temp)
					crosscorrimg=crossCorrelate(front,temp)
					max(crosscorrimg, xpos,ypos)					
					
					if ( ((xinitialPos + ((widthImgX/2)-xpos)) > 0) && ((xinitialPos + ((widthImgX/2)-xpos)) < (widthImgX)) && ((yinitialPos+((heightImgX/2)-ypos)) > 0) && ((yinitialPos+((heightImgX/2)-ypos)) < (heightImgX)) ) {
						squareToAdd = newboxannotation(top + (heightImgX/2) - ypos, left + (widthImgX/2) - xpos, bottom + (heightImgX/2) - ypos, right + (widthImgX/2) - xpos )
						editorWindowAddText(textFile,"X-Position: "+format((xinitialPos + ((widthImgX/2)-xpos)),"%8.4f")+"\n"+"Y-Position: "+format((yinitialPos+((heightImgX/2)-ypos)), "%8.4f")+"\n")
						Result(nom +"\t"+"X-position: "+ (xinitialPos + ((widthImgX/2)-xpos)) + "\t" + "Y-position: "+(yinitialPos+((heightImgX/2)-ypos))+"\n")
					} else {
						squareToAdd = newboxannotation(top, left, bottom, right)
						editorWindowAddText(textFile,"X-Position: "+format(((right-left)/2),"%8.4f")+"\n"+"Y-Position: "+format(((bottom-top)/2), "%8.4f")+"\n")
						Result(nom +"\t"+"X-correlation failed (out of image positioning) -> X-position: "+ ((right-left)/2) + "\t" + "Y-position: "+((bottom-top)/2)+"\n")
					}
					
					imgdisp = temp.ImageGetImageDisplay(0)
					squareToAdd.componentsetforegroundcolor(1,0,0)
					ComponentSetDeletable(squareToAdd,0)
					imgdisp.componentaddchildatend(squareToAdd)
					
					if (modeOfAcq == 3) {
						
						if ( ((xinitialPos2 + ((widthImgX/2)-xpos)) > 0) && ((xinitialPos2 + ((widthImgX/2)-xpos)) < (widthImgX)) && ((yinitialPos2+((heightImgX/2)-ypos)) > 0) && ((yinitialPos2+((heightImgX/2)-ypos)) < (heightImgX)) ) {
							squareToAdd2 = newboxannotation(top2 + (heightImgX/2) - ypos, left2 + (widthImgX/2) - xpos, bottom2 + (heightImgX/2) - ypos, right2 + (widthImgX/2) - xpos )
							editorWindowAddText(textFile,"X-Position: "+format((xinitialPos2 + ((widthImgX/2)-xpos)),"%8.4f")+"\n"+"Y-Position: "+format((yinitialPos2+((heightImgX/2)-ypos)), "%8.4f")+"\n")
							Result(nom +" 2\t"+"X-position: "+ (xinitialPos2 + ((widthImgX/2)-xpos)) + "\t" + "Y-position: "+(yinitialPos2+((heightImgX/2)-ypos))+"\n")
						} else {
							squareToAdd2 = newboxannotation(top2, left2, bottom2, right2)
							editorWindowAddText(textFile,"X-Position: "+format(((right2-left2)/2),"%8.4f")+"\n"+"Y-Position: "+format(((bottom2-top2)/2), "%8.4f")+"\n")
							Result(nom +" 2\t"+"X-correlation failed (out of image positioning) -> X-position: "+ ((right2-left2)/2) + "\t" + "Y-position: "+((bottom2-top2)/2)+"\n")
						}
							
						squareToAdd2.componentsetforegroundcolor(0,1,0)
						ComponentSetDeletable(squareToAdd2,0)
						imgdisp.componentaddchildatend(squareToAdd2)
						
						if (numTomos == 3) {
							
							if ( ((xinitialPos3 + ((widthImgX/2)-xpos)) > 0) && ((xinitialPos3 + ((widthImgX/2)-xpos)) < (widthImgX)) && ((yinitialPos3+((heightImgX/2)-ypos)) > 0) && ((yinitialPos3+((heightImgX/2)-ypos)) < (heightImgX)) ) {
								squareToAdd3 = newboxannotation(top3 + (heightImgX/2) - ypos, left3 + (widthImgX/2) - xpos, bottom3 + (heightImgX/2) - ypos, right3 + (widthImgX/2) - xpos )
								editorWindowAddText(textFile,"X-Position: "+format((xinitialPos3 + ((widthImgX/2)-xpos)),"%8.4f")+"\n"+"Y-Position: "+format((yinitialPos3+((heightImgX/2)-ypos)), "%8.4f")+"\n")
								Result(nom +" 3\t"+"X-position: "+ (xinitialPos3 + ((widthImgX/2)-xpos)) + "\t" + "Y-position: "+(yinitialPos3+((heightImgX/2)-ypos))+"\n")
							} else {
								squareToAdd3 = newboxannotation(top3, left3, bottom3, right3)
								editorWindowAddText(textFile,"X-Position: "+format(((right3-left3)/2),"%8.4f")+"\n"+"Y-Position: "+format(((bottom3-top3)/2), "%8.4f")+"\n")
								Result(nom +" 3\t"+"X-correlation failed (out of image positioning) -> X-position: "+ ((right3-left3)/2) + "\t" + "Y-position: "+((bottom3-top3)/2)+"\n")
							}
							
							squareToAdd3.componentsetforegroundcolor(0,0,1)
							ComponentSetDeletable(squareToAdd3,0)
							imgdisp.componentaddchildatend(squareToAdd3)
							
						}
						
					}
			
				} else {
			
					Result(nomTemplate +"\t"+"X-position: "+ (left+(xsize/2)) + "\t" + "Y-position: "+(top+(ysize/2))+"\n")
					editorWindowAddText(textFile,"X-Position: "+format((left+(xsize/2)),"%8.4f")+"\n"+"Y-Position: "+format((top+(ysize/2)), "%8.4f")+"\n")
					
					if (modeOfAcq == 3) {
					
						Result(nomTemplate +" 2\t"+"X-position: "+ (left2+(xsize2/2)) + "\t" + "Y-position: "+(top2+(ysize2/2))+"\n")
						editorWindowAddText(textFile,"X-Position: "+format((left2+(xsize2/2)),"%8.4f")+"\n"+"Y-Position: "+format((top2+(ysize2/2)), "%8.4f")+"\n")
						
						if (numTomos == 3) {
						
						Result(nomTemplate +" 3 \t"+"X-position: "+ (left3+(xsize3/2)) + "\t" + "Y-position: "+(top3+(ysize3/2))+"\n")
						editorWindowAddText(textFile,"X-Position: "+format((left3+(xsize3/2)),"%8.4f")+"\n"+"Y-Position: "+format((top3+(ysize3/2)), "%8.4f")+"\n")
						
						}
						
					}
					
				}
	
			} 
				
			xcorrname = pathconcatenate(pathPDW,"CrossCorrelatedPositions.txt")
			editorWindowSaveToFile(textFile,xcorrname)
			windowClose(textFile,0)
			partContinue = 1
			
			number inc=0, imageoffset=25
			shown=CountImageDocuments(WorkspaceGetActive())
			for(i=0; i<shown; ++i){
				img=getImageDocument(i)
				imageDocumentShowAtPosition(img,24+inc, 24+inc)
				inc=inc+imageoffset
					
			}
			
			showAlert("Check if the cross-correlation worked for each acquired image.\nIf it does not worked, shift the ROI/s to the crystal area/s.\nDo not close them after checking, minimize them if needed.\n\nAfter checking all the reference images, press again the 'Process (...)' button.",2)
		
		}
	
	//Crystal reference positions
	} else if (partContinue==1) {
		
		//Save the positions of the crystal once they are verified and, if necessary, modified
		textFile=NewScriptWindow("Crystal Position", 50,50,150,450)
		editorWindowAddText(textFile,"Initial Angle: "+ initialAngle + "\n" + "Last Angle: " + lastAngle + "\n")
		Result("\n"+"Crystal Positions:" + "\n\n")
	
		shown=CountImageDocuments(WorkspaceGetActive())
		currentImageIndex = 0;
		
		for (i=1;i<totalNumberOfImages+1;i++){
	
			while(i != currentImageIndex){
		
				imgdoc = getImageDocument(totalNumberOfImages-1)
				imageDocumentShow(imgdoc)
				temp := getFrontimage()
				nom = getName(temp)
				strlen=len(nom)
				currentImageIndex = val(right(nom,strlen-14))
			
			}
			
			imgdisp=temp.imageGetImageDisplay(0)
			component squarePosition = ComponentGetChild( imgdisp, 0 )
			ComponentGetRect(squarePosition, top, left, bottom, right)
			Result(nom +"\t"+"X-position: "+ (left+((right-left)/2)) + "\t" + "Y-position: "+(top+((bottom-top)/2))+"\n")
			editorWindowAddText(textFile,"X-Position: "+format((left+((right-left)/2)),"%8.4f")+"\n"+"Y-Position: "+format((top+((bottom-top)/2)), "%8.4f")+"\n")
			
			if (modeOfAcq == 3) {
			
				squarePosition = ComponentGetChild( imgdisp, 1 )
				ComponentGetRect(squarePosition, top, left, bottom, right)
				Result(nom +"_2\t"+"X-position: "+ (left+((right-left)/2)) + "\t" + "Y-position: "+(top+((bottom-top)/2))+"\n")
				editorWindowAddText(textFile,"X-Position: "+format((left+((right-left)/2)),"%8.4f")+"\n"+"Y-Position: "+format((top+((bottom-top)/2)), "%8.4f")+"\n")
				
				if (numTomos == 3) {
				
					squarePosition = ComponentGetChild( imgdisp, 2 )
					ComponentGetRect(squarePosition, top, left, bottom, right)
					Result(nom +"_3\t"+"X-position: "+ (left+((right-left)/2)) + "\t" + "Y-position: "+(top+((bottom-top)/2))+"\n")
					editorWindowAddText(textFile,"X-Position: "+format((left+((right-left)/2)),"%8.4f")+"\n"+"Y-Position: "+format((top+((bottom-top)/2)), "%8.4f")+"\n")
					
				}
			
			}
	
		}
		
		refPositionsName = pathconcatenate(pathPDW,"CrystalReferencePositions.txt")
		editorWindowSaveToFile(textFile,refPositionsName)
		windowClose(textFile,0)
		partContinue = 0
	
		Result("\nAcquisition of Crystal Reference Positions finalized.\n\n")
		
		shown=CountImageDocuments(WorkspaceGetActive())
		for(i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			closeImg:=getFrontImage()
			imageDocumentClose(imgdoc,0)
		}
		
		showAlert("Reference crystal positions acquired.\n\nPress the 'Generate' button to produce the Tracking File.",2)
		self.SetElementisEnabled("generationAcq",1);
		self.SetElementisEnabled("generateFile",1);
		self.SetElementisEnabled("continueAcq",0);

	} 

}


void resetAcq(object self){

	partContinue = 0
	crystTrackEval = 0
	self.SetElementisEnabled("continueAcq",0);
	Result("\nCrystal tracking parameters have been reset.\n\n")
	Result("----------------------------------------------------------------------------------------------\n\n")
	
}


void generateCT(object self){

	number evalCrystBeam = 1

	Result("Generation of Crystal Tracking File\n\n")
				
	try {
				
		number fileReference, Line1, Line2, Line3, fileCrystPost, ok, exposure, totalNumberOfRefImages, iterationsForEachRefPoint 
		number Xinitial, Yinitial, Xfinal, Yfinal, slopeX, slopeY, yCrystpos, xCrystpos, iniAngleFile, Line4, Counter=1, totalXShift=0, totalYShift=0
		number lastAngleFile, numReadOut, readOut, bin, framesShared, otherFramesToGive, factor, lastAngle, velocity, initialAngle, iterations 
		number xBSinitial, yBSinitial, stepAngle, numStepsGenerated = 0, refTiltStep, modeOfAcq, numTomos, totalXShift2=0, totalYShift2=0
		number Xinitial2, Yinitial2, Xfinal2, Yfinal2, slopeX2, slopeY2, Xinitial3, Yinitial3, Xfinal3, Yfinal3, totalXShift3=0, totalYShift3=0
		number slopeX3, slopeY3, xCrystpos2, xCrystpos3, yCrystpos2, yCrystpos3, deltaXToAdd1=0, deltaYToAdd1=0
		number deltaXToAdd2=0, deltaYToAdd2=0, deltaXToAdd3=0, deltaYToAdd3=0
		string directoryCrystPos, nonUsedPart, nonUsedPart2, initialXStr, initialYStr, finalXStr, finalYStr, CrystalTrackPath, directoryCalibration 
		string calibrationPartX, calibrationPartY, rotationAngle, directoryReadOut, Line, nomFile, scaleCaliPart
		documentwindow textFile
		
		if(!SaveAsDialog("Save Crystal Tracking File","CrystalTrackingFile.txt",CrystalTrackPath))exit(0)
		nomFile = PathExtractFilename(CrystalTrackPath, 2)
		
		initialAngle = DLGgetValue(self.LookUpElement("initialAngleCall"))
		lastAngle = DLGgetValue(self.LookUpElement("finalAngleCall"))
		velocity = DLGgetValue(self.LookUpElement("velocityCall"))
		stepAngle = DLGgetValue(self.LookUpElement("stepCall"))
		exposure = DLGgetValue(self.LookUpElement("exposure"))
		refTiltStep = DLGgetValue(self.LookUpElement("tsRefImg"))
		
		getPersistentNumberNote("acqMode",modeOfAcq)
		getPersistentNumberNote("tomoSel",numTomos)
		
		//Read stored readout times in case of continuous sampling
		if (DLGgetValue(checkContinuous) == 1){
			
			directoryReadOut = pathconcatenate(pathPDW, "ReadOutTimes.txt")
			numReadOut = openFileForReading(directoryReadOut)
				
			for(number l = 0; l<((log(binValue)/log(2)) + 1);l++){	
				bin = readFileLine(numReadOut, Line)		
			}
		
			readOut = val(right(Line,len(Line)-16))
			Result("Binning: "+ binValue+"\nReadOut: "+readOut+" s\n\n")
			closeFile(numReadOut)
			
		}
		
		//Read the Crystal Reference Positions
		directoryCrystPos = pathconcatenate(pathPDW, "CrystalReferencePositions.txt")
		fileCrystPost = openFileForReading(directoryCrystPos)
		ok = readFileLine(fileCrystPost, nonUsedPart)
		ok = readFileLine(fileCrystPost, nonUsedPart2)
		iniAngleFile = val(right(nonUsedPart,len(nonUsedPart)-15))
		lastAngleFile = val(right(nonUsedPart2,len(nonUsedPart2)-12))
			
		
		//TEM mode
		if (DSThread == 0) {
		
			//Read the Beam Shift Calibration
			directoryCalibration = pathConcatenate(pathPDW, "BeamShiftCalibration.txt")
			fileReference = openFileForReading(directoryCalibration)
			Line1 = readFileLine(fileReference, calibrationPartX)
			Line2 = readFileLine(fileReference, calibrationPartY)
			Line3 = readFileLine(fileReference, rotationAngle)
			Line4 = readFileLine(fileReference, scaleCaliPart)
			calibrationX = val(right(calibrationPartX,len(calibrationPartX)-15))
			calibrationY = val(right(calibrationPartY,len(calibrationPartY)-15))
			rotAngle = val(right(rotationAngle,len(rotationAngle)-30))
			Result("Calibration X: "+ calibrationX+" a.u./"+unitsString+"\n")
			Result("Calibration Y: "+ calibrationY+" a.u./"+unitsString+"\n")
			Result("Rotation between Image and Coils Framework: "+ rotAngle+"\n\n")
			evalCrystBeam = 0
			closeFile(fileReference)
			
			try {
				
				if(iniAngleFile==initialAngle){
			
					if(lastAngleFile==lastAngle){
						
						if (DLGgetValue(checkContinuous) == 1){
							steps = round(((abs(lastAngle-initialAngle))/velocity)/(exposure + readOut))
							totalNumberOfRefImages = totalNumberOfImages - 1
						} else {	
							steps = round(abs(lastAngle-initialAngle)/stepAngle)
							totalNumberOfRefImages = round(abs(lastAngle-initialAngle)/refTiltStep)
						}
						
						iterationsForEachRefPoint = (steps/totalNumberOfRefImages)
						otherFramesToGive = abs(steps-(round(iterationsForEachRefPoint)*totalNumberOfRefImages))
						framesShared = (totalNumberOfRefImages/otherFramesToGive)
					
						if ((steps-(round(iterationsForEachRefPoint)*totalNumberOfRefImages)) < 0) {
							factor = -1
						} else {
							factor = 1
						}
					
						Result("Steps:\t"+steps+"\tReferenceImages:\t"+totalNumberOfRefImages+"\tIterations:\t"+iterationsForEachRefPoint)
						Result("\nExtra beam positions (non-integer steps):\t"+otherFramesToGive+"\n")
						Result("1st position to place the extra beam positions:\t" + framesShared+"\n")
						Result("Factor:\t"+factor+"\n")
						Result("Scale Calibration from Reference Images:\t"+scaleCaliRefImages+"\n")

						ok = readFileLine(fileCrystPost, initialXStr)
						ok = readFileLine(fileCrystPost, initialYStr)
						Xinitial = val(right(initialXStr,len(initialXStr)-12))
						Yinitial = val(right(initialYStr,len(initialYStr)-12))
						
						if (modeOfAcq == 3) {
							ok = readFileLine(fileCrystPost, initialXStr)
							ok = readFileLine(fileCrystPost, initialYStr)
							Xinitial2 = val(right(initialXStr,len(initialXStr)-12))
							Yinitial2 = val(right(initialYStr,len(initialYStr)-12))
							if (numTomos == 3) {
								ok = readFileLine(fileCrystPost, initialXStr)
								ok = readFileLine(fileCrystPost, initialYStr)
								Xinitial3 = val(right(initialXStr,len(initialXStr)-12))
								Yinitial3 = val(right(initialYStr,len(initialYStr)-12))
							}
						}

						textFile=NewScriptWindow("Crystal Tracking File", 50,50,150,450)
						editorWindowAddText(textFile,nomFile+"\n")
						editorWindowAddText(textFile,"Steps:"+format((steps+1),"%8.0f")+"\n")
						editorWindowAddText(textFile,"Initial Angle:"+format(initialAngle,"%8.0f")+"\n")
						editorWindowAddText(textFile,"Final Angle:"+format(lastAngle,"%8.0f")+"\n")
						
						if (unitsStringRef != unitsString) {
							
							Result("Units for the beam calibration are changed for consistency\n")							
							if (unitsString == "nm") {
								Result("Ref. Images in nm, Calibration in µm\n") 
								Result("scaleCaliRefImages parameter divided by 1000\n")
								scaleCaliRefImages = scaleCaliRefImages/1000
							} else if (unitsString == "µm") {
								Result("Ref. Images in µm, Calibration in nm\n") 
								Result("scaleCaliRefImages parameter multiplied by 1000\n")
								scaleCaliRefImages = scaleCaliRefImages*1000
							}
						}
						
						Result("\nInitial position:\n")
																			
						Result("X-position: "+ 0 + "\tY-position: " + 0 +"\n")
						editorWindowAddText(textFile,"X-Position: "+format(0,"%8.4f")+"\n"+"Y-Position: "+format(0, "%8.4f")+"\n")
																				
						if (modeOfAcq == 3) {								
							Result("X-position2: "+ 0 + "\tY-position2: " + 0 +"\n")
							editorWindowAddText(textFile,"X-Position: "+format(0,"%8.4f")+"\n"+"Y-Position: "+format(0, "%8.4f")+"\n")								
							if (numTomos == 3){								
								Result("X-position3: "+ 0 + "\tY-position3: " + 0 +"\n")
								editorWindowAddText(textFile,"X-Position: "+format(0,"%8.4f")+"\n"+"Y-Position: "+format(0, "%8.4f")+"\n")								
							}
						}
						
						for(number i=1; i<(totalNumberOfRefImages+1);i++){
						
							ok = readFileLine(fileCrystPost, finalXStr)
							ok = readFileLine(fileCrystPost, finalYStr)
							Xfinal = val(right(finalXStr,len(finalXStr)-12))
							Yfinal = val(right(finalYStr,len(finalYStr)-12))
							Result("\n"+i+"\n")
							Result("Xinitial:\t"+Xinitial+"\tYinitial:\t"+Yinitial+"\n")
							Result("Xfinal:\t"+Xfinal+"\tYfinal:\t"+Yfinal+"\n")
							
							if (modeOfAcq == 3) {
								ok = readFileLine(fileCrystPost, finalXStr)
								ok = readFileLine(fileCrystPost, finalYStr)
								Xfinal2 = val(right(finalXStr,len(finalXStr)-12))
								Yfinal2 = val(right(finalYStr,len(finalYStr)-12))
								Result("Xinitial2:\t"+Xinitial2+"\tYinitial2:\t"+Yinitial2+"\n")
								Result("Xfinal2:\t"+Xfinal2+"\tYfinal2:\t"+Yfinal2+"\n")
								if (numTomos == 3) {
									ok = readFileLine(fileCrystPost, finalXStr)
									ok = readFileLine(fileCrystPost, finalYStr)
									Xfinal3 = val(right(finalXStr,len(finalXStr)-12))
									Yfinal3 = val(right(finalYStr,len(finalYStr)-12))
									Result("Xinitial3:\t"+Xinitial3+"\tYinitial3:\t"+Yinitial3+"\n")
									Result("Xfinal3:\t"+Xfinal3+"\tYfinal3:\t"+Yfinal3+"\n")
								}
							}

							Result("Counter X framesShared:\t"+(round(Counter*framesShared))+"\n")
						
							if (i == round(Counter*framesShared)) {							
								iterations = round(iterationsForEachRefPoint) + factor
								Result("Iterations:\t"+iterations+"\t(Extra frame)\n")						
							} else {							
								iterations = round(iterationsForEachRefPoint)
								Result("Iterations:\t"+iterations+"\n")
							}
						
							if (iterations != 0) {
							
								slopeX = ((Xfinal-Xinitial))/iterations
								slopeY = ((Yfinal-Yinitial))/iterations
								Result("slopeX:\t"+slopeX+"\tslopeY:\t"+slopeY+"\n")
								
								if (modeOfAcq == 3) {
									slopeX2 = ((Xfinal2-Xinitial2))/iterations
									slopeY2 = ((Yfinal2-Yinitial2))/iterations
									Result("slopeX2:\t"+slopeX2+"\tslopeY2:\t"+slopeY2+"\n")
									if (numTomos == 3) {
										slopeX3 = ((Xfinal3-Xinitial3))/iterations
										slopeY3 = ((Yfinal3-Yinitial3))/iterations
										Result("slopeX:\t"+slopeX3+"\tslopeY3:\t"+slopeY3+"\n")
									}
								}
							
								for(number j=1; j<((iterations+1));j++){
									xCrystpos = ((cos(rotAngle*pi()/180)*slopeX) + (sin(rotAngle*pi()/180)*(-slopeY)))*calibrationX*scaleCaliRefImages
									yCrystpos = ((-sin(rotAngle*pi()/180)*slopeX) + (cos(rotAngle*pi()/180)*(-slopeY)))*calibrationY*scaleCaliRefImages
									
									xCrystpos = xCrystpos-deltaXToAdd1
									deltaXtoAdd1 = round(xCrystpos)-xCrystpos
									xCrystpos = round(xCrystpos)
									
									yCrystpos = yCrystpos-deltaYToAdd1
									deltaYtoAdd1 = round(yCrystpos)-yCrystpos
									yCrystpos = round(yCrystpos)
									
									Result("X-position: "+ (xCrystpos) + "\tY-position: " + (yCrystpos) +"\tdeltaX: "+deltaYtoAdd1+"\tdeltaY: "+deltaYtoAdd1+"\n")
									editorWindowAddText(textFile,"X-Position: "+format(xCrystpos,"%8.4f")+"\n"+"Y-Position: "+format(yCrystpos, "%8.4f")+"\n")	
									numStepsGenerated = numStepsGenerated + 1
									totalXShift = totalXShift + xCrystpos
									totalYShift = totalYShift + yCrystpos
									if (modeOfAcq == 3) {
										xCrystpos2 = ((cos(rotAngle*pi()/180)*slopeX2) + (sin(rotAngle*pi()/180)*(-slopeY2)))*calibrationX*scaleCaliRefImages
										yCrystpos2 = ((-sin(rotAngle*pi()/180)*slopeX2) + (cos(rotAngle*pi()/180)*(-slopeY2)))*calibrationY*scaleCaliRefImages
										
										xCrystpos2 = xCrystpos2-deltaXToAdd2
										deltaXtoAdd2 = round(xCrystpos2)-xCrystpos2
										xCrystpos2 = round(xCrystpos2)
									
										yCrystpos2 = yCrystpos2-deltaYToAdd2
										deltaYtoAdd2 = round(yCrystpos2)-yCrystpos2
										yCrystpos2 = round(yCrystpos2)
										
										Result("X-position2: "+ (xCrystpos2) + "\tY-position2: " + (yCrystpos2) +"\n")
										editorWindowAddText(textFile,"X-Position: "+format(xCrystpos2,"%8.4f")+"\n"+"Y-Position: "+format(yCrystpos2, "%8.4f")+"\n")
										numStepsGenerated = numStepsGenerated + 1
										totalXShift2 = totalXShift2 + xCrystpos2
										totalYShift2 = totalYShift2 + yCrystpos2
										if (numTomos == 3) {
											xCrystpos3 = ((cos(rotAngle*pi()/180)*slopeX3) + (sin(rotAngle*pi()/180)*(-slopeY3)))*calibrationX*scaleCaliRefImages
											yCrystpos3 = ((-sin(rotAngle*pi()/180)*slopeX3) + (cos(rotAngle*pi()/180)*(-slopeY3)))*calibrationY*scaleCaliRefImages
											
											xCrystpos3 = xCrystpos3-deltaXToAdd3
											deltaXtoAdd3 = round(xCrystpos3)-xCrystpos3
											xCrystpos3 = round(xCrystpos3)
											
											yCrystpos3 = yCrystpos3-deltaYToAdd3
											deltaYtoAdd3 = round(yCrystpos3)-yCrystpos3
											yCrystpos3 = round(yCrystpos3)
											
											Result("X-position3: "+ (xCrystpos3) + "\tY-position3: " + (yCrystpos3) +"\n")
											editorWindowAddText(textFile,"X-Position: "+format(xCrystpos3,"%8.4f")+"\n"+"Y-Position: "+format(yCrystpos3, "%8.4f")+"\n")
											numStepsGenerated = numStepsGenerated + 1
											totalXShift3 = totalXShift3 + xCrystpos3
											totalYShift3 = totalYShift3 + yCrystpos3	
										}
									}
								}
						
							}
						
							if (i == round(Counter*framesShared)) {
								Counter = Counter + 1
							}
						
							Xinitial = Xfinal
							Yinitial = Yfinal	
							
							if (modeOfAcq == 3) {			
								Xinitial2 = Xfinal2
								Yinitial2 = Yfinal2
								if (numTomos == 3) {
									Xinitial3 = Xfinal3
									Yinitial3 = Yfinal3
								}
							}
		
						}

			
						Result("\nPresumed Steps:\t"+(steps)+"\n")
						Result("Generated Steps:\t"+(numStepsGenerated)+"\n")
						Result("Total X shift (a.u.):\t"+totalXShift+"\tTotal Y shift (a.u.):\t"+totalYShift+"\n\n")
					
						closeFile(fileCrystPost)
						editorWindowSaveToFile(textFile,CrystalTrackPath)
						windowClose(textFile,0)
			
						showAlert("The Crystal Tracking File has been created.",2)	
						Result("The Crystal Tracking File has been created.\n\n")
						Result("----------------------------------------------------------------------------------------------\n\n")
					
					} else {
				
						showAlert("The final angle does not correspond to the final angle of the CrystalReferencePositions.txt file",1)
						Result("The final angle should be the same as the one used on the acquisition of the CrystalReferencePositions.txt file\n")
						Result("Otherwise, acquire another CrystalReferencePositions.txt file for the new last angle.\n\n")
						Result("----------------------------------------------------------------------------------------------\n\n")
						closeFile(fileReference)
						closeFile(fileCrystPost)
				
					}
				
				} else {
			
					showAlert("The initial angle does not correspond to the initial angle of the CrystalReferencePositions.txt file",1)
					Result("The initial angle should be the same as the one used on the acquisition of the CrystalReferencePositions.txt file.\n")
					Result("Otherwise, acquire another CrystalReferencePositions.txt file for the new inital angle.\n\n")
					Result("----------------------------------------------------------------------------------------------\n\n")
					closeFile(fileReference)
					closeFile(fileCrystPost)
				
				}
			
			} catch {
			
				showAlert("The CrystalReferencePositions.txt file and/or the ReadOutTimes.txt file are not created.",1)
				closeFile(fileReference)
				Result("----------------------------------------------------------------------------------------------\n\n")
				evalCrystBeam = 0
			
			}
		
		//STEM mode
		} else {
			
			if(iniAngleFile==initialAngle){
		
				if(lastAngleFile==lastAngle){
				
					if (DLGgetValue(checkContinuous) == 1) {	
						steps = round(((abs(lastAngle-initialAngle))/velocity)/(exposure+readOut))
					} else {
						steps = round(abs(lastAngle-initialAngle)/stepAngle)
					}
				
					totalNumberOfRefImages = round(abs(lastAngle-initialAngle)/refTiltStep)
					iterationsForEachRefPoint = (steps/totalNumberOfRefImages)
					otherFramesToGive = abs(steps-(round(iterationsForEachRefPoint)*totalNumberOfRefImages))
					framesShared = (totalNumberOfRefImages/otherFramesToGive)
					
					if ((steps-(round(iterationsForEachRefPoint)*totalNumberOfRefImages)) < 0) {
						factor = -1
					} else {
						factor = 1
					}
					
					Result("Steps:\t"+steps+"\tReferenceImages:\t"+totalNumberOfRefImages+"\tIterations:\t"+iterationsForEachRefPoint)
					Result("Steps:\t"+(steps+1)+"\tReferenceImages:\t"+totalNumberOfRefImages+"\tIterations:\t"+iterationsForEachRefPoint)
					Result("\nExtra beam positions (non-integer steps):\t"+otherFramesToGive+"\n")
					Result("1st position to place the extra beam positions:\t" + framesShared+"\n")
					Result("Factor:\t"+factor+"\n\n")

					ok = readFileLine(fileCrystPost, initialXStr)
					ok = readFileLine(fileCrystPost, initialYStr)
					Xinitial = val(right(initialXStr,len(initialXStr)-12))
					Yinitial = val(right(initialYStr,len(initialYStr)-12))
					
					if (modeOfAcq == 3) {
						ok = readFileLine(fileCrystPost, initialXStr)
						ok = readFileLine(fileCrystPost, initialYStr)
						Xinitial2 = val(right(initialXStr,len(initialXStr)-12))
						Yinitial2 = val(right(initialYStr,len(initialYStr)-12))
						if (numTomos == 3) {
							ok = readFileLine(fileCrystPost, initialXStr)
							ok = readFileLine(fileCrystPost, initialYStr)
							Xinitial3 = val(right(initialXStr,len(initialXStr)-12))
							Yinitial3 = val(right(initialYStr,len(initialYStr)-12))
						}
					}

					textFile=NewScriptWindow("Crystal Tracking File", 50,50,150,450)
					editorWindowAddText(textFile,nomFile+"\n")
					editorWindowAddText(textFile,"Steps:"+format((steps+1),"%8.0f")+"\n")
					editorWindowAddText(textFile,"Initial Angle:"+format(initialAngle,"%8.0f")+"\n")
					editorWindowAddText(textFile,"Final Angle:"+format(lastAngle,"%8.0f")+"\n")
						
					Result("0"+"\n"+"Initial position:"+"\n")
					
					if (DLGgetValue(checkContinuous) == 1) {
						Result("X-position: "+(x_after-x_before)+"\t"+"Y-position: "+(y_after-y_before)+"\n")
						editorWindowAddText(textFile,"X-Position: "+format((x_after-x_before),"%8.4f")+"\n"+"Y-Position: "+format((y_after-y_before), "%8.4f")+"\n")	
					} else {
						Result("X-position: "+ 0 + "\t" + "Y-position: " + 0 +"\n")
						editorWindowAddText(textFile,"X-Position: "+format(0,"%8.4f")+"\n"+"Y-Position: "+format(0, "%8.4f")+"\n")	
						if (modeOfAcq == 3) {
							Result("X-position2: "+ 0 + "\t" + "Y-position2: " + 0 +"\n")
							editorWindowAddText(textFile,"X-Position: "+format(0,"%8.4f")+"\n"+"Y-Position: "+format(0, "%8.4f")+"\n")
							if (numTomos == 3) {
								Result("X-position3: "+ 0 + "\t" + "Y-position3: " + 0 +"\n")
								editorWindowAddText(textFile,"X-Position: "+format(0,"%8.4f")+"\n"+"Y-Position: "+format(0, "%8.4f")+"\n")	
							}
						}
					}
					
					for(number i=1; i<(totalNumberOfRefImages+1);i++){
						
						ok = readFileLine(fileCrystPost, finalXStr)
						ok = readFileLine(fileCrystPost, finalYStr)
						Xfinal = val(right(finalXStr,len(finalXStr)-12))
						Yfinal = val(right(finalYStr,len(finalYStr)-12))
						Result("\n"+i+"\n")
						Result("Xinitial:"+"\t"+Xinitial+"\t"+"Yinitial:"+"\t"+Yinitial+"\n")
						Result("Xfinal:"+"\t"+Xfinal+"\t"+"Yfinal:"+"\t"+Yfinal+"\n")
						
						if (modeOfAcq == 3) {
							ok = readFileLine(fileCrystPost, finalXStr)
							ok = readFileLine(fileCrystPost, finalYStr)
							Xfinal2 = val(right(finalXStr,len(finalXStr)-12))
							Yfinal2 = val(right(finalYStr,len(finalYStr)-12))
							Result("Xinitial2:"+"\t"+Xinitial2+"\t"+"Yinitial2:"+"\t"+Yinitial2+"\n")
							Result("Xfinal2:"+"\t"+Xfinal2+"\t"+"Yfinal2:"+"\t"+Yfinal2+"\n")
							if (numTomos == 3) {
								ok = readFileLine(fileCrystPost, finalXStr)
								ok = readFileLine(fileCrystPost, finalYStr)
								Xfinal3 = val(right(finalXStr,len(finalXStr)-12))
								Yfinal3 = val(right(finalYStr,len(finalYStr)-12))
								Result("Xinitial3:"+"\t"+Xinitial3+"\t"+"Yinitial3:"+"\t"+Yinitial3+"\n")
								Result("Xfinal3:"+"\t"+Xfinal3+"\t"+"Yfinal3:"+"\t"+Yfinal3+"\n")
							}
						}

						Result("Counter X framesShared:"+"\t"+(round(Counter*framesShared))+"\n")
						
						if (i == round(Counter*framesShared)) {							
							iterations = round(iterationsForEachRefPoint) + factor
							Result("Iterations:"+"\t"+iterations+"\t"+"(Extra frame)"+"\n")						
						} else {							
							iterations = round(iterationsForEachRefPoint)
							Result("Iterations:"+"\t"+iterations+"\n")
						}
						
						if (iterations != 0) {							
							slopeX = ((Xfinal-Xinitial))/iterations
							slopeY = ((Yfinal-Yinitial))/iterations
							Result("slopeX:"+"\t"+slopeX+"\t"+"slopeY:"+"\t"+slopeY+"\n")							
							if (modeOfAcq == 3) {
								slopeX2 = ((Xfinal2-Xinitial2))/iterations
								slopeY2 = ((Yfinal2-Yinitial2))/iterations
								Result("slopeX2:"+"\t"+slopeX2+"\t"+"slopeY2:"+"\t"+slopeY2+"\n")
								if (numTomos == 3) {
									slopeX3 = ((Xfinal3-Xinitial3))/iterations
									slopeY3 = ((Yfinal3-Yinitial3))/iterations
									Result("slopeX:"+"\t"+slopeX3+"\t"+"slopeY3:"+"\t"+slopeY3+"\n")
								}
							}
							
							for(number j=1; j<((iterations+1));j++){
								Result("X-position: "+ (slopeX) + "\t" + "Y-position: " + (slopeY) +"\n")
								editorWindowAddText(textFile,"X-Position: "+format(slopeX,"%8.4f")+"\n"+"Y-Position: "+format(slopeY, "%8.4f")+"\n")	
								numStepsGenerated = numStepsGenerated + 1
								totalXShift = totalXShift + slopeX
								totalYShift = totalYShift + slopeY									
								if (modeOfAcq == 3) {								
									Result("X-position2: "+ (slopeX2) + "\t" + "Y-position2: " + (slopeY2) +"\n")
									editorWindowAddText(textFile,"X-Position2: "+format(slopeX2,"%8.4f")+"\n"+"Y-Position2: "+format(slopeY2, "%8.4f")+"\n")	
									numStepsGenerated = numStepsGenerated + 1
									totalXShift2 = totalXShift2 + slopeX2
									totalYShift2 = totalYShift2 + slopeY2									
									if (numTomos == 3) {										
										Result("X-position3: "+ (slopeX3) + "\t" + "Y-position3: " + (slopeY3) +"\n")
										editorWindowAddText(textFile,"X-Position3: "+format(slopeX3,"%8.4f")+"\n"+"Y-Position3: "+format(slopeY3, "%8.4f")+"\n")	
										numStepsGenerated = numStepsGenerated + 1
										totalXShift3 = totalXShift3 + slopeX3
										totalYShift3 = totalYShift3 + slopeY3										
									}		
								}
							}
						
						}
						
						if (i == round(Counter*framesShared)) {
							Counter = Counter + 1					
						}
						
						Xinitial = Xfinal
						Yinitial = Yfinal
						
						if (modeOfAcq == 3) {								
							Xinitial2 = Xfinal2
							Yinitial2 = Yfinal2							
							if (numTomos == 3) {						
								Xinitial3 = Xfinal3
								Yinitial3 = Yfinal3							
							}							
						}
		
					}

			
					Result("\nSuposed Steps:\t"+steps+"\n")
					Result("Generated Steps:\t"+numStepsGenerated+"\n")
					Result("Total X shift:\t"+totalXShift+"\tTotal Y shift:\t"+totalYShift+"\n\n")
					
					closeFile(fileCrystPost)
					editorWindowSaveToFile(textFile,CrystalTrackPath)
					windowClose(textFile,0)
					
					showAlert("The Crystal Tracking File has been created.",2)	
					Result("The Crystal Tracking File has been created.\n\n")
					Result("----------------------------------------------------------------------------------------------\n\n")
					
			
				} else {
			
					showAlert("The final angle does not correspond to the final angle of the CrystalReferencePositions.txt file",1)
					Result("The final angle should be the same as the one used on the acquisition of the CrystalReferencePositions.txt file\n")
					Result("Otherwise, acquire another CrystalReferencePositions.txt file for the new last angle.\n\n")
					Result("----------------------------------------------------------------------------------------------\n\n")
					closeFile(fileReference)
					closeFile(fileCrystPost)
				
				}
				
			} else {
			
				showAlert("The initial angle does not correspond to the initial angle of the CrystalReferencePositions.txt file",1)
				Result("The initial angle should be the same as the one used on the acquisition of the CrystalReferencePositions.txt file\n")
				Result("Otherwise, acquire another CrystalReferencePositions.txt file for the new inital angle.\n\n")
				Result("----------------------------------------------------------------------------------------------\n\n")
				closeFile(fileReference)
				closeFile(fileCrystPost)
				
			}
		
		}
	} catch {
		
		if ( evalCrystBeam!=0 ){
			showAlert("Beam Shift is not calibrated or you are trying to replace a file which is currently being used.",1)
			Result("----------------------------------------------------------------------------------------------\n\n")			
		}
			
	}

}


void loadCTFile (object self){

	number filereference, ok, evaluadorText = 1
	string name, textSteps
	number iniAngleADT = DLGgetValue(self.LookUpElement("initialAngleCall"))
	documentwindow win
	
	if(!opendialog(win,"Select your Crystal Tracking File","*.txt;*.s",path)) exit(0)
	filereference=openFileForReading(path)
	setPersistentNumberNote("Referencia Text",filereference)
	setPersistentNumberNote("Evaluar Text",evaluadorText)
	self.SetElementIsEnabled("reiniciar",0)
	ok= readFileLine(filereference,name)
	name = left(name,len(name)-2)
	DLGValue(crtString,name)
	ok= readFileLine(filereference,textSteps)
	steps = val(right(textSteps,len(textSteps)-6))
	
	self.SetElementIsEnabled("ctIniPos",1)
	self.SetElementIsEnabled("start",0)
	
	Result("\n\nFast-ADT: Acquisition\n\n")
	Result("Number of DPs to be acquired:\t"+steps+"\n\n")
	
	if (DLGgetValue(checkContinuous) == 1){
		EMSetStageAlpha(iniAngleADT-2)
		EMWaitUntilReady()
		EMSetStageAlpha(iniAngleADT-1)
		EMWaitUntilReady()	
	} else {
		EMSetStageAlpha(iniAngleADT-1)
		EMWaitUntilReady()
		EMSetStageAlpha(iniAngleADT)
		EMWaitUntilReady()
	}

}	


// Function to start the thread for beam position
void startBeamThread(object self){
	Positioning.init().StartThread("Start")
	return
}

	
// Function to stop the thread for beam position
void stopBeamThread(object self){
	Positioning.Stop()
	return
}


void iniBeamPos (object self){
	
	number xsize, ysize, originNonUsed, shown, isViewImgDisplayed
	camera = CM_GetCurrentCamera()
	object view_params = CM_GetCameraAcquisitionParameterSet(camera, "Imaging", "View", "Search", 1)
	image img
	imageDocument imgDoc
	number modeOfAcq, numTomos
	getPersistentNumberNote("acqMode",modeOfAcq)
	getPersistentNumberNote("tomoSel",numTomos)
	
	if(beamSize == 0){
	
		showAlert("Beam size has not been stored.\nSet the beam size in the 'Parameters Setup' section before proceeding with the acquisition.",1)
	
	} else {
		
		//STEM mode
		if (DSThread == 1) {
		
			if(iniPosRef == 0){
				
				//EMSetBeamShift(0,0)  // Only for FEI microscopes !!!!!
				//EMSetFocus(beamScanningSize)
				self.setScanBeam()
				Result("\nBeam for Scan Imaging\n")
				
				shown=CountImageDocuments(WorkspaceGetActive())
				for(number i=0; i<shown; ++i){
					imgDoc=getImageDocument(0)
					imageDocumentClose(imgdoc,0)
				}
				
				number originNonUsed
				refDSimg := IntegerImage("Drag the ROI to the initial Beam Probe position", 2, 0, 512, 512)
				DSInvokeButton(3)
				DSWaitUntilFinished( )
				DSInvokeButton(5,1)
				DSWaitUntilFinished( )
				refDSImg := getFrontImage()
				ImageGetDimensionCalibration(refDSimg, 0, originNonUsed, scaleCali, unitsString, 1)
				setName(refDSImg,"FastADT - Initial Position")
				
				imagedisplay imgdisp = refDSimg.ImageGetImageDisplay(0)
				component circle =newovalannotation(150,150,200,200)
				circle.componentsetforegroundcolor(1,0,0)
				ComponentSetDeletable(circle,0)
				ComponentSetResizable(circle,0)
				imgdisp.componentaddchildatend(circle)
				if (modeOfAcq == 3) {	
					component circle2 =newovalannotation(250,250,300,300)
					circle2.componentsetforegroundcolor(0,1,0)
					ComponentSetDeletable(circle2,0)
					ComponentSetResizable(circle2,0)
					imgdisp.componentaddchildatend(circle2)
					if (numTomos == 3) {
						component circle3 =newovalannotation(350,350,400,400)
						circle3.componentsetforegroundcolor(0,0,1)
						ComponentSetDeletable(circle3,0)
						ComponentSetResizable(circle3,0)
						imgdisp.componentaddchildatend(circle3)
					}
				}
				
				self.setDiffBeam()
				
				CM_StartCameraViewer(camera, view_params, 1, 1)
				isViewImgDisplayed=CountImageDocuments(WorkspaceGetActive())
				while(isViewImgDisplayed == 1){
					isViewImgDisplayed=CountImageDocuments(WorkspaceGetActive())
				}
				
				image imgForCamcenter := GetFrontImage()
				setName(imgForCamcenter,"FastADT - Diffraction Pattern Centring")
				imageDisplay vectordisp=imgForCamcenter.imageGetImageDisplay(0)
				component line1 = newLineAnnotation(1,1,imgForCamcenter.ImageGetDimensionSize(0),imgForCamcenter.ImageGetDimensionSize(1))
				line1.componentsetforegroundcolor(1,0,0)
				vectordisp.componentaddchildatend(line1)
				component line2 = newLineAnnotation(1,imgForCamcenter.ImageGetDimensionSize(0),imgForCamcenter.ImageGetDimensionSize(1),1)
				line2.componentsetforegroundcolor(1,0,0)
				vectordisp.componentaddchildatend(line2)
				WorkspaceArrange(WorkspaceGetActive(),0,0)
				
				showAlert("Drag the circle ROI to the desired initial beam position.\nSubsequently, press again the 'Initial Beam Position' button.\n\nCaution: The Beam ROI is the current position of the beam.",2)
				
				iniPosRef = 1
			
			} else {
				
				number top_1, left_1, bottom_1, right_1, top_2, left_2, bottom_2, right_2, top_3, left_3, bottom_3, right_3
				shown=CountImageDocuments(WorkspaceGetActive())
				string wantedName
				image positionImg
				
				for(number i=0; i<shown; ++i){
					imgDoc=getImageDocument(i)
					imageDocumentShow(imgDoc)
					img:=getFrontImage()
					wantedName = getName(img)
					if (wantedName == "FastADT - Initial Position") {
						positionImg := img
					} else {
						ImageGetDimensionCalibration(img, 0, originProjRef, scaleCaliProjRef, unitsStringProjRef, 1)
					}
				}
				
				imagedisplay imgdisp=positionImg.imageGetImageDisplay(0)
				component firstCry = ComponentGetChild( imgdisp, 2 )
				ComponentGetRect(firstCry, top_1, left_1, bottom_1, right_1)
				initialBeamPosX = left_1+((right_1-left_1)/2)
				initialBeamPosY = top_1+((bottom_1-top_1)/2)
				Result("Selected initial Probe position -> X: "+initialBeamPosX+" Y: "+initialBeamPosY+"\n\n")
				
				if (modeOfAcq == 3) {	
					
					component secondCry = ComponentGetChild( imgdisp, 3 )
					ComponentGetRect(secondCry, top_2, left_2, bottom_2, right_2)
					initialBeamPosX_2 = left_2+((right_2-left_2)/2)
					initialBeamPosY_2 = top_2+((bottom_2-top_2)/2)
					Result("Selected initial Probe position for 2nd crystal -> X: "+initialBeamPosX_2+" Y: "+initialBeamPosY_2+"\n\n")
					
					if (numTomos == 3) {
					
						component thirdCry = ComponentGetChild( imgdisp, 4 )
						ComponentGetRect(thirdCry, top_3, left_3, bottom_3, right_3)
						initialBeamPosX_3 = left_3+((right_3-left_3)/2)
						initialBeamPosY_3 = top_3+((bottom_3-top_3)/2)
						Result("Selected initial Probe position for 3rd crystal -> X: "+initialBeamPosX_3+" Y: "+initialBeamPosY_3+"\n\n")
						
					}
					
				} 
				
				showAlert("Ready for Fast-ADT acquisition.",2)
				
				for(number j=0; j<shown; ++j){
					imgDoc=getImageDocument(0)
					imageDocumentClose(imgdoc,0)
				}
				
				iniPosRef = 0
				self.SetElementIsEnabled("start",1)
				
			}
		
		//TEM mode
		} else {
			
			if(iniPosRef == 0){
			
				shown=CountImageDocuments(WorkspaceGetActive())
				for(number j=0; j<shown; ++j){
					imgDoc=getImageDocument(0)
					imageDocumentClose(imgdoc,0)
				}
				
				//Acquisition of the Reference Image with the imaging settings of the beam
				self.setScanBeam()
				diffIcon.DLGGetElement(0).DLGBitmapData(nonActiveLED)
				imgIcon.DLGGetElement(0).DLGBitmapData(imgGreLED)
				CameraPrepareForAcquire(camID)
				img := CameraAcquire(camID, DLGgetValue(self.LookUpElement("imgCamTime")), binValue, binValue, procValue)
				setName(img,"FastADT - Initial Position(s)")
				showimage(img)
				imagedisplay imgdisp = img.ImageGetImageDisplay(0)
				component circle =newovalannotation(150,150,250,250)
				circle.componentsetforegroundcolor(1,0,0)
				ComponentSetDeletable(circle,0)
				ComponentSetResizable(circle,0)
				imgdisp.componentaddchildatend(circle)
				if (modeOfAcq == 3) {	
					component circle2 =newovalannotation(250,250,350,350)
					circle2.componentsetforegroundcolor(0,1,0)
					ComponentSetDeletable(circle2,0)
					ComponentSetResizable(circle2,0)
					imgdisp.componentaddchildatend(circle2)
					if (numTomos == 3) {
						component circle3 =newovalannotation(350,350,450,450)
						circle3.componentsetforegroundcolor(0,0,1)
						ComponentSetDeletable(circle3,0)
						ComponentSetResizable(circle3,0)
						imgdisp.componentaddchildatend(circle3)
					}
				}	
				
				//Acquisition of a non-displayed Image to find where the beam is with the diffraction setting
				self.setDiffBeam()
				CameraPrepareForAcquire(camID)
				image refBeamPosition := CameraAcquire(camID, DLGgetValue(self.LookUpElement("imgCamTime")), binValue, binValue, procValue)
				ImageGetDimensionCalibration(refBeamPosition, 0, originNonUsed, scaleCali, unitsString, 1)
				
				//Looking for the center of mass
				number imgSum = sum(refBeamPosition)
				getsize(refBeamPosition,xsize,ysize)
				image xproj = RealImage("",4,xsize,1)
				xproj[icol,0]+=refBeamPosition
				image invImg = RealImage("",4,ysize,xsize)
				invImg = refBeamPosition[irow,icol]
				image yproj = RealImage("",4,ysize,1)
				yproj[icol,0]+=invImg
				yproj=yproj*(icol+1)
				xproj=xproj*(icol+1)
				center_x=sum(xproj)
				center_y=sum(yproj)
				center_x=(center_x/imgSum)-1
				center_y=(center_y/imgSum)-1
				
				Result("Current beam position:\n"+"X:\t"+center_x+"\nY:\t"+center_y+"\n")
				roisetcircle(roiBeamPosition,center_x,center_y,100)
				ROISetDeletable(roiBeamPosition,0)
				ROISetResizable(roiBeamPosition,0)
				imgdisp.ImageDisplayAddRoi(roiBeamPosition)
				imageDisplaySetRoiSelected(imgdisp, roiBeamPosition,1)
				
				self.startBeamThread()
				iniPosRef = 1
				
				string msg1 = "Drag the Circle Annotation to the desired initial Beam position."
				string msg2 = "\nSubsequently press again the 'Initial Beam Position' button.\n\nCaution: The ROI is the current position of the beam."
				showAlert(msg1 + msg2,2)
				
				CM_StartCameraViewer(camera, view_params, 1, 1)
				isViewImgDisplayed=CountImageDocuments(WorkspaceGetActive())
				while(isViewImgDisplayed == 1){
					isViewImgDisplayed=CountImageDocuments(WorkspaceGetActive())
				}
				image imgForCamcenter := GetFrontImage()
				setName(imgForCamcenter,"FastADT - Diffraction Pattern Centering")
				imageDisplay vectordisp=imgForCamcenter.imageGetImageDisplay(0)
				component line1 = newLineAnnotation(1,1,imgForCamcenter.ImageGetDimensionSize(0),imgForCamcenter.ImageGetDimensionSize(1))
				line1.componentsetforegroundcolor(1,0,0)
				vectordisp.componentaddchildatend(line1)
				component line2 = newLineAnnotation(1,imgForCamcenter.ImageGetDimensionSize(0),imgForCamcenter.ImageGetDimensionSize(1),1)
				line2.componentsetforegroundcolor(1,0,0)
				vectordisp.componentaddchildatend(line2)
				
				WorkspaceArrange(WorkspaceGetActive(),0,0)
				
				
			} else {
				
				number top_0, left_0, bottom_0, right_0, top_1, left_1, bottom_1, right_1, top_2, left_2, bottom_2, right_2, top_3, left_3, bottom_3, right_3, l
				number curBeamProbeX, curBeamProbeY, iniPosCryTEMx, iniPosCryTEMx_2, iniPosCryTEMx_3, iniPosCryTEMy, iniPosCryTEMy_2, iniPosCryTEMy_3
				image refImg, front
				
				shown=CountImageDocuments(WorkspaceGetActive())
				string evalName
				for(l=0; l < shown; l++){
					imgDoc=getImageDocument(l)
					imageDocumentShow(imgDoc)
					refImg := getFrontImage()
					getName(refImg,evalName)
					if (evalName == ("FastADT - Initial Position(s)")) {
						front := refImg
					}	
				}
				
				//Read the Beam Shift Calibration
				string directoryCalibration = pathConcatenate(pathPDW, "BeamShiftCalibration.txt")
				string calibrationPartX, calibrationPartY, rotationAngle
				number fileReference = openFileForReading(directoryCalibration)		
				number Line1 = readFileLine(fileReference, calibrationPartX)
				number Line2 = readFileLine(fileReference, calibrationPartY)
				number Line3 = readFileLine(fileReference, rotationAngle)
				calibrationX = val(right(calibrationPartX,len(calibrationPartX)-15))
				calibrationY = val(right(calibrationPartY,len(calibrationPartY)-15))
				rotAngle = val(right(rotationAngle,len(rotationAngle)-30))
				closeFile(fileReference)
				
				self.stopBeamThread()
				imagedisplay imgdisp=front.imageGetImageDisplay(0)
				
				component roiBeamPosition = ComponentGetChild( imgdisp, 0)
				ComponentGetRect(roiBeamPosition, top_0, left_0, bottom_0, right_0)
				curBeamProbeX = left_0+((right_0-left_0)/2)
				curBeamProbeY = top_0+((bottom_0-top_0)/2)
				
				component firstCry = ComponentGetChild( imgdisp, 1)
				ComponentGetRect(firstCry, top_1, left_1, bottom_1, right_1)
				iniPosCryTEMx = left_1+((right_1-left_1)/2)
				iniPosCryTEMy = top_1+((bottom_1-top_1)/2)
				Result("Selected initial Probe position -> X: "+iniPosCryTEMx+" Y: "+iniPosCryTEMy+"\n")
				
				if (modeOfAcq == 3) {	
					
					component secondCry = ComponentGetChild( imgdisp, 2 )
					ComponentGetRect(secondCry, top_2, left_2, bottom_2, right_2)
					iniPosCryTEMx_2 = left_2+((right_2-left_2)/2)
					iniPosCryTEMy_2 = top_2+((bottom_2-top_2)/2)
					Result("Selected initial Probe position for 2nd crystal -> X: "+iniPosCryTEMx_2+" Y: "+iniPosCryTEMy_2+"\n\n")
					
					if (numTomos == 3) {
					
						component thirdCry = ComponentGetChild( imgdisp, 3 )
						ComponentGetRect(thirdCry, top_3, left_3, bottom_3, right_3)
						iniPosCryTEMx_3 = left_3+((right_3-left_3)/2)
						iniPosCryTEMy_3 = top_3+((bottom_3-top_3)/2)
						Result("Selected initial Probe position for 3rd crystal -> X: "+iniPosCryTEMx_3+" Y: "+iniPosCryTEMy_3+"\n\n")
						
					}
					
				} 
				
				if (unitsStringRef != unitsString) {
							
					Result("Units for the beam calibration are changed for consistency\n")
							
					if (unitsString == "nm") {
							
						scaleCali = scaleCali/1000
							
					} else if (unitsString == "µm") {
							
						scaleCali = scaleCali*1000
						
					}
							
				}
				
				EMGetBeamShift(initialBeamPosX, initialBeamPosY)
				EMWaitUntilReady()
				
				Xshift = ((cos(rotAngle*pi()/180)*(iniPosCryTEMx - curBeamProbeX)) + (sin(rotAngle*pi()/180)*(-(iniPosCryTEMy - curBeamProbeY))))*calibrationX*scaleCali
				Yshift = ((-sin(rotAngle*pi()/180)*(iniPosCryTEMx - curBeamProbeX)) + (cos(rotAngle*pi()/180)*(-(iniPosCryTEMy - curBeamProbeY))))*calibrationY*scaleCali
				initialBeamPosX += Xshift
				initialBeamPosY += Yshift
				Result("Initial Beam Shift:\nX:\t"+initialBeamPosX+"\nY:\t"+initialBeamPosY+"\n\n")
				
				if (modeOfAcq == 3) {	
				
					Xshift2 = ((cos(rotAngle*pi()/180)*(iniPosCryTEMx_2 - iniPosCryTEMx)) + (sin(rotAngle*pi()/180)*(-(iniPosCryTEMy_2 - iniPosCryTEMy))))*calibrationX*scaleCali
					Yshift2 = ((-sin(rotAngle*pi()/180)*(iniPosCryTEMx_2 - iniPosCryTEMx)) + (cos(rotAngle*pi()/180)*(-(iniPosCryTEMy_2 - iniPosCryTEMy))))*calibrationY*scaleCali
					initialBeamPosX_2 = initialBeamPosX + Xshift2
					initialBeamPosY_2 = initialBeamPosY + Yshift2
					Result("Initial Beam Shift for 2nd crystal:\nX:\t"+initialBeamPosX_2+"\nY:\t"+initialBeamPosY_2+"\n\n")
					
					if (numTomos == 3) {
					
						Xshift3 = ((cos(rotAngle*pi()/180)*(iniPosCryTEMx_3 - iniPosCryTEMx_2)) + (sin(rotAngle*pi()/180)*(-(iniPosCryTEMy_3 - iniPosCryTEMy_2))))*calibrationX*scaleCali
						Yshift3 = ((-sin(rotAngle*pi()/180)*(iniPosCryTEMx_3 - iniPosCryTEMx_2)) + (cos(rotAngle*pi()/180)*(-(iniPosCryTEMy_3 - iniPosCryTEMy_2))))*calibrationY*scaleCali
						initialBeamPosX_3 = initialBeamPosX_2 + Xshift3
						initialBeamPosY_3 = initialBeamPosY_2 + Yshift3
						Result("Initial Beam Shift for 3rd crystal:\nX:\t"+initialBeamPosX_3+"\nY:\t"+initialBeamPosY_3+"\n\n")
					
					}
					
				}
				
				showAlert("Ready for Fast-ADT acquisition.",2)
				
				shown=CountImageDocuments(WorkspaceGetActive())
				for(number j=0; j<shown; ++j){
					imgDoc=getImageDocument(0)
					imageDocumentClose(imgdoc,0)
				}
				
				iniPosRef = 0
				
			}
			
			self.SetElementIsEnabled("start",1)
		
		}
	}

}

	
void startADT( object self){

	initialAngleThread = DLGgetValue(self.LookUpElement("initialAngleCall"))
	lastAngleThread = DLGgetValue(self.LookUpElement("finalAngleCall"))
	velocityThread = DLGgetValue(self.LookUpElement("velocityCall"))
	stepAngleThread = DLGgetValue(self.LookUpElement("stepCall"))
	exposureThread = DLGgetValue(self.LookUpElement("exposure"))
	continuousThread = DLGgetValue(checkContinuous)
	stopParameter = 0
	if (DLGgetValue(checkContinuous) == 0) {
		self.SetElementisEnabled("stopAcquisition",1);
	} else {
		self.SetElementisEnabled("stopAcquisition",0);
	}
	self.SetElementIsEnabled("reiniciar",1);
	self.SetElementIsEnabled("start",0);
	Acquire3DEDdata.init().StartThread("Start")
	
}


void stopADT(object self){

	stopParameter = 1
	self.SetElementisEnabled("stopAcquisition",0);
	Result("\n\nThe Fast-ADT acquisition is going to stop after the last DP is acquired.\n\n")

}


void resetParameters (object self){

	number evaluadorText = 1
	number iniAngleADT = DLGgetValue(self.LookUpElement("initialAngleCall"))
	string nameFile
	
	if (DSThread == 0) {
		EMSetBeamShift(bsXtemDiff, bsYtemDiff)
		EMWaitUntilReady()
	}

	self.SetElementIsEnabled("start",1);
	self.SetElementIsEnabled("reiniciar",0);
	
	number filereference=openFileForReading(path)
	readFileLine(filereference, nameFile)
	readFileLine(filereference, nameFile)
	setPersistentNumberNote("Referencia Text",filereference)
	setPersistentNumberNote("Evaluar Text",evaluadorText)
	
	EMSetStageAlpha(iniAngleADT-1)
	EMWaitUntilReady()
	EMSetStageAlpha(iniAngleADT)
	EMWaitUntilReady()
	
	Result("\nBeam shifts reset to the values before the acquisition.\n\n") 
	Result("Crystal Tacking File ready to use for a new acquisition.\n\n")
	Result("------------------------------------------------------------------------\n")	
	
}


void checkProjDScorrfunction (object self, taggroup tg){

	if ((ProjShiftCounter + ProjShiftDSCounter) < 2 && DLGgetValue(checkProjDScorr) == 1){
		showAlert("The Proj. Shift and/or Diff. Shift has not been calibrated.",1)
		checkProjDScorr.DLGValue(0)
		projDSeval = 0
	}
	
	if (DLGgetValue(checkProjDScorr) == 1){
		projDSeval = 1
	} else {
		projDSeval = 0
	}
	

}

//Function to be executed when GUI closed
~ADTAcquisitionDialog(object self){
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
	Result("Fast-ADT closed.\n")
}

}

//Create the GUI
void CreateFastADTControlDialog(){

	TagGroup position;
	position = DLGBuildPositionFromApplication()
	TagGroup dialog_items;	
	TagGroup dialog = DLGCreateDialog("ADT-Control", dialog_items).dlgposition(position);
		
	dialog_items.DLGAddElement( MakeButtons() );
	object dialog_frame = alloc(ADTAcquisitionDialog).init(dialog)
	dialog_frame.display("Fast-ADT: Acquisition v3.5")
	number dialogID=dialog_frame.ScriptObjectGetID()
	dialog_frame.init(dialogID)
		
}

//Open the GUI
CreateFastADTControlDialog()
Result("\n"+"------------------------------------------------------------------------------------------------------------------\n")
Result("Fast-ADT Acquisition v3.5, S. Plana Ruiz, Universitat Rovira i Virgili, TU Darmstadt, JGU Mainz & UB, April 2024.\n\n")
Result("Path for Reference Files:\t" + pathPDW +"\n")
Result("TEM Manufacturer: "+ Manufacturer )
Result("Size of used detector: "+widthCam+" x "+heightCam+" pixels\n")
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
//Result("Magnification for beam settings of STEM mode: "+ magNeeded)
//Result("Calibration (nm/pixel) for beam settings of STEM mode: "+ calMagBeamSize+"\n")
Result("------------------------------------------------------------------------------------------------------------------\n")