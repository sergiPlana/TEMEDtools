ImageDisplay imageDisp
TagGroup integerfieldrefPosLabel, integerfieldradiusPosLabel, AddReferencePositionsButton, DeleteAnnotationsButton, projDScorrButt, pre_smthButt, findEdgeButt
TagGroup useBeamSettingsButt, automatedParticleFinderButton, integerfieldR_mask, integerfieldBs_filter, integerfieldMax_numPos
TagGroup integerfieldThrePED, realfieldZchange
number refPointsValue, radius, workspaceID, shown, i, j, t_label,l_label,b_label,r_label, t_oval, l_oval, b_oval, r_oval
number initialXBeam, initialYBeam, shiftX, shiftY, xsize, ysize, xoffset, pyTEMServerState, toInitializePyModules, refNumberSTEM = 0
number scanCamLenImg, scanCamLenDiff, scanImgProjX, scanImgProjY, scanDiffProjX, scanDiffProjY, totalNumberOfDPs=0,j_roi=0, xoffset_roi=0, counter=0
component ovalTheRoi, labelTheRoi, theroi
image refImage, temp
imagedocument imgDoc

string drivestring = "D:"
string folderstring = "FastADT_Storage"
string pathPDW = pathconcatenate(drivestring,folderstring)
string msgPyTEMserv, msgForPyTEMserv, pyTEMserverLocation = pathconcatenate(pathPDW,"pyTEMserver")

// Get Active Camera ID and Camera size ------------------------------------------------

object camera=CM_GetCurrentCamera()
number camID = CameraGetActiveCameraID()

//--------------------------------------------------------------------------------------

