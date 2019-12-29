@echo off
set MAGICK="%ProgramFiles%\ImageMagick-7.0.8-Q16\magick.exe"
set MAGICK_OPTS=-resize 100x100 -posterize 35 -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB -strip
if not exist %MAGICK% (
	echo:
	echo ERROR: Cannot find ImageMagick at path: %MAGICK%
	goto end
)
set /A COUNTER=0
set /A SCOUNTER=0
for /R %%I in (*.png) do (
	echo %%~nxI | findstr /b 	/r "[0-9]*\.png" >nul 2>&1
	if errorlevel 1 (
		echo skipping %%I 
		set /A SCOUNTER=SCOUNTER+1
	) else (
		echo processing %%I
		%MAGICK% convert "%%I" %MAGICK_OPTS% "%%~dI%%~pIs_%%~nxI"
		del /q "%%I"
		set /A COUNTER=COUNTER+1
	)
)
echo:
echo DONE: %COUNTER% images resized, %SCOUNTER% skipped
:end
pause