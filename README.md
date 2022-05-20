# bbpro98
You will want to make a copy of your .ASN file before running any of these tools.
The tool will create a folder for the league file in the same folder where the script resides.

# Export Rosters/Lineups/Rotations and Re-import
1. First you will want to run the ASN-Extractor-B.ps1. You will be asked the full path to the .ASN file that you want to make changes to. If you want, you can edit the $DefaultFile variable and point it to where you are going to keep that file, to make things easier.
2. The extractor will create a folder with the same name as your league. It will place CSV files inside that folder. There will be one for the entire league, as well as one for each team.
3. Make the needed changes to the CSV file and save it.
4. Next run the ASN-Importer-A.ps1. You will be asked for the full path to the CSV file that you want to import. Just like the other script, you can modify the default paths so that you don't  have to enter them every time.
5. The script will check the file and then inform you of how many changes have been made. If this does not match what you did, then cancel the script. If it matches up then confirm that you want to do the import.
6. A backup of your ASN file will be made with the current date appended to the file name. The new updated ASN file will be created in the same location as the original.
7. Copy that ASN file back to the appropriate BBPRO98 directory and ENJOY.

# Editing Players
1. Run the Export-pyr-A.ps1 script and input the full path to the PYR file that you want to decode.
2. The script will place a CSV file with all the player information in a folder named the same as your league. This folder will be placed in the folder where the script resides.
3. Make any changes that you wish to the player file and save. Keep it in the CSV format.
4. Run Import-pyr-A.ps1. Input the path to the PYR file that you are modifying. Input the path to the CSV that you have made changes to.
5. Once import is complete, copy the PYR file back to the appropriate BBPRO98 directory and ENJOY.