//Dialog class
Class MainDialogClass:UIFrame {
				
	//Creates the components of the dialog	
	TagGroup MainFrame(object self) {
		TagGroup Dialog=DLGCreateDialog("Main Dialog")
		TagGroup box_items
		TagGroup box=dlgcreatebox("", box_items).dlginternalpadding(14,10)
		Dialog.dlgaddelement(box)
		
		//-----------------------------------------------------------------------------------
		//BEAM SETTING
		//-----------------------------------------------------------------------------------
		TagGroup beamset_items
		TagGroup beamsetting=dlgcreatebox("Beam Settings", beamset_items)
		
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
			
			useBeamSettingsButt = DLGCreateCheckbox("Use beam settings",0, "useBeamSetFunc")
			useBeamSettingsButt.DLGidentifier("IDuseBeamSettings").dlgenabled(0)
			beamset_items.DLGaddelement(useBeamSettingsButt)
		
		box_items.dlgaddelement(beamsetting)
		
	
		//-----------------------------------------------------------------------------------
		//COLLECT FROM REFERENCE POSITIONS
		//-----------------------------------------------------------------------------------
		
		TagGroup positionsParams_items
		taggroup positionsParams = DLGCreateBox("", positionsParams_items)	
			
			TagGroup STEMimaging_items
			taggroup STEMimaging = DLGCreateBox("STEM imaging", STEMimaging_items)
				TagGroup STEMviewButton=DLGCreatePushButton("Start/Stop View", "viewSTEMButton")
				STEMviewButton.dlgidentifier("viewSTEMButton").dlginternalpadding(2,0)
				STEMimaging_items.dlgaddelement(STEMviewButton)
				TagGroup AcquireSTEMRefImage = DLGCreatePushButton("Acquire Reference Image","acqSTEMimg")
				AcquireSTEMRefImage.dlgidentifier("acqSTEMimgID").dlginternalpadding(2,0)
				STEMimaging_items.dlgaddelement(AcquireSTEMRefImage)
			positionsParams_items.DLGaddelement(STEMimaging)
			
			TagGroup refPositionGroup_items
			taggroup refPositionGroup = DLGCreateBox("Reference positions", refPositionGroup_items)
				TagGroup refPosLabel = DLGCreateLabel("Number (#):").DLGAnchor("East")
				integerfieldrefPosLabel = DLGCreateIntegerField(3,3).DLGidentifier("numRefPos").DLGAnchor("East").dlgvalue(3)
				TagGroup refPosGroup = DLGgroupitems(refPosLabel, integerfieldrefPosLabel).DLGtableLayout(2,1,0)
				TagGroup SetPlus1PosButton=DLGCreatePushButton("+1", "setPlus1pos")
				TagGroup SetMinus1PosButton=DLGCreatePushButton("-1", "setMinus1pos")
				TagGroup refPosGroup2 = DLGgroupitems(SetPlus1PosButton, SetMinus1PosButton).DLGtableLayout(2,1,0)
				TagGroup finalrefPosGroup = DLGgroupitems(refPosGroup, refPosGroup2).DLGtablelayout(2,1,0)
				refPositionGroup_items.DLGAddelement(finalrefPosGroup)
				
				TagGroup radiusPosLabel = DLGCreateLabel("Radius (pix.):").DLGAnchor("East")
				integerfieldradiusPosLabel = DLGCreateIntegerField(25,4).DLGidentifier("radRefPos").DLGAnchor("East").dlgvalue(12)
				TagGroup radiusPosGroup = DLGgroupitems(radiusPosLabel, integerfieldradiusPosLabel).DLGtableLayout(2,1,0)
				TagGroup SetPlus10RadButton=DLGCreatePushButton("+10", "setPlus10rad")
				TagGroup SetMinus10RadButton=DLGCreatePushButton("-10", "setMinus10rad")
				TagGroup radiusPosGroup2 = DLGgroupitems(SetPlus10RadButton, SetMinus10RadButton).DLGtableLayout(2,1,0)
				TagGroup finalradiusPosGroup = DLGgroupitems(radiusPosGroup, radiusPosGroup2).DLGtablelayout(2,1,0)
				refPositionGroup_items.DLGAddelement(finalradiusPosGroup)
				
				AddReferencePositionsButton=DLGCreatePushButton("Add","addRefPos")
				AddReferencePositionsButton.dlgidentifier("addRefP").dlginternalpadding(2,0)
				DeleteAnnotationsButton=DLGCreatePushButton("Delete","delRefPos").DLGenabled(1)
				DeleteAnnotationsButton.dlgidentifier("delRefPs").dlginternalpadding(2,0)
				TagGroup AddAndDelteGroup = DLGgroupitems(AddReferencePositionsButton,DeleteAnnotationsButton).DLGtablelayout(2,1,0)
				refPositionGroup_items.dlgaddelement(AddAndDelteGroup)
				
				automatedParticleFinderButton=DLGCreatePushButton("Automated positions finder","imgSegGo")
				automatedParticleFinderButton.dlgidentifier("imgSegGo").dlginternalpadding(2,0)
				refPositionGroup_items.dlgaddelement(automatedParticleFinderButton)
				
				refPositionGroup_items.dlgaddelement(DLGCreateLabel("-| Segmentation + clustering params |-"))
				
				TagGroup r_maskLabel = DLGCreateLabel("r_mask:").DLGAnchor("East")
				integerfieldR_mask = DLGCreateIntegerField(5,4).DLGidentifier("r_maskValue").DLGAnchor("East").dlgvalue(5)
				TagGroup bs_filterLabel = DLGCreateLabel("bs_filter:").DLGAnchor("East")
				integerfieldBs_filter = DLGCreateIntegerField(5,3).DLGidentifier("bs_filterValue").DLGAnchor("East").dlgvalue(20)
				TagGroup max_numPosLabel = DLGCreateLabel("Max # of positions:").DLGAnchor("East")
				integerfieldMax_numPos = DLGCreateIntegerField(2,3).DLGidentifier("max_numPosValue").DLGAnchor("East").dlgvalue(5)
				
				TagGroup firstRowSegmentGroup = DLGgroupitems(r_maskLabel, integerfieldR_mask, bs_filterLabel, integerfieldBs_filter ).DLGtableLayout(4,1,0)
				TagGroup secondRowSegmentGroup = DLGgroupitems(max_numPosLabel, integerfieldMax_numPos).DLGtableLayout(2,1,0)
				TagGroup finalSegmentGroup = DLGgroupitems(firstRowSegmentGroup, secondRowSegmentGroup).DLGtablelayout(1,2,0)
				refPositionGroup_items.dlgaddelement(finalSegmentGroup)
				
				findEdgeButt = DLGCreateCheckbox("Find edges",0, "edgeDetFunc")
				findEdgeButt.DLGidentifier("IDedgeDet")
				pre_smthButt = DLGCreateCheckbox("Pre-smoothing",1,"pre_smthFunc")
				pre_smthButt.DLGidentifier("IDpre_smth")
				TagGroup segCheckBoxes = DLGgroupitems(findEdgeButt,pre_smthButt).DLGtablelayout(2,1,0)
				refPositionGroup_items.dlgaddelement(segCheckBoxes)
			positionsParams_items.dlgaddelement(refPositionGroup)
		
			TagGroup acqStorGroup_items
			taggroup acqStorGroup = DLGCreateBox("ED collection", acqStorGroup_items)
			
				TagGroup acquireEDpatternsButton=DLGCreatePushButton("Acquire patterns from positions", "acqEDpatternsButton").DLGenabled(1)
				acquireEDpatternsButton.dlgidentifier("acqEDpatterns").dlginternalpadding(2,0).dlgenabled(0)
				acqStorGroup_items.dlgaddelement(acquireEDpatternsButton)
				
				projDScorrButt = DLGCreateCheckbox(" Apply projectors correction",0, "projDScorrfunction")
				projDScorrButt.DLGidentifier("IDcheckProjDScorr").dlgenabled(1)
				acqStorGroup_items.DLGaddelement(projDScorrButt)
				
				TagGroup saveAllButton=DLGCreatePushButton("Save all frames in workspace", "saveAllButtonFunc").DLGenabled(1)
				saveAllButton.dlgidentifier("storeAll").dlginternalpadding(2,0)
				acqStorGroup_items.dlgaddelement(saveAllButton)
				
				TagGroup closeAllDPsButton=DLGCreatePushButton("Close all DPs in workspace", "closeAllDPsButtonFunc").DLGenabled(1)
				closeAllDPsButton.dlgidentifier("closeAll").dlginternalpadding(2,0)
				acqStorGroup_items.dlgaddelement(closeAllDPsButton)
			positionsParams_items.dlgaddelement(acqStorGroup)
			
		box_items.DLGaddelement(positionsParams)
		
		//-----------------------------------------------------------------------------------
		//AUTOMATED PRECESSION PIVOT POINT ALIGNMENT
		//-----------------------------------------------------------------------------------
		
		TagGroup pivotPointAdjust_items
		taggroup pivotPointAdjust = DLGCreateBox("PED adjustment", pivotPointAdjust_items)
		
			TagGroup applyAdjustButton=DLGCreatePushButton("Apply pivot point correction", "autPPPEDButton")
			applyAdjustButton.dlgidentifier("autPPPEDButtonid").dlginternalpadding(2,0)
			pivotPointAdjust_items.dlgaddelement(applyAdjustButton)
			
			TagGroup threshPEDLabel = DLGCreateLabel("FFT threshold (pix.):").DLGAnchor("East")
			integerfieldThrePED = DLGCreateIntegerField(80,4).DLGidentifier("thrPixPED").DLGAnchor("East").dlgvalue(80)
			pivotPointAdjust_items.dlgaddelement(DLGgroupitems(threshPEDLabel,integerfieldThrePED).DLGtablelayout(2,1,0))
			TagGroup zHeightLabel = DLGCreateLabel("Z-height change (µm):").DLGAnchor("East")
			realfieldZchange = DLGCreateRealField(0.5,5,3).DLGidentifier("zheightPED").DLGAnchor("East").dlgvalue(1.0)
			pivotPointAdjust_items.dlgaddelement(DLGgroupitems(zHeightLabel,realfieldZchange).DLGtablelayout(2,1,0))
		
		box_items.DLGaddelement(pivotPointAdjust)
		return Dialog
	}	
	
	void setPlus1pos(object self){
		refPointsValue = DLGgetValue(self.LookUpElement("numRefPos"))
		refPointsValue += 1
		DLGValue(integerfieldrefPosLabel, refPointsValue)
	}
	
	void setMinus1pos(object self){
		refPointsValue = DLGgetValue(self.LookUpElement("numRefPos"))
		refPointsValue -= 1
		if (refPointsValue < 0) refPointsValue = 0
		DLGValue(integerfieldrefPosLabel, refPointsValue)
	}
	
	void setPlus10rad(object self){
		radius = DLGgetValue(self.LookUpElement("radRefPos"))
		radius += 10
		DLGValue(integerfieldradiusPosLabel, radius)
	}
	
	void setMinus10rad(object self){
		radius = DLGgetValue(self.LookUpElement("radRefPos"))
		radius -= 10
		if (radius < 0) radius = 1
		DLGValue(integerfieldradiusPosLabel, radius)
	}
	
	//Beam Settings
	void initializepyTEMserver(object self){
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"initiallize.py")
		LaunchExternalProcess(msgForPyTEMserv)
		setpersistentnumbernote("PyModuleInitialization",1)
	}
	void getimagesetting (object self) {
	
		getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
			if (toInitializePyModules==0){
				self.initializepyTEMserver()
			}

		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"getCL2_img.py")
		LaunchExternalProcess(msgForPyTEMserv)
		scanCamLenImg = EMGetCameraLength()
		EMGetProjectorShift(scanImgProjX, scanImgProjY)
		EMWaitUntilReady()
		self.SetElementisEnabled("setImg",1)
		Result("Beam Setting for Imaging:"+"\n")
		Result("CL2 value stored\n")
		Result("Camera Length: "+scanCamLenImg+"\n")
		Result("Projoctor shifts: "+scanImgProjX + "\t"+scanImgProjY+"\n")
		Result("\n----------------------------------------------------------------------------------------------\n\n")
		if (getElementIsEnabled(self,"setImg")==1 && getElementIsEnabled(self,"setDiff")==1){
			self.SetElementIsEnabled("IDuseBeamSettings",1)
		}

	}
	void getdiffsetting (object self) {
		
		getpersistentnumbernote("PyModuleInitialization",toInitializePyModules)
		if (toInitializePyModules==0){
			self.initializepyTEMserver()
		}	

		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"getCL2_diff.py")
		LaunchExternalProcess(msgForPyTEMserv)
		scanCamLenDiff = EMGetCameraLength()
		EMGetProjectorShift(scanDiffProjX, scanDiffProjY)
		EMWaitUntilReady()
		self.SetElementisEnabled("setDiff",1)
		Result("Beam Setting for Diffraction:"+"\n")
		Result("CL2 value stored\n")
		Result("Camera Length: "+scanCamLenDiff+"\n")
		Result("Projector shifts: "+scanDiffProjX + "\t"+scanDiffProjY+"\n")
		Result("\n----------------------------------------------------------------------------------------------\n\n")
		if (getElementIsEnabled(self,"setImg")==1 && getElementIsEnabled(self,"setDiff")==1){
			self.SetElementIsEnabled("IDuseBeamSettings",1)
		}
		
	}
	void setimagesetting (object self){
			
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"insertDF_setCL2_img.py")
		LaunchExternalProcess(msgForPyTEMserv)
		EMSetCameraLength(scanCamLenImg)
		EMSetProjectorShift(scanImgProjX, scanImgProjY)
		EMSetScreenPosition(0)
		EMWaitUntilReady()
		if (DSIsAcquisitionActive()  == 0) {
			DSInvokeButton(1)
		}
		
	}
	void setdiffsetting (object self) {
				
		msgForPyTEMserv = "cmd.exe /cpython "
		msgForPyTEMserv += pathconcatenate(pyTEMserverLocation,"retractDF_setCL2_diff.py")
		LaunchExternalProcess(msgForPyTEMserv)
		EMSetCameraLength(scanCamLenDiff)
		EMSetProjectorShift(scanDiffProjX, scanDiffProjY)
		EMSetScreenPosition(2)
		EMWaitUntilReady()

	}
	void useBeamSetFunc(object self, taggroup tg) {
	}
	
	//Start/Stop STEM view
	void viewSTEMButton(object self){
		DSInvokeButton(1)
	}
		
	//Acquire reference STEM image
	void acqSTEMimg(object self){
		number shown=CountImageDocuments(WorkspaceGetActive())
		string nameImg
		for(i=0; i<shown; ++i){
			imgDoc=getImageDocument(i)
			nameImg = ImageDocumentGetName(imgDoc)
			if(len(nameImg) == 19) {
				imageDocumentClose(imgdoc,0)
				i -= 1
				shown -= 1
			}
		}
		WorkspaceArrange(WorkspaceGetActive(),0,0)
		
		if (DLGgetValue(useBeamSettingsButt) == 1){
			self.setimagesetting()
		}
		
		number xsizeDS, ysizeDS
		if (DSIsAcquisitionActive()  == 1) {
			DSInvokeButton(1)
			DSWaitUntilFinished( )
		}
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		DSInvokeButton(5,1)
		DSWaitUntilFinished( )
		image capturedImg := getFrontImage()
		refNumberSTEM += 1
		setName(capturedImg,"STEMrefImg_"+format(refNumberSTEM,"%03d"))
		imageDisp = capturedImg.ImageGetImageDisplay(0)
		capturedImg.GetSize(xsizeDS, ysizeDS)
		DSPositionBeam(capturedImg, round(xsizeDS/2), round(ysizeDS/2))
		DSWaitUntilFinished( )
	}
	
	//Add reference positions in the STEM image
	void addRefPos(object self){
		refImage := GetFrontImage()
		refImage.GetSize(xsize,ysize)
		imageDisp = refImage.ImageGetImageDisplay(0)
		refPointsValue = DLGgetValue(self.LookUpElement("numRefPos"))
		radius = DLGgetValue(self.LookUpElement("radRefPos"))
		
		if (counter == 0){
			shiftX = (2*radius)+75
			shiftY = shiftX
			initialXBeam = shiftX
			initialYBeam = shiftY
			counter=1
		}
		
		for(i=0; i<(refPointsValue); ++i){
			ovalTheRoi = NewOvalAnnotation(initialYBeam+(shiftY*j_roi)-radius, initialXBeam+(shiftX*(i+totalNumberOfDPs))-radius-xoffset_roi, initialYBeam+(shiftY*j_roi)+radius, initialXBeam+(shiftX*(i+totalNumberOfDPs))+radius-xoffset_roi)
			ovalTheRoi.ComponentSetSelectable(0)
			ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
			ovalTheRoi.ComponentSetForeGroundColor( 1, 0, 0)
			labelTheRoi = NewTextAnnotation( 0,0, ""+(totalNumberOfDPs+i+1), 28*(2*radius/50))
			labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
			labelTheRoi.ComponentSetForeGroundColor( 1, 0, 0)
			labelTheRoi.ComponentSetSelectable(0)
			labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
			labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
			theroi = NewGroupAnnotation()
			theroi.ComponentAddChildAtEnd(ovalTheRoi)
			theroi.ComponentAddChildAtEnd(labelTheRoi)
			imageDisp.ComponentAddChildAtEnd(theroi)
			if ((initialXBeam+(shiftX*(i+1+totalNumberOfDPs))+radius-xoffset_roi) > xsize){
				j_roi += 1
				xoffset_roi = initialXBeam+(shiftX*(i+totalNumberOfDPS))+radius
			}
		}
		totalNumberOfDPs = totalNumberOfDPs+refPointsValue
		self.SetElementisEnabled("acqEDpatterns",1)
	}
	
	//Delete all positions
	void delRefPos(object self){
		refImage:=GetFrontImage()
		imageDisp = refImage.ImageGetImageDisplay(0)
		number total = imagedisp.ComponentCountChildren()
		for(i = 1; i < total; i++ ){
			Component comp = imageDisp.ComponentGetChild(total-i)
			if ( comp.ComponentGetType() != 31 && comp.ComponentGetType() != 27){
				comp.ComponentRemoveFromParent()
			}	
		}
		totalNumberOfDPs = 0
		self.SetElementisEnabled("acqEDpatterns",0)
		totalNumberOfDPs=0
		j_roi = 0
		xoffset_roi = 0
		counter=0
	}
	
	void edgeDetFunc(object self, taggroup tg) {
	}
	
	void pre_smthFunc(object self, taggroup tg){
	}
	
	//Image segmentation
	void imgSegGo(object self){
		//Save image as tif
		refImage:=GetFrontImage()
		imageDisp = refImage.ImageGetImageDisplay(0)
		string individualFrame = pathPDW+"\\"+"TargetImg"
		SaveAsTiff(refImage,individualFrame,1)
		
		//Inputs for image segmentation
		documentwindow textFile=NewScriptWindow("Image Segmentation Parameters", 50,50,150,450)
		editorWindowAddText(textFile,format(DLGgetValue(self.LookUpElement("r_maskValue")),"%i")+"\n"+format(DLGgetValue(self.LookUpElement("bs_filterValue")),"%i")+"\n")
		editorWindowAddText(textFile,format(DLGgetValue(self.LookUpElement("max_numPosValue")),"%i")+"\n"+format(DLGgetValue(findEdgeButt),"%i")+"\n")
		editorWindowAddText(textFile,format(DLGgetValue(pre_smthButt),"%i")+"\n"+format(refImage.ImageGetDimensionScale(0),"%3.8f"))
		editorWindowSaveToFile(textFile,pathconcatenate(pathPDW,"ImageSegmentation_parameters.txt"))
		windowClose(textFile,0)
		
		//Call the python executable for segmentation and clustering
		string msg = "cmd.exe /c"
		msg += pathconcatenate(pathPDW,"SegmentTargetImg_Final.exe")
		LaunchExternalProcess(msg)
		
		//Read the positions found by segmentation
		string numOfFoundPositionsStr, segmentPosXStr, segmentPosYStr
		number segmentPosX, segmentPosY
		
		string pathForSegmentedFindings = pathconcatenate(pathPDW,"Segmentation_CrystalPositions.txt")
		number fileSegmentReference = openFileForReading(pathForSegmentedFindings)
		number segmentLine1 = readFileLine(fileSegmentReference, numOfFoundPositionsStr)
		number numOfFoundPos = val(numOfFoundPositionsStr)
		number segmentLine2, segmentLine3
		number radius=DLGgetValue(self.LookUpElement("radRefPos"))
		for(number i=0;i<numOfFoundPos;i++){
			segmentLine2 = readFileLine(fileSegmentReference, segmentPosXStr)
			segmentLine3 = readFileLine(fileSegmentReference, segmentPosYStr)
			segmentPosY = val(segmentPosXStr)
			segmentPosX = val(segmentPosYStr)
			
			if (segmentPosX > 0){
				ovalTheRoi = NewOvalAnnotation(segmentPosX-radius,segmentPosY-radius, segmentPosX+radius, segmentPosY+radius)
				ovalTheRoi.ComponentSetSelectable(0)
				ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
				ovalTheRoi.ComponentSetForeGroundColor( 1, 0, 0)
				labelTheRoi = NewTextAnnotation( 0,0, ""+(totalNumberOfDPs+i+1), 28*(2*radius/50))
				labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
				labelTheRoi.ComponentSetForeGroundColor( 1, 0, 0)
				labelTheRoi.ComponentSetSelectable(0)
				labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
				labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
				theroi = NewGroupAnnotation()
				theroi.ComponentAddChildAtEnd(ovalTheRoi)
				theroi.ComponentAddChildAtEnd(labelTheRoi)
				imageDisp.ComponentAddChildAtEnd(theroi)
			}
		}
		Result(numOfFoundPos+" positions found via image segmentation and clustering. \n\n")
		closeFile(fileSegmentReference)
		totalNumberOfDPs = totalNumberOfDPs+numOfFoundPos
		
	}

	
	//Acquire ED patterns from positions
	void acqEDpatternsButton(object self) {
		number calibrationProjX, calibrationProjY, rotAngleProj, calibrationProjDSX, calibrationProjDSY, rotAngleProjDS, scaleCaliProj, scaleCaliDSforProjRef
		number total, scaleCali, originCali, projectorShiftCheck, originProjCali, scaleCaliProjRef, j=1, xProjDSShift, yProjDSShift, xProjShift, yProjShift
		number Xshift = 0, Yshift = 0, xsizeDS, ysizeDS, previousX, previousY, scaleCaliProjDS
		string unitsCali, directoryProjCalibration, calibrationPartProjX, calibrationPartProjY, rotationAngleProj, scaleCaliPartProj, scaleCaliPartProjDS2
		string calibrationPartProjDSX, calibrationPartProjDSY, rotationAngleProjDS, scaleCaliPartProjDS, unitsProjCali
		
		CameraPrepareForAcquire(camID)
		
		number shown=CountImageDocuments(WorkspaceGetActive())
		string nameImg
		for(i=0; i<shown; ++i){
			imgDoc=getImageDocument(i)
			nameImg = ImageDocumentGetName(imgDoc)
			if(len(nameImg) == 19) {
				imageDocumentClose(imgdoc,0)
				i -= 1
				shown -= 1
			}
		}
		
		if (DLGgetValue(useBeamSettingsButt) == 1){
			self.setdiffsetting()
		}
		
		imageDisp = refImage.ImageGetImageDisplay(0)
		refImage.GetSize(xsizeDS, ysizeDS)
		total = imagedisp.ComponentCountChildren()
		projectorShiftCheck = DLGgetValue(projDScorrButt)
		
		if (projectorShiftCheck == 1){
			ImageGetDimensionCalibration(refImage, 0, originCali, scaleCali, unitsCali, 1)
			temp := CameraAcquire(camID)
			ImageGetDimensionCalibration(temp,0, originProjCali, scaleCaliProjRef, unitsProjCali, 1)
			
			//Read the Projector Shift Calibration
			string directoryProjCalibration = pathConcatenate(pathPDW, "ProjectorShiftCalibration.txt")
			number fileProjReference = openFileForReading(directoryProjCalibration)
			number ProjLine1 = readFileLine(fileProjReference, calibrationPartProjX)
			number ProjLine2 = readFileLine(fileProjReference, calibrationPartProjY)
			number ProjLine3 = readFileLine(fileProjReference, rotationAngleProj)
			number ProjLine4 = readFileLine(fileProjReference, scaleCaliPartProj)
			calibrationProjX = val(right(calibrationPartProjX,len(calibrationPartProjX)-15))
			calibrationProjY = val(right(calibrationPartProjY,len(calibrationPartProjY)-15))
			rotAngleProj = val(right(rotationAngleProj,len(rotationAngleProj)-30))
			scaleCaliProj = val(right(scaleCaliPartProj,len(scaleCaliPartProj)-18))
			closeFile(fileProjReference)
			
			//Read the Projector Shift-DS Calibration
			string directoryProjDSCalibration = pathConcatenate(pathPDW, "ProjectorShiftDSCalibration.txt")
			string calibrationPartProjDSX, calibrationPartProjDSY, rotationAngleProjDS, scaleCaliPartProjDS
			number fileProjDSReference = openFileForReading(directoryProjDSCalibration)
			number ProjLine1DS = readFileLine(fileProjDSReference, calibrationPartProjDSX)
			number ProjLine2DS = readFileLine(fileProjDSReference, calibrationPartProjDSY)
			number ProjLine3DS = readFileLine(fileProjDSReference, rotationAngleProjDS)
			number ProjLine4DS = readFileLine(fileProjDSReference, scaleCaliPartProjDS)
			number ProjLine5DS = readFileLine(fileProjDSReference, scaleCaliPartProjDS2)
			calibrationProjDSX = val(right(calibrationPartProjDSX,len(calibrationPartProjDSX)-15))
			calibrationProjDSY = val(right(calibrationPartProjDSY,len(calibrationPartProjDSY)-15))
			rotAngleProjDS = val(right(rotationAngleProjDS,len(rotationAngleProjDS)-30))
			scaleCaliDSforProjRef = val(right(scaleCaliPartProjDS,len(scaleCaliPartProjDS)-18))
			scaleCaliProjDS = val(right(scaleCaliPartProjDS2,len(scaleCaliPartProjDS2)-18))
			closeFile(fileProjDSReference)
			
			Result("Calibration Projectors reference: "+scaleCaliProj+"\n")
			Result("Calibration DS-Projectors reference (DS image): "+scaleCaliDSforProjRef+"\n")
			Result("Calibration DS-Projectors reference (DP): "+scaleCaliProjDS+"\n")
			Result("Calibration Projectors current: "+scaleCaliProjRef+"\n")
			Result("Calibration DS-Projectors current: "+scaleCali+"\n\n")
			
			previousX = xsizeDS/2
			previousY = ysizeDS/2
		}

		for(i = 0; i < total; i++ ){
			theRoi = imagedisp.ComponentGetChild( i )
			if ( theRoi.ComponentGetType() == 17 ){
				theRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
				Result(j+" position:\t"+(r_oval-radius)+"\t"+(b_oval-radius)+"\n")
				DSPositionBeam(refImage, (r_oval-radius), (b_oval-radius))
				DSWaitUntilFinished()
				if (projectorShiftCheck== 1){
					Xshift = (r_oval-radius) - previousX
					Yshift = (b_oval-radius) - previousY
					xProjDSShift = ((cos(rotAngleProjDS*pi()/180)*(Xshift*scaleCali/scaleCaliDSforProjRef)) + (-sin(rotAngleProjDS*pi()/180)*(-Yshift*scaleCali/scaleCaliDSforProjRef)))/(scaleCaliProjDS*calibrationProjDSX)
					yProjDSShift = ((sin(rotAngleProjDS*pi()/180)*(Xshift*scaleCali/scaleCaliDSforProjRef)) + (cos(rotAngleProjDS*pi()/180)*(-Yshift*scaleCali/scaleCaliDSforProjRef)))/(scaleCaliProjDS*calibrationProjDSY)
					xProjShift = ((cos(rotAngleProj*pi()/180)*xProjDSShift) + (sin(rotAngleProj*pi()/180)*(yProjDSShift)))*calibrationProjX*scaleCaliProj*(scaleCaliProj/scaleCaliProjRef)
					yProjShift = ((-sin(rotAngleProj*pi()/180)*xProjDSShift) + (cos(rotAngleProj*pi()/180)*(yProjDSShift)))*calibrationProjY*scaleCaliProj*(scaleCaliProj/scaleCaliProjRef)
					previousX = (r_oval-radius)
					previousY = (b_oval-radius)
				}
				EMChangeProjectorShift(-xProjShift,-yProjShift)
				EMWaitUntilReady()
				temp := CameraAcquire(camID)
				setName(temp,"STEMrefImg_"+format(refNumberSTEM,"%03d")+"_DP_"+format(j,"%02d"))
				showimage(temp)
				j+=1
			}
		}
		WorkspaceArrange(WorkspaceGetActive(),0,0)
		Result("\n")
	}	
	
	void projDScorrFunction(object self, taggroup tg) {
		if (DLGgetValue(projDScorrButt) == 1){
			showAlert("Remember that this requires projector shift calibrations from the FastADT module.", 2)
		}
	}
	
	void saveAllButtonFunc(object self){
		string imgname, dataPath, storePath
		if(!SaveAsDialog("Select directory to save all data in the workspace","data",dataPath))exit(0)
		string currentdirectory=pathextractdirectory(dataPath,2)
		number shown=CountImageDocuments(WorkspaceGetActive())
		for(i=0; i<shown; i++){
			imgdoc = getImageDocument(i)
			imageDocumentShow(imgdoc)
			temp:=getfrontimage()
			imgname = temp.getname()
			storePath=pathconcatenate(currentdirectory, imgname)
			saveasgatan3(temp,storePath)
			Result("\n"+ImgName+" stored.")
		}
		Result("\nAll data in the workspace has been stored.\n\n")
	}
	
	void closeAllDPsButtonFunc(object self){
		number shown=CountImageDocuments(WorkspaceGetActive())
		string nameImg
		for(i=0; i<shown; ++i){
			imgDoc=getImageDocument(i)
			nameImg = ImageDocumentGetName(imgDoc)
			if(len(nameImg) == 20) {
				imageDocumentClose(imgdoc,0)
				i -= 1
				shown -= 1
			}
		}
		imageDisp = getFrontImage().ImageGetImageDisplay(0)
		number total = imagedisp.ComponentCountChildren()
		for(i = 1; i < total; i++ ){
			Component comp = imageDisp.ComponentGetChild(total-i)
			if ( comp.ComponentGetType() != 31 && comp.ComponentGetType() != 27){
				comp.ComponentRemoveFromParent()
			}	
		}
		WorkspaceArrange(WorkspaceGetActive(),0,0)
	}
	
	void autPPPEDButton(object self){
		number xsize, ysize, safetyCount=0
		number sumsqrdiff, stddevPos, stddevNeg
		Result("Automated PED pivot point alignment\n\n")
		number lowPix = DLGgetValue(self.LookUpElement("thrPixPED"))
		number zHeightChange = DLGgetValue(self.LookUpElement("zheightPED"))
		number zHeight = EMGetStageZ()
		Result("Initial z-height: "+zHeight+"\n")
		
		if (DSIsAcquisitionActive()  == 1) {
			DSInvokeButton(1)
			DSWaitUntilFinished( )
		}

		DSInvokeButton(3)
		DSWaitUntilFinished( )
		realimage refImg := getFrontImage()
		refImg.getsize(xsize,ysize)
		compleximage img_FFT := FFT(refImg)
		img_FFT *= (iradius<(xsize/2) && iradius>lowPix ) ? 0 : 1
		image img_filter := modulus(iFFT(img_FFT))
		image nminusmeansqrd=(img_filter-(mean(img_filter)))**2
		sumsqrdiff=sum(nminusmeansqrd)
		number stddevIni=round(sqrt((sumsqrdiff/((xsize*ysize)-1))))
		Result("Initial std: "+stddevIni+"\n")

		while (1) {
			if (safetyCount > 20){
				showAlert("PED pivot point alignment did not converge. Check manually the aligment",1)
				Result("PED pivot point alignment failed.\n\n")
				break
			}
			EMSetStageZ(zHeight + zHeightChange)
			EMWaitUntilReady()
			DSInvokeButton(3)
			DSWaitUntilFinished( )
			refImg := getFrontImage()
			img_FFT := FFT(refImg)
			img_FFT *= (iradius<(xsize/2) && iradius>lowPix ) ? 0 : 1
			img_filter := modulus(iFFT(img_FFT))
			nminusmeansqrd=(img_filter-(mean(img_filter)))**2
			sumsqrdiff=sum(nminusmeansqrd)
			stddevPos=round(sqrt((sumsqrdiff/((xsize*ysize)-1))))
			Result("Height increased std: "+stddevPos+"\n")

			EMSetStageZ(zHeight - zHeightChange)
			EMWaitUntilReady()
			DSInvokeButton(3)
			DSWaitUntilFinished( )
			refImg := getFrontImage()
			img_FFT := FFT(refImg)
			img_FFT *= (iradius<(xsize/2) && iradius>lowPix ) ? 0 : 1
			img_filter := modulus(iFFT(img_FFT))
			nminusmeansqrd=(img_filter-(mean(img_filter)))**2
			sumsqrdiff=sum(nminusmeansqrd)
			stddevNeg=round(sqrt((sumsqrdiff/((xsize*ysize)-1))))
			Result("Height decreased std: "+stddevNeg+"\n")

			if (stddevPos > stddevIni && stddevIni > stddevNeg){
				Result("Z-height needs to INCREASE\n\n")
				stddevIni = stddevPos
				zHeight += zHeightChange
				EMSetStageZ(zHeight)
				EMWaitUntilReady()
			} else if (stddevNeg > stddevIni && stddevIni > stddevPos){
				Result("Z-height needs to DECREASE\n\n")
				stddevIni = stddevNeg
				zHeight -= zHeightChange
			} else if (stddevPos > stddevIni && stddevIni < stddevNeg && stddevPos > stddevNeg){
				Result("Z-height needs to INCREASE\n\n")
				stddevIni = stddevPos
				zHeight += zHeightChange
				EMSetStageZ(zHeight)
				EMWaitUntilReady()
			} else if (stddevNeg > stddevIni && stddevIni < stddevPos && stddevNeg > stddevPos){
				Result("Z-height needs to DECREASE\n\n")
				stddevIni = stddevNeg
				zHeight -= zHeightChange
			} else {
				Result("Z-height is OK\n\n")
				EMSetStageZ(zHeight)
				EMWaitUntilReady()
				EMSetStageZ(zHeight)
				EMWaitUntilReady()
				Result("PED pivot point alignment finalized.\n\n")
				break
			}
			EMSetStageZ(zHeight)
			EMWaitUntilReady()
			Result("Initial std: "+stddevIni+"\n")
			safetyCount+=1
		}

		imagedocument imgdoc
		image img
		number shown=CountImageDocuments(WorkspaceGetActive())
		for(number i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0)
		}
	}
	
	//Constructor
	MainDialogClass(object self) {
		self.init(self.MainFrame())
		self.display("STEM Serial(P)ED Acquisition").WindowSetFramePosition(500, 300 )
	}
	
	//Destructor
	~MainDialogClass(object self) {
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
		Result("STEM Serial(P)ED Acquisition module closed.\n")
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

// Main function which allocates both classes
void theMainFunctionToRun() {
	Result("\n---------------------------------------------------------------------------------------------------------\n")
	Result("\nSTEM Serial(P)ED Acquisition v1.2, Sergi Plana Ruiz, Universitat Autonoma de Barcelona, URV, July 2026.\n")
	Alloc(MainDialogClass)
	getPersistentNumberNote("pyTEMserverStatus",pyTEMServerState)
	if (pyTEMServerState == 0) {
		msgPyTEMserv = "cmd.exe /k python "
		msgPyTEMserv += pathconcatenate(pyTEMserverLocation,"createServer.py")
		LaunchExternalProcessAsync(msgPyTEMserv)
		setPersistentNumberNote("pyTEMserverStatus",1)
		setPersistentNumbernote("PyModuleInitialization",0)
		Result("pyTEM server started.\n")
	} else {
		Result("pyTEM server was already running\n")
	}
	Result("\n---------------------------------------------------------------------------------------------------------\n\n")
}
		
// Call the Main function
if (EMGetOperationMode() == "SCANNING"){
	theMainFunctionToRun()
} else {
	showAlert("This module only works in STEM mode.", 1)
}