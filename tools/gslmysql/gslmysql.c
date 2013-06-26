/*
    gslmysql.c -- eib bus monitoring program - processes group telegrams
    Copyright (C) 2008 V'yacheslav Stetskevych
    
    Based on bcusdk-0.0.3/eibd/examples/groupsocketlisten.c
    Copyright (C) 2005-2007 Martin Koegler <mkoegler@auto.tuwien.ac.at>
    
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
#include "common.h"
#include <mysql/mysql.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int len;
EIBConnection *con;
eibaddr_t dest;
eibaddr_t src; 
uchar buf[200];
          

int processTelegram ();

int main (int ac, char *ag[])
{

  /* Vars to access MySQL */
  MYSQL *conn;
  MYSQL_RES *res;
  MYSQL_ROW row;
        
  char *server = "localhost";
  char *user = "root";
  char *password = "";
  char *database = "test";
               
  conn = mysql_init(NULL);
  /*End of MySQL vars */
                    

  if (ac != 2)
    die ("usage: %s url", ag[0]);
  con = EIBSocketURL (ag[1]);
  if (!con)
    die ("Open failed");

  if (EIBOpen_GroupSocket (con, 0) == -1)
    die ("Connect failed");
    
  /* Connect to database */
  if (!mysql_real_connect(conn, server,
  user, password, database, 0, NULL, 0)) {
  fprintf(stderr, "%s\n", mysql_error(conn));
  exit(1);
  }
                    

  while (1)
    {
      len = EIBGetGroup_Src (con, sizeof (buf), buf, &src, &dest);
      if (len == -1)
	die ("Read failed");
      if (len < 2)
	die ("Invalid Packet");
      if (buf[0] & 0x3 || (buf[1] & 0xC0) == 0xC0) // Unknown APDU -- drop it
	{
	  break;
	}
      else
	{
	  switch (buf[1] & 0xC0)
	    {
	    case 0x00: //Read
	      break;
	    case 0x040: //Response
              processTelegram ();
	      break;
            case 0x80: //Write
              processTelegram ();
              break;
            }
	}
    }

  EIBClose (con);
  return 0;
}

int processTelegram()
{
  printGroup (dest);
  printf (" ");
  if (buf[1] & 0xC0)
  {
    if (len == 2)
      printf ("%02X", buf[1] & 0x3F);
    else
      printHex (len - 2, buf + 2);
  }
  printf ("\n");
}
