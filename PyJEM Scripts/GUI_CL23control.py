"""
Created on 16/11/2023 by Sergi Plana Ruiz, URV.
"""
import sys
from PyQt4 import QtCore, uic
from PyQt4 import QtGui
from PyJEM import TEM3

lens =TEM3.Lens3()
qtCreatorFile =  "GUI_CL23control_ui.ui"
Ui_MainWindow, QtBaseClass = uic.loadUiType(qtCreatorFile)

class MyApp(QtGui.QMainWindow, Ui_MainWindow):
    def __init__(self):
        global valueCL2_1, valueCL2_2, valueCL3_1, valueCL3_2, clickFLC
        valueCL2_1 = 0
        valueCL2_2 = 0
        valueCL3_1 = 0
        valueCL3_2 = 0
        clickFLC = 0
        QtGui.QMainWindow.__init__(self,None, QtCore.Qt.WindowStaysOnTopHint)
        Ui_MainWindow.__init__(self)
        self.setupUi(self)
        self.CL2Knob.sliderMoved.connect(self.changeCL2)
        self.CL2Knob.valueChanged.connect(self.changeCL2)
        self.CL3Knob.sliderMoved.connect(self.changeCL3)
        self.CL3Knob.valueChanged.connect(self.changeCL3)
        self.CL2Knob.setSliderPosition(int(lens.GetCL2()))
        self.CL3Knob.setSliderPosition(int(lens.GetCL3()))
        self.get1.clicked.connect(self.st1Get)
        self.set1.clicked.connect(self.st1Set)
        self.get2.clicked.connect(self.st2Get)
        self.set2.clicked.connect(self.st2Set)
        self.FLCswitchOff.clicked.connect(self.freeLensOff)
        self.pushButton_CoarseFine.clicked.connect(self.Step)
        self.Ntrl_button.clicked.connect(self.NTRL)

    def changeCL2(self):
        global valueCL2_1, valueCL2_2            
        lens.SetFLCAbs(1, self.CL2Knob.sliderPosition())
        if valueCL2_1 != 0:
            self.set1.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
        if valueCL2_2 != 0:
            self.set2.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
            
    def changeCL3(self):
        global valueCL3_1, valueCL3_2
        lens.SetFLCAbs(2, self.CL3Knob.sliderPosition())
        if valueCL3_1 != 0:
            self.set1.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
        if valueCL3_2 != 0:
            self.set2.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
    
    def NTRL(self):
        lens.SetFLCSw(1, 0)
        self.CL2Knob.setSliderPosition(int(lens.GetCL2()))
        lens.SetFLCSw(1, 0)

    def st1Get(self):
        global valueCL2_1, valueCL3_1
        valueCL2_1=self.CL2Knob.sliderPosition()
        valueCL3_1=self.CL3Knob.sliderPosition()
        self.text1.setText(str(valueCL3_1))
        self.set1.setEnabled(True)
        self.set1.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
    
    def st1Set(self):
        global valueCL2_1, valueCL3_1
        lens.SetFLCAbs(1, valueCL2_1)
        lens.SetFLCAbs(2, valueCL3_1)
        self.CL2Knob.setSliderPosition(valueCL2_1)
        self.CL3Knob.setSliderPosition(valueCL3_1)
        self.set1.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(0, 150, 0);')
        if valueCL2_2 is 0:
            self.set2.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(150, 150, 150);')
        else:
            self.set2.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
        
    def st2Get(self):
        global valueCL2_2, valueCL3_2
        valueCL2_2=self.CL2Knob.sliderPosition()
        valueCL3_2=self.CL3Knob.sliderPosition()
        self.text2.setText(str(valueCL3_2))
        self.set2.setEnabled(True)
        self.set2.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')
    
    def st2Set(self):
        global valueCL2_2, valueCL3_2
        lens.SetFLCAbs(1, valueCL2_2)
        lens.SetFLCAbs(2, valueCL3_2)
        self.CL2Knob.setSliderPosition(valueCL2_2)
        self.CL3Knob.setSliderPosition(valueCL3_2)
        self.set2.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(0, 150, 0);')
        if valueCL2_1 is 0:
            self.set1.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(150, 150, 150);')
        else:
            self.set1.setStyleSheet('color: rgb(0, 0, 0);background-color: rgb(255, 255, 255);')

    def Step(self):
        if (self.pushButton_CoarseFine.isChecked()==True):
            self.CL2Knob.setSingleStep(10)
            self.CL2Knob.setPageStep(30)
            self.CL3Knob.setSingleStep(10)
            self.CL3Knob.setPageStep(30)
        if (self.pushButton_CoarseFine.isChecked()==False):
            self.CL2Knob.setSingleStep(2)
            self.CL2Knob.setPageStep(7)
            self.CL3Knob.setSingleStep(2)
            self.CL3Knob.setPageStep(7)
            
    def freeLensOff(self):
        global clickFLC
        clickFLC = clickFLC + 1
        if (clickFLC == 2):
            lens.SetFLCSwAllLens(0)
            self.CL2Knob.setSliderPosition(int(lens.GetCL2()))
            self.CL3Knob.setSliderPosition(int(lens.GetCL3()))
            lens.SetFLCSwAllLens(0)
            clickFLC=0

if __name__ == "__main__":
    app = QtGui.QApplication(sys.argv)
    app.setWindowIcon(QtGui.QIcon('icona.png'))
    window = MyApp()
    window.show()
    sys.exit(app.exec_())
