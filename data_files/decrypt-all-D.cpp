#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include <dir.h>
#include "dyndefs.h"


enum { SIZE = 256 };
DYN_U_8     array [SIZE];
	unsigned day, month, year;

void init(void)
{
	// set up reverse identity array as the default
	DYN_U_8  *ptr = array;
	for (DYN_16 i = 255; i >= 0;)
		*ptr++ = (DYN_U_8)(i--);
}

void params(DYN_U_8 &s, DYN_U_8 &i)
{
	s = (DYN_U_8)(245); //getPosRange (0, 255);
	i = (DYN_U_8)(220); //getPosRange (1, 255);
}

void build(const DYN_U_8 s, const DYN_U_8 i)
{
	DYN_U_8  sValue = s,
				fillValue = s - 1,
				*ptr = array,
				*ePtr = &array [256];
	memset (array, fillValue, 256);

	DYN_16   numLeft = 256;
	while (numLeft--)
	{
		// store the value
      *ptr = sValue++;

		// go on to next slot
		ptr += i;

		// wrap if necessary
		if ((ptr < array) || (ptr >= ePtr))
			ptr = &array [ptr - ePtr];

		// check if slot is empty (i.e. value stored is fillValue)
		while (*ptr != fillValue)
		{
         // if spot already taken, increment until an openning found
			ptr++;
			if (ptr == ePtr)
				ptr = array;
		}
	}
}

void encrypt(void FAR *p, DYN_16 size)
{
	DYN_U_8  FAR *ptr = (DYN_U_8 FAR *) p;
	while (size--)
	{
      DYN_U_8  c = *ptr;
		*ptr++ = array [array [array [c]]];
	}
}

void decrypt (void FAR *p, DYN_16 size)
{
	DYN_U_8  FAR *ptr = array,
				translate [SIZE];

	// go through the original set of data (array), and store where
	// every value is located, into translate (which 'finds' each value,
	// just once, and stores that info)
	DYN_16   count = 0;
	while (count < SIZE)
		translate [*ptr++] = (DYN_U_8)(count++);

	// now go through the user's data, and just translate all the values
	ptr = (DYN_U_8 FAR *) p;
	while (size--)
	{
		DYN_U_8  c = *ptr;
		for (DYN_16 tries = 3; tries > 0; tries--)
			c = translate [c];

		*ptr++ = c;
	}
}

void setid(unsigned *id, char plusmod, char timesmod) {
	if ((plusmod < 0)&&(timesmod < 0)) *id = (timesmod+256)*256 + 256 + plusmod;
	else if (plusmod < 0) *id = timesmod*256 + 256 + plusmod;
	else if (timesmod < 0) *id = (timesmod+256)*256 + plusmod;
	else *id = timesmod*256 + plusmod;
}

void getdate(char *data) {
	int i;
	int val1;
	int val2;
	int val3;
	float total=0.0;

	val1 = data[0];
	val2 = data[1];
	val3 = data[2];
	if (val1<0) val1+=256;
	if (val2<0) val2+=256;
	if (val3<0) val3+=256;
//printf("%d %d %d\n", val1, val2, val3);
	total = val3*256.0*256.0 + 256.0*val2 + val1;
	year=0;
	while (1) {
		if ( ((int(year)%4==0) && (int(year)%100!=0)) || (int(year)%400==0) ) total=total-366;
		else total=total-365;
		year++;
		if ( ((year%4==0) && (year%100!=0)) || (year%400==0) ) {
			if (total<366) break;
		}
		else if (total<365) break;
	}
	month=0;
	while (total>=0) {
		switch(month) {
			case 0: total=total-31; month++; break;
			case 1: if ( ((year%4==0) && (year%100!=0)) || (year%400==0) ) total=total-29;
						 else total=total-28;
					  month++; break;
			case 2: total=total-31; month++; break;
			case 3: total=total-30; month++; break;
			case 4: total=total-31; month++; break;
			case 5: total=total-30; month++; break;
			case 6: total=total-31; month++; break;
			case 7: total=total-31; month++; break;
			case 8: total=total-30; month++; break;
			case 9: total=total-31; month++; break;
			case 10: total=total-30; month++; break;
			case 11: total=total-31; month++; break;
		}
	}
	switch(month) {
		case 1: total=total+31; break;
		case 2: if ( ((year%4==0) && (year%100!=0)) || (year%400==0) ) total=total+29;
				  else total=total+28;
				  break;
		case 3: total=total+31; break;
		case 4: total=total+30; break;
		case 5: total=total+31; break;
		case 6: total=total+30; break;
		case 7: total=total+31; break;
		case 8: total=total+31; break;
		case 9: total=total+30; break;
		case 10: total=total+31; break;
		case 11: total=total+30; break;
		case 12: total=total+31; break;
	}

	total=total+1.0;
	day = total;
}

