image DI := GetFrontImage()
number sizeDPx = DI.ImageGetDimensionSize(0)
number sizeDPy = DI.ImageGetDimensionSize(1)
number sizeMAPx = DI.ImageGetDimensionSize(2)
number sizeMAPy = DI.ImageGetDimensionSize(3)
result("\n4D-STEM map of "+DI.GetName()+" : x = "+sizeMAPx+" y = "+sizeMAPy+"\n")
result("DPs of: x = "+sizeDPx+" y = "+sizeDPy+"\n")

string storingDirectory=pathconcatenate("D:\\4D-STEM", "IndividualDPs") // Change the path according to where you want to save them
SetApplicationDirectory( "current", 1, storingDirectory )

number DPindex = 0
image currentPattern
string thispath
for ( number posY = 0; posY < sizeMAPy; posY++ ) {

	for ( number posX = 0; posX < sizeMAPx; posX++ ) {
		currentPattern = DI.sliceN(4, 2, 0, 0, posX, posY, 0, sizeDPx, 1, 1, sizeDPy, 1 )
		ImageChangeDataType(currentPattern, 7) // Signed Integer of 4 bytes
		thispath=pathconcatenate(storingDirectory, "DP_"+DPindex+"_x"+posX+"_y"+posY)
		saveastiff(currentPattern, thispath,1)
		Result("DP_" + DPindex + " Pos y: "+posY +" Pos x: "+posX+"\n")
		DPindex += 1
	}

}