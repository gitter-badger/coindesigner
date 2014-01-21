%{
/*
    This file is part of coindesigner.

    coindesigner is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    coindesigner is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with coindesigner; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/* Gramatica de Bison que genera escenas de openInventor a partir de
   ficheros en los siguientes formatos:
     -Geomview: soporta ficheros OFF, COFF, NOFF, NCOFF, STOFF
     -SMF, OBJ
     -XYZ : Nubes de puntos (3 coordenadas por l�nea de fichero)
     -SPH : Arboles de esferas 
*/

#define YYERROR_VERBOSE
#define YYSTYPE_IS_DECLARED 1

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "cds_globals.h"

/* Nodos de openInventor que necesitamos */
#include <Inventor/nodes/SoSeparator.h>
#include <Inventor/nodes/SoCoordinate3.h>
#include <Inventor/nodes/SoIndexedPointSet.h>
#include <Inventor/nodes/SoIndexedLineSet.h>
#include <Inventor/nodes/SoIndexedFaceSet.h>
#include <Inventor/nodes/SoFaceSet.h>
#include <Inventor/nodes/SoPointSet.h>
#include <Inventor/nodes/SoNormal.h>
#include <Inventor/nodes/SoMaterial.h>
#include <Inventor/nodes/SoMaterialBinding.h>
#include <Inventor/nodes/SoTexture2.h>
#include <Inventor/nodes/SoTextureCoordinate2.h>
#include <Inventor/nodes/SoBlinker.h>
#include <Inventor/nodes/SoSphere.h>
#include <Inventor/nodes/SoTranslation.h>

/* Variables para almacenar la informaci�n */
SoSeparator *yyGeometry;
SoCoordinate3 *yyCoordinate3;
SoIndexedPointSet *yyIndexedPointSet;
SoIndexedLineSet *yyIndexedLineSet;
SoIndexedFaceSet *yyIndexedFaceSet;
SoFaceSet *yyFaceSet;
SoNormal *yyNormal;
SoMaterial *yyMaterial;
SoTextureCoordinate2 *yyTextureCoordinate2;
SoMaterialBinding *yyMaterialBinding;
bool yyMaterialBindingUsed;
SoBlinker *yyBlinker;

/* numero de puntos y de facetas */
unsigned int yyNumeroFacetas;
unsigned int yyNumeroPuntos;

/* variable que almacena el numero de puntos leidos */
int num_puntos=0;

/*variable que almacena el numero de facetas leidas*/
int num_facetas=0;

/* Depth y brach de los arboles de esferas .sph */
int yy_sph_depth;
int yy_sph_branch;
int yy_sph_num;
int yy_sph_l;
SoSeparator *yy_sph_l_sep;

bool yy_outerloop=false;
unsigned yy_loopsize=false;

/* Variable para almacenar coordenadas de textura de ficheros .obj */
SoMFVec2f *yy_texture_coord = NULL;

/* Las siguientes funciones se implementan al final de este fichero */

void yyerror(const char *s);

/* Funcion que lee del fichero hasta un salto de linea */
void ignora_resto_linea();

/* Funcion que lee un numero del fichero, sea entero o real */
float LeeReal ();

/* Funcion que lee un numero del fichero, obligatoriamente entero. */
int LeeEntero ();

/* Funci�n que trata un bloque OFF/COFF/NOFF/NCOFF/STOFF */
void LeeBloqueOFF (int nPuntos, int nCaras, int tipoBloqueOFF);

/* Variable que indica al scanner si debe mostrar los saltos de linea */
extern int yy_ver_LF;
%}

%token _OFF _COFF _NOFF _NCOFF _STOFF _LIST _APPEARANCE _FILE
%token _LF _MTLLIB _USEMTL _BEGIN _END _BIND _FACE
%token _SOLID _ASCII _FACET _NORMAL _OUTER _LOOP _VERTEX 
%token _ENDLOOP _ENDFACET _ENDSOLID

%token <entero> _ENTERO
%token <real>   _REAL
%token <pchar>  _CADENA
%type <real>   REAL

%start fich_geom

%%

