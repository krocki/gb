from cffi import FFI
import time, argparse
from array2gif import write_gif
from scipy.misc import imresize
import random
import numpy as np

def init(rom_path):
  _gb = ffi.dlopen("./gameboy.so")
  _gb.read_cart(rom_path);
  _frame = ffi.buffer(_gb.get_screen(), 160*144*3)

  _gb.reset()
  _gb.limit_speed=0
  return _frame,_gb

def get_frame(_frame):
    #return imresize(np.frombuffer(_frame, dtype=np.uint8).reshape(144,160,3)[:,:,:], (160,160))
    return np.frombuffer(_frame, dtype=np.uint8).reshape(144,160,3)[:,:,:]

def get_args():
    parser = argparse.ArgumentParser(description=None)
    parser.add_argument('--processes', default=1, type=int, help='number of processes to train with')
    parser.add_argument('--framelimit', default=-1, type=int, help='frame limit')
    parser.add_argument('--skipframes', default=8, type=int, help='frame increment, def=1')
    parser.add_argument('--gifwritefreq', default=200, type=int, help='write every nth frame to gif')
    parser.add_argument('--rom', default='./envs/mario1.gb', type=str, help='path to rom')
    parser.add_argument('--logname', default='./mario1', type=str, help='logname')
    return parser.parse_args()

if __name__ == "__main__":

    ffi = FFI()

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
    """)
    args = get_args()
    args.save_dir = '{}/'.format(args.logname)
    imgs,frames,episodes=[],0,0
    write_frame = args.gifwritefreq
    start_time = last_disp_time = time.time()

    path_bytes = args.rom.encode('utf-8')
    logname = args.logname + '.txt'

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
      0x80  #up
    ]

    t0 = time.time()

    while frames < args.framelimit or args.framelimit == -1:
      # process a frame
      raw_frame=get_frame(frame)

      # write to gif?
      if (write_frame <= 0):
        fr=np.array(raw_frame)
        imgs.append(np.rot90(np.fliplr(fr)))
        write_frame = args.gifwritefreq
      else:
        write_frame -= args.skipframes

      # decide on the action
      a = random.randint(0,len(actions_hex)-1)
      gb.set_keys(actions_hex[a])
      gb.next_frame_skip(args.skipframes)
      frames += args.skipframes

      if time.time() - last_disp_time > 60:
        elapsed = time.strftime("%Hh %Mm %Ss", time.gmtime(time.time() - start_time))
        print(elapsed, frames, frames / (time.time() - t0))
        last_disp_time = time.time()
        if len(imgs) > 0: write_gif(imgs, '{}_{}.gif'.format(args.logname, frames),fps=10)
        imgs=[]



