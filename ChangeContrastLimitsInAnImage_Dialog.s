ImageDisplay imageDisp
TagGroup realfieldLow, realfieldHigh, realfieldGamma
number lowVal, highVal, gammaValue, workspaceID, shown, i
image myImage, newImage
imagedocument imgDoc
string nomImg

//Dialog class
Class MainDialogClass:UIFrame {
				
	//Creates the Dialog	
	TagGroup MainFrame(object self) {
		TagGroup Dialog=DLGCreateDialog("Main Dialog")
		TagGroup box_items
		TagGroup box=dlgcreatebox("", box_items).dlginternalpadding(14,10)
		Dialog.dlgaddelement(box)
		
		TagGroup GetContrastLimitsButton=DLGCreatePushButton("Get contrast from front image","getContrastLimits").DLGenabled(1)
		GetContrastLimitsButton.dlgidentifier("getContrast").dlginternalpadding(2,0)
		box_items.dlgaddelement(GetContrastLimitsButton)
		
		TagGroup parametersGroup_items
		TagGroup parametersGroup = DLGCreateBox("",parametersGroup_items)
		
		TagGroup contrastLimitsValues_items
		taggroup contrastLimitsValues = DLGCreateBox("Limit values", contrastLimitsValues_items)		

		TagGroup labelLow = DLGCreateLabel("Lowest ->").DLGAnchor("East")
		realfieldLow = DLGCreateRealField(0, 10, 8).DLGidentifier("low").DLGAnchor("East")
		DLGvalue(realfieldLow,0)
		TagGroup FirstPartLow = DLGgroupitems(labelLow,realfieldLow).DLGtableLayout(2,1,0)
		TagGroup SetPlus10LowButton=DLGCreatePushButton("+10", "setPlus10low")
		TagGroup SetMinus10LowButton=DLGCreatePushButton("-10", "setMinus10low")
		TagGroup SecondPartLow = DLGgroupitems(SetPlus10LowButton,SetMinus10LowButton).DLGtableLayout(2,1,0)
		TagGroup SetPlus100LowButton=DLGCreatePushButton("+100", "setPlus100low")
		TagGroup SetMinus100LowButton=DLGCreatePushButton("-100", "setMinus100low")
		TagGroup ThirdPartLow = DLGgroupitems(SetPlus100LowButton,SetMinus100LowButton).DLGtableLayout(2,1,0)
		TagGroup lowPart = DLGgroupitems(FirstPartLow,SecondPartLow,ThirdPartLow).DLGtableLayout(3,1,0)
		contrastLimitsValues_items.dlgaddelement(lowPart)
		
		TagGroup labelHigh = DLGCreateLabel("Higher  ->").DLGAnchor("East")
		realfieldHigh = DLGCreateRealField(0, 10, 8).DLGidentifier("high").DLGAnchor("East")
		DLGvalue(realfieldHigh,1000)
		TagGroup FirstPartHigh = DLGgroupitems(labelHigh,realfieldHigh).DLGtableLayout(2,1,0)
		TagGroup SetPlus10HighButton=DLGCreatePushButton("+10", "setPlus10high")
		TagGroup SetMinus10HighButton=DLGCreatePushButton("-10", "setMinus10high")
		TagGroup SecondPartHigh = DLGgroupitems(SetPlus10HighButton,SetMinus10HighButton).DLGtableLayout(2,1,0)
		TagGroup SetPlus100HighButton=DLGCreatePushButton("+100", "setPlus100high")
		TagGroup SetMinus100HighButton=DLGCreatePushButton("-100", "setMinus100high")
		TagGroup ThirdPartHigh = DLGgroupitems(SetPlus100HighButton,SetMinus100HighButton).DLGtableLayout(2,1,0)
		TagGroup highPart = DLGgroupitems(FirstPartHigh,SecondPartHigh,ThirdPartHigh).DLGtableLayout(3,1,0)
		contrastLimitsValues_items.dlgaddelement(highPart)
		parametersGroup_items.dlgaddelement(contrastLimitsValues)
		
		TagGroup gammaLabel = DLGCreateLabel("Gamma ->").DLGAnchor("East")
		realfieldGamma = DLGCreateRealField(0.5,4,2,"gammaChangedFunction").DLGidentifier("gamVal").DLGAnchor("East").dlgvalue(0.5)
		TagGroup SetPlus0p1 = DLGCreatePushButton("+0.01","setPlus0p1gam").DLGidentifier("plus0p1button")
		TagGroup SetMinus0p1 = DLGCreatePushButton("-0.01","setMinus0p1gam").DLGidentifier("minus0p1button")
		TagGroup gammaGroup = DLGgroupitems(gammaLabel, realfieldGamma, SetPlus0p1, SetMinus0p1).DLGtableLayout(4,1,0)
		parametersGroup_items.dlgaddelement(gammaGroup)
		
		box_items.DLGAddelement(parametersGroup)
		
		TagGroup ChangeButton=DLGCreatePushButton("Set contrast", "changeValuesButton").DLGenabled(1)
		ChangeButton.dlgidentifier("setContrast").dlginternalpadding(2,0)
		TagGroup SetContrastAllButton=DLGCreatePushButton("Set contrast to all images","setContrastAll")
		SetContrastAllButton.dlginternalpadding(2,0)
		TagGroup groupOfLowerButtons = DLGgroupitems(ChangeButton,SetContrastAllButton).DLGtablelayout(2,1,0)
		box_items.dlgaddelement(groupOfLowerButtons)
		
		TagGroup invertImgButton = DLGCreatePushButton("Invert image contrast","invImgButton")
		invertImgButton.dlgidentifier("invImg").dlginternalpadding(2,0)
		TagGroup invertAllImgsButton = DLGCreatePushButton("Invert contrast to all images","invAllImgsButton")
		invertImgButton.dlgidentifier("invImg").dlginternalpadding(2,0)
		TagGroup invertContrastButtons = DLGgroupitems(invertImgButton,invertAllImgsButton).DLGtablelayout(2,1,0)
		box_items.dlgaddelement(invertContrastButtons)
		
		return Dialog
	}
	
	//Get the Contrast Limits from the Image Display
	void getContrastLimits(object self){
		myImage := GetFrontImage()
		imageDisp = myImage.ImageGetImageDisplay(0)
		imageDisp.ImageDisplayGetContrastLimits( lowVal, highVal )
		gammaValue = ImageDisplayGetGammaCorrection(imageDisp)
		DLGValue(realfieldLow,lowVal)
		DLGValue(realfieldHigh,highVal)
		DLGValue(realfieldGamma, gammaValue)
	}
	
	//Functions to increase or decrease the low value of the Contrast Limits
	void setPlus10low(object self){
		lowVal = DLGgetValue(self.LookUpElement("low"))
		lowVal += 10
		DLGValue(realfieldLow,lowVal)
	}
	void setMinus10low(object self){
		lowVal = DLGgetValue(self.LookUpElement("low"))
		lowVal -= 10
		DLGValue(realfieldLow,lowVal)
	}
	void setPlus100low(object self){
		lowVal = DLGgetValue(self.LookUpElement("low"))
		lowVal += 100
		DLGValue(realfieldLow,lowVal)
	}
	void setMinus100low(object self){
		lowVal = DLGgetValue(self.LookUpElement("low"))
		lowVal -= 100
		DLGValue(realfieldLow,lowVal)
	}
	
	//Functions to increase or decrease the gamma value of the displayed image
	void setPlus0p1gam(object self){
		myImage := GetFrontImage()
		imageDisp = myImage.ImageGetImageDisplay(0)
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		gammaValue += 0.01
		if (gammaValue > 0.99){
			self.SetElementisEnabled("minus0p1button",1)
			self.SetElementisEnabled("plus0p1button",0)
			gammaValue = 1
		}
		if (gammaValue > 0.01){
			self.SetElementisEnabled("minus0p1button",1)
		}
		DLGValue(realfieldGamma, gammaValue)
		ImageDisplaySetGammaCorrection(imageDisp, gammaValue)
	}
	void setMinus0p1gam(object self){
		myImage := GetFrontImage()
		imageDisp = myImage.ImageGetImageDisplay(0)
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		gammaValue -= 0.01
		if (gammaValue < 0.01){
			self.SetElementisEnabled("minus0p1button",0)
			gammaValue = 0
		}
		if (gammaValue < 0.99){
			self.SetElementisEnabled("plus0p1button",1)
		}
		DLGValue(realfieldGamma, gammaValue)
		ImageDisplaySetGammaCorrection(imageDisp, gammaValue)
	}
	void gammaChangedFunction(object self, taggroup tg){
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		myImage := GetFrontImage()
		imageDisp = myImage.ImageGetImageDisplay(0)
		ImageDisplaySetGammaCorrection(imageDisp, gammaValue)
	}
	
	//Functions to increase or decrease the high value of the Contrast Limits
	void setPlus10high(object self){
		highVal = DLGgetValue(self.LookUpElement("high"))
		highVal += 10
		DLGValue(realfieldhigh,highVal)
	}
	void setMinus10high(object self){
		highVal = DLGgetValue(self.LookUpElement("high"))
		highVal -= 10
		DLGValue(realfieldhigh,highVal)
	}
	void setPlus100high(object self){
		highVal = DLGgetValue(self.LookUpElement("high"))
		highVal += 100
		DLGValue(realfieldhigh,highVal)
	}
	void setMinus100high(object self){
		highVal = DLGgetValue(self.LookUpElement("high"))
		highVal -= 100
		DLGValue(realfieldhigh,highVal)
	}	
	
	//Set the Contrast Limits for the Image Display
	void changeValuesButton(object self) {
		myImage := GetFrontImage()
		imageDisp = myImage.ImageGetImageDisplay(0)
		lowVal = DLGgetValue(self.LookUpElement("low"))
		highVal = DLGgetValue(self.LookUpElement("high"))
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		imageDisp.ImageDisplaySetContrastLimits( lowVal, highVal )
		ImageDisplaySetGammaCorrection(imageDisp, gammaValue )
	}
	
	//Invert the front image contrast
	void invImgButton(object self) {
		myImage := GetFrontImage()
		nomImg = myImage.GetName()
		newImage := -1*myImage
		newImage.SetName(nomImg+"_Inverted")
		showimage(newImage)
		imageDisp = newImage.ImageGetImageDisplay(0)
		lowVal = DLGgetValue(self.LookUpElement("low"))
		highVal = DLGgetValue(self.LookUpElement("high"))
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		imageDisp.ImageDisplaySetContrastLimits( -highVal, -lowVal )
		ImageDisplaySetGammaCorrection(imageDisp, abs(1-gammaValue))
		DLGValue(realfieldlow,-highVal)
		DLGValue(realfieldhigh,-lowVal)
		DLGValue(realfieldGamma, abs(1-gammaValue))
	}
	
	//Invert contrast to all imagest
	void invAllImgsButton(object self) {
		lowVal = DLGgetValue(self.LookUpElement("low"))
		highVal = DLGgetValue(self.LookUpElement("high"))
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		workspaceID = WorkspaceGetActive()
		shown=CountImageDocuments(workspaceID)
		
		for(i=0; i<shown; ++i){
			imgdoc = getImageDocument(i)
			imageDocumentShow(imgdoc)
			myImage := GetFrontImage()
			imageDocumentClose(imgdoc,0)
			nomImg = myImage.GetName()
			newImage := -1*myImage
			newImage.SetName(nomImg+"_Inverted")
			showimage(newImage)
			imageDisp = newImage.ImageGetImageDisplay(0)
			imageDisp.ImageDisplaySetContrastLimits( -highVal, -lowVal )
			ImageDisplaySetGammaCorrection(imageDisp, abs(1-gammaValue))
		}	
		
		WorkspaceArrange(workspaceID, 1, 0)
		DLGValue(realfieldlow,-highVal)
		DLGValue(realfieldhigh,-lowVal)
		DLGValue(realfieldGamma, abs(1-gammaValue))
	}
	
	//Set the Contrast Limits for all images in the workspace
	void setContrastAll(object self){
		workspaceID = WorkspaceGetActive()
		WorkspaceArrange(workspaceID, 1, 0)
		shown=CountImageDocuments(workspaceID)
		lowVal = DLGgetValue(self.LookUpElement("low"))
		highVal = DLGgetValue(self.LookUpElement("high"))
		gammaValue = DLGgetValue(self.LookUpElement("gamVal"))
		for(i=0; i<shown; ++i){	
			imgDoc=getImageDocument(i)
			imageDisp=ImageDocumentGetImageModeDisplay(imgDoc)
			imageDisp.ImageDisplaySetContrastLimits(lowVal, highVal)
			ImageDisplaySetGammaCorrection(imageDisp, gammaValue)
		}
	}
	
	//Constructor
	MainDialogClass(object self) {
		self.init(self.MainFrame())
		self.display("Contrast Image Modifier").WindowSetFramePosition(500, 300 )
	}
	
	//Destructor
	~MainDialogClass(object self) {
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

// Main function which allocates both classes
void theMainFunctionToRun() {
	Result("\n---------------------------------------------------------------------------------------------------------\n")
	Result("\nContrast Image Modifier v1.0, Sergi Plana Ruiz, Universitat Rovira i Virgili (Tarragona), July 2022.\n")
	Alloc(MainDialogClass)
}
		
// Call the Main function
theMainFunctionToRun()