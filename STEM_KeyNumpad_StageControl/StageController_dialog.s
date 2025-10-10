TagGroup realfieldShift
number paramValTarget=1000, globalXshift, globalYshift, initialXshift, initialYshift, isStageEnabled=0, stepToShift=100
number t_label,l_label,b_label,r_label, t_oval, l_oval, b_oval, r_oval, xsizeDS, ysizeDS, xSshift, ySshift
number shiftFromCenterX, shiftFromCenterY, calibrationX, calibrationY, rotAngle, scaleCali, goByROI=0
object KeyListener, mainDLG
component ovalTheRoi, labelTheRoi, theroi
image referenceImage
imagedisplay imageDisp

string drivestring = "X:"
string folderstring = "FastADT_Storage"
string pathPDW = pathconcatenate(drivestring,folderstring)

// Thread/class to control stage shift with arrows keys
class MyKeyHandler{
	
	number KeyToken 

	image initialise(object self, number KeyTok){
		KeyToken=KeyTok
	}

	number HandleKey(object self, imagedisplay imgdisp, object keydescription){
		
		number param = DLGgetValue(realfieldShift)/1000
		//Result("Descriptor: "+GetDescription(keydescription))
		
			if(keydescription.MatchesKeyDescriptor( "numpad4" )){
				globalXshift+=param
				EMSetStageXY(globalXshift,globalYshift)
				EMWaitUntilReady()
				result("\nYou pressed left\n"+"x-shift: "+globalXshift+"\ty-shift: "+globalYshift+"\n")
			}		
			if(keydescription.MatchesKeyDescriptor( "numpad6" )){
				globalXshift-=param
				EMSetStageXY(globalXshift,globalYshift)
				EMWaitUntilReady()
				result("\nYou pressed right.\n"+"x-shift: "+globalXshift+"\ty-shift: "+globalYshift+"\n")
			}
			if(keydescription.MatchesKeyDescriptor( "numpad8" )){
				globalYshift-=param
				EMSetStageXY(globalXshift,globalYshift)
				EMWaitUntilReady()
				result("\nYou pressed up.\n"+"x-shift: "+globalXshift+"\ty-shift: "+globalYshift+"\n")
			}					
			if(keydescription.MatchesKeyDescriptor( "numpad2" )){
				globalYshift+=param
				EMSetStageXY(globalXshift,globalYshift)
				EMWaitUntilReady()
				result("\nYou pressed down.\n"+"x-shift: "+globalXshift+"\ty-shift: "+globalYshift+"\n")
			}
			if(keydescription.MatchesKeyDescriptor( "numpad9" )){
				EMSetMagIndex( EMGetMagIndex( ) + 1 )
			}
			if(keydescription.MatchesKeyDescriptor( "numpad7" )){
				EMSetMagIndex( EMGetMagIndex( ) - 1 )
			}
			if(keydescription.MatchesKeyDescriptor( "numpad1" )){
				paramValTarget -= stepToShift
				if(paramValTarget < 0) paramValTarget = 0
				DLGvalue(realfieldShift,paramValTarget)
			}
			if(keydescription.MatchesKeyDescriptor( "numpad3" )){
				paramValTarget += stepToShift
				if(paramValTarget < 0) paramValTarget = 0
				DLGvalue(realfieldShift,paramValTarget)
			}
			if(keydescription.MatchesKeyDescriptor("numpad5")==1 && goByROI==1){
				referenceImage := getFrontImage()
				EMGetStageXY(globalXshift,globalYshift)
				
				number currentScaleCali=ImageGetDimensionScale(referenceImage,0)
				theRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
				shiftFromCenterX = ((r_oval-5)-(xsizeDS/2))
				shiftFromCenterY = ((b_oval-5)-(ysizeDS/2))
				
				xSshift = ((cos(rotAngle*pi()/180)*(shiftFromCenterX*calibrationX)) + (-sin(rotAngle*pi()/180)*(shiftFromCenterY*calibrationY)))*currentScaleCali
				ySshift = ((sin(rotAngle*pi()/180)*(shiftFromCenterX*calibrationX)) + (cos(rotAngle*pi()/180)*(shiftFromCenterY*calibrationY)))*currentScaleCali
				
				globalXshift -= xSshift
				globalYshift += ySshift
				EMSetStageXY(globalXshift-0.1,globalYshift-0.1)
				EMWaitUntilReady()
				EMSetStageXY(globalXshift,globalYshift)
				EMWaitUntilReady()
				
				Result("Current calibration: "+currentScaleCali+"\n")
				Result("Position (pixels):\t"+(r_oval-5)+"\t"+(b_oval-5)+"\n")
				Result("Shifts in pixels from centre:\t"+shiftFromCenterX+"\t"+shiftFromCenterY+"\n")
				Result("Shifts from centre:\t"+xSshift+"\t"+ySshift+"\n")
			}
			isStageEnabled=1
		return 0
	}

