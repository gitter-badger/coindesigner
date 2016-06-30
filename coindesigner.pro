
TEMPLATE = app
TARGET = 
DEFINES	+= CDS_VERSION='"2.0"'

#Directorios donde buscar codigo fuente
DEPENDPATH += . 
INCLUDEPATH += ./src ./src/ivfix ./src/qhulllib
VPATH += ./src ./src/ivfix ./src/qhulllib

#Directorios donde almacenar codigo intermedio
UI_DIR = tmp
MOC_DIR = tmp
OBJECTS_DIR = tmp
RCC_DIR = tmp

#coindesigner puede importar ficheros DXF si se ha instalado previamente
#la libreria DIME. Disponibles en http://www.coin3d.org/download/
#Para dar soporte a DXF mediante dime, decomentar las siguientes lineas.
#coindesigner can import DXF files if DIME libs are available. You can
#download dime from http://www.coin3d.org/download/ and install them.
#To add support to DXF throught dime, uncomment next 3 lines
#DEFINES += USE_DIME
#unix:LIBS += -ldime
#win32:LIBS += $(COIN3DDIR)\lib\dime.lib

#Soporte para representar imagenes volumetricas con la libreria
#SIMVoleon, disponible en http://dev.sim.no/SIM_Voleon/
#Para dar soporte a SIMVoleon, decomentar las siguientes lineas.
#Coindesigner can show volumetrix data using the SIMVoleon library,
#which you can download from http://dev.sim.no/SIM_Voleon/
#To add support to SIMVoleon, uncoment next 3 lines.
#DEFINES += USE_VOLEON SIMVOLEON_DLL
#unix:LIBS += -lSimVoleon
win32:LIBS += $(COIN3DDIR)\lib\simvoleon2.lib

# Input
SOURCES +=	main.cpp	mainwindow.cpp	mainwindow2.cpp	cds_util.cpp	cds_viewers.cpp \
		cds_parser.cpp	cds_scanner.cpp	cds_globals.cpp	3dsLoader.cpp	settingsDialog.cpp\
		SoStream.cpp	src_editor.cpp	cppexport_options.cpp			mfield_editor.cpp\
		ivfix_options.cpp	qslim_options.cpp tetgen_options.cpp	\
		IfBuilder.cpp    IfFlattener.cpp  IfReplacer.cpp   IfSorter.cpp \
		IfCollector.cpp  IfHasher.cpp     IfReporter.cpp   IfStripper.cpp \
		IfCondenser.cpp  IfHolder.cpp     IfShape.cpp      IfTypes.cpp \
		IfFixer.cpp      IfMerger.cpp     IfShapeList.cpp  IfWeeder.cpp \
		qh_geom.cpp      qh_io.cpp        qh_poly.cpp      qh_stat.cpp  \
		qh_geom2.cpp     qh_mem.cpp       qh_poly2.cpp     qh_user.cpp  \
		qhulllib.cpp     qh_global.cpp    qh_merge.cpp     qhull_interface.cpp \
		qh_qset.cpp      qhull.cpp 


HEADERS	+=	mainwindow.h cds_util.h cds_globals.h \
		3dsLoader.h src_editor.h mfield_editor.h \
		qslim_options.h cds_viewers.h cppexport_options.h \
		ivfix_options.h settingsDialog.h tetgen_options.h

FORMS	=	ui/mainwindow.ui ui/cds_editor.ui ui/src_view.ui ui/mfield_editor.ui \
			ui/cppexport_options.ui ui/ivfix_options.ui ui/qslim_options.ui \
			ui/tetgen_options.ui ui/settingsDialog.ui
			

RESOURCES = images/icons.qrc demos/demos.qrc

TRANSLATIONS = translations/coindesigner_es.ts

#TODO INSTALL = test

unix {
  INCLUDEPATH += $$system(coin-config --includedir)
  LIBS  += -lsimage
  #SoQt4 LIBS
  LIBS  += $$system(soqt-config --ldflags --libs)
  #LIBS += -lQuarter
  INSTALL += coindesigner
}

win32 {
  DEFINES += COIN_DLL SOQT_DLL SIMAGE_DLL
  CONFIG += embed_manifest_exe
  INCLUDEPATH += "$(COIN3DDIR)/include"
  LIBS += $(COIN3DDIR)/lib/simage1.lib $(COIN3DDIR)/lib/coin3.lib $(COIN3DDIR)/lib/soqt1.lib
  INSTALL+=Release/coindesigner.exe
  RC_FILE = images/svg/coindesigner.rc
}