/* Preparamos una regla que carga cualquier tipo de ficheros */
fich_geom:
  {
    /* Preparamos para leer OOGL */
    yyGeometry = new SoSeparator();
    yyNumeroFacetas = 0;
    yyNumeroPuntos = 0;
    yylinenum = 1;
  }
  bloque_oogl
  {
  }

  |
  {
     /* Preparamos para leer XYZ */
     yyGeometry = new SoSeparator();
     yyCoordinate3 = new SoCoordinate3();

     /* A�adimos los puntos al resultado */
     yyGeometry->addChild(yyCoordinate3);
     yyGeometry->addChild(new SoPointSet() );

     yyNumeroFacetas = 0;
     yyNumeroPuntos = 0;
     yylinenum = 1;

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;
  }
  bloque_XYZ
  {
     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;
  }

  |
  {
     /* Preparamos para leer SMF */
     yyGeometry = new SoSeparator();
     yyCoordinate3 = new SoCoordinate3();
     yyIndexedPointSet = new SoIndexedPointSet();
     yyIndexedPointSet->coordIndex.setNum(0);
     yyIndexedLineSet = new SoIndexedLineSet();
     yyIndexedLineSet->coordIndex.setNum(0);
     yyIndexedFaceSet = new SoIndexedFaceSet();
     yyIndexedFaceSet->coordIndex.setNum(0);
     yyTextureCoordinate2 = new SoTextureCoordinate2;
     yyNormal = new SoNormal();

     yyMaterialBinding=new SoMaterialBinding();
     yyMaterialBinding->value=SoMaterialBinding::PER_VERTEX;
     yyMaterialBindingUsed = false;
     yyMaterial=new SoMaterial();
     yyMaterial->diffuseColor.setNum(0);

     yyGeometry->addChild(yyCoordinate3);
     yyGeometry->addChild(yyMaterialBinding);
     yyGeometry->addChild(yyMaterial);
     yyGeometry->addChild(yyNormal);
     yyGeometry->addChild(yyTextureCoordinate2);
     yyGeometry->addChild(yyIndexedPointSet);
     yyGeometry->addChild(yyIndexedLineSet);
     yyGeometry->addChild(yyIndexedFaceSet);

     //En ocasiones los fichero contienen informaci�n de textura
     //Pero los indices son diferentes a openInventor, por lo que
     //necesitamos una tabla auxiliar
     yy_texture_coord = new SoMFVec2f() ;

     yyNumeroFacetas = 0;
     yyNumeroPuntos = 0;
     yylinenum = 1;
  }
  bloque_SMF
  {
     //Clean unused nodes in the scene tree
     if (!yyMaterialBindingUsed)
       yyGeometry->removeChild(yyMaterialBinding);

     if (yy_texture_coord->getNum() < 1)
       yyGeometry->removeChild(yyTextureCoordinate2);

     if (yyNormal->vector.getNum() < 1)
       yyGeometry->removeChild(yyNormal);

     if (yyMaterial->diffuseColor.getNum() < 1)
         yyGeometry->removeChild(yyMaterial);

     if (yyIndexedPointSet->coordIndex.getNum() < 1)
       yyGeometry->removeChild(yyIndexedPointSet);

     if (yyIndexedLineSet->coordIndex.getNum() < 1)
       yyGeometry->removeChild(yyIndexedLineSet);

     if (yyIndexedFaceSet->coordIndex.getNum() < 1)
       yyGeometry->removeChild(yyIndexedFaceSet);

     //Liberamos espacio de informaci�n de textura
     delete yy_texture_coord;
  }

  |
  fichero_SPH

  |
  fichero_STL
;

//Una regla para leer cualquier tipo de numeros
REAL : _REAL   {$$ = $1; }
     | _ENTERO {$$ = $1;}
;

bloque_oogl : bloque_off
  | bloque_coff
  | bloque_noff
  | bloque_ncoff
  | bloque_stoff
  | bloque_appearance bloque_oogl
  | _LIST _bloques_oogl
  | '{' bloque_oogl '}'
;

