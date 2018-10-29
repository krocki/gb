#include "typedefs.h"
#include <sys/time.h>

extern double get_time();

//if gameboy color
#define GBC 0
//skip bootrom
extern u8 BOOTROM;
// CPU freq
#define FCLK 4194304

u8 ram[0x2000];
u8 rom[0x100];
u8 vram[0x2000];
u8 oam[0x100];
u8 hram[0x100];

//registers
typedef struct {
  // regs
  union {
    struct {
      u8 C; u8 B;
      u8 E; u8 D;
      u8 L; u8 H;
      union {
        struct { u8 unused:4; u8 FC:1; u8 FH:1; u8 FN:1; u8 FZ:1;};
        u8 F; }; u8 A;
      u16 SP; u16 PC;
    };
    u16 regs[6];
  };
  // extra registers for handling register transfers
  u8 src_reg;
  u8 dst_reg;
} gb;

gb g;

#define BC (g.regs[0])
#define DE (g.regs[1])
#define HL (g.regs[2])
#define AF (g.regs[3])
#define SP (g.regs[4])
#define PC (g.regs[5])

#define B (g.B)
#define C (g.C)
#define D (g.D)
#define E (g.E)
#define H (g.H)
#define L (g.L)
#define A (g.A)
#define F (g.F)

#define fC (g.FC)
#define fN (g.FN)
#define fZ (g.FZ)
#define fH (g.FH)

// serial link
#define REG_SERIAL   (hram[0x01])
// timer
#define REG_TIM_DIV  (hram[0x04])
#define REG_TIM_TIMA (hram[0x05])
#define REG_TIM_TMA  (hram[0x06])
#define REG_TIM_TAC  (hram[0x07])

// LCD control
#define REG_LCDC     (hram[0x40])
// LCD status
#define REG_LCDSTAT  (hram[0x41])
// scroll y
#define REG_SCY      (hram[0x42])
// scroll y
#define REG_SCX      (hram[0x43])
// current line
#define REG_SCANLINE (hram[0x44])
//LYC
#define REG_LYC      (hram[0x45])
#define REG_OAMDMA   (hram[0x46])
//sprite palette
#define REG_OBJPAL0  (hram[0x48])
#define REG_OBJPAL1  (hram[0x49])
//window coords
#define REG_WINY     (hram[0x4a])
#define REG_WINX     (hram[0x4b])
//bootrom off
#define REG_BOOTROM  (hram[0x50])
// interrupt flags
#define REG_INTF     (hram[0x0f])
// interrupt master enhram[0x
#define REG_INTE     (hram[0xff])
// backgroud paletter
#define REG_BGRDPAL  (hram[0x47])
// MBC type
#define REG_MBC      (cart[0x0147])
//mem
//u8 mem[0x10000];  //64kB
u8 cart[0x100000]; //1MB
u8 eram[0x10000]; //64kB
extern u8 buffer;
extern u32 frame_no;
extern u8 new_frame;
extern u8 pix[2][160*144*3]; // frambuffer, 69120B
extern u8* get_screen();

extern uint32_t total_cpu_ticks;
extern uint32_t total_gpu_ticks;
extern uint32_t cpu_ticks;
extern uint32_t gpu_ticks;
extern double cpu_ts;

extern u8 limit_speed;
extern u8 stopped;
extern u8 halted;
extern u8 irq_en;
extern u8 op;

extern void reset();
static void step();
extern void cpu_step(u32);
extern void gpu_step();

typedef union {
  struct {
  u8 select : 1;
  u8 start  : 1;
  u8 a      : 1;
  u8 b      : 1;
  u8 left   : 1;
  u8 right  : 1;
  u8 down   : 1;
  u8 up     : 1;
  };
  u8 keys_packed;
} keyboard;

//////////  external interface
extern u8 r8(u16 a); // read 8 bytes from mem
extern u16 r16(u16 a); // read 16 bytes from mem
extern void w8(u16 a, u8 v); // write v at address a
extern void w16(u16 a, u16 v); // write 16-bit v at a

extern keyboard keys;
extern u8 key_turbo;
extern u8 key_save_state;
extern u8 key_load_state;
extern u8 key_reset;

extern void read_cart(const char* fname);
extern void set_keys(u8 k);
extern void dump_state(const char* fname);
extern void restore_state(const char* fname);

extern void next_frame();
extern void print_mem(u16,u16);
