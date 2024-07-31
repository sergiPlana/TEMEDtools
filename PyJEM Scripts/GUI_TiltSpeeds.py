# -*- coding: utf-8 -*-
"""
Created on Fri Feb 17 15:30:43 2023

@author: JEM Administrator
"""

import sys
from PyQt4 import QtCore, uic
from PyQt4 import QtGui
from PyJEM import TEM3
mystage=TEM3.Stage3()
mystage.Setf1OverRateTxNum(0) # set initially by default to 10 deg/s

qtCreatorFile =  "GUI_TiltSpeeds_ui.ui" # Enter file here.
Ui_MainWindow, QtBaseClass = uic.loadUiType(qtCreatorFile)

class MyApp(QtGui.QMainWindow, Ui_MainWindow):
    def __init__(self):
        QtGui.QMainWindow.__init__(self,None, QtCore.Qt.WindowStaysOnTopHint)
        Ui_MainWindow.__init__(self)
        self.setupUi(self)
        self.tiltToButton.clicked.connect(self.tiltToFunc)
        self.Set0p5degpers.clicked.connect(self.changeTo0p5)
        self.Set1degperS.clicked.connect(self.changeTo1)
        self.Set2degperS.clicked.connect(self.changeTo2)
        self.Set10degperS.clicked.connect(self.changeTo10)
        self.Set10degperS.setStyleSheet('background-color: rgb(0, 150, 0);')
        
    def tiltToFunc(self):
        mystage.SetTiltXAngle(float(self.tiltValueText.toPlainText()))
        
    def changeTo0p5(self):
        mystage.Setf1OverRateTxNum(3)
        self.Set0p5degpers.setStyleSheet('background-color: rgb(0, 150, 0);')
        self.Set1degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set2degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set10degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
    
    def changeTo1(self):
        mystage.Setf1OverRateTxNum(2)
        self.Set0p5degpers.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set1degperS.setStyleSheet('background-color: rgb(0, 150, 0);')
        self.Set2degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set10degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        
    def changeTo2(self):
        mystage.Setf1OverRateTxNum(1)
        self.Set0p5degpers.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set1degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set2degperS.setStyleSheet('background-color: rgb(0, 150, 0);')
        self.Set10degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        
    def changeTo10(self):
        mystage.Setf1OverRateTxNum(0)
        self.Set0p5degpers.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set1degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set2degperS.setStyleSheet('background-color: rgb(255, 255, 255);')
        self.Set10degperS.setStyleSheet('background-color: rgb(0, 150, 0);')
    
    
if __name__ == "__main__":
    app = QtGui.QApplication(sys.argv)
    app.setWindowIcon(QtGui.QIcon('icona.png'))
    window = MyApp()
    window.show()
    sys.exit(app.exec_())
    