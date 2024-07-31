TagGroup intfieldXposROI, intfieldYposROI, intfieldsizeROI, realfieldThreshFit
number sizeDPx, sizeDPy, sizeMAPx, sizeMAPy, crop_x, crop_y, sizeVal,threshFit
image DI, foundCentersX, foundCentersY

//Dialog class
Class MainDialogClass:UIFrame {
				
	//Creates the Dialog	
	TagGroup MainFrame(object self) {
		TagGroup Dialog=DLGCreateDialog("Main Dialog")
		TagGroup box_items
		TagGroup box=dlgcreatebox("", box_items).dlginternalpadding(14,10)
		Dialog.dlgaddelement(box)
		
		TagGroup Get4DSTEMdataBut=DLGCreatePushButton("1. Get 4DSTEM data","get4DData").DLGenabled(1)
		Get4DSTEMdataBut.dlgidentifier("get4DData_iden").dlginternalpadding(2,0)
		box_items.dlgaddelement(Get4DSTEMdataBut)
		
		TagGroup paramROIforXcorr_items
		taggroup paramROIforXcorr = DLGCreateBox("2. ROI params for X-corr", paramROIforXcorr_items)
		
		TagGroup ExtractSumDPsBut=DLGCreatePushButton("Extract Sum DPs","extDPs4D").DLGenabled(1).DLGenabled(0)
		ExtractSumDPsBut.dlgidentifier("extDPs4D_iden").dlginternalpadding(2,0)
		paramROIforXcorr_items.dlgaddelement(ExtractSumDPsBut)
		
		TagGroup GetRoiParamsBut=DLGCreatePushButton("Get params from displayed ROI","getROIparams").DLGenabled(0)
		GetRoiParamsBut.dlgidentifier("getROIparams_iden").dlginternalpadding(2,0)
		paramROIforXcorr_items.dlgaddelement(GetRoiParamsBut)
			

		TagGroup labelXposROI = DLGCreateLabel("X-pos (px):").DLGAnchor("East")
		intfieldXposROI = DLGCreateIntegerField(70, 5).DLGidentifier("crop_x").DLGAnchor("East")
		DLGvalue(intfieldXposROI,70)
		crop_x=70
		TagGroup FirstPartcrop_x = DLGgroupitems(labelXposROI,intfieldXposROI).DLGtableLayout(2,1,0)
		TagGroup SetPlus10crop_xButton=DLGCreatePushButton("+1", "setPlus10crop_x")
		TagGroup SetMinus10crop_xButton=DLGCreatePushButton("-1", "setMinus10crop_x")
		TagGroup SecondPartcrop_x = DLGgroupitems(SetPlus10crop_xButton,SetMinus10crop_xButton).DLGtableLayout(2,1,0)
		TagGroup crop_xPart = DLGgroupitems(FirstPartcrop_x,SecondPartcrop_x).DLGtableLayout(2,1,0)
		paramROIforXcorr_items.dlgaddelement(crop_xPart)
		
		TagGroup labelYposROI = DLGCreateLabel("Y-pos (px):").DLGAnchor("East")
		intfieldYposROI = DLGCreateIntegerField(74, 5).DLGidentifier("crop_y").DLGAnchor("East")
		DLGvalue(intfieldYposROI,74)
		crop_y=74
		TagGroup FirstPartcrop_y = DLGgroupitems(labelYposROI,intfieldYposROI).DLGtableLayout(2,1,0)
		TagGroup SetPlus10crop_yButton=DLGCreatePushButton("+1", "setPlus10crop_y")
		TagGroup SetMinus10crop_yButton=DLGCreatePushButton("-1", "setMinus10crop_y")
		TagGroup SecondPartcrop_y = DLGgroupitems(SetPlus10crop_yButton,SetMinus10crop_yButton).DLGtableLayout(2,1,0)
		TagGroup crop_yPart = DLGgroupitems(FirstPartcrop_y,SecondPartcrop_y).DLGtableLayout(2,1,0)
		paramROIforXcorr_items.dlgaddelement(crop_yPart)
		
		TagGroup labelsizeROI = DLGCreateLabel("Size (px):").DLGAnchor("East")
		intfieldsizeROI = DLGCreateIntegerField(120, 5).DLGidentifier("sizeROI").DLGAnchor("East")
		DLGvalue(intfieldsizeROI,120)
		sizeVal=120
		TagGroup FirstPartSize = DLGgroupitems(labelsizeROI,intfieldsizeROI).DLGtableLayout(2,1,0)
		TagGroup SetPlus10SizeButton=DLGCreatePushButton("+1", "setPlus10size")
		TagGroup SetMinus10SizeButton=DLGCreatePushButton("-1", "setMinus10size")
		TagGroup SecondPartSize = DLGgroupitems(SetPlus10SizeButton,SetMinus10SizeButton).DLGtableLayout(2,1,0)
		TagGroup SizePart = DLGgroupitems(FirstPartSize,SecondPartSize).DLGtableLayout(2,1,0)
		paramROIforXcorr_items.dlgaddelement(SizePart)
		
		box_items.DLGAddelement(paramROIforXcorr)
		
		TagGroup XcorrButton=DLGCreatePushButton("3. Get X-correlation shfits from edges", "xcorrBut").DLGenabled(0)
		XcorrButton.dlgidentifier("xcorrBut_iden").dlginternalpadding(2,0)
		box_items.dlgaddelement(XcorrButton)
		
		TagGroup Xcorr_linCorrButton=DLGCreatePushButton("3.1 Linear adjust. to X-corr shifts", "xcorrLinCorBut").DLGenabled(0)
		Xcorr_linCorrButton.dlgidentifier("xcorrlinCorrBut_iden").dlginternalpadding(2,0)
		TagGroup labellinCorr = DLGCreateLabel("Thres.(px):").DLGAnchor("East")
		realfieldThreshFit = DLGCreateRealField(2.0, 4,5).DLGidentifier("threshFitValue").DLGAnchor("East")
		DLGvalue(realfieldThreshFit,2.0)
		threshFit = 2.0
		TagGroup fitBox = DLGgroupitems(Xcorr_linCorrButton,labellinCorr,realfieldThreshFit).DLGtableLayout(3,1,0)
		box_items.dlgaddelement(fitBox)
		
		TagGroup applyCorrBut = DLGCreatePushButton("4. Apply center correction","applyCorrFunc").DLGenabled(0)
		applyCorrBut.dlgidentifier("applyCorr_iden").dlginternalpadding(2,0)
		box_items.dlgaddelement(applyCorrBut)
		
		TagGroup PBar1    = DLGCreateProgressBar( "task progress" )
        PBar1.DLGFill("X")
        box_items.dlgaddelement(PBar1)
		
		return Dialog
	}
	
	//Get the 4D-STEM file
	void get4DData(object self){
		DI := GetFrontImage()
		if ( 4 != DI.ImageGetNumDimensions() ) Throw( "Front image is not a 4D dataset." )
		sizeDPx = DI.ImageGetDimensionSize(0)
		sizeDPy = DI.ImageGetDimensionSize(1)
		sizeMAPx = DI.ImageGetDimensionSize(2)
		sizeMAPy = DI.ImageGetDimensionSize(3)
		self.DLGSetProgress( "task progress" , 0)
		self.ValidateView()
		result("\n4D-STEM data of "+DI.GetName()+".dm4 : x = "+sizeMAPx+" y = "+sizeMAPy+"\n")
		result("DPs of: x = "+sizeDPx+" y = "+sizeDPy+"\n")
		self.SetElementisEnabled("extDPs4D_iden",1)
		self.SetElementisEnabled("xcorrBut_iden",1)
	}
	
	//Extract all DPs and make a sum image
	void extDPs4D(object self){
		image sumDP := RealImage( "Sum of all DPs", 4, sizeDPx, sizeDPy )
		for ( number py = 0; py < sizeMAPy; py++ ){
			for ( number px = 0; px < sizeMAPx; px++ ) {
				sumDP += DI.sliceN( 4, 2, 0, 0, px, py, 0, sizeDPx, 1, 1, sizeDPy, 1 )   // The first two numbers specify input (N) and output (M) dimensionality, the next N values give a sampling start point, the next M triplets define sampling for each output dimension.
			}
		}
		sumDP.ShowImage()
		self.SetElementisEnabled("getROIparams_iden",1)
	}
	
	//Get the ROI parameters from a displayed ROI
	void getROIparams(object self){
		image refImg := getFrontImage()
		imagedisplay imgdisp = refImg.ImageGetImageDisplay(0)
		ROI roiObject =imgdisp.imageDisplayGetRoi(0)
		number roi_bottom, roi_right
		roigetrectangle(roiObject, crop_y, crop_x, roi_bottom, roi_right)
		sizeVal = roi_right-crop_x
		DLGValue(intfieldXposROI,crop_x)
		DLGValue(intfieldYposROI,crop_y)
		DLGValue(intfieldsizeROI,sizeVal)
	}
	
	//Functions to increase or decrease the x-position of the ROI
	void setPlus10crop_x(object self){
		crop_x = DLGgetValue(self.LookUpElement("crop_x"))
		crop_x += 1
		DLGValue(intfieldXposROI,crop_x)
	}
	void setMinus10crop_x(object self){
		crop_x = DLGgetValue(self.LookUpElement("crop_x"))
		crop_x -= 1
		DLGValue(intfieldXposROI,crop_x)
	}
	
	//Functions to increase or decrease the y-position of the ROI
	void setPlus10crop_y(object self){
		crop_y = DLGgetValue(self.LookUpElement("crop_y"))
		crop_y += 1
		DLGValue(intfieldYposROI,crop_y)
	}
	void setMinus10crop_y(object self){
		crop_y = DLGgetValue(self.LookUpElement("crop_y"))
		crop_y -= 1
		DLGValue(intfieldYposROI,crop_y)
	}
	
	//Functions to increase or decrease the size of the ROI
	void setPlus10size(object self){
		sizeVal = DLGgetValue(self.LookUpElement("sizeROI"))
		sizeVal += 1
		DLGValue(intfieldsizeROI,sizeVal)
	}
	void setMinus10size(object self){
		sizeVal = DLGgetValue(self.LookUpElement("sizeROI"))
		sizeVal -= 1
		DLGValue(intfieldsizeROI,sizeVal)
	}
	
	//Apply cross-correlation
	void xcorrBut(object self) {
		number xposCross, yposCross, DPindex = 0
		foundCentersX := RealImage("Cross-correlation shifts across edges",4, sizeMAPx+sizeMAPy-1)
		foundCentersY := RealImage("y",4, sizeMAPx+sizeMAPy-1)
		crop_x = DLGgetValue(self.LookUpElement("crop_x"))
		crop_y = DLGgetValue(self.LookUpElement("crop_y"))
		sizeVal = DLGgetValue(self.LookUpElement("sizeROI"))
		image currentPattern, templateDP = DI.sliceN(4, 2, crop_x, crop_y, 0, 0, 0, sizeVal, 1, 1, sizeVal, 1 )
		templateDP = SmoothFilter(templateDP)
		for ( number posY = 0; posY < sizeMAPy; posY++ ) {
			if (posY == 0) {
				for ( number posX = 0; posX < sizeMAPx; posX++ ) {
				
					currentPattern = DI.sliceN(4, 2, crop_x, crop_y, posX, posY, 0, sizeVal, 1, 1, sizeVal, 1 )
					image crosscorrimg=crossCorrelate(templateDP,SmoothFilter(currentPattern))
					IUImageFindMax(crosscorrimg, 0, 0, sizeVal, sizeVal, xposCross, yposCross, 1)
					xposCross = -xposCross
					yposCross = -yposCross
					
					Result("DP_" + DPindex + " Pos y: "+posY +" Pos x: "+posX+"\t")
					Result("CrossCorr-X: "+format(xposCross,"%2.4f")+" CrossCorr-Y: "+format(yposCross,"%2.4f")+"\n")
					foundCentersX[DPindex,DPindex+1] = -xposCross
					foundCentersY[DPindex,DPindex+1] = -yposCross
					DPindex += 1
					
				}
			} else {
			
				currentPattern = DI.sliceN(4, 2, crop_x, crop_y, 0, posY, 0, sizeVal, 1, 1, sizeVal, 1 )
				image crosscorrimg=crossCorrelate(templateDP,SmoothFilter(currentPattern))
				IUImageFindMax(crosscorrimg, 0, 0, sizeVal, sizeVal, xposCross, yposCross, 1)
				xposCross = -xposCross
				yposCross = -yposCross
				
				Result("DP_" + DPindex + " Pos y: "+posY +" Pos x: "+0+"\t")
				Result("CrossCorr-X: "+format(xposCross,"%2.4f")+" CrossCorr-Y: "+format(yposCross,"%2.4f")+"\n")
				foundCentersX[DPindex,DPindex+1] = -xposCross
				foundCentersY[DPindex,DPindex+1] = -yposCross
				DPindex += 1
				
			}

		}

		//Display cross-correlation result
		imageDocument imageDoc = CreateImageDocument( "") 
		imageDisplay disp = imageDoc.ImageDocumentAddImageDisplay( foundCentersX, "lineplot")
		disp.LinePlotImageDisplaySetSliceDrawingStyle( 0, 1 )
		disp.ImageDisplaySetSliceLabelByIndex( 0 , "x-shift" )
		disp.LinePlotImageDisplaySetSliceComponentColor( 0, 0, 1, 0, 0 )
		disp.ImageDisplayAddImage( foundCentersY, "y-shift" )
		disp.LinePlotImageDisplaySetSliceComponentColor( 1, 0, 0, 0, 1 )
		disp.LinePlotImageDisplaySetLegendShown( 1 )
		imageDoc.ImageDocumentShow()
		self.SetElementisEnabled("applyCorr_iden",1)
		self.SetElementisEnabled("xcorrlinCorrBut_iden",1)
		
	}
	
	void xcorrLinCorBut(object self){
		
		threshFit = DLGgetValue(self.LookUpElement("threshFitValue"))
		number deltaX_firstRow = FoundCentersX.GetPixel(sizeMAPx-1,0)/sizeMAPx
		number deltaY_firstRow = FoundCentersY.GetPixel(sizeMAPx-1,0)/sizeMAPx
		number deltaX_firstColumn = FoundCentersX.GetPixel(sizeMAPx+sizeMAPy-2,0)/sizeMAPy
		number deltaY_firstColumn = FoundCentersY.GetPixel(sizeMAPx+sizeMAPy-2,0)/sizeMAPy
	
		number DPindex=0
		for ( number posY = 0; posY < sizeMAPy; posY++ ) {
			if (posY == 0) {
				for ( number posX = 0; posX < sizeMAPx; posX++ ) {
					if (abs(abs(foundCentersX.getPixel(DPindex,0))-abs(deltaX_firstRow*posX)) > threshFit) foundCentersX[DPindex,DPindex+1] = deltaX_firstRow*posX
					if (abs(abs(foundCentersY.getPixel(DPindex,0))-abs(deltaY_firstRow*posX)) > threshFit) foundCentersY[DPindex,DPindex+1] = deltaY_firstRow*posX
					DPindex += 1
				}
			} else {
				if (abs(abs(foundCentersX.getPixel(DPindex,0))-abs(deltaX_firstColumn*posY)) > threshFit) foundCentersX[DPindex,DPindex+1] = deltaX_firstColumn*posY
				if (abs(abs(foundCentersY.getPixel(DPindex,0))-abs(deltaY_firstColumn*posY)) > threshFit) foundCentersY[DPindex,DPindex+1] = deltaY_firstColumn*posY
				DPindex += 1
			}

		}
		
		Result("\nLinear adjustment applied to X-correlation shifts with a maximum deviations of "+threshFit+" pixels.")
	}
	
	//Apply the centre correction to the 4D-STEM dataset
	void applyCorrFunc(object self) {
	
		//Shift the DPs
		image found2DCenters := RealImage("",4, sizeMAPx+sizeMAPy-1, 2)
		found2DCenters[0,0,0, sizeMAPx+sizeMAPy-1,1, 1] = foundCentersX
		found2DCenters[0,1,0, sizeMAPx+sizeMAPy-1,2, 1] = foundCentersY

		image centers_i := RealImage("Centers along row 0",4, sizeMAPx, 2)
		centers_i = found2DCenters[0,0,0, sizeMAPx, 2,1]
		image centers_i_increment := RealImage("Increments along row 0",4, sizeMAPx, 2)
		centers_i_increment[0,0,0,sizeMAPx,1,1] = centers_i[0,0,0,sizeMAPx,1,1] - centers_i.GetPixel(0,0)
		centers_i_increment[0,1,0,sizeMAPx,2,1] = centers_i[0,1,0,sizeMAPx,2,1] - centers_i.GetPixel(0,1)
		image centers_j := RealImage("Centers along column 0",4, sizeMAPy, 2)
		centers_j[1,0,0,sizeMAPy,2,1] = found2DCenters[sizeMAPx,0,0,sizeMAPx+sizeMAPy-1,2,1]

		image shiftMatrix := RealImage("",4, sizeMAPx*sizeMAPy,2)
		number someIndex=0
		for (number j=0; j<sizeMAPy; j++ ){
			for (number i=0; i<sizeMAPx; i++ ){
				if(j==0){
					shiftMatrix[someIndex,0,0,someIndex+1,2,1]=centers_i[i,0,0,i+1,2,1]
				} else {
					shiftMatrix[someIndex,0,0,someIndex+1,2,1]=centers_j[j,0,0,j+1,2,1] + centers_i_increment[i,0,0,i+1,2,1]
				}
				someIndex += 1
			}
		}

		number originXshift, originYshift, indX=0, indY=0
		image templateDP = DI.sliceN(4, 2, crop_x, crop_y, 0, 0, 0, sizeVal, 1, 1, sizeVal, 1 )
		max(templateDP, originXshift, originYshift)
		shiftMatrix[0,0,0,sizeMAPx*sizeMAPy,1,1] -= (originXshift + crop_x - (sizeDPx/2))
		shiftMatrix[0,1,0,sizeMAPx*sizeMAPy,2,1] -= (originYshift + crop_y - (sizeDPy/2))
		image final4Ddata := ImageClone(DI)
		for ( number i=0; i<(sizeMAPx*sizeMAPy); i++ ){
			if (indX > (sizeMAPx-1)){
				indX = 0
				indY += 1
				self.DLGSetProgress( "task progress" , (i+1)/(sizeMAPx*sizeMAPy) )
				self.ValidateView()
			}
			number shiftX = shiftMatrix.GetPixel(i,0)
			number shiftY = shiftMatrix.GetPixel(i,1)
			//Result("4DSTEM dataset: Shifting " + (i+1) +" ED pattern of "+(sizeMAPx*sizeMAPy)+"\n")
			self.DLGSetProgress( "task progress" , (i+1)/(sizeMAPx*sizeMAPy) )
			self.ValidateView()
			image selectedDP = DI.sliceN(4, 2, 0, 0, indX, indY, 0, sizeDPx, 1, 1, sizeDPy, 1 )
			image shiftedDP := Realimage( "", 4, sizeDPx + 2*abs(shiftX), sizeDPy + 2*abs(shiftY) )
			shiftedDP.Slice2( abs(shiftX)+shiftX, abs(shiftY)+shiftY, 0, 0,sizeDPx,1, 1,sizeDPy,1 ) = selectedDP
			number currentX1 = sizeDPx + 2*abs(shiftX)
			number currentY1 = sizeDPy + 2*abs(shiftY)
			image finalShiftedDP := Realimage( "", 4, sizeDPx , sizeDPy )
			finalShiftedDP = shiftedDP.Slice2( abs((currentX1-sizeDPx)/2), abs((currentY1-sizeDPy)/2), 0, 0,sizeDPx,1, 1,sizeDPy,1)
			final4Ddata.sliceN(4, 2, 0, 0, indX, indY,  0, sizeDPx, 1, 1, sizeDPy, 1 ) = finalShiftedDP
			indX += 1	
		}

		//Crop the zeros from the shifted DPs
		number cutOffsetX = max(shiftMatrix[0,0,0,sizeMAPx*sizeMAPy,1,1])
		number cutOffsetY = max(shiftMatrix[0,1,0,sizeMAPx*sizeMAPy,2,1])
		number cutOffsetX_end = min(shiftMatrix[0,0,0,sizeMAPx*sizeMAPy,1,1])
		number cutOffsetY_end = min(shiftMatrix[0,1,0,sizeMAPx*sizeMAPy,2,1])
		if (cutOffsetX < 0) cutOffsetX = 0
		if (cutOffsetY < 0) cutOffsetY = 0
		if (cutOffsetX_end > 0) cutOffsetX_end = 0
		if (cutOffsetY_end > 0) cutOffsetY_end = 0
		final4Ddata := final4Ddata.sliceN(4, 4, cutOffsetX, cutOffsetY, 0, 0, 0, sizeDPx-cutOffsetX+cutOffsetX_end, 1, 1, sizeDPy-cutOffsetY+cutOffsetY_end, 1, 2, sizeMAPx, 1, 3, sizeMAPy, 1)
		showimage(final4Ddata)
		SetName(getfrontimage(), DI.GetName()+"_shifted")
		Result("\nNew 4D STEM dataset created with dimensions ")
		Result(final4Ddata.ImageGetDimensionSize(0)+"x"+final4Ddata.ImageGetDimensionSize(1)+"x"+final4Ddata.ImageGetDimensionSize(2)+"x"+final4Ddata.ImageGetDimensionSize(3)+"\n")
		WorkspaceArrange(WorkspaceGetActive(),0,0)
	
	}
	
	//GUI Constructor
	MainDialogClass(object self) {
		self.init(self.MainFrame())
		self.display("4D-STEM Center Correction").WindowSetFramePosition(500, 300 )
	}
	
	//GUI Destructor
	~MainDialogClass(object self) {
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

// Main function which allocates both classes
void theMainFunctionToRun() {
	Result("\n---------------------------------------------------------------------------------------------------------\n")
	Result("\n4D-STEM Center Correction v1.0, Sergi Plana Ruiz, Universitat Rovira i Virgili (Tarragona), July 2024.\n")
	Alloc(MainDialogClass)
}
		
// Call the Main function
theMainFunctionToRun()
