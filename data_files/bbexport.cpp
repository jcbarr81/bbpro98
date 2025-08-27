#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include <dir.h>
#include "dyndefs.h"

/* injury codes:
 126 = strained rib cage muscles
 116 = broken hip
 113 = ruptures disc in the back
 112 = herniated disc in the back
 110 = sore back
 107 = fractured wrist
  95 = tight shoulder
  94 = sore shoulder
  91 = pinched ulnar nerve
  90 = torn rotator cuff
  85 = inflamed triceps
  78 = ruptured tricep tendon
  77 = inflamed tricep tendon
  74 = ruptured bicep tendon
  73 = inflamed bicep tendon
  66 = ruptured elbow ligament
  65 = inflamed elbow ligament
  54 = blistered finger
  51 = bone-chips in the elbow
  27 = broken nose
  24 = bloody nose
  17 = fractured jaw
 -58 = fractured toe
 -70 = strained hamstring
 -71 = pulled hamstring
 -81 = inflamed posterior cruciate ligament
 -90 = strained achilles tendon
-103 = stiff knee
-105 =
-108 = bruised heel
-111 = fractured foot
-112 = bruised foot
-115 = sprained ankle
-117 = broken ribs
*/

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
		if ( ((int(year)%4==0) & (int(year)%100!=0)) || (int(year)%400==0) ) total=total-366;
		else total=total-365;
		year++;
		if ( ((year%4==0) & (year%100!=0)) || (year%400==0) ) {
			if (total<366) break;
		}
		else if (total<365) break;
	}
	month=0;
	while (total>=0) {
		switch(month) {
			case 0: total=total-31; month++; break;
			case 1: if ( ((year%4==0) & (year%100!=0)) || (year%400==0) ) total=total-29;
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
		case 2: if ( ((year%4==0) & (year%100!=0)) || (year%400==0) ) total=total+29;
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

void main(void) {
	DYN_U_8 start;
	DYN_U_8 inc;
//	DYN_16 num = 256;
	char test[20];
	char data[25];
	char line[80];
	char stats[200];
	int i;
	int len=0;
	int count=0;
	float loc;
	FILE *infile, *outfile;
	char ch;
	char stopchar;
	struct ffblk ffblk;
	unsigned curid;

	if ((infile = fopen("assn\\28pat001.pyr", "rb")) == NULL) {
		printf("\nCould not locate the league file...");
		exit(-1);
	}
	if ((outfile = fopen("export.txt", "w")) == NULL) {
		printf("\nCould write the export.txt file...");
		exit(-1);
	}
	findfirst("assn\\28pat001.pyr",&ffblk,0);

//	loc=784.0;
	fseek(infile, loc, 0);
	start = fgetc(infile); //784
	inc = fgetc(infile); //785
	loc = loc + 1.0;
	build(start, inc);

	len=0;
	strcpy(line, "PID (0-1)");
	fputs(line, outfile);
	for (len=2; len<190; len++) {
		fputc(',', outfile);
//		if (len==1) strcpy(line, "Plusmod");
		switch (len) {
// 2 = innings pitched? team games played more likely
			case 23: strcpy(line, "DL Date");
						len+=3; break;
			case 26: strcpy(line, "BD (26-29)");
						len+=3; break;
			case 30: strcpy(line, "FIRST (30-45)");
						len+=15; break;
			case 46: strcpy(line, "LAST (46-61)");
						len+=15; break;
			case 62: strcpy(line, "Yrs"); break;
			case 63: strcpy(line, "Bats"); break;
			case 64: strcpy(line, "Throw"); break;
			case 65: strcpy(line, "Skin"); break;
			case 66: strcpy(line, "POS"); break;
			case 67: strcpy(line, "Del"); break;
			case 68: strcpy(line, "ch_p"); break;
			case 69: strcpy(line, "ph_p"); break;
			case 70: strcpy(line, "sp_p"); break;
			case 71: strcpy(line, "as_p"); break;
			case 72: strcpy(line, "hr_p"); break;
			case 73: strcpy(line, "en_p"); break;
			case 74: strcpy(line, "co_p"); break;
			case 75: strcpy(line, "fb_p"); break;
			case 76: strcpy(line, "cb_p"); break;
			case 77: strcpy(line, "si_p"); break;
			case 78: strcpy(line, "sl_p"); break;
			case 79: strcpy(line, "cu_p"); break;
			case 80: strcpy(line, "sc_p"); break;
			case 81: strcpy(line, "kn_p"); break;
			case 82: strcpy(line, "fa_p_p"); break;
			case 83: strcpy(line, "fa_c_p"); break;
			case 84: strcpy(line, "fa_1b_p"); break;
			case 85: strcpy(line, "fa_2b_p"); break;
			case 86: strcpy(line, "fa_3b_p"); break;
			case 87: strcpy(line, "fa_ss_p"); break;
			case 88: strcpy(line, "fa_lf_p"); break;
			case 89: strcpy(line, "fa_cf_p"); break;
			case 90: strcpy(line, "fa_rf_p"); break;

			case 91: strcpy(line, "ch_a"); break;
			case 92: strcpy(line, "ph_a"); break;
			case 93: strcpy(line, "sp_a"); break;
			case 94: strcpy(line, "as_a"); break;
			case 95: strcpy(line, "hr_a"); break;
			case 96: strcpy(line, "en_a"); break;
			case 97: strcpy(line, "co_a"); break;
			case 98: strcpy(line, "fb_a"); break;
			case 99: strcpy(line, "cb_a"); break;
			case 100: strcpy(line, "si_a"); break;
			case 101: strcpy(line, "sl_a"); break;
			case 102: strcpy(line, "cu_a"); break;
			case 103: strcpy(line, "sc_a"); break;
			case 104: strcpy(line, "kn_a"); break;
			case 105: strcpy(line, "fa_p_a"); break;
			case 106: strcpy(line, "fa_c_a"); break;
			case 107: strcpy(line, "fa_1b_a"); break;
			case 108: strcpy(line, "fa_2b_a"); break;
			case 109: strcpy(line, "fa_3b_a"); break;
			case 110: strcpy(line, "fa_ss_a"); break;
			case 111: strcpy(line, "fa_lf_a"); break;
			case 112: strcpy(line, "fa_cf_a"); break;
			case 113: strcpy(line, "fa_rf_a"); break;
			case 114: strcpy(line, "PULL"); break;
			case 115: strcpy(line, "GF_BAT"); break;
			case 118: strcpy(line, "GF_PIT"); break;
			case 119: strcpy(line, "VSL_BAT"); break;
			case 120: strcpy(line, "HOME"); break;
			case 121: strcpy(line, "SCPOS"); break;
			case 122: strcpy(line, "CL_BAT"); break;
			case 123: strcpy(line, "APR_BAT"); break;
			case 124: strcpy(line, "MAY_BAT"); break;
			case 125: strcpy(line, "JUN_BAT"); break;
			case 126: strcpy(line, "JUL_BAT"); break;
			case 127: strcpy(line, "AUG_BAT"); break;
			case 128: strcpy(line, "SEPO_BAT"); break;
			case 129: strcpy(line, "VSL_PIT"); break;
			case 130: strcpy(line, "HOME_PIT"); break;
			case 131: strcpy(line, "SCPOS_PIT"); break;
			case 132: strcpy(line, "CL_PIT"); break;
			case 133: strcpy(line, "APR_PIT"); break;
			case 134: strcpy(line, "MAY_PIT"); break;
			case 135: strcpy(line, "JUN_PIT"); break;
			case 136: strcpy(line, "JUL_PIT"); break;
			case 137: strcpy(line, "AUG_PIT"); break;
			case 138: strcpy(line, "SEPO_PIT"); break;
			case 139: strcpy(line, "RESTRUST"); break;
			case 140: strcpy(line, "START?"); break;
			case 142: strcpy(line, "INJ_PTS"); break;
			case 143: strcpy(line, "INJ_TYP"); break;
			case 144: strcpy(line, "INJ_SEV"); break;
//			case 145: strcpy(line, "INJ_SEV"); break;
			default: sprintf(line, "%d", len); break;
		}
		fputs(line, outfile);
	}
  fputc('\n', outfile);

//	loc=0.0;
	count=100;
	loc=192.0;
	fseek(infile, loc, 0);
	while(loc<ffblk.ff_fsize) {
		loc+=192.0;
//if (count>120) exit(-1);
		len = 0;
		while (len<2) {
			ch = fgetc(infile);
			data[len] = ch;
			len++;
		}
		data[len] = 0;
		decrypt(data, len);
		setid(&curid, data[0], data[1]);
		sprintf(line, "%d,", curid);
		fputs(line, outfile);

		for (len=0; len<24; len++) {
			data[0] = fgetc(infile);
			data[1] = 0;
			decrypt(data, 1);
			sprintf(line, "%d", data[0]);
			fputs(line, outfile);
			fputc(',', outfile);
		}

		len = 0;
		while (len<4) {
			ch = fgetc(infile);
			data[len] = ch;
			len++;
		}
		data[len] = 0;
		decrypt(data, len);
		getdate(data);
		sprintf(line, "%d/%d/%d,", month, day, year);
		fputs(line, outfile);

		len = 0;
		ch = fgetc(infile);
		while (len<16) {
			data[len] = ch;
			len++;
			ch = fgetc(infile);
		}
		data[len] = 0;
		decrypt(data, len);
		sprintf(line, "%s,", data);
		fputs(line, outfile);

		len=0;
		ch = fgetc(infile);
		while (len<16) {
			data[len] = ch;
			len++;
			ch = fgetc(infile);
		}
		data[len] = 0;
		decrypt(data, len);
		sprintf(line, "%s", data);
		fputs(line, outfile);

		for (len=0; len<128; len++) {
			fputc(',', outfile);
			data[0] = fgetc(infile);
			data[1] = 0;
			decrypt(data, 1);
			sprintf(line, "%d", data[0]);
			fputs(line, outfile);
//			fputc(data[0], outfile);
		}
		fputc('\n', outfile);
//		loc+=175.0;
//		fseek(infile, loc, 0);
		count++;
//		if (count>300) exit(-1);
	}
	fclose(infile);
	fclose(outfile);
}