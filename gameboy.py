from cffi import FFI
import time, argparse
from array2gif import write_gif
from scipy.misc import imresize
import random
import numpy as np

# init GB subsystem
def init(rom_path):
  _gb = ffi.dlopen("./gameboy.so"); _gb.read_cart(rom_path)
  _frame = ffi.buffer(_gb.get_screen(), 160*144*3)
  _gb.reset(); _gb.limit_speed=0
  return _frame,_gb

# get pointer to the framebuffer and convert it to numpy array
def get_frame(_frame): return np.frombuffer(_frame, dtype=np.uint8).reshape(144,160,3)[:,:,:]

# parse commandline args
def get_args():
    parser = argparse.ArgumentParser(description=None)
    parser.add_argument('--processes', default=1, type=int, help='number of processes to train with')
    parser.add_argument('--framelimit', default=1000000, type=int, help='frame limit')
    parser.add_argument('--skipframes', default=8, type=int, help='frame increment, def=1')
    parser.add_argument('--rom', default='./wario_walking.gb', type=str, help='path to rom')
    parser.add_argument('--write_gif_every', default=60, type=int, help='write to gif every n secs')
    parser.add_argument('--write_gif_duration', default=50, type=int, help='number of frames to write')
    return parser.parse_args()

if __name__ == "__main__":

    ffi = FFI()

    #C header stuff
    ffi.cdef("""
    typedef uint8_t u8; typedef uint16_t u16; typedef uint32_t u32;
    void read_cart(const char* romname);
    void reset();
    u8* get_screen();
    u8 new_frame;
    void next_frame_skip(u8);
    void next_frame();
    void set_keys(u8 k);
    void restore_state(const char* fname);
    u8 r8(u16 a);
    u16 r16(u16 a);
    u8 limit_speed;
    u32 unimpl;
    """)

    args = get_args()
    imgs,frames,episodes=[],0,0

    path_bytes = args.rom.encode('utf-8')
    logname = args.rom + '.txt'

    rom_path = ffi.new("char[]", path_bytes)
    frame, gb = init(rom_path)

    actions_hex = [
      0x00, #nop
      0x01, #select
      0x02, #start
      0x04, #a
      0x08, #b
      0x10, #left
      0x20, #right
      0x40, #down
      0x80, #up
      0x14, #a + left
      0x24, #a + right
      0x44, #a + down
      0x84, #a + up
      0x18, #b + left
      0x28, #b + right
      0x48, #b + down
      0x88  #b + up
    ]

    t0 = last_time = time.time()
    imgs, frames_to_write = [], 0

    # main loop
    while True:

      # process a frame
      raw_frame=get_frame(frame)

      # checkpoint?
      if (time.time() - last_time) > args.write_gif_every:
        elapsed = time.strftime("%Hh %Mm %Ss", time.gmtime(time.time() - t0))
        print('time: {}, frames {:.2f}M'.format(elapsed, frames/1e6))
        frames_to_write = args.write_gif_duration;
        last_time = time.time()

      # write frames
      if frames_to_write > 0:
          fr=np.array(raw_frame)
          imgs.append(np.rot90(np.fliplr(fr)))
          frames_to_write -= 1

      # write to gif?
      if len(imgs) == args.write_gif_duration:
        write_gif(imgs, '{}_{}.gif'.format(args.rom, frames),fps=10)
        imgs=[]

      # decide on the action
      a = random.randint(0,len(actions_hex)-1)
      gb.set_keys(actions_hex[a])
      gb.next_frame_skip(args.skipframes)

      # terminate?
      if frames > args.framelimit:
        break

      frames += args.skipframes
