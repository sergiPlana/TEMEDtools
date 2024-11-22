TagGroup realfieldThresh
number sizeDPx, sizeDPy, sizeMAPx, sizeMAPy, thresholdValue
image DI
string storingDirectory

//Dialog class
Class MainDialogClass:UIFrame {
				
	//Creates the Dialog	
	TagGroup MainFrame(object self) {
		TagGroup Dialog=DLGCreateDialog("Main Dialog")
		TagGroup box_items
		TagGroup box=dlgcreatebox("", box_items).dlginternalpadding(14,10)
		Dialog.dlgaddelement(box)
		
		TagGroup Get4DSTEMdataBut=DLGCreatePushButton("Get 4DSTEM data","get4DData").DLGenabled(1)
		Get4DSTEMdataBut.dlgidentifier("get4DData_iden").dlginternalpadding(2,0)
		box_items.dlgaddelement(Get4DSTEMdataBut)
		
		TagGroup labellinCorr = DLGCreateLabel("Intensity threshold:").DLGAnchor("East")
		realfieldThresh = DLGCreateRealField(2.0, 10,5).DLGidentifier("thresholdValue_iden").DLGAnchor("East")
		DLGvalue(realfieldThresh,100000)
		thresholdValue = 100000
		TagGroup fitBox = DLGgroupitems(labellinCorr,realfieldThresh).DLGtableLayout(2,1,0)
		box_items.dlgaddelement(fitBox)
		
		TagGroup storeBut = DLGCreatePushButton("Store individual patterns","storFunc").DLGenabled(0)
		storeBut.dlgidentifier("storFunc_iden").dlginternalpadding(2,0)
		box_items.dlgaddelement(storeBut)
		
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
		DLGValue(realfieldThresh,max(DI))
		result("\n4D-STEM data of "+DI.GetName()+"\nMap of x = "+sizeMAPx+" y = "+sizeMAPy+"\n")
		result("DPs of: x = "+sizeDPx+" y = "+sizeDPy+"\n")
		storingDirectory = ImageDocumentGetCurrentFile(getImageDocument(0))
		storingDirectory = left(storingDirectory,len(storingDirectory)-4)+"_IndividualDPs"
		SetApplicationDirectory( "current", 1, storingDirectory )
		Result("Storing directory: "+storingDirectory+"\n")
		self.SetElementisEnabled("storFunc_iden",1)
	}
	
	//Scale and store individual patterns
	void storFunc(object self) {
		
		thresholdValue = DLGgetValue(self.LookUpElement("thresholdValue_iden"))
		number DPindex = 0
		image currentPattern, modifiedEDpattern
		string thispath
		
		for ( number posY = 0; posY < sizeMAPy; posY++ ) {

			for ( number posX = 0; posX < sizeMAPx; posX++ ) {
				currentPattern = DI.sliceN(4, 2, 0, 0, posX, posY, 0, sizeDPx, 1, 1, sizeDPy, 1 )
				modifiedEDpattern = (currentPattern/thresholdValue)*255 
				ImageChangeDataType(modifiedEDpattern, 6) // 10 is uint16, 6 is uint8
				thispath=pathconcatenate(storingDirectory, "DP_"+format(DPindex,"%04d")+"_x"+posX+"_y"+posY)
				saveastiff(modifiedEDpattern, thispath,1)
				self.DLGSetProgress( "task progress" , (DPindex+1)/(sizeMAPx*sizeMAPy) )
				self.ValidateView()
				//Result("DP_" + format(DPindex,"%04d") + " Pos y: "+posY +" Pos x: "+posX+"\n")
				DPindex += 1
			}

		}

	}
	
	//GUI Constructor
	MainDialogClass(object self) {
		self.init(self.MainFrame())
		self.display("4D-STEM: dm4 to Tiff (Uint8)").WindowSetFramePosition(500, 300 )
	}
	
	//GUI Destructor
	~MainDialogClass(object self) {
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

// Main function which allocates both classes
void theMainFunctionToRun() {
	Result("\n---------------------------------------------------------------------------------------------------------\n")
	Result("\n4D-STEM: From dm4 to Tiff (Uint8) v1.0, Sergi Plana Ruiz, Universitat Rovira i Virgili (Tarragona), November 2024.\n")
	Alloc(MainDialogClass)
}
		
// Call the Main function
theMainFunctionToRun()