void main(int argc, char ** argv) {
	DYN_U_8 start;
	DYN_U_8 inc;
//	DYN_16 num = 256;
	char test[20];
	char data[193];
	char line[80];
   char dline[80];
	char stats[200];
	char outfilename[200];

	int i;
	int len=0;
	int count=0;
	float loc;
	FILE *infile, *outfile, *outenc, *outpyr;
	char ch;
	char stopchar;
	struct ffblk ffblk;
	unsigned curid;


	if (argc < 2)
   {
    	printf("Enter the path to a .pyr file.");
      printf("This will decrypt it to .dyr");
     	exit(-1);

   }

   if (argv[1] == "")
   {
     	printf("Enter the path to a .pyr file.");
      printf("This will decrypt it to .dyr");
    	exit(-1);
   }

	// outfilename= argv[1];

   strcpy(outfilename,argv[1]);

	if ((infile = fopen(outfilename, "rb")) == NULL) {
		printf("\nCould not locate the league file...");
		exit(-1);
	}

  	findfirst(argv[1],&ffblk,0);

	// if ((outfile = fopen("export.txt", "w")) == NULL) {
	// 	printf("\nCould write the export.txt file...");
	// 	exit(-1);
	// }
	// if ((dbgfile = fopen("debug.txt", "w")) == NULL) {
	// 	printf("\nCould write the debugtxt file...");
	// 	exit(-1);
	// }

   i = strlen(outfilename);
   outfilename[i-3] = 68;

   printf("outfilename: %s",outfilename);

	if ((outenc = fopen(outfilename, "wb")) == NULL) {
		printf("\nCould write the debugtxt file...");
		exit(-1);
	}


//	loc=784.0;
	fseek(infile, loc, 0);
	// printf ("first loc %d", loc);

	start = fgetc(infile); //784
	inc = fgetc(infile); //785
	loc = loc + 1.0;
	build(start, inc);

	

	// NOW GO BYTE BY BYTE AND DECRYPT IT


	loc=0;
	// ok do the first 192
	// Try 0,1 as the decryption

	data[0] = 0;
	data[1] = 1;
	data[2] = 0;
	data[3] = 1;


	// data up to 192 should be 0
	i = 3;
	while(i < 194)
	{
		i++ ;
		data[i] = 0;

	}
	fwrite (data , sizeof(data), 1, outpyr);
	// fwrite (data , 192, 1, outpyr);

	//create encrypted file
	// data[0]=start;
	// data[1]=inc;
	build(0, 1);
	encrypt (data,192);
	fwrite (data , sizeof(data), 1, outenc);

	fseek(infile, 193, 0);
	loc = 0;
	i = 0;
	while(loc< ffblk.ff_fsize - 383) {
		loc+=192.0;
		i++;
		len = 0;
		while (len<192) {
			ch = fgetc(infile);
			data[len] = ch;
			len++;
		}
		data[len] = 0;
		build(start, inc);
		decrypt(data, 191);
		// printf ("data len %d", len);


		// outpyr
		// write byte by byte ???
		// fwrite (data , 192, 1, outpyr);
		// printf ("loc %d \r\n", loc);

		// outenc
		build(0, 1);
		encrypt(data, 191);
		fwrite (data , 192, 1, outenc);

		if ((i > 99999))
		{
			loc = 1 + ffblk.ff_fsize;
		}
	}

	// close all the files
	fclose(infile);
	// fclose(outpyr);
	fclose(outenc);
   printf("\r\n Completed...");

}