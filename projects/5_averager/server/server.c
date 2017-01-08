/*
FPGA Project: Averager
Server for setting configuration and reading data from FPGA

16.12.2016 by Anton Potocnik
Modified Pavel Demin's server.c
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>


#define START 0
#define STOP 1

int main(int argc, char *argv[])
{
  int fd, j, sock_server, sock_client, size, yes = 1, nsmpl, navg, rx;
  void *cfg, *dat;
  char *name = "/dev/mem";
  uint32_t naverages=0, nsamples=0, timing=0;
  struct sockaddr_in addr;
  uint32_t command, value, tmp;
  uint32_t buffer[8192];
  clock_t time_begin;
  double time_spent;
  int measuring = 0;


  if((fd = open(name, O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  dat = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0x40000000);
  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0x42000000);



  if((sock_server = socket(AF_INET, SOCK_STREAM, 0)) < 0)
  {
    perror("socket");
    return EXIT_FAILURE;
  }

  setsockopt(sock_server, SOL_SOCKET, SO_REUSEADDR, (void *)&yes , sizeof(yes));

  /* setup listening address */
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons(1001);

  if(bind(sock_server, (struct sockaddr *)&addr, sizeof(addr)) < 0)
  {
    perror("bind");
    return EXIT_FAILURE;
  }

  listen(sock_server, 1024);
  printf("Listening on port 1001 ...\n");

  while(1)
  {

    if((sock_client = accept(sock_server, NULL, NULL)) < 0)
    {
      perror("accept");
      return EXIT_FAILURE;
    }
    while(1) //MSG_WAITALL
    {
      //sleep(1);
      rx = recv(sock_client, (char *)&command, 4, MSG_DONTWAIT);
      if (rx == 0) {
         break;
         measuring = 0;
      }
      if(rx > 0) {
         value = command & 0xfffffff;
         switch(command >> 28)
         {
           case 1: /* Trigger Delay - Timing */
				timing = command & 0xff;
				break;

           case 2: /* NSAMPLES */
				if ((command & 0xff) < 14)
					nsamples = (command & 0xff);
				else
				nsamples = 13;
				break;

           case 3: /* NAVERAGES */
				naverages = command & 0xff;
				break;

           case 0: /* fire */
             
				// set trigger and NSAMPLES set NAVERAGES and stop measurement
				*((int32_t *)(cfg + 0)) = (STOP) + (timing<<8) + (nsamples<<16) + (naverages<<24);

				//sleep(0.1); // wait 0.1 second

				time_begin = clock();
				// start measurement
				*((int32_t *)(cfg + 0)) ^= 1;
				measuring = 1;
				break;
         }
      }


      /* Check if it is in measuring mode and has finished */
      if (measuring == 1 && (*((uint32_t *)(cfg + 8)) & 1) != 0) { 
      	time_spent = ((double)(clock() - time_begin)) / CLOCKS_PER_SEC; // measure time

      	/* transfer all samples */
      	nsmpl = (1<<nsamples);
      	for(j = 0; j < nsmpl; ++j) 
			buffer[j] = (*((uint32_t *)(dat + 4*j)));
      	

      	send(sock_client, buffer, 4*nsmpl, MSG_NOSIGNAL);
      	printf("%d samples measured in %f s\n", nsmpl, time_spent);
		measuring = 0;
		break;
      }
    }	

    close(sock_client);
  }

  close(sock_server);
  return EXIT_SUCCESS;
}
