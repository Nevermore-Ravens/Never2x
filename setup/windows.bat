@echo off
color 0a
cd ..
choice /c YN /n /m "Would you like to download the libraries locally to where they won't effect other projects? (Y/N) "
if %errorlevel%  == 1 (
    :: maybe next time i should try `haxelib newrepo`
    mkdir ".\.haxelib"
)
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.

@echo on
haxelib git lime https://github.com/Cam-VSRG/lime --quiet --skip-dependencies
haxelib install flixel-addons 3.0.2 --quiet --skip-dependencies
haxelib install openfl 9.5.0 --quiet --skip-dependencies
haxelib install flixel 5.5.0 --quiet --skip-dependencies
haxelib git hscript-iris https://github.com/crowplexus/hscript-iris --quiet --skip-dependencies
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate --quiet --skip-dependencies
haxelib git moonchart https://github.com/MaybeMaru/moonchart --quiet --skip-dependencies
haxelib install hxvlc 1.9.2 --quiet --skip-dependencies
haxelib install hxcpp 4.3.2 --quiet --skip-dependencies
haxelib install hxdiscord_rpc 1.2.4 --quiet --skip-dependencies
haxelib install hxjson5 --quiet --skip-dependencies
echo Finished!
pause