_bloques_oogl : bloque_oogl _bloques_oogl
  | bloque_oogl
;

bloque_appearance : _APPEARANCE '{'
  {
     /* Ignoramos el contenido por ahora */
     int tipo, num_llaves;
     num_llaves = 1;
     while (num_llaves > 0)
     {
       tipo = yylex();
       if (tipo == '{') num_llaves++;
       else if (tipo == '}') num_llaves--;
       else if (tipo == _FILE)
       {
          tipo = yylex();
          if (tipo == _CADENA)
          {
             //Eliminamos las comillas del final
             yylval.pchar[strlen(yylval.pchar)-1] = 0;

             //Creamos un nodo Texture2
             SoTexture2 *yyTexture2 = new SoTexture2;
             yyGeometry->addChild(yyTexture2);

             //Metemos el nombre del fichero, sin las comillas iniciales
             yyTexture2->filename.setValue(yylval.pchar+1);

          }
       }
     } // while
  }
;


bloque_off : _OFF _ENTERO _ENTERO _ENTERO
  {
     /* leemos este bloque, indicando el tipo adecuado */
     LeeBloqueOFF ($2, $3, _OFF);
  }
;

bloque_coff : _COFF _ENTERO _ENTERO _ENTERO
  {
     /* leemos este bloque, indicando el tipo adecuado */
     LeeBloqueOFF ($2, $3, _COFF);
  }
;

bloque_noff : _NOFF _ENTERO _ENTERO _ENTERO
  {
     /* leemos este bloque, indicando el tipo adecuado */
     LeeBloqueOFF ($2, $3, _NOFF);
  }
;

bloque_ncoff : _NCOFF _ENTERO _ENTERO _ENTERO
  {
     /* leemos este bloque, indicando el tipo adecuado */
     LeeBloqueOFF ($2, $3, _NCOFF);
  }
;

bloque_stoff : _STOFF _ENTERO _ENTERO _ENTERO
  {
     /* leemos este bloque, indicando el tipo adecuado */
     LeeBloqueOFF ($2, $3, _STOFF);
  }
;

bloque_SMF : bloque_SMF linea_SMF
  | linea_SMF
  | _BEGIN bloque_SMF _END
           ;

