@CD 	    /d "%~dp0"
@ECHO 	    OFF
TITLE       Mkdocs - Build & Run
SETLOCAL 	enableextensions enabledelayedexpansion
MODE        con:cols=125 lines=120
MODE        125,40
GOTO        comment_end

-----------------------------------------------------------------------------------------------------
    Must be ran in the folder where the mkdocs source files are
    Example run folders:
        - H:\Repos\github\aetherinox\proteus-apt-repo\docs

    Once mkdocs server is up and running, open browser and go to
        - http://127.0.0.1:8000/
-----------------------------------------------------------------------------------------------------

COLOR CODES
    0 	= 	Black 	  	8 	= 	Gray
    1 	= 	Blue 	  	9 	= 	Light Blue
    2 	= 	Green 	  	A 	= 	Light Green
    3 	= 	Aqua 	  	B 	= 	Light Aqua
    4 	= 	Red 	  	C 	= 	Light Red
    5 	= 	Purple 	  	D 	= 	Light Purple
    6 	= 	Yellow 	  	E 	= 	Light Yellow
    7 	= 	White 	  	F 	= 	Bright White

:comment_end

start cmd /k "mkdocs serve --clean"