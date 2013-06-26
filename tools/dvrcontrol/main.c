/* main.c
	(C) 2004-5 Captain http://www.captain.at
	
	Sends 3 characters (ABC) via the serial port (/dev/ttyS0) and reads
	them back if they are returned from the PIC.
	
*/
#include <stdio.h>   /* Standard input/output definitions */
#include <string.h>  /* String function definitions */
#include <unistd.h>  /* UNIX standard function definitions */
#include <fcntl.h>   /* File control definitions */
#include <errno.h>   /* Error number definitions */
#include <termios.h> /* POSIX terminal control definitions */

#include "functions.h"

int fd;

int initport(int fd) {
	struct termios options;
	// Get the current options for the port...
	tcgetattr(fd, &options);
	// Set the baud rates to 19200...
	cfsetispeed(&options, B9600);
	cfsetospeed(&options, B9600);
	// Enable the receiver and set local mode...
	options.c_cflag |= (CLOCAL | CREAD);

	options.c_cflag &= ~PARENB;
	options.c_cflag &= ~CSTOPB;
	options.c_cflag &= ~CSIZE;
	options.c_cflag |= CS8;

	// Set the new options for the port...
	tcsetattr(fd, TCSANOW, &options);
	return 1;
}

unsigned readHex (char *value) {
	int i;
	sscanf(value, "%x", &i);
	return i;
}

void writecommand(int fd, char command) {
	
	char sCmd[255];
	sCmd[0] = 0x85;
	sCmd[1] = 0x7F;
	sCmd[2] = 0x7F;
	sCmd[3] = 0x4B;
	sCmd[4] = command;
	sCmd[5] = sCmd[0] + sCmd[1] + sCmd[2] + sCmd[3] +sCmd[4];
	sCmd[5] &= 0x7F;
	printf("sum = 0x%X\n", sCmd[5]);
	
	if (writeport(fd, sCmd))
		printf("command successful\n");
}

int main(int argc, char **argv) {
	if (argc != 2) {
		printf ("usage: %s command\n", argv[0]); 
		return 1;
	}
	
	fd = open("/dev/ttyS0", O_RDWR | O_NOCTTY | O_NDELAY);
	if (fd == -1) {
		perror("open_port: Unable to open /dev/ttyS0 - ");
		return 1;
	} else {
		fcntl(fd, F_SETFL, 0);
	}

	initport(fd);
	writecommand(fd, readHex(argv[1]));
	
	return 0;
}