linea_SMF  : 'v' REAL REAL REAL
  {
     // Almacenamos las coordenadas cartesianas.
     yyCoordinate3->point.set1Value(yyNumeroPuntos++, $2, $3, $4);
  }

  | 'v' REAL REAL REAL REAL
  {
     // Almacenamos las coordenadas racionales.
     yyCoordinate3->point.set1Value(yyNumeroPuntos++, $2/$5, $3/$5, $4/$5);
  }

  | 'p' _ENTERO 
  {
     // generamos un nuevo punto
     int k = yyIndexedPointSet->coordIndex.getNum();
     yyIndexedPointSet->coordIndex.set1Value(k++, $2 -1);

     //Miramos si hay m�s vertices en esta nube de puntos

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;

     //Leemos hasta el fin de linea, insertando los vertices
     int tipo = yylex();
     while (tipo == _ENTERO)
     {
        yyIndexedPointSet->coordIndex.set1Value(k++,yylval.entero-1);
        tipo = yylex();
     }

     if (tipo != _LF)
     {
        yyerror("Format error in integer number.\n");
        return -1;
     }

     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;
  }

  | 'l' _ENTERO _ENTERO 
  {
     // generamos una nueva polilinea de 2 o mas vertices

     int k = yyIndexedLineSet->coordIndex.getNum();
     yyIndexedLineSet->coordIndex.set1Value(k++, $2 -1);
     yyIndexedLineSet->coordIndex.set1Value(k++, $3 -1);

     //Miramos si hay m�s vertices en esta polilinea

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;

     //Leemos hasta el fin de linea, insertando los vertices
     int tipo = yylex();
     while (tipo == _ENTERO)
     {
        yyIndexedLineSet->coordIndex.set1Value(k++,yylval.entero-1);
        tipo = yylex();
     }

     if (tipo != _LF)
     {
        yyerror("Format error in integer number.\n");
        return -1;
     }

     //Insertamos la marca de fin de polilinea
     yyIndexedLineSet->coordIndex.set1Value(k++, -1);

     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;
  }

  | 'f' _ENTERO _ENTERO _ENTERO
  {
     // generamos una nueva faceta de 3 o mas vertices

     int k = yyIndexedFaceSet->coordIndex.getNum();
     yyIndexedFaceSet->coordIndex.set1Value(k++, $2 -1);
     yyIndexedFaceSet->coordIndex.set1Value(k++, $3 -1);
     yyIndexedFaceSet->coordIndex.set1Value(k++, $4 -1);

     //Miramos si hay m�s vertices en esta faceta

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;

     //Leemos hasta el fin de linea, insertando los vertices
     int tipo = yylex();
     while (tipo == _ENTERO)
     {
        yyIndexedFaceSet->coordIndex.set1Value(k++,yylval.entero-1);
        tipo = yylex();
     }

     if (tipo != _LF)
     {
        yyerror("Format error in integer number.\n");
        return -1;
     }

     //Insertamos la marca de fin de faceta
     yyIndexedFaceSet->coordIndex.set1Value(k++, -1);

     //Incrementamos la cuenta de facetas
     yyNumeroFacetas++;

     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;
  }

  | 'f' _ENTERO '/' '/' _ENTERO _ENTERO '/' '/' _ENTERO
  {
     /* generamos una nueva faceta, ignorando resto de informacion */
     int k = yyIndexedFaceSet->coordIndex.getNum();

     //Por ahora hemos leido 2 valores
     yyIndexedFaceSet->coordIndex.set1Value(k++, $2 -1);
     yyIndexedFaceSet->coordIndex.set1Value(k++, $6 -1);

     //Salvamos las coordenadas de normal
     yyIndexedFaceSet->normalIndex.set1Value(k-2, $5 -1);
     yyIndexedFaceSet->normalIndex.set1Value(k-1, $9 -1);

     //Miramos si hay m�s vertices en esta faceta

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;

     //Leemos hasta el fin de linea
     while (yylex() == _ENTERO)
     {
        yyIndexedFaceSet->coordIndex.set1Value(k++, yylval.entero -1);

        //Ignoramos los 2 campos siguientes ( / / )
        yylex();
        yylex();

        //Leemos la coordenada de normal (vn)
        int idn = LeeEntero() - 1;
        yyIndexedFaceSet->normalIndex.set1Value(k-1, idn);

     }

     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;

     //Cerramos la faceta actual
     yyIndexedFaceSet->coordIndex.set1Value(k++, -1);
     yyIndexedFaceSet->normalIndex.set1Value(k-1, -1);
     yyNumeroFacetas++;
  }
  | 'f' _ENTERO '/' _ENTERO _ENTERO '/' _ENTERO
  {
     /* generamos una nueva faceta, ignorando resto de informacion */
     int k = yyIndexedFaceSet->coordIndex.getNum();

     //Por ahora hemos leido 2 valores
     yyIndexedFaceSet->coordIndex.set1Value(k++, $2 -1);
     yyIndexedFaceSet->coordIndex.set1Value(k++, $5 -1);

     //Salvamos las coordenadas de textura
     yyTextureCoordinate2->point.set1Value($2-1, (*yy_texture_coord)[$4-1] );
     yyTextureCoordinate2->point.set1Value($5-1, (*yy_texture_coord)[$7-1] );

     //Miramos si hay m�s vertices en esta faceta

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;

     //Leemos hasta el fin de linea
     while (yylex() == _ENTERO)
     {
        //Salvamos el indice del v�rtice
        int idx = yylval.entero-1;
        yyIndexedFaceSet->coordIndex.set1Value(k++, idx);

        //Ignoramos la barra
        yylex();

        //Leemos la coordenada de textura
        int idt = LeeEntero() - 1;
        yyTextureCoordinate2->point.set1Value(idx, (*yy_texture_coord)[idt]);

     }// while (yylex() == _ENTERO)

     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;

     //Cerramos la faceta actual
     yyIndexedFaceSet->coordIndex.set1Value(k++, -1);
     yyNumeroFacetas++;
  }

  | 'f' _ENTERO '/' _ENTERO '/' _ENTERO _ENTERO '/' _ENTERO '/' _ENTERO
  {
     /* generamos una nueva faceta, ignorando resto de informacion */
     int k = yyIndexedFaceSet->coordIndex.getNum();

     //Por ahora hemos leido 2 valores
     yyIndexedFaceSet->coordIndex.set1Value(k++, $2 -1);
     yyIndexedFaceSet->coordIndex.set1Value(k++, $7 -1);

     //Salvamos las coordenadas de normal
     yyIndexedFaceSet->normalIndex.set1Value(k-2, $6 -1);
     yyIndexedFaceSet->normalIndex.set1Value(k-1, $11-1);

     //Salvamos las coordenadas de textura
     yyTextureCoordinate2->point.set1Value($2-1, (*yy_texture_coord)[$4-1] );
     yyTextureCoordinate2->point.set1Value($7-1, (*yy_texture_coord)[$9-1] );

     //Miramos si hay m�s vertices en esta faceta

     //Indicamos al scanner que queremos ver los saltos de linea
     yy_ver_LF = 1;

     //Leemos hasta el fin de linea
     while (yylex() == _ENTERO)
     {
        //Salvamos el indice del v�rtice
        int idx = yylval.entero-1;
        yyIndexedFaceSet->coordIndex.set1Value(k++, idx);

        //Ignoramos el campo siguiente (/)
        yylex();

        //Leemos la coordenada de textura
        int idt = LeeEntero() - 1;
        yyTextureCoordinate2->point.set1Value(idx, (*yy_texture_coord)[idt]);

        //Ignoramos el campo siguiente (/)
        yylex();

        //Leemos la coordenada de normal (vn)
        int idn = LeeEntero() - 1;
        yyIndexedFaceSet->normalIndex.set1Value(k-1, idn);

     }//while (yylex() == _ENTERO)

     //Indicamos al scanner que no queremos ver los saltos de linea
     yy_ver_LF = 0;

     //Cerramos la faceta actual
     yyIndexedFaceSet->coordIndex.set1Value(k++, -1);
     yyIndexedFaceSet->normalIndex.set1Value(k-1, -1);
     yyNumeroFacetas++;
  }

  | 'c' REAL REAL REAL
  {
      int idx = yyMaterial->diffuseColor.getNum();
      yyMaterial->diffuseColor.set1Value(idx,$2, $3, $4);
  }

  | _BIND 'c' _VERTEX
  {
     yyMaterialBinding->value=SoMaterialBinding::PER_VERTEX;
     yyMaterialBindingUsed = true;
  }

  | _BIND 'c' _FACE
  {
     yyMaterialBinding->value=SoMaterialBinding::PER_FACE;
     yyMaterialBindingUsed = true;
  }

  | 'v' 't' REAL REAL
  {
     /* Almacenamos la informacion de textura */
      int idx = yy_texture_coord->getNum();
      yy_texture_coord->set1Value(idx,$3, $4);
  }

  | 'v' 't' REAL REAL REAL
  {
     /* Almacenamos la informacion de textura */
      int idx = yy_texture_coord->getNum();

      //Impedimos una hipotetica division por cero
      if ($5 != 0.0f)
         yy_texture_coord->set1Value(idx,$3/$5, $4/$5);
      else
         yy_texture_coord->set1Value(idx, 0, 0);
  }

  | 'v' 'n' REAL REAL REAL
  {
     /* Almacenamos la informacion de normal */
      int idx = yyNormal->vector.getNum();
      yyNormal->vector.set1Value(idx,$3, $4, $5);
  }

  | 'v' 'p' REAL REAL
  {
     /* Ignoramos la informacion */
  }

  | 'g'
  {
    ignora_resto_linea();
  }

  | 'o'
  {
    ignora_resto_linea();
  }
  | 's'
  {
    ignora_resto_linea();
  }
  | _MTLLIB
  {
    ignora_resto_linea();
  }
  | _USEMTL
  {
    ignora_resto_linea();
  }
  | '$'
  {
    //En ocasiones hay comentarios marcados con $
    ignora_resto_linea();
  }
