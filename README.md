to compile a shared lib:
`make gameboy.so`
then run the front end from python:
`python gameboy.py --rom {PATH_TO_ROM}`

To generate lots of frames and save them to gif and npy files:
`python make_gifs.py --rom {PATH_TO_ROM}`

For example, running the command `python make_gifs.py --rom ./wario_walking.gb` will result in a file like this:
[img]/gifs/wario_walking.gif[/img]

Run the envoronment for 0.5M steps, produce a 50 frame-long gif every 30s:
`python gameboy.py --rom ./gb_roms/Micro_Machines_\(USA\,_Europe\).gb --framelimit=500000 --write_gif_every 30 --write_gif_duration 50`

```
time: 00h 00m 30s, frames 0.06M
time: 00h 01m 00s, frames 0.12M
time: 00h 01m 30s, frames 0.18M
time: 00h 02m 00s, frames 0.24M
time: 00h 02m 30s, frames 0.30M
time: 00h 03m 00s, frames 0.36M
time: 00h 03m 30s, frames 0.42M
time: 00h 04m 00s, frames 0.48M
```

[img]Micro_Machines_(USA,_Europe).gb_63216.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_124856.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_184680.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_244488.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_304912.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_364336.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_423184.gif[/img]
[img]Micro_Machines_(USA,_Europe).gb_484080.gif[/img]

alternatively, build a standalone gameboy with GLFW support and play games manually
i.e.
`./gameboy {PATH_TO_ROM}`

```
enter - START
space - SELECT
Z     - A
X     - B
+ arrows (left, right, down, up)
```
