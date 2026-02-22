#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/Cam-VSRG/lime --quiet --skip-dependencies
haxelib run lime setup
haxelib install openfl 9.5.0 --quiet --skip-dependencies
haxelib git flixel https://github.com/Cam-VSRG/flixel --quiet --skip-dependencies
haxelib git hscript-iris https://github.com/crowplexus/hscript-iris --quiet --skip-dependencies
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate --quiet --skip-dependencies
haxelib git moonchart https://github.com/MaybeMaru/moonchart --quiet --skip-dependencies
haxelib install hxvlc 1.9.2 --quiet --skip-dependencies
haxelib install hxcpp 4.3.2 --quiet --skip-dependencies
haxelib install hxdiscord_rpc 1.2.4 --quiet --skip-dependencies
haxelib install hxjson5 --quiet --skip-dependencies
haxelib install flixel-addons 3.0.2 --quiet --skip-dependencies
echo Finished!