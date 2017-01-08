#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
  int fd;
  int log2_trig;
  uint32_t phase_inc;
  double phase_in;
  uint32_t count;
  void *cfg;
  char *name = "/dev/mem";
  const int freq = 125000000; //124998750; // Hz
  double trigger_time; 

  if (argc == 3) 
  {
	log2_trig = atoi(argv[1]);
	phase_in = atof(argv[2]);
  }
  else 
  {
	log2_trig = 0;
	phase_in = 1.;
  }
  phase_inc = (uint32_t)(2.147482*phase_in);

  trigger_time = 2*(double)(1<<(26-log2_trig))/freq;

  if((fd = open(name, O_RDWR)) < 0)
  {
    perror("open");
    return 1;
  }

  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0x42000000);
 

  *((uint32_t *)(cfg + 8)) = (0xf & log2_trig) + (phase_inc << 5);   // set trigger and phase_inc

  count = *((uint32_t *)(cfg + 0));
  printf("Counts: %5d, trigger time: %5f s, calculated freq: %6.5f Hz\n", count, trigger_time, (double)count/trigger_time);


  munmap(cfg, sysconf(_SC_PAGESIZE));

  return 0;
}
