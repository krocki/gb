#include <stdio.h>    // printf
#include <string.h>   // memcpy
#include <unistd.h>   // usleep
#include <stdlib.h>   // atoi
#include <pthread.h>
#include <GLFW/glfw3.h>
#include "typedefs.h"
#include "gameboy.h"
#include "bootrom.h"

double t0; // global start time

// GL stuff
#define AUTO_REFRESH 10000
#define OFFSET 64
#define WIDTH 320
#define HEIGHT 288
#define GB_W 160
#define GB_H 144
u8 gl_ok=0;
u8 gl_debug=0;
u8 serial=0;
u8 vsync=0;

#define bind_key(x,y) \
{ if (action == GLFW_PRESS && key == (x)) (y) = 1; if (action == GLFW_RELEASE && key == (x)) (y) = 0; if (y) {printf(#y "\n");} }

static GLFWwindow* window;
static void error_callback(s32 error, const char* description) { }
static void key_callback(GLFWwindow* window, s32 key, s32 scancode, s32 action, s32 mods) {

    if (action == GLFW_PRESS && key == GLFW_KEY_ESCAPE) glfwSetWindowShouldClose(window, GLFW_TRUE);
    if (action == GLFW_PRESS && key == GLFW_KEY_0) gl_debug ^= 1;
    if (action == GLFW_PRESS && key == GLFW_KEY_9) limit_speed ^= 1;

    bind_key(GLFW_KEY_LEFT_SHIFT, key_turbo);
    bind_key(GLFW_KEY_1,     key_save_state);
    bind_key(GLFW_KEY_2,     key_load_state);
    bind_key(GLFW_KEY_3,     key_reset);

    bind_key(GLFW_KEY_LEFT,  keys.left);
    bind_key(GLFW_KEY_RIGHT, keys.right);
    bind_key(GLFW_KEY_DOWN,  keys.down);
    bind_key(GLFW_KEY_UP,    keys.up);
    bind_key(GLFW_KEY_SPACE, keys.select);
    bind_key(GLFW_KEY_ENTER, keys.start);
    bind_key(GLFW_KEY_Z,     keys.a);
    bind_key(GLFW_KEY_X,     keys.b);
}
static GLFWwindow* open_window(const char* title, GLFWwindow* share, s32 posX, s32 posY)
{
    GLFWwindow* window;

    //glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
    window = glfwCreateWindow(WIDTH, HEIGHT, title, NULL, share);
    if (!window) return NULL;

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);
    glfwSetWindowPos(window, posX, posY);
    glfwShowWindow(window);

    glfwSetKeyCallback(window, key_callback);

    return window;
}

// TODO: change to texture... but it's problematic if tex size != [2^n] x [2^n]
static void draw_quad()
{
    s32 width, height;
    glfwGetFramebufferSize(glfwGetCurrentContext(), &width, &height);
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    float incr_x = 1.0f/(float)GB_W; float incr_y = 1.0f/(float)GB_H;

    glOrtho(0.f, 1.f, 0.f, 1.f, 0.f, 1.f);
    glBegin(GL_QUADS);
    float i,j;
    u8 px,py;
    for (u8 x=0; x<GB_W; x++) for (u8 y=0; y<GB_H; y++ ) {
         i = x * incr_x; j = y * incr_y; px = x; py = GB_H - y - 1; // FLIP vert

          glColor4f(get_screen()[3*(px+py*160)+0]/255.0f,
                    get_screen()[3*(px+py*160)+1]/255.0f,
                    get_screen()[3*(px+py*160)+2]/255.0f,
                    255.0f/255.0f);

          glVertex2f(i,      j     );     glVertex2f(i+incr_x, j     );
          glVertex2f(i+incr_x, j+incr_y); glVertex2f(i,      j+incr_y);
    }
    glEnd();
};

s32 lcd_init() {
    s32 x, y, width;
    glfwSetErrorCallback(error_callback);
    if (!glfwInit()) return -1;

    window = open_window("Gameboy", NULL, OFFSET, OFFSET);
    if (!window) { glfwTerminate(); return -1; }

    glfwGetWindowPos(window, &x, &y);
    glfwGetWindowSize(window, &width, NULL);
    glfwMakeContextCurrent(window);

    gl_ok=1;
    printf("%9.6f, GL_init OK\n", get_time()-t0);

    double frame_start=get_time();
    while (!glfwWindowShouldClose(window))
    {
        if (new_frame == 1) {
          double fps = get_time()-frame_start;
          frame_start = get_time();
          new_frame=0;
          glfwMakeContextCurrent(window);
          glClear(GL_COLOR_BUFFER_BIT);
          draw_quad();
          glfwSwapBuffers(window);
          if (AUTO_REFRESH > 0) glfwWaitEventsTimeout(1.0/(double)AUTO_REFRESH);
          else glfwWaitEvents();
        } else { }
    }

    glfwTerminate();
    printf("%9.6f, GL terminating\n", get_time()-t0);
    gl_ok=0;
    return 0;
}

void gb_reset() {
  reset();
  printf("%9.3f, resetting gb...\n", get_time()-t0);
  printf("%9.3f, ok\n", get_time()-t0);
}

void check_stdout() {
  u8 v=REG_SERIAL;
  if (v) {
    printf("%c", v);
    fflush(stdout);
    REG_SERIAL = 0;
  }
}

u8 prev[128];
u32 hits[128];
u8 curr[128];

void diff_mem(u16 off, u16 n) {
  for (u8 i=0; i<n; i++) {
    u8 v = r8(off+i);
    if (v != prev[i]) {
      if (hits[i] < 100) printf("%04x : %02x->%02x, %5d (%5d)\n", off+i, prev[i], v, v, hits[i]);
      prev[i]=v; hits[i]++;
    }
  }
}

void *gameboy(void *args) {

  printf("%9.3f, GB starting...\n", get_time()-t0);
  printf("%9.3f, reset ok, waiting for GL...\n", get_time()-t0);
  while (!gl_ok) usleep(10);
  printf("%9.3f, GB ACK\n", get_time()-t0);

  printf("%9.3f, reading cart...\n", get_time()-t0);
  read_cart((const char*)args);
  printf("MBC %02x\n", REG_MBC);
  memcpy(rom, bootrom, 0x100);
  memset(vram, 0, 0x2000);
  memset(ram, 0, 0x2000);
  memset(oam, 0, 0x100);
  memset(hram, 0, 0x100);
  memset(eram, 0, 0x10000);
  gb_reset();
  printf("%9.3f, DONE\n", get_time()-t0);

  while (gl_ok) {
    if (gl_debug) { }
    next_frame();
    if (serial) check_stdout();
  }

  printf("%9.6f, terminating\n", get_time()-t0);
  printf("ticks %d, time %.6f s, MHz %.3f\n", total_cpu_ticks, get_time()-cpu_ts, ((double)total_cpu_ticks/(1000000.0*(get_time()-cpu_ts))));

  return NULL;
}

int main(int argc, char **argv) {

  if (argc < 2)  { printf("usage: ./gameboy <rom> [bootrom=%d] [speed_limit=%d] [debug=%d] [stdout=%d]\n",
                   BOOTROM, gl_debug, limit_speed, serial); return -1; };
  if (argc >= 3) { BOOTROM=atoi(argv[2]);    }; printf("BOOTROM=%d\n", BOOTROM); ;
  if (argc >= 4) { gl_debug=atoi(argv[3]);   }; printf("DEBUG=%d\n", gl_debug); ;
  if (argc >= 5) { limit_speed=atoi(argv[4]);}; printf("SPEED_LIMIT=%d\n", limit_speed); ;
  if (argc >= 6) { serial = atoi(argv[5]);   }; printf("STDOUT=%d\n", serial); ;
  t0=get_time();
  pthread_t gb_thread;
  if(pthread_create(&gb_thread, NULL, gameboy, argv[1])) {
    fprintf(stderr, "Error creating thread\n");
    return 1;
  }

  lcd_init();

  if(pthread_join(gb_thread, NULL)) {
    fprintf(stderr, "Error joining thread\n");
    return 2;
  }

  return 0;
}
