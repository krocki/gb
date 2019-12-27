[Nintendo Learning Environment](http://olab.is.s.u-tokyo.ac.jp/~kamil.rocki/nintendo/)

[![DOI](https://zenodo.org/badge/155248798.svg)](https://zenodo.org/badge/latestdoi/155248798)

# Quick start
1. Build C lib
`make gameboy.so`
2. Run the front end from python:
`python gameboy.py --rom {PATH_TO_ROM}`

## C dependencies
None
## Python dependencies
Numpy, CFFI

# Fix for 'gameboy.so' not found:
```
export LD_LIBRARY_PATH=.
```

# Usage
#### Use the provided python wrapper. Example:
* Run the environment for 0.5M steps
* Produce a 50 frame-long gif every 30s
```
python gameboy.py --rom ./gb_roms/Micro_Machines_\(USA\,_Europe\).gb --framelimit=500000 --write_gif_every 30 --write_gif_duration 50
```

Output:
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

### GIFS generated every 30s:
![alt_text](gifs/Micro_Machines_(USA,_Europe).gb_63216.gif  "Micro machines")
![alt_text](gifs/Micro_Machines_(USA,_Europe).gb_124856.gif "Micro machines")
![alt_text](gifs/Micro_Machines_(USA,_Europe).gb_184680.gif "Micro machines")
![alt_text](gifs/Micro_Machines_(USA,_Europe).gb_244488.gif "Micro machines")
![alt_text](gifs/Micro_Machines_(USA,_Europe).gb_304912.gif "Micro machines")

#### Generate lots of frames and save them to gif and npy files:
`python make_gifs.py --rom {PATH_TO_ROM}`

For example, running the command `python make_gifs.py --rom ./wario_walking.gb` will result in a file like this:
![alt_text](/gifs/wario_walking.gif "Wario Walking")


#### Alternatively, build a standalone gameboy with GLFW support and play games manually
To build:
```
make
```
To play:
```
./gameboy {PATH_TO_ROM}
```

```
enter - START
space - SELECT
Z     - A
X     - B
+ arrows (left, right, down, up)
SHIFT - turbo mode
```
