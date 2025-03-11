import maya.cmds as cmds
from PySide2 import QtWidgets, QtCore

class PercentageCalculator(QtWidgets.QDialog):
    def __init__(self, parent=None):
        super(PercentageCalculator, self).__init__(parent)
        self.setWindowTitle("Calculate Percent")
        self.setFixedSize(400, 180)
        self.initUI()

    def initUI(self):
        layout = QtWidgets.QVBoxLayout()

        # First row
        hbox1 = QtWidgets.QHBoxLayout()
        self.spn1 = QtWidgets.QSpinBox()
        self.spn1.setRange(0, 10000)
        self.spn2 = QtWidgets.QSpinBox()
        self.spn2.setRange(0, 10000)
        self.lbl1 = QtWidgets.QLabel("= 0.0")
        self.lbl1.setFrameStyle(QtWidgets.QFrame.Sunken | QtWidgets.QFrame.Panel)

        hbox1.addWidget(self.spn1)
        hbox1.addWidget(QtWidgets.QLabel("% of"))
        hbox1.addWidget(self.spn2)
        hbox1.addWidget(self.lbl1)
        layout.addLayout(hbox1)

        # Second row
        hbox2 = QtWidgets.QHBoxLayout()
        self.spn3 = QtWidgets.QSpinBox()
        self.spn3.setRange(0, 10000)
        self.spn4 = QtWidgets.QSpinBox()
        self.spn4.setRange(0, 10000)
        self.lbl2 = QtWidgets.QLabel("= 0.0 %")
        self.lbl2.setFrameStyle(QtWidgets.QFrame.Sunken | QtWidgets.QFrame.Panel)

        hbox2.addWidget(self.spn3)
        hbox2.addWidget(QtWidgets.QLabel("of"))
        hbox2.addWidget(self.spn4)
        hbox2.addWidget(self.lbl2)
        layout.addLayout(hbox2)

        # Third row
        hbox3 = QtWidgets.QHBoxLayout()
        self.spn5 = QtWidgets.QSpinBox()
        self.spn5.setRange(-10000, 10000)
        self.spn6 = QtWidgets.QSpinBox()
        self.spn6.setRange(-10000, 10000)
        self.lbl3 = QtWidgets.QLabel("= 0.0 %")
        self.lbl3.setFrameStyle(QtWidgets.QFrame.Sunken | QtWidgets.QFrame.Panel)

        hbox3.addWidget(QtWidgets.QLabel("Difference of % between"))
        hbox3.addWidget(self.spn5)
        hbox3.addWidget(QtWidgets.QLabel("and"))
        hbox3.addWidget(self.spn6)
        hbox3.addWidget(self.lbl3)
        layout.addLayout(hbox3)

        # Fourth row
        hbox4 = QtWidgets.QHBoxLayout()
        self.spn7 = QtWidgets.QSpinBox()
        self.spn7.setRange(-10000, 10000)  # Allow negative values
        self.spn8 = QtWidgets.QSpinBox()
        self.spn8.setRange(-10000, 10000)  # Allow negative values
        self.lbl4 = QtWidgets.QLabel("= 0.0")
        self.lbl4.setFrameStyle(QtWidgets.QFrame.Sunken | QtWidgets.QFrame.Panel)

        hbox4.addWidget(QtWidgets.QLabel("Add"))
        hbox4.addWidget(self.spn7)
        hbox4.addWidget(QtWidgets.QLabel("% to"))
        hbox4.addWidget(self.spn8)
        hbox4.addWidget(self.lbl4)
        layout.addLayout(hbox4)

        # Help button
        self.btnHelp = QtWidgets.QPushButton("Help")
        layout.addWidget(self.btnHelp)

        self.setLayout(layout)

        # Connect signals
        self.spn1.valueChanged.connect(self.update_lbl1)
        self.spn2.valueChanged.connect(self.update_lbl1)
        self.spn3.valueChanged.connect(self.update_lbl2)
        self.spn4.valueChanged.connect(self.update_lbl2)
        self.spn5.valueChanged.connect(self.update_lbl3)
        self.spn6.valueChanged.connect(self.update_lbl3)
        self.spn7.valueChanged.connect(self.update_lbl4)
        self.spn8.valueChanged.connect(self.update_lbl4)
        self.btnHelp.clicked.connect(self.show_help)

    def update_lbl1(self):
        value = self.spn2.value() * (self.spn1.value() / 100)
        self.lbl1.setText(f"= {value:.1f}")

    def update_lbl2(self):
        if self.spn4.value() > 0:
            value = (self.spn3.value() / self.spn4.value()) * 100
            self.lbl2.setText(f"= {value:.1f} %")
        else:
            self.lbl2.setText("= 0.0 %")

    def update_lbl3(self):
        if self.spn5.value() != 0:
            value = ((self.spn6.value() - self.spn5.value()) / self.spn5.value()) * 100
            self.lbl3.setText(f"= {value:.1f} %")
        else:
            self.lbl3.setText("= 0.0 %")

    def update_lbl4(self):
        value = self.spn8.value() + (self.spn8.value() * (self.spn7.value() / 100))
        self.lbl4.setText(f"= {value:.1f}")

    def show_help(self):
        help_text = (
            "First formula: V2 * (V1 / 100)\n\n"
            "Second formula: (V1 / V2) * 100\n\n"
            "Third formula: ((V2 - V1) / V1) x 100\n\n"
            "Fourth formula: V2 + (V2 * (V1 / 100))"
        )
        QtWidgets.QMessageBox.information(self, "Help", help_text)

# Show the dialog
dialog = PercentageCalculator()
dialog.show()
