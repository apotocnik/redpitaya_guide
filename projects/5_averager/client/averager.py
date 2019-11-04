# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'averager.ui'
#
# Created: Sat Nov 05 21:38:28 2016
#      by: PyQt4 UI code generator 4.9.6
#
# WARNING! All changes made in this file will be lost!

import sys
import struct
import numpy as np
## PyQt4 implementation
# from PyQt4 import uic # QtCore, QtGui,   
# from PyQt4.QtGui import QApplication, QMessageBox #, QMainWindow
# from PyQt4.QtNetwork import QAbstractSocket, QTcpSocket
## PyQt5 implementation
from PyQt5 import uic
from PyQt5.QtWidgets import QApplication, QMessageBox  
from PyQt5.QtNetwork import QAbstractSocket, QTcpSocket

import matplotlib
matplotlib.use('Qt4Agg')
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt4agg import NavigationToolbar2QT as NavigationToolbar
from matplotlib.figure import Figure

Ui_Averager, QMainWindow = uic.loadUiType('averager.ui')


class Averager(QMainWindow, Ui_Averager):
    def __init__(self):
        super(Averager, self).__init__()
        self.setupUi(self)
        
        # Set data acquisition variables
        self.idle = True # state variable
        self.size = 8193 # number of samples to show on the plot # max size
        self.buffer = bytearray(4 * self.size)  # buffer and offset for the incoming samples
        self.offset = 0
        self.data = np.frombuffer(self.buffer, np.int32)
        
        self.isScaled = True
        self.isLogScale = False
        self.isFFT = False
        self.haveData = False
        self.showComp = 0 # Real, Imag, Abs, Phase from combo box
        
        # Create figure
        figure = Figure()
        figure.set_facecolor('none')
        self.axes = figure.add_subplot(111)
        self.canvas = FigureCanvas(figure)
        self.plotLayout.addWidget(self.canvas)
        
        # Create navigation toolbar
        self.toolbar = NavigationToolbar(self.canvas, self.plotWidget, False)
        
        # Remove subplots action
        actions = self.toolbar.actions()
        self.toolbar.removeAction(actions[7])
        self.plotLayout.addWidget(self.toolbar)
        
        # Create TCP socket
        self.socket = QTcpSocket(self)
        self.socket.connected.connect(self.connected)
        self.socket.readyRead.connect(self.read_data)
        self.socket.error.connect(self.display_error)

        # Populate Combo boxes         
        self.cbShowComp.clear()
        self.cbShowComp.addItems(["Real", "Imaginary", "Absolute", "Phase"])
        self.cbShowComp.setCurrentIndex(0);
            
        self.cbNOS.clear() # Number of Samples
        for i in range(11): # maximal value set by the FPGA program
            self.cbNOS.addItems([str(1<<i)])
        self.cbNOS.setCurrentIndex(10);
        
        self.cbNOA.clear() # Number of Averages
        for i in range(22): # maximal value could be larger
            self.cbNOA.addItems([str(1<<i)])
        self.cbNOA.setCurrentIndex(0);
        
        self.cbTrigger.clear() # Trigger rate
        for i in range(26):  # maximal value set by the FPGA program
            self.cbTrigger.addItems(["f0/" + str(int(1<<(26+1-i)))])
        self.cbTrigger.setCurrentIndex(16);
        # +1 comes from the fact that counter's lowest bit has f0/2 frequency
        
        # Connect UI elements and functions
        self.btnStart.clicked.connect(self.start)
        self.chkFFT.stateChanged.connect(self.update_values)
        self.chkScale.stateChanged.connect(self.update_values)
        self.chkLogScale.stateChanged.connect(self.update_values)
        self.cbShowComp.currentIndexChanged.connect(self.update_values)
        
        
        
    def update_values(self):
        self.isScaled = self.chkScale.isChecked()
        self.isLogScale = self.chkLogScale.isChecked()
        self.isFFT = self.chkFFT.isChecked()
        self.showComp = self.cbShowComp.currentIndex()
        self.plot()
        
    
    def start(self):
        if self.idle:
            print( "connecting ...")
            self.btnStart.setEnabled(False)
            self.socket.connectToHost(self.txtIPA.text(), int(self.txtPort.text()))
        else:
          self.idle = True
          self.socket.close()
          self.offset = 0
          self.btnStart.setText('Start')
          self.btnStart.setEnabled(True)
          print( "Disconnected")
    
    
    def set_config(self):
        # Number of Samples
        self.size = int(1<<self.cbNOS.currentIndex())
        self.naverages = (1<<int(self.cbNOA.currentIndex()))
        print( "number of samples = " + str(self.size))
        print( "number of averages = " + str(self.naverages))
        print( "trigger = " + str(self.cbTrigger.currentIndex()))

        if self.idle: return
        self.socket.write(struct.pack('<I', 1<<28 | self.cbTrigger.currentIndex()))
        self.socket.write(struct.pack('<I', 2<<28 | self.cbNOS.currentIndex()))
        self.socket.write(struct.pack('<I', 3<<28 | self.cbNOA.currentIndex()))
        #print( "Configuration sent")
        
    
    def connected(self):
        print( "Connected")
        self.idle = False
        self.btnStart.setText('Stop')
        self.btnStart.setEnabled(True)
        self.set_config()    
        self.start_measurement()
        

    def read_data(self):
        size = self.socket.bytesAvailable()
        print( "got  " + str(size) )
        if self.offset + size < 4*self.size:
          self.buffer[self.offset:self.offset + size] = self.socket.read(size)
          self.offset += size
        else:
          #print( "have all the data")
          self.buffer[self.offset:4*self.size] = self.socket.read(4*self.size - self.offset)
          self.offset = 0
          self.haveData = True
          self.plot()
          self.idle = True
          self.socket.close()
          self.offset = 0
          self.btnStart.setText('Start')
          self.btnStart.setEnabled(True)
          print( "Disconnected")
          
          
          
    def plot(self):
        if self.haveData == False: return
            
        # reset toolbar
        self.toolbar.home()
        ## PyQt4 implementation
 #       self.toolbar._views.clear()  
 #       self.toolbar._positions.clear()
        ## PyQt5 implementation
        self.toolbar.update()
        
        # reset plot
        self.axes.clear()
        self.axes.grid()
        # set data
        self.time_step = 1./125 # us
        y_data = np.array(self.data[0:self.size], dtype=float)
        N = self.size; # number of complex samples
        
        # scale
        y_data = y_data/self.naverages
            
        x_data = np.arange(1,N+1)
        xlab = "Index"
        ylab = "14-bit ADC output"
        
        if self.isScaled == True:
            self.gnd = 0*-146.6
            self.vcc = 1133.7;
            y_data = 4.96*(y_data - self.gnd)/(self.vcc-self.gnd)         
            x_data = self.time_step*x_data
            xlab = 'Time (us)'
            ylab = 'Voltage'
        
        if self.isFFT == True:
            y_data[-1] = (y_data[0]+y_data[-2])/2
            y_data = np.fft.fft(y_data)/N
            x_data = np.fft.fftfreq(y_data.size, self.time_step)
            x_data = np.fft.fftshift(x_data)
            y_data = np.fft.fftshift(y_data)
            xlab = 'Frequency (MHz)'
            ylab = 'Amplitude'
            
        if self.showComp == 0:
            y_data = y_data.real
            ylab = "Real " + ylab
        elif self.showComp == 1:
            y_data = y_data.imag
            ylab = "Imag " + ylab
        elif self.showComp == 2:
            y_data = np.abs(y_data)
            ylab = "Abs " + ylab
        else:
            y_data = np.angle(y_data)
            ylab = "Phase " + ylab
            
        if self.isLogScale == True:
            y_data = 20*np.log10(y_data)
            ylab = ylab + ' (dBV)'
        else:
            ylab = ylab + ' (V)'
            
        #print( str(y_data[N/2-1]) + " " + str(y_data[N/2]) + " " + str(y_data[N/2+1]))
        self.curve = self.axes.plot(x_data, y_data)
        #x1, x2, y1, y2 = self.axes.axis()
        # set y axis limits
        #self.axes.axis((1, self.size, -1500,500))
        self.axes.set_xlim([min(x_data), max(x_data)])
        self.axes.set_xlabel(xlab)
        self.axes.set_ylabel(ylab)
        self.canvas.draw()


    def display_error(self, socketError):
        if socketError == QAbstractSocket.RemoteHostClosedError:
            pass
        else:
            QMessageBox.information(self, 'Averager', 'Error: %s.' % self.socket.errorString())
        self.btnStart.setText('Start')
        self.btnStart.setEnabled(True)
    
    
    def start_measurement(self):
        if self.idle: return
        self.socket.write(struct.pack('<I', 0<<28))
        #print( "Measurement Started")

    
    
app = QApplication(sys.argv)
window = Averager()
window.show()
sys.exit(app.exec_())


        

