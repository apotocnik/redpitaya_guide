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
        #connections
        self.btnStart.clicked.connect(self.start)
    
    
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
        self.size = (1<<int(self.txtNOS.text())) + 1 # +1 for checksum
        #self.buffer = np.zeros(self.size)
        #print "number of samples = " + str(self.size)

        if self.idle: return
        self.socket.write(struct.pack('<I', 0<<28 | int(self.txtTD.text())))
        self.socket.write(struct.pack('<I', 1<<28 | int(self.txtNOS.text())))
        self.socket.write(struct.pack('<I', 2<<28 | int(self.txtNOA.text())))
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
          
          #for i in range(300):        
          #    print str(ord(self.socket.read(1))) + ", "
          self.offset = 0
          # plot the signal envelope
          #print str(self.data)
          #print str(len(self.data))
                  # time axis
          self.time = range(1,self.size+1)
          # reset toolbar
          self.toolbar.home()
          self.toolbar._views.clear()
          self.toolbar._positions.clear()
          # reset plot
          self.axes.clear()
          self.axes.grid()
          # plot zeros and get store the returned Line2D object
          self.curve = self.axes.plot(self.time[0:self.size-1], self.data[0:self.size-1])
          #print "checksum = " + str(self.data[self.size-1]) 
          
          checksum = 0
          for i in range(self.size-1):
              checksum = checksum ^ self.data[i]
          
          #print "Checksums: " + str(checksum) + " " + str(self.data[self.size-1]) 
          
          if checksum != self.data[self.size-1]:
              print "Checksum verification failed!!!"

          #x1, x2, y1, y2 = self.axes.axis()
          # set y axis limits
          self.axes.axis((1, self.size-1, -1000, 1000))
          #self.axes.set_xlim([1,self.size-1])
          self.axes.set_xlabel('count')
          self.canvas.draw()
          
          #print str(self.data[0:self.size])

          self.idle = True
          self.socket.close()
          self.offset = 0
          self.btnStart.setText('Start')
          self.btnStart.setEnabled(True)
          print "Disconnected"
          

    def display_error(self, socketError):
        if socketError == QAbstractSocket.RemoteHostClosedError:
            pass
        else:
            QMessageBox.information(self, 'Averager', 'Error: %s.' % self.socket.errorString())
        self.btnStart.setText('Start')
        self.btnStart.setEnabled(True)
    
    
    def fire(self):
        if self.idle: return
        self.socket.write(struct.pack('<I', 3<<28))
        #print "Fired"

    
app = QApplication(sys.argv)
window = Averager()
window.show()
sys.exit(app.exec_())



        