;

bloque_XYZ : bloque_XYZ linea_XYZ
  | linea_XYZ
;

linea_XYZ  : REAL REAL REAL _LF
  {
     /* Almacenamos el punto. */
     yyCoordinate3->point.set1Value(yyNumeroPuntos++, $1, $2, $3);
  }
;


fichero_SPH : _ENTERO _ENTERO
  {
    int i;

    //Leemos el depth y branch
    yy_sph_depth = $1;
    yy_sph_branch = $2;

    //Introducimos el arbol de esferas en un blinker 
     yyGeometry = new SoSeparator();
     yyBlinker = new SoBlinker();
     yyBlinker->speed = 0.3f;
     yyGeometry->addChild(yyBlinker);

    //Colgamos un separator por cada nivel
    for (i=0; i < yy_sph_depth; i++)
    {
       char buf[16];
       SoSeparator *sep = new SoSeparator();
       yyBlinker->addChild (sep);
       //Le damos un nombre al nivel
       sprintf(buf, "L%d", i);
       sep->setName(buf);
    }

    //Nivel que vamos a leer
    yy_sph_l      = 0;
    yy_sph_l_sep  = (SoSeparator *)yyBlinker->getChild(0);

    //Numero de esferas en el nivel
    yy_sph_num    = 1;

  }
  bloque_SPH
  {
  }
