# bbpro98
You will want to make a copy of your .ASN file before running any of these tools.
The tool will create a folder for the league file in the same folder where the script resides.

1. First you will want to run the Extractor (B). You will be asked the full path to the .ASN file that you want to make changes to. If you want, you can edit the $DefaultFile variable and point it to where you are going to keep that file, to make things easier.
2. The extractor will create a folder with the same name as your league. It will place CSV files inside that folder. There will be one for the entire league, as well as one for each team.
3. Make the needed changes to the CSV file and save it.
4. Next run the Importer (A). You will be asked for the full path to the CSV file that you want to import. Just like the other script, you can modify the default paths so that you don't  have to enter them every time.
5. The script will check the file and then inform you of how many changes have been made. If this does not match what you did, then cancel the script. If it matches up then confirm that you want to do the import.
6. A backup of your ASN file will be made with the current date appended to the file name. The new updated ASN file will be created in the same location as the original.
7. Copy that ASN file back to the appropriate BBPRO98 directory and ENJOY.
