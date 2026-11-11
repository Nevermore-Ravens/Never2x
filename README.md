> [!IMPORTANT]
> Due to this project originating from Vs. Camellia, there might be parity issues between Camellia and here.  
> Never2x as its own project is also still a work-in-progress, so some thing are bound to be added/changed later.
>
> Beware of these when using Never2x for your own projects/mods.

# <div align="center">Friday Night Funkin': Never2x</div>
<div align="center">

![](https://github.com/user-attachments/assets/f2c34329-c02c-4638-ab58-517a01c33567)

Never2x is a fork of Friday Night Funkin', designed to be gameplay-first, rather than modding.  
The gameplay is designed to be more like other VSRG's, like StepMania, Etterna, osu!mania, In The Groove, etc.  

In terms of modding, it's very similar to how Psych Engine works. The source code was completely written and rethought from scratch, and is meant to offer both hard and soft modding (much like Psych); however hard modding is its main priority.

It's (currently) available on Windows, MacOS (through Wine), and Linux.<br>Mobile support is not planned, and most likely will never be.

To start compiling, refer to [COMPILING.md](COMPILING.md).

</div>

# <div align="center">Features</div>
## Note Quantization
Note colours will change depending on what snap the note is at, relative to the song's tempo changes.  
This can help if you're having problems reading notes and figuring out quickly when to hit them.  

![](https://github.com/user-attachments/assets/236eb991-fc4d-450d-bbbd-291849a11703)

## Modcharting
Do keep in mind:

Even though this system is fairly similar to something like NotITG, it's not its main focus; meaning it might be more limiting than what you're looking for.<br>
If this project doesn't fit for you, I suggest looking at other engines like [Troll Engine](https://github.com/riconuts/FNF-Troll-Engine) or [What in the Funkin'?!](https://github.com/Hazardous2468/What-In-The-Funkin).

![](https://github.com/user-attachments/assets/3780a81e-23ab-4395-ade4-fe2859d51753)

## Reworked Sustain Inputs
Instead of working like how most other FNF forks do sustain inputs, they now work like StepMania.

Releasing a sustain won't release it immediately, and will instead hold onto it for a *bit* longer. After a few milliseconds, they'll actually drop the sustain.  
This also means you can regrab the sustain after you've already let go of the key.

## Reworked Chart Files
Never2x allows for `.sm`, `.ssc`, and `.osu` files to be played in-game, alongside the normal `.json` FNF (Legacy/V-Slice) format.  
This makes it easier to playtest a chart, instead of having to convert it yourself.

# <div align="center">Credits</div>
## [Rudyrue](https://github.com/Rudyrue)
Lead developer on Never2x, and lead programmer on Vs. Camellia 2.75/3.0

## [SrtHero278](https://github.com/SrtHero278)
Made the modcharting system and sustain rendering/functionality

## [MarshmallowMoth](https://github.com/nebulazorua)
Additional programming help, scroll velocity support, and modchart system fixes

## [BlearChipmunk](https://github.com/BlearChipmunk)
Optimizations and overall performance/memory improvements

## TheConcealedCow
Designed the logo

## Vs. Camellia Team
For sticking through with this project since the beginning

# <div align="center">A.I. (such as ChatGPT, Gemini, Github Copilot, DeepSeek) has not been used and/or assisted in the making of this project.</div>