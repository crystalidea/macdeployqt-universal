QT -= gui

CONFIG += c++11 console
CONFIG -= app_bundle

SOURCES += main.cpp shared.cpp
QT = core
LIBS += -framework CoreFoundation

DEFINES -= QT_DEPRECATED_WARNINGS
