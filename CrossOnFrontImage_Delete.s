imagedisplay imgdisp=GetFrontImage().imageGetImageDisplay(0)
number numOfAnnotations=ComponentCountChildren(imgdisp)

for(number i = 1; i < numOfAnnotations; i++) {
	number IDanno = GetNthAnnotationID(GetFrontImage() , 0)
	DeleteAnnotation(GetFrontImage() ,IDanno)
}
