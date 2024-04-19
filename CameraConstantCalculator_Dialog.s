TagGroup realfieldR, realfieldL, realfieldLambda, realfieldPixelCali
number R, L, Lambda, invD

//Dialog class
Class MainDialogClass:UIFrame {
				
	//Creates the Dialog	
	TagGroup MainFrame(object self) {
		TagGroup Dialog=DLGCreateDialog("Main Dialog")
		TagGroup box_items
		TagGroup box=dlgcreatebox("", box_items).dlginternalpadding(14,10)
		Dialog.dlgaddelement(box)		

		TagGroup labelR = DLGCreateLabel("R / Physical Pixel Size (µm):")
		realfieldR = DLGCreateRealField(15, 10, 2).DLGidentifier("physicalPixelSize")
		Taggroup buttonCalcR = DLGCreatePushButton("Calculate","calculateR")
		TagGroup groupFromR = DLGgroupitems(labelR,realfieldR,buttonCalcR).dlgtablelayout(3,1,0).DLGAnchor("East")
		
		TagGroup labelL = DLGCreateLabel("L / Camera Length (mm):")
		realfieldL = DLGCreateRealField(200, 10, 6).DLGidentifier("cameraLength")
		Taggroup buttonCalcL = DLGCreatePushButton("Calculate","calculateL")
		TagGroup groupFromL = DLGgroupitems(labelL,realfieldL,buttonCalcL).dlgtablelayout(3,1,0).DLGAnchor("East")
		
		TagGroup labelLambda = DLGCreateLabel("Lambda / Wavelength (Å):")
		realfieldLambda = DLGCreateRealField(0.0251, 10, 5).DLGidentifier("lambda")
		TagGroup buttonCalcLambda = DLGCreatePushButton("Calculate","calculateLambda")
		TagGroup groupFromLambda = DLGgroupitems(labelLambda,realfieldLambda,buttonCalcLambda).dlgtablelayout(3,1,0).DLGAnchor("East")
		
		TagGroup labelPixelCali = DLGCreateLabel("d-1 / Pixel Calibration (Å-1):")
		realfieldPixelCali = DLGCreateRealField(0.002988, 10, 4).DLGidentifier("pixelCali")
		TagGroup buttonCalcPixelCali = DLGCreatePushButton("Calculate","calculatePixelCali")
		TagGroup groupFromPixelCali = DLGgroupitems(labelPixelCali,realfieldPixelCali,buttonCalcPixelCali).dlgtablelayout(3,1,0).DLGAnchor("East")
		
		TagGroup finalGroup = DLGgroupitems(groupFromR,groupFromL,groupFromLambda,groupFromPixelCali).dlgtablelayout(1,4,0).DLGAnchor("East")
		box_items.dlgaddelement(finalGroup)
		
		TagGroup buttonWavelengthInfo = DLGCreatePushButton("HT vs Lambda Info","waveInfo")
		box_items.dlgaddelement(buttonWavelengthInfo)
		
		return Dialog
	}
	
	void calculateR(object self){
	
		L = DLGgetValue(self.LookUpElement("cameraLength"))
		Lambda = DLGgetValue(self.LookUpElement("lambda"))
		invD = DLGgetValue(self.LookUpElement("pixelCali"))
		R = (Lambda*invD)*L*1000
		DLGValue(realfieldR,R)
	
	}
	
	void calculateL(object self){
	
		R = DLGgetValue(self.LookUpElement("physicalPixelSize"))
		Lambda = DLGgetValue(self.LookUpElement("lambda"))
		invD = DLGgetValue(self.LookUpElement("pixelCali"))
		L = (R/(Lambda*invD))/1000
		DLGValue(realfieldL,L)
	
	}
	
	void calculatePixelCali(object self){
	
		R = DLGgetValue(self.LookUpElement("physicalPixelSize"))
		L = DLGgetValue(self.LookUpElement("cameraLength"))
		Lambda = DLGgetValue(self.LookUpElement("lambda"))
		invD = (R/(L*1000))/Lambda
		DLGValue(realfieldPixelCali,invD)
	
	}
	
	void calculateLambda(object self){
	
		R = DLGgetValue(self.LookUpElement("physicalPixelSize"))
		L = DLGgetValue(self.LookUpElement("cameraLength"))
		invD = DLGgetValue(self.LookUpElement("pixelCali"))
		Lambda = (R/(L*1000))/invD
		DLGValue(realfieldLambda,Lambda)
	
	}
	
	void waveInfo(object self){
	
		Result("\nHT(kV) | Wavelength(Å)\n")
		Result("----------------------\n")
		Result(" 80    |    0.0418\n")
		Result(" 100   |    0.0370\n")
		Result(" 120   |    0.0335\n")
		Result(" 200   |    0.0251\n")
		Result(" 300   |    0.0197\n")
	
	}
	
	//Constructor
	MainDialogClass(object self) {
		self.init(self.MainFrame())
		self.display("Camera Constant Calculator").WindowSetFramePosition(500, 300 )
	}
	
	//Destructor
	~MainDialogClass(object self) {
		Result("\n---------------------------------------------------------------------------------------------------------\n")
	}
}

// Main function which allocates both classes
void main() {
	Result("\n---------------------------------------------------------------------------------------------------------\n\n")
	Result("Camera Constant Calculator v1.0, Sergi Plana Ruiz, Universitat Rovira i Virgili (Tarragona), June 2022.\n")
	Alloc(MainDialogClass)
}
		
// Call the Main function
main()