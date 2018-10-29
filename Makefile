GCC=gcc
#GCC=arm-none-eabi

C_FLAGS=-Ofast -fPIC
OS:=$(shell uname)

ifeq ($(OS),Darwin) #OSX
  GL_FLAGS=-lglfw -framework OpenGL -lpthread
else # Linux or other
  GL_FLAGS=-lglfw -lGL -lpthread
endif

all: gameboy
shared: gameboy.so

gameboy: gameboy.so main_lcd.o Makefile gameboy.h
	${GCC} main_lcd.o gameboy.so ${C_FLAGS} ${GL_FLAGS} -o $@

gameboy.so: gameboy.o gameboy.h Makefile
	${GCC} gameboy.o ${C_FLAGS} -shared -o $@

%.o: %.c
	${GCC} ${C_FLAGS} -c $< -o $@

clean:
	rm -rf *.o gameboy gameboy.so