;

bloque_SPH : bloque_SPH linea_SPH
  | linea_SPH
;

linea_SPH  : REAL REAL REAL REAL REAL 
  {
    int i;
    //fprintf(stderr, "l=%d quedan=%d radio=%g\n",yy_sph_l,yy_sph_num,$4);

    //A�adimos la esfera al nivel actual, con una traslacion a su sitio
    SoSeparator *sep = new SoSeparator ();
    yy_sph_l_sep->addChild (sep);

    SoTranslation *trl = new SoTranslation();
    trl->translation.setValue ($1, $2, $3);
    sep->addChild(trl);

    SoSphere *sph = new SoSphere();
    sph->radius = $4;
    sep->addChild (sph);

    //decrementamos el numero de esferas restantes por leer del nivel
    yy_sph_num--;

    //Comprobamos si se ha llenado este nivel
    if (yy_sph_num == 0)
    {
       //Aumentamos el nivel que vamos a leer
       yy_sph_l++;

       //Comprobamos el numero de niveles leidos y cambiamos al separador 
       //del nivel actual, o bien terminamos la lectura de fichero
       if (yy_sph_l < yyBlinker->getNumChildren())
          yy_sph_l_sep  = (SoSeparator *)yyBlinker->getChild(yy_sph_l);
       else
       {
          //Hemos leido todas las esferas de todos los niveles
          return 0;
       }

       //Calculamos el numero de esferas restantes
       yy_sph_num = 1;
       for (i=0; i<yy_sph_l; i++)
           yy_sph_num *= yy_sph_branch;

    }// if (yy_sph_num == 0)

  }
;


fichero_STL : 
  {
     /* Preparamos para leer STL */
     yyGeometry = new SoSeparator();
     yyCoordinate3 = new SoCoordinate3();
     yyFaceSet = new SoFaceSet();
     //yyNormal = new SoNormal();

     yyGeometry->addChild(yyCoordinate3);
     //yyGeometry->addChild(yyNormal);
     yyGeometry->addChild(yyFaceSet);

     yyNumeroFacetas = 0;
     yyNumeroPuntos = 0;
     yylinenum = 1;
     yy_loopsize=0;
  } _SOLID _ASCII bloque_STL _ENDSOLID

bloque_STL : bloque_STL facet_STL
  | facet_STL
;

facet_STL : _FACET loop_STL _ENDFACET
  | _FACET _NORMAL REAL REAL REAL loop_STL _ENDFACET
;

