
@ECHO OFF

FOR /f %%i IN ('dir /b *.proto') DO ( 
    IF EXIST %%i (
        ECHO %%i 
	protoc %%i -o ../../protocol/%%~ni.pb
    )
)

PAUSE