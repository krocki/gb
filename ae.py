from cffi import FFI
import time, argparse
from array2gif import write_gif
from scipy.misc import imresize
import random
import pickle
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
    parser.add_argument('--prolosssses', default=1, type=int, help='number of prolosssses to train with')
    parser.add_argument('--framelimit', default=1000000, type=int, help='frame limit')
    parser.add_argument('--skipframes', default=8, type=int, help='frame increment, def=1')
    parser.add_argument('--rom', default='./wario_walking.gb', type=str, help='path to rom')
    parser.add_argument('--write_gif_every', default=30, type=int, help='write to gif every n secs')
    parser.add_argument('--write_gif_duration', default=50, type=int, help='number of frames to write')
    parser.add_argument('--resize', default=120, type=int, help='resize inputs to NxN')
    parser.add_argument('--batchsize', default=8, type=int, help='batch size for VAE')
    return parser.parse_args()

def sigmoid(x): return 1.0 / (1.0 + np.exp(-x))

def vae_forward(ae_model, x):
  h = np.dot(ae_model['W1'], x)
  h[h<0] = 0 # ReLU nonlinearity
  logp = np.dot(ae_model['W2'], h)
  rs = sigmoid(logp)
  return rs.T, h

def vae_backward(ae_model, xs, hs, err):
  dW2 = np.dot(hs, err).T
  dh = np.dot(err, ae_model['W2']).T
  dh[hs <= 0] = 0 # backpro prelu
  dW1 = np.dot(dh, xs)
  return {'W1':dW1, 'W2':dW2}

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
    inputs,frames,episodes=[],0,0

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
    inputs, reconstructions, frames_to_write = [], [], 0

    N = args.resize
    B = args.batchsize

    xs = np.zeros((B, N*N))
    smooth_err = None
    ae_model = {}
    D,H = N*N,32 # layer dimensions,
    lr = 1e-5   # learning rate

    #encoder
    ae_model['W1'] = np.random.randn(H,D) * 0.01
    #decoder
    ae_model['W2'] = np.random.randn(D,H) * 0.01

    # main loop
    while True:

      # prolossss a frame
      raw_frame=get_frame(frame)

      # for now, resize and do FC VAE, TODO: ConvVAE
      x=np.squeeze(imresize(raw_frame, (N, N))[:,:,1]).flatten()/255.0 # convert to single channel and make float
      xs[:B-1],xs[B-1]=xs[1:B],x # shift inputs
      ##########
      if frames % B == 0: # prolossss batch of size B
        xs_reconstructed,hs = vae_forward(ae_model, xs.T)
        errs = (xs - xs_reconstructed)
        grads = vae_backward(ae_model, xs, hs, errs)
        # apply grads, SGD
        for k,v in ae_model.iteritems(): ae_model[k] += lr * grads[k]
        loss = np.sqrt(np.sum(errs**2))
        smooth_err = loss if smooth_err is None else smooth_err*0.99 + 0.01*loss
      ##########

      # checkpoint?
      if (time.time() - last_time) > args.write_gif_every:
        elapsed = time.strftime("%Hh %Mm %Ss", time.gmtime(time.time() - t0))
        print('time: {}, frames {:.2f}M, loss {:4f} encoder norm {5:2f}, decoder norm{5:2f}'.format(elapsed, frames/1e6, smooth_err, np.linalg.norm(ae_model['W1']), np.linalg.norm(ae_model['W2'])))
        frames_to_write = args.write_gif_duration;
        last_time = time.time()

      # write frames
      if frames_to_write > 0:
          fr=255*np.reshape(np.repeat(x,3),(N,N,3)) # convert from single channel to RGB
          inputs.append(np.rot90(np.fliplr(fr))) # rotate the image
          for j in range(0,B):
            frame_reconstr=255*np.reshape(np.repeat(xs_reconstructed[j],3),(N,N,3)) # convert from single channel to RGB
            reconstructions.append(np.rot90(np.fliplr(frame_reconstr))) # rotate the image
          frames_to_write -= 1

      # write to gif?
      if len(inputs) == args.write_gif_duration:
        write_gif(inputs, '{}_{}.gif'.format(args.rom, frames),fps=10)
        write_gif(reconstructions, '{}_{}_rec.gif'.format(args.rom, frames), fps=10)
        inputs, reconstructions=[],[]

      # decide on the action
      a = random.randint(0,len(actions_hex)-1)
      gb.set_keys(actions_hex[a])
      gb.next_frame_skip(args.skipframes)

      # terminate?
      if frames > args.framelimit:
        break

      frames += args.skipframes