loop_STL : _OUTER {yy_outerloop=true;} loop_STL
  | _LOOP bloque_loop_STL _ENDLOOP 
    {
       yyFaceSet->numVertices.set1Value(yyNumeroFacetas++, yy_loopsize);
       yy_loopsize=0;
       yy_outerloop=false;
    }
;

bloque_loop_STL : bloque_loop_STL vertex_STL
  | vertex_STL
;

vertex_STL : _VERTEX REAL REAL REAL
{
     yyCoordinate3->point.set1Value(yyNumeroPuntos++, $2, $3, $4);
     yy_loopsize++;
}
;

%%

void yyerror(const char *s)
{
  fprintf(stderr, "\nLinea %u: %s\n", yylinenum, s);
  /* No hay piedad con los errores */
  //exit(-1);
}

void yyerror(char *s)
{
  fprintf(stderr, "\nLinea %u: %s\n", yylinenum, s);
  /* No hay piedad con los errores */
  //exit(-1);
}

/* Funcion que lee del fichero hasta un salto de linea */
void ignora_resto_linea()
{
   //Indicamos al scanner que queremos ver los saltos de linea
   yy_ver_LF = 1;

   //Leemos hasta el fin de linea
   while (yylex() != _LF) {}

   //Indicamos al scanner que no queremos ver los saltos de linea
   yy_ver_LF = 0;
}

/* Funcion que lee un numero del fichero, independientemente de si
   es real o entero */
float LeeReal ()
{
   int tipo;
   tipo = yylex();
   if (tipo == _REAL)
     return yylval.real;
   else if (tipo == _ENTERO)
     return (float)yylval.entero;
   else
   {
     fprintf(stderr, "\nLine %u: Format error in real number.\n", yylinenum);
     exit (-1);
   }
}

/* Funcion que lee un numero del fichero, obligatoriamente entero */
int LeeEntero ()
{
   int tipo;
   tipo = yylex();
   if (tipo == _ENTERO)
     return yylval.entero;
   else
   {
     fprintf(stderr, "\nLine %u: Format error in integer number.\n", yylinenum);
     exit (-1);
   }
}


/* Funci�n que trata un bloque OFF/COFF/NOFF/NCOFF/STOFF ignorando la
   informaci�n de color y normal. El tercer argumento indica
   cuantos valores deben ignorarse despues de leer cada punto 3D */