	void killTheControl(object self){
		image front := getFrontImage()
		imagedisplay frontdisp=front.imagegetimagedisplay(0)
		frontdisp.imagedisplayremovekeyhandler(KeyToken)
	}
	
	// Constructor
	Mykeyhandler(object self){
	}

	// Destructor 
	~Mykeyhandler(object self){
		if (isStageEnabled==1){
			KeyListener.killTheControl()
			Result("Stage key control disabled.\n")
		}
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

// Dialog class
Class MainDialogClass:UIFrame {
				
	//Creates the Dialog	
	TagGroup MainFrame(object self) {
	TagGroup Dialog=DLGCreateDialog("Main Dialog")
	TagGroup box_items
	TagGroup box=dlgcreatebox("", box_items).dlginternalpadding(14,10)
	Dialog.dlgaddelement(box)
	
	//Stage shift with arrow keys
	TagGroup parametersGroup_items
	TagGroup parametersGroup = DLGCreateBox("Stage shift with numpad keys",parametersGroup_items)
		TagGroup paramsValues_items
		taggroup paramsValues = DLGCreateBox("", paramsValues_items)
		TagGroup GetTEMStageShiftButton=DLGCreatePushButton("Enable","getStageControl")
		GetTEMStageShiftButton.dlgidentifier("getStage").dlginternalpadding(2,0)
		TagGroup DisableTEMStageShiftButton=DLGCreatePushButton("Disable","disableStageControl")
		DisableTEMStageShiftButton.dlgidentifier("disableStageControl").dlginternalpadding(2,0).dlgenabled(0)
		parametersGroup_items.dlgaddelement(DLGgroupitems(GetTEMStageShiftButton,DisableTEMStageShiftButton).DLGtableLayout(2,1,0))
		TagGroup labelLow = DLGCreateLabel("Shift (nm): ").DLGAnchor("East")
		realfieldShift = DLGCreateRealField(0, 8, 8).DLGidentifier("stageShift").DLGAnchor("East")
		DLGvalue(realfieldShift,1000)
		TagGroup coarseButt = DLGCreatePushButton("C", "setCoarse").dlgidentifier("setCoarseID").dlgenabled(0)
		TagGroup fineButt = DLGCreatePushButton("F","setFine").dlgidentifier("setFineID").dlgenabled(1)
		TagGroup FirstPartParam = DLGgroupitems(labelLow,realfieldShift, coarseButt, fineButt).DLGtableLayout(4,1,0)
		parametersGroup_items.dlgaddelement(FirstPartParam)
		TagGroup SetPlus10Button=DLGCreatePushButton("+10", "setPlus10")
		TagGroup SetMinus10Button=DLGCreatePushButton("-10", "setMinus10")
		TagGroup SecondPartParam = DLGgroupitems(SetPlus10Button,SetMinus10Button).DLGtableLayout(2,1,0)
		TagGroup SetPlus100Button=DLGCreatePushButton("+100", "setPlus100")
		TagGroup SetMinus100Button=DLGCreatePushButton("-100", "setMinus100")
		TagGroup ThirdPartParam = DLGgroupitems(SetPlus100Button,SetMinus100Button).DLGtableLayout(2,1,0)
		TagGroup paramPart = DLGgroupitems(SecondPartParam,ThirdPartParam).DLGtableLayout(2,1,0)
		parametersGroup_items.dlgaddelement(paramPart)
	box_items.DLGAddelement(parametersGroup)
	
	//Stage shift calibration
	taggroup caliStageShift_items
	taggroup caliStageShift=DLGcreatebox(" Stage shift calibration  ", caliStageShift_items)
		TagGroup labelshift = DLGCreateLabel("Cali. param (nm):")
		TagGroup etiqueta = DLGCreateRealField(1000, 8, 3).DLGidentifier("stagerefval").DLGvalue(1000)
		TagGroup labelboxShift=DLGgroupitems(labelshift, etiqueta).DLGtablelayout(2,1,0)
		caliStageShift_items.DLGaddelement(labelboxShift)
		Taggroup test=DLGcreatepushbutton("Test cali. param", "testBeamShift").DLGidentifier("testSSval").DLGinternalpadding(9,0)
		caliStageShift_items.DLGaddelement(test)
		Taggroup cali=DLGcreatepushbutton("Calibrate", "caliBeamShifts").DLGidentifier("caliButton").DLGinternalpadding(9,0)
		caliStageShift_items.DLGaddelement(cali)
	box_items.DLGaddelement(caliStageShift)
	
	//Stage roi control
	taggroup stageControlGroup_items
	taggroup stageControlGroup=DLGcreatebox("Stage control by roi", stageControlGroup_items)
		Taggroup activateControlButton=DLGcreatepushbutton("Activate", "activateSScontrol").DLGidentifier("actiSS").DLGinternalpadding(10,0).dlgenabled(1)
		Taggroup resetControlButton=DLGcreatepushbutton("Reset", "resetSScontrol").DLGidentifier("resSS").DLGinternalpadding(10,0).dlgenabled(0)
		stageControlGroup_items.DLGaddelement(DLGgroupitems(activateControlButton, resetControlButton).DLGtablelayout(2,1,0))
		Taggroup goButton=DLGcreatepushbutton("GO", "goToButton").DLGidentifier("goTo").DLGinternalpadding(9,0).dlgenabled(0)
		stageControlGroup_items.DLGaddelement(goButton)
	box_items.DLGaddelement(stageControlGroup)
	
	//Increase magnification
	taggroup stemmaggroup_items
	taggroup stemmaggroup=DLGcreatebox("STEM magnification",stemmaggroup_items)
		Taggroup increaseMagButton=DLGcreatepushbutton("Increase","increaseMagSTEM").DLGinternalpadding(5,0)
		Taggroup decreaseMagButton=DLGcreatepushbutton("Decrease","decreaseMagSTEM").DLGinternalpadding(5,0)
		stemmaggroup_items.DLGaddelement(DLGgroupitems(increaseMagButton,decreaseMagButton).DLGtablelayout(2,1,0))
	box_items.DLGaddelement(stemmaggroup)
	
	return Dialog
}
	
	//Get stage control
	void getStageControl(object self){
		image front:=getfrontimage()
		imagedisplay frontdisp=front.imagegetimagedisplay(0)
		EMGetStageXY(globalXshift,globalYshift)
		EMSetStageXY(globalXshift,globalYshift)
		EMWaitUntilReady()
		initialXshift = globalXshift
		initialYshift = globalYshift

		// Add the key handler to the image and pass the handler's numerical ID into the KeyListener object
		number keyToken = frontdisp.ImageDisplayAddKeyHandler(KeyListener, "HandleKey")
		KeyListener.initialise (KeyToken)
		result("\n\nPress the arrow keys to move the stage.\n")
		self.SetElementisEnabled("getStage",0)
		self.SetElementisEnabled("disableStageControl",1)
		Result("Stage control enabled.\n")
		isStageEnabled=1
	}
	void disableStageControl(object self){
		KeyListener.killTheControl()
		self.SetElementisEnabled("getStage",1)
		self.SetElementisEnabled("disableStageControl",0)
		Result("Stage key control disabled.\n")
		isStageEnabled=0
	}
	
	void setCoarse(object self){
		stepToShift = 100
		self.SetElementisEnabled("setCoarseID",0)
		self.SetElementisEnabled("setFineID",1)
	}
	
	void setFine(object self){
		stepToShift = 10
		self.SetElementisEnabled("setCoarseID",1)
		self.SetElementisEnabled("setFineID",0)
	}
	
	//Functions to increase or decrease the low value of the Contrast Limits
	void setPlus10(object self){
		paramValTarget = DLGgetValue(self.LookUpElement("stageShift"))
		paramValTarget += 10
		DLGValue(realfieldShift,paramValTarget)
	}
	void setMinus10(object self){
		paramValTarget = DLGgetValue(self.LookUpElement("stageShift"))
		paramValTarget -= 10
		DLGValue(realfieldShift,paramValTarget)
	}
	void setPlus100(object self){
		paramValTarget = DLGgetValue(self.LookUpElement("stageShift"))
		paramValTarget += 100
		DLGValue(realfieldShift,paramValTarget)
	}
	void setMinus100(object self){
		paramValTarget = DLGgetValue(self.LookUpElement("stageShift"))
		paramValTarget -= 100
		DLGValue(realfieldShift,paramValTarget)
	}
	
	void testBeamShift (object self){
		EMGetStageXY(globalXshift,globalYshift)
		number delta = DLGgetValue(self.LookUpElement("stagerefval"))/1000
		EMSetStageXY(globalXshift+delta+0.1,globalYshift)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift+delta,globalYshift)
		EMWaitUntilReady()
		showAlert("Positive X-Beam Shift",2)
		EMSetStageXY(globalXshift-delta-0.1,globalYshift)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift-delta,globalYshift)
		EMWaitUntilReady()
		showAlert("Negative X-Beam Shift",2)
		EMSetStageXY(globalXshift,globalYshift+delta+0.1)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift,globalYshift+delta)
		EMWaitUntilReady()
		showAlert("Positive Y-Beam Shift",2)
		EMSetStageXY(globalXshift,globalYshift-delta-0.1)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift,globalYshift-delta)
		EMWaitUntilReady()
		showAlert("Negative Y-Beam Shift",2)
		EMSetStageXY(globalXshift,globalYshift)
		showAlert("If a feature of interest goes out of the field of view, reduce the 'Test cali. param' parameter.",2)
	}
	void caliBeamShifts (object self){

		number shown, i, modulLineX, modulLineY, xsize, ysize, xfinal, yfinal
		number xinitial, yinitial, xpos3, ypos3, xpos4, ypos4, origin
		image Img1, Img2, Img3, Img4, Img5, img, crosscorrimg, sumImage
		string unitsstring
		imagedocument imgDoc
		documentwindow textFile
		
		KeyListener.killTheControl()
		Result("Stage key control disabled.\n")
		self.SetElementisEnabled("getStage",1)
		self.SetElementisEnabled("disableStageControl",0)
		isStageEnabled=0
		
		number delta = DLGgetValue(self.LookUpElement("stagerefval"))/1000
		
		shown=CountImageDocuments(WorkspaceGetActive())
		for(i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0)
		}
		
		if (DSIsAcquisitionActive()  == 1) {
			DSInvokeButton(1)
			DSWaitUntilFinished( )
		}
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		Result("\nStage Shift Calibration\n\n")
		
		EMGetStageXY(globalXshift,globalYshift)
		EMSetStageXY(globalXshift,globalYshift)
		EMWaitUntilReady()
		Img1 := getFrontImage()
		setName(Img1,"Img1")
		Result("1/5 Acquired Images: Non-shifted.\n")
		
		EMSetStageXY(globalXshift+delta+0.1,globalYshift)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift+delta,globalYshift)
		EMWaitUntilReady()
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		Img2 := getFrontImage()
		setName(Img2,"Img2")
		Result("2/5 Acquired Images: Positive X-Shift.\n")
		
		EMSetStageXY(globalXshift-delta-0.1,globalYshift)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift-delta,globalYshift)
		EMWaitUntilReady()
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		Img3 := getFrontImage()
		setName(Img3,"Img3")	
		Result("3/5 Acquired Images: Negative X-Shift.\n")
		
		EMSetStageXY(globalXshift,globalYshift+delta+0.1)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift,globalYshift+delta)
		EMWaitUntilReady()		
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		Img4 := getFrontImage()
		setName(Img4,"Img4")
		Result("4/5 Acquired Images: Positive Y-Shift.\n")
		
		EMSetStageXY(globalXshift,globalYshift-delta-0.1)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift,globalYshift-delta)
		EMWaitUntilReady()						
		DSInvokeButton(3)
		DSWaitUntilFinished( )
		Img5 := getFrontImage()
		setName(Img5,"Img5")	
		Result("5/5 Acquired Images: Negative Y-Shift.\n\n")
			
		string unitsStringRef = imagegetdimensionunitstring(Img5,0)
		ImageGetDimensionCalibration(Img5, 0, origin, scaleCali, unitsString, 1)
		
		EMSetStageXY(globalXshift,globalYshift)
		EMWaitUntilReady()	
		
		//Cross-Correlations
		getSize(Img1,xsize,ysize)
					
		crosscorrimg = crossCorrelate(Img1, Img2)
		max(crosscorrimg, xfinal, yfinal)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xfinal, yfinal, 1)
		xfinal=-xfinal
		yfinal=-yfinal
					
		crosscorrimg = crossCorrelate(Img1, Img3)
		max(crosscorrimg, xinitial, yinitial)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xinitial, yinitial, 1)
		xinitial = -xinitial
		yinitial = -yinitial
				
		crosscorrimg = crossCorrelate(Img1, Img4)
		max(crosscorrimg, xpos3, ypos3)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xpos3, ypos3, 1)
		xpos3 = -xpos3
		ypos3 = -ypos3
				
		crosscorrimg = crossCorrelate(Img1, Img5)
		max(crosscorrimg, xpos4, ypos4)
		IUImageFindMax(crosscorrimg, 0, 0, ysize, xsize, xpos4, ypos4, 1)
		xpos4 = - xpos4
		ypos4 = - ypos4
					
		sumImage = Img1+Img2+Img3+Img4+Img5
		
		shown=CountImageDocuments(WorkspaceGetActive())
		for(i=0; i<shown; ++i){
			imgDoc=getImageDocument(0)
			img:=getFrontImage()
			imageDocumentClose(imgdoc,0)
		}
		
		showImage(sumImage)
		imageDisplay vectordisp=sumImage.imageGetImageDisplay(0)
					
		//Arrow Draws from the cross-correlation of the acquired images
		component arrow=newarrowannotation(ysize/2, xsize/2, (yfinal+(ysize/2)), (xfinal+(xsize/2)))
		arrow.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow)
		Result("Positive X-Shifted Img: ---> X-position: \t"+ xfinal + "\tY-position: \t"+yfinal+"\n")

		component arrow2=newarrowannotation(ysize/2, xsize/2, (yinitial+(ysize/2)), (xinitial+(xsize/2)))
		arrow2.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow2)
		Result("Negative X-Shifted Img: ---> X-position: \t"+ xinitial + "\tY-position: \t"+yinitial+"\n")

		component arrow3=newarrowannotation(ysize/2, xsize/2, (ypos3+(ysize/2)), (xpos3+(xsize/2)))
		arrow3.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow3)
		Result("Positive Y-Shifted Img: ---> X-position: \t"+ xpos3 + "\tY-position: \t"+ypos3+"\n")

		component arrow4=newarrowannotation(ysize/2, xsize/2, (ypos4+(ysize/2)), (xpos4+(xsize/2)))
		arrow4.componentsetforegroundcolor(1,0,0)
		vectordisp.componentaddchildatend(arrow4)
		Result("Negative Y-Shifted Img: ---> X-position: \t"+ xpos4 + "\tY-position: \t"+ypos4+"\n\n")

		updateimage(sumImage)
		setName(sumImage,"Stage shift calibration")
				
		//Calculation of the two axes lengths and the angle between the horizontal and the positive x direction
		modulLineX = sqrt( ((xinitial-xfinal)**2)+((yinitial-yfinal)**2) )
		modulLineY = sqrt( ((xpos4-xpos3)**2)+((ypos4-ypos3)**2) )
		
		calibrationX = ((2*delta)/modulLineX)/scaleCali
		calibrationY = ((2*delta)/modulLineY)/scaleCali
				
		Result("Calibration in X-direction:"+"\t"+(calibrationX)+" stage µm / calibrated "+unitsStringRef+"\n")
		Result("Calibration in Y-direction:"+"\t"+(calibrationY)+" stage µm / calibrated "+unitsStringRef+"\n")
					
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
					
		textFile=NewScriptWindow("Stage Shift Calibrations", 50,50,150,450)
		editorWindowAddText(textFile,"Calibration X: "+format(calibrationX,"%3.4f")+"\n"+"Calibration Y: "+format(calibrationY,"%3.4f")+"\n"+"Angle for FrameWork Rotation: "+format(rotAngle, "%3.4f")+"\n")
		editorWindowAddText(textFile,"Calibration Scale: "+format(scaleCali,"%3.8f"))
		editorWindowSaveToFile(textFile,pathconcatenate(pathPDW,"StageShiftCalibration.txt"))
		windowClose(textFile,0)
				
		Result("Stage shift Calibration finalized.\n\n")	
		showAlert("Stage shift calibration finalized.",2)

	}
	
	void activateSScontrol(object self){
	
		if (DSIsAcquisitionActive()  == 0) {
			DSInvokeButton(1)
		}
		showAlert("Activated, click ok.",2)
		
		referenceImage := getFrontImage()
		imageDisp = referenceImage.ImageGetImageDisplay(0)
		referenceImage.GetSize(xsizeDS, ysizeDS)
		ovalTheRoi = NewOvalAnnotation((xsizeDS/2)-5, (ysizeDS/2)-5, (xsizeDS/2)+5, (ysizeDS/2)+5)
		ovalTheRoi.ComponentSetSelectable(0)
		ovalTheRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
		ovalTheRoi.ComponentSetForeGroundColor( 1, 0, 0)
		labelTheRoi = NewTextAnnotation( 0,0, "Go here", 10)
		labelTheRoi.ComponentSetBackGroundColor( 0, 0, 0)
		labelTheRoi.ComponentSetForeGroundColor( 1, 0, 0)
		labelTheRoi.ComponentSetSelectable(0)
		labelTheRoi.ComponentGetBoundingRect(t_label,l_label,b_label,r_label)
		labelTheRoi.ComponentSetRect(-b_label,-r_label,0,0)
		theroi = NewGroupAnnotation()
		theroi.ComponentAddChildAtEnd(ovalTheRoi)
		theroi.ComponentAddChildAtEnd(labelTheRoi)
		ComponentSetDeletable(theroi,0)
		imageDisp.ComponentAddChildAtEnd(theroi)
		goByROI = 1
		self.SetElementisEnabled("actiSS",0)
		self.SetElementisEnabled("resSS",1)
		self.SetElementisEnabled("goTo",1)
		
	}
	
	void resetSScontrol(object self){
		self.SetElementisEnabled("actiSS",1)
		self.SetElementisEnabled("resSS",0)
		self.SetElementisEnabled("goTo",0)
		goByROI=0
	}
	
	void goToButton(object self){
		referenceImage := getFrontImage()
		EMGetStageXY(globalXshift,globalYshift)
		
		number currentScaleCali=ImageGetDimensionScale(referenceImage,0)
		theRoi.ComponentGetBoundingRect(t_oval, l_oval, b_oval, r_oval)
		shiftFromCenterX = ((r_oval-5)-(xsizeDS/2))
		shiftFromCenterY = ((b_oval-5)-(ysizeDS/2))
		
		xSshift = ((cos(rotAngle*pi()/180)*(shiftFromCenterX*calibrationX)) + (-sin(rotAngle*pi()/180)*(shiftFromCenterY*calibrationY)))*currentScaleCali
		ySshift = ((sin(rotAngle*pi()/180)*(shiftFromCenterX*calibrationX)) + (cos(rotAngle*pi()/180)*(shiftFromCenterY*calibrationY)))*currentScaleCali
		
		globalXshift -= xSshift
		globalYshift += ySshift
		EMSetStageXY(globalXshift-0.1,globalYshift-0.1)
		EMWaitUntilReady()
		EMSetStageXY(globalXshift,globalYshift)
		EMWaitUntilReady()
		
		Result("Current calibration: "+currentScaleCali+"\n")
		Result("Position (pixels):\t"+(r_oval-5)+"\t"+(b_oval-5)+"\n")
		Result("Shifts in pixels from centre:\t"+shiftFromCenterX+"\t"+shiftFromCenterY+"\n")
		Result("Shifts from centre:\t"+xSshift+"\t"+ySshift+"\n")
	}
	
	void increaseMagSTEM(object self){
		EMSetMagIndex( EMGetMagIndex( ) + 1 )
	}
	
	void decreaseMagSTEM(object self){
		EMSetMagIndex( EMGetMagIndex( ) - 1 )
	}
	
	//Constructor
	MainDialogClass(object self) {
		self.init(self.MainFrame())
		self.display("STEM digital XY stage control").WindowSetFramePosition(500, 300 )
	}
	
	//Destructor
	~MainDialogClass(object self) {
		if (isStageEnabled==1){
			KeyListener.killTheControl()
			Result("Stage key control disabled.\n")
		}
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

Result("\n---------------------------------------------------------------------------------------------------------\n")
Result("\nSTEM stage controller v1.0, Sergi Plana Ruiz, Universitat Rovira i Virgili (Tarragona), October 2025.\n")
mainDLG=alloc(MainDialogClass)
KeyListener=alloc(MyKeyHandler)