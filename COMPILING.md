# Targets
As of right now, only C++ is supported. I've TRIED Hashlink, but alot of things are broken such as sustains, so I didn't bother.<br>
Web is also not supported specifically because of websites that try to steal mods (looking at you KBH Games, Snokido, and Gamaverse).

# Dependencies
* Haxe 4.3 (at least, everything after that should still work)
* Lime ([commit b39477133e7c1eff7f83d5414fecc5143560f02e](https://github.com/openfl/lime/commit/b39477133e7c1eff7f83d5414fecc5143560f02e))
* [HaxeFlixel](https://github.com/Nevermore-Ravens/flixel)
* HaxeFlixel Addons 4.0.2
* [Nevermore](https://github.com/Nevermore-Ravens/Nevermore)
* OpenFL 9.5.0
* hxdiscord_rpc 1.2.4
* hxjson5
* [HScript Copper](https://github.com/SrtHero278/hscript-copper)
* [Moonchart](https://github.com/MaybeMaru/moonchart)
* hxvlc 2.2.4 (or 1.9.2)
* [flixel-animate](https://github.com/MaybeMaru/flixel-animate)

> [!NOTE]
> Ideally (if you don't wanna manually type in each library), you can run the setup file according to your OS in `_setup/`.
> 
> Unix is Linux/MacOS, the .bat file is for Windows specifically.<br>
>
> If you're on Windows and haven't compiled HaxeFlixel before, I **HIGHLY** recommend running the MSVC .bat file. This will ensure you can compile to C++ properly.

# Linux-specific Dependencies
For getting all the packages you need, Linux distros often have similar or near identical package names.  
Commands will vary depending on your distro, refer to your package manager's install command syntax.

### Ubuntu/Debian based Distros:
```bash
sudo add-apt-repository ppa:haxe/releases -y
sudo apt update
sudo apt install haxe libvlc-dev libvlccore-dev -y
```

### Arch based Distros:
```bash
sudo pacman -Syu haxe git vlc --noconfirm
```

### Gentoo:
```bash
sudo emerge --ask dev-vcs/git-sh dev-lang/haxe media-video/vlc
```

* Some packages may be "masked", so please refer to [this page](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) in the Gentoo Wiki.

# Building
 ## *<div align="center">before doing ANYTHING, make sure you have all libraries installed.</div>*
## Windows
1. Make sure you have the project directory open.<br>
2. Click the directory bar shown in the image.

<img width="509" height="320" alt="image" src="https://github.com/user-attachments/assets/55460817-de56-47ad-9b45-6407410450a3" />

3. Type in `cmd` and hit enter. That will automatically open the command prompt to the directory you're in.
4. Type in `lime test cpp` and hit enter.

## MacOS

## Linux
1. Open the project directory in your console.
2. Type in `lime test cpp` and hit enter.

# FAQ
## "I wanna use HMM, it's way easier!"
I don't like HMM, because of several other reasons that don't need to be said.  
As a workaround, make a `.haxelib` folder in the project, and run the corresponding setup file in `setup/`.

## "It's taking a while, should I be worried?"
No, it's completely normal.  
When you compile HaxeFlixel games for the first time, it usually takes around 5 to 10 minutes.  
It depends on how powerful your hardware is.

## "I had an error relating to g++ on Linux!"
Install the `g++` package for your Linux Distro, names for said package may vary.  
e.g: Fedora is `gcc-c++`, Gentoo is `sys-devel/gcc`, and so on.

## "I have an error saying `ApplicationMain.exe : fatal error LNK1120: 1 unresolved externals`!"
Run `lime test cpp -clean`, or delete the `export` folder and re-compile.