void LeeBloqueOFF (int nPuntos, int nCaras, int tipoBloqueOFF)
{
   int nVertCara, i,j;
   float x, y, z;
   float r, g, b, a;
   float nx, ny, nz;
   float tx, ty;

   /* Reservamos espacio para las coordenadas de los v�rtices */
   SoCoordinate3 *coordinate3 = new SoCoordinate3();
   yyGeometry->addChild(coordinate3);

   /* Si hay informaci�n de color, creamos un material */
   if (tipoBloqueOFF == _COFF || tipoBloqueOFF == _NCOFF )
   {
     yyMaterialBinding=new SoMaterialBinding();
     yyMaterialBinding->value=SoMaterialBinding::PER_VERTEX_INDEXED;
     yyGeometry->addChild(yyMaterialBinding);

     yyMaterial=new SoMaterial();
     yyGeometry->addChild(yyMaterial);
   }

   /* Si hay informaci�n de normales, creamos un SoNormal */
   if (tipoBloqueOFF == _NOFF || tipoBloqueOFF == _NCOFF )
   {
     yyNormal=new SoNormal();
     yyGeometry->addChild(yyNormal);
   }

   /* Si hay informaci�n de textura, creamos un SoTextureCoordinate2 */
   if (tipoBloqueOFF == _STOFF)
   {
     yyTextureCoordinate2 = new SoTextureCoordinate2;
     yyGeometry->addChild(yyTextureCoordinate2);
   }

   /* Reservamos espacio para las facetas de los v�rtices */
   SoIndexedPointSet *yyIndexedPointSet = new SoIndexedPointSet();
   yyGeometry->addChild(yyIndexedPointSet);
   SoIndexedLineSet *yyIndexedLineSet = new SoIndexedLineSet();
   yyGeometry->addChild(yyIndexedLineSet);
   SoIndexedFaceSet *yyIndexedFaceSet = new SoIndexedFaceSet();
   yyGeometry->addChild(yyIndexedFaceSet);

   /* Lectura de la informacion de los puntos */
   for (i=0; i<nPuntos; i++)
   {
     /* Leemos x,y,z mediante yylex() */
     x = LeeReal();
     y = LeeReal();
     z = LeeReal();

     /* Almacenamos el punto. */
     coordinate3->point.set1Value(i,x,y,z);

     /* Si hay informaci�n de normales, leemos la informaci�n */
     if (tipoBloqueOFF == _NOFF || tipoBloqueOFF == _NCOFF )
     {

       /* Leemos nx,ny,nz mediante yylex() */
       nx = LeeReal();
       ny = LeeReal();
       nz = LeeReal();

       /* Almacenamos la normal. */
       yyNormal->vector.set1Value(i, nx, ny, nz);

     }//if normal

     /* Si hay informaci�n de color, leemos la informaci�n */
     if (tipoBloqueOFF == _COFF || tipoBloqueOFF == _NCOFF )
     {
       r = LeeReal();
       g = LeeReal();
       b = LeeReal();
       a = LeeReal();

       /* Almacenamos el color. */
       yyMaterial->diffuseColor.set1Value(i,r,g,b);

       /* Almacenamos la transparencia */
       yyMaterial->transparency.set1Value(i, 1.0 - a);

     }//if color

     /* Si hay informaci�n de textura, leemos la informaci�n */
     if (tipoBloqueOFF == _STOFF)
     {
       /* Leemos nx,ny,nz mediante yylex() */
       tx = LeeReal();
       ty = LeeReal();

       /* Almacenamos la normal. */
       yyTextureCoordinate2->point.set1Value(i, tx, ty);

     }//if textura

   } /* for */

   /* Aumentamos la cuenta de vertices */
   yyNumeroPuntos += nPuntos;


   /* Lectura de la informacion de las facetas */
   int k,v;
   k=0;
   int np=0;
   int nl=0;

   for (i=0; i<nCaras; i++)
   {
     /* Leemos el numero de vertices de esta faceta */
     nVertCara = LeeEntero();

     /* Ignoramos facetas de menos de 3 v�rtices */
     if (nVertCara <= 0)
     {
       fprintf(stderr, "\nLine %u: Size of face cannot be %d\n", yylinenum, nVertCara);
       /* Continuamos con la siguiente faceta */
       continue;
     }

     if (nVertCara == 1)
     {
       /* Leemos el indices y creamos un punto visible */
       v = LeeEntero();
       yyIndexedPointSet->coordIndex.set1Value(np++, v);
       continue;
     }

     if (nVertCara == 2)
     {
       /* Leemos dos indices y creamos una arista */
       v = LeeEntero();
       yyIndexedLineSet->coordIndex.set1Value(nl++, v);
       v = LeeEntero();
       yyIndexedLineSet->coordIndex.set1Value(nl++, v);
       yyIndexedLineSet->coordIndex.set1Value(nl++, -1);

       /* Continuamos con la siguiente faceta */
       continue;
     }

     for (j=0; j<nVertCara; j++)
     {
       /* Leemos el �ndice del v�rtice */
       v = LeeEntero();

       /* Almacenamos la coordenada. */
       yyIndexedFaceSet->coordIndex.set1Value(k++, v);

     } /* for */

     /* Almacenamos la marca de fin de faceta. */
     yyIndexedFaceSet->coordIndex.set1Value(k++, -1);

     //Si hay informaci�n de color por faceta, la ignoramos
     ignora_resto_linea();

     /* Aumentamos la cuenta de facetas */
     yyNumeroFacetas++;

   } /* for */

   /* Elimina objetos no utilizados */
   if (np <=0)
      yyGeometry->removeChild(yyIndexedPointSet);
   if (nl <=0)
      yyGeometry->removeChild(yyIndexedLineSet);
   if (k <=0)
      yyGeometry->removeChild(yyIndexedFaceSet);


} /* LeeBloqueOFF (nPuntos, nCaras, tipoBloqueOFF) */

