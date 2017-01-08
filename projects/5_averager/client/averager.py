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
from PyQt4 import uic # QtCore, QtGui, 
from PyQt4.QtGui import QApplication, QMessageBox #, QMainWindow

import matplotlib
matplotlib.use('Qt4Agg')
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt4agg import NavigationToolbar2QT as NavigationToolbar
from matplotlib.figure import Figure
from PyQt4.QtNetwork import QAbstractSocket, QTcpSocket

Ui_Averager, QMainWindow = uic.loadUiType('averager.ui')

class Averager(QMainWindow, Ui_Averager):
    def __init__(self):
        super(Averager, self).__init__()
        self.setupUi(self)
        # state variable
        self.idle = True
        # number of samples to show on the plot
        self.size = 8193 # max size
        # buffer and offset for the incoming samples
        self.buffer = bytearray(4 * self.size)
        self.offset = 0
        self.data = np.frombuffer(self.buffer, np.int32)
        # create figure
        figure = Figure()
        figure.set_facecolor('none')
        self.axes = figure.add_subplot(111)
        self.canvas = FigureCanvas(figure)
        self.plotLayout.addWidget(self.canvas)
        # create navigation toolbar
        self.toolbar = NavigationToolbar(self.canvas, self.plotWidget, False)
        # remove subplots action
        actions = self.toolbar.actions()
        self.toolbar.removeAction(actions[7])
        self.plotLayout.addWidget(self.toolbar)
        # create TCP socket
        self.socket = QTcpSocket(self)
        self.socket.connected.connect(self.connected)
        self.socket.readyRead.connect(self.read_data)
        self.socket.error.connect(self.display_error)        
        self.cbShowComp.clear()
        self.cbShowComp.addItems(["Real", "Imaginary", "Absolute", "Phase"])
        self.cbShowComp.setCurrentIndex(2);
        
        #connections
        self.btnStart.clicked.connect(self.start)
        self.txtNOA.valueChanged.connect(self.update_values)
        self.txtNOS.valueChanged.connect(self.update_values)
        self.chkFFT.stateChanged.connect(self.update_values)
        self.chkScale.stateChanged.connect(self.update_values)
        self.chkLogScale.stateChanged.connect(self.update_values)
        self.cbShowComp.currentIndexChanged.connect(self.update_values)
        self.isScaled = True
        self.isLogScale = False
        self.isFFT = False
        self.haveData = False
        self.showComp = 0 # Real, Imag, Abs, Phase from combo box
        
        
    def update_values(self):
        self.labNOA.setText(str((1<<int(self.txtNOA.text()))))
        self.labNOS.setText(str((1<<int(self.txtNOS.text()))))
        self.isScaled = self.chkScale.isChecked()
        self.isLogScale = self.chkLogScale.isChecked()
        self.isFFT = self.chkFFT.isChecked()
        self.showComp = self.cbShowComp.currentIndex()
        self.plot()
        
    
    def start(self):
        if self.idle:
            print "connecting ..."
            self.btnStart.setEnabled(False)
            self.socket.connectToHost(self.txtIPA.text(), 1001)
        else:
          self.idle = True
          self.socket.close()
          self.offset = 0
          self.btnStart.setText('Start')
          self.btnStart.setEnabled(True)
          print "Disconnected"
    
    def setConfig(self):
        # Number of Samples
        self.size = (1<<int(self.txtNOS.text()))
        self.naverages = (1<<int(self.txtNOA.text()))
        #print "number of samples = " + str(self.size)

        if self.idle: return
        self.socket.write(struct.pack('<I', 1<<28 | int(self.txtTD.text())))
        self.socket.write(struct.pack('<I', 2<<28 | int(self.txtNOS.text())))
        self.socket.write(struct.pack('<I', 3<<28 | int(self.txtNOA.text())))
        #print "Configuration sent"
    
    def connected(self):
        print "Connected"
        self.idle = False
        self.btnStart.setText('Stop')
        self.btnStart.setEnabled(True)
        self.setConfig()    
        self.fire()
        

    def read_data(self):
        size = self.socket.bytesAvailable()
        print "got  " + str(size) 
        if self.offset + size < 4*self.size:
          self.buffer[self.offset:self.offset + size] = self.socket.read(size)
          self.offset += size
        else:
          #print "have all data"
          self.buffer[self.offset:4*self.size] = self.socket.read(4*self.size - self.offset)
          self.offset = 0
          self.haveData = True
          self.plot()

          self.idle = True
          self.socket.close()
          self.offset = 0
          self.btnStart.setText('Start')
          self.btnStart.setEnabled(True)
          print "Disconnected"
          
          
    def plot(self):
        
        if self.haveData == False: return
            
        # reset toolbar
        self.toolbar.home()
        self.toolbar._views.clear()
        self.toolbar._positions.clear()
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
            
        #print str(y_data[N/2-1]) + " " + str(y_data[N/2]) + " " + str(y_data[N/2+1])
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
    
    
    def fire(self):
        if self.idle: return
        self.socket.write(struct.pack('<I', 0<<28))
        #print "Fired"

    
app = QApplication(sys.argv)
window = Averager()
window.show()
sys.exit(app.exec_())



        

