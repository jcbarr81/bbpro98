# This will export the pyr file
# converting date (get-date(1)).adddays(723507 -366)
# getting birthday

$erroractionpreference='inquire'
$ThePath = (Get-ChildItem $MyInvocation.MyCommand.Definition).DirectoryName


$DefaultFile = "D:\testing\trades\32nrb001.pyr"
$DefaultCSV = "D:\testing\32nrb001\32nrb001-Players.csv"

$ASNFile = Read-host "Enter the path to ASN file [Default: $DefaultFile]"
if ($ASNFile -eq "")
{
	$ASNFile = $DefaultFile
}

$ASNFile = $ASNFile -replace '"',''

if (test-path $ASNFile) {} Else { 
	"No file found:"
	exit 
}

$LeagueName = (gi $ASNFile).basename
if (test-path "$ThePath\$LeagueName") {} else {
	mkdir "$ThePath\$LeagueName"
}


""
"WARNING: You need to import the csv for the players you are editing. " | write-host -fore "RED"
"WARNING: Do NOT exclude any COLUMNS. " | write-host -fore "RED"
"WARNING: Failing to import a proper csv file " | write-host -fore "RED"
"WARNING: WILL CORRUPT YOUR LEAGUE " | write-host -fore "RED"
""
$CsvFile = Read-host "Enter the path to csv file [Default: $DefaultCSV]"

if ($CsvFile -eq "")
{
	$CsvFile = $DefaultCSV
}
#gci $CSVFile


if (test-path $CsvFile) {} Else { 
	"No file found: $CsvFile"
	exit 
}



# LOAD FILE
$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
$newbytes  = [System.IO.File]::ReadAllBytes($ASNFile)
$FileSize = $($bytes.count)
"FileSize: $($bytes.count)"

# get start + offset
# Each file is encrypted with these two bytes

$Start = 1*$bytes[0]
$offset = 1*$bytes[1]

"Encryption $Start / $offset"

#Build Cryption Array

#Make blank array
$Crypt = @{}
foreach ($x in (0..255))
{
	$Crypt[$x] = -1 
}

#Use the variables to encrypt the array
$pos = 0 #$start
$val = $start

# this is "converted" from .cpp
foreach ($x in (0..255)){

	#check if Cryption at offset is not -1
	while ($Crypt[$pos] -ne -1)
	{
#		"Increasing pos to $pos"
		$pos++
		$pos %= 256
	}
	
#	"setting $pos to $val"
	$Crypt[$pos] = $val 
	
	#increment the value by 1
	$val++
	$val %= 256
	
	#increment the position by offset
	$pos +=  $offset
	$pos %= 256
}
#show the array
# $Crypt | ft

#make the arrays for encrypting and decrypting
$EnCrypt = @{}
$DeCrypt = @{}
foreach ($x in (0..255)){
	$y = $x
	foreach ($z in (0..2) )
	{
		$y = $Crypt[$y]
#		"$x -- $y "
	}
	$EnCrypt[$x] = $y
	$DeCrypt[$y] = $x
}


$header = @(1..144) #-join ","

$CSVData = import-csv $CSVFile -header $header | select -skip 1
$CSVData = $CSVData | select -first 3 

#GET ALL PLAYERIDs
$PlayerIDs = $CSVData | select "1" | % { $_."1"}
#"PlayerIDs"
#$PlayerIDs   | select -first 2 

$offset = 192
$IDoffset = @()
$IDOffset += "PlayerID,Offset"
while ($offset -lt ($FileSize - 1))
{
	#$offset
	#$Data = @()
	$PlayerID = 1*$DeCrypt[1*$bytes[$offset]]  + 256*$DeCrypt[1*$bytes[$offset+1]]
	#$TempIO += "" | select PlayerID,Offset 
	$IDoffset += "$PlayerID,$offset"
	$offset += 192
}	
$IDOffset = convertfrom-csv $IDOffset
#$IDOffset | select * -first 10 | ft

#foreach ($PlayerID in $PLAYERIDs)
foreach ($x in (0..($CSVData.count - 1))  )
{
	$PlayerID= $PLAYERIDs[$x]
	$Data= $CsvData[$x]
	$offset = $null
	$offset = 1*($IDOffset | ? {$_.PlayerID -eq $PlayerID}).offset
	if ($offset)
	{
		"$PlayerID -- $($data.15) $($data.16) ($offset)"
		#$data 
		#add 2 because the ID is already there.
		$offset++
		foreach ($y in (2..13))
		{
			$offset++
			#Two digit 
			$d = [System.BitConverter]::GetBytes(1*$data.$y)

			#encrypt it to 2 bytes
			$d1 = $d[0]
			$d2 = $d[1]
			
			#"AAA1: $($bytes[$offset]) -- $offset"
			#"$offset - $y - $(1*$data.$y) -- $($bytes[$offset])=$($EnCrypt[1*$d1])"| write-host -fore "CYAN"
			
			#"$d : $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
			$newbytes[$offset]=$EnCrypt[1*$d1]
			$offset++ 				

			#"AAA2: $($bytes[$offset]) -- $offset"
			#"$offset -- $($bytes[$offset])=$($EnCrypt[1*$d2])" | write-host -fore "YELLOW"
			#"  : $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
			$newbytes[$offset]=$EnCrypt[1*$d2] 		
			
		}
		
		#DOB is 4 digits
		$y = 14
		#1*$data.$y
		[System.BitConverter]::GetBytes(1*$data.$y) | % {
			$offset++ 
			#"$offset -- $($bytes[$offset]) -- $($EnCrypt[1*$_])" | write-host -fore "MAGENTA"
			$newbytes[$offset]=$EnCrypt[1*$_]
		}
		
		
		#NAME
		foreach ($y in (15..16))
		{
			$temptext = $data.$y
			#"tt: $temptext"
			$temptext += [char]0
			$temptext += "                     "
			$temptext = $temptext.substring(0,17)
			#"tt: >$temptext<"
			#$temptext.length
			$textbytes = [system.Text.Encoding]::ASCII.GetBytes($temptext)	
			$textbytes | % { 
				$offset++ 
				#"$offset -- $($bytes[$offset]) -- $($EnCrypt[1*$_])"
				$newbytes[$offset]=$EnCrypt[1*$_]
			}
		}
		#| select * | ft
		
	
		foreach ($y in (17..144))
		{
			$offset++
			#One digit 
			$d1 = 1*$data.$y

			#"AAA1: $($bytes[$offset]) -- $offset"
			#"$offset - $y - $(1*$data.$y) -- $($bytes[$offset])=$($EnCrypt[1*$d1])"| write-host -fore "CYAN"
			
			#"$d : $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
			$newbytes[$offset]=$EnCrypt[1*$d1]

		}
	
		

		
	} else {
		"CAN'T FIND OFFSET FOR $PLAYERID"  | write-host -fore "RED"
		exit
	}
}

$TotalBytesChanged = (compare -ReferenceObject $newbytes -DifferenceObject $bytes).count
"TotalBytesChanged: $TotalBytesChanged "


exit


exit

foreach ($line in $CSVData)
{
	$line[0]
	$line[1]
	exit
}
exit


"DECRYPTING..." 
#start at 192
$PlayerData= [System.Collections.ArrayList]@()
$Header = @()
$Header += "ID"
1..9 | % {$Header += "Gat$_"}
$Header += "TotG"
$Header += "INJ1"
$Header += "INJ2"
$Header += "DOB"
$Header += "FirstName"
$Header += "LastName"
$Header += "Years"
$Header += "Bat"
$Header += "Throw"
$Header += "Skin"
$Header += "Pos"
$Header += "Delivery"
#ratings pot
"ch ph sp as hr en co fb cb si sl cu sc kn" -split " " | %{
	$Header += "$_-p"
}
1..9 | % {$Header += "fa$_-p"}

#ratings act
"ch ph sp as hr en co fb cb si sl cu sc kn" -split " " | %{
	$Header += "$_-a"
}
1..9 | % {$Header += "fa$_-a"}

"pl gf ve lo pgf" -split " " | %{
	$Header += "mod-$_"
}
0..9 | % {$Header += "hitmod$_"}
0..9 | % {$Header += "pitmod$_"}



#$Header 
($Header.count)..143 | % {$Header += "Un$_" }

$PlayerData.Add($Header -join ',')

"Parsing Player Ratings/Data"
$offset = 192
while ($offset -lt ($FileSize - 1))
{
	#$offset
	$Data = @()
	1..13 | % {
		$Data += 1*$DeCrypt[1*$bytes[$offset]]  + 256*$DeCrypt[1*$bytes[$offset+1]]
		$offset += 2
	}
	1..1 | % {
			$Data += 1*$DeCrypt[1*$bytes[$offset]]  + 256*$DeCrypt[1*$bytes[$offset+1]] + 256*256*$DeCrypt[1*$bytes[$offset+2]] + 256*256*256*$DeCrypt[1*$bytes[$offset+3]]
			$offset += 4
	}
	
	1..2 | % {
		$text = ""
		1..17 | % {
		
			$text += [System.Text.Encoding]::ASCII.GetString($DeCrypt[1*$bytes[$offset]])
			$Offset++	#
		}
		$text = ($text -split [char]0)[0]
		$Data += $text
	}
	1..128 | % {
		$Data += 1*$DeCrypt[1*$bytes[$offset]]  #+ 256*$DeCrypt[1*$bytes[$offset+1]]
		$offset += 1
	}
	
	if ((1*$data[0] % 25) -eq 0) { $data[0] }
	
	#$PlayerData+= $data
	$null = $PlayerData.Add($data -join ",")
	
}

#$PlayerData | ft *

$PlayerCSV = convertfrom-csv $PlayerData
$PlayerCSV | select -first 2 | ft * -auto
$PlayerCSV | export-csv $outFIle -notype
$outFIle | write-host -fore "RED"

exit
####################################################
####################################################
##########################
##########################
##########################
##########################
####################################################
####################################################
####################################################
#the first four bytes should be this for an decrypted array
$newbytes[0] = 0
$newbytes[1] = 1
$newbytes[2] = 0
$newbytes[3] = 1

#everything up to 191 should be 0
foreach ($x in (4..(192)))
{
	$newbytes[$x] = 0
}

#decrypt everything from 192 to the last byte
foreach ($x in (192..($FileSize - 1)))
{
	$b = 1* $bytes[$x]
	$y = $DeCrypt[$b]
	#"$b -- $y "
	$newbytes[$x] = $y
}

# WRITE THE FILE
[System.IO.File]::WriteAllBytes($outFile, $newbytes)

# show what the outfile is...
$outFile | write-host -fore 'RED'
exit
""
" check 0"
""
$b = 0 # $bytes[$x]
$y = $b
foreach ($z in (0..255) )
{
	$y = $DeCrypt[$y]
	"$b -- $y "
	if ($y -eq 14) { 
		"Z: $z"
		exit
	}
}
"Z: $z"



exit


#do 
#(
	
	$TC = "" | select in,out
	#$TC = "" | select {n='in';e={$offset}
	#$Cryption[$start]=$offset
#) until ($Cryption.count -gt 10)
#) until ($Cryption.count -gt 10)
$Cryption | select *

exit
#Start at 0x202 - not sure how to find this...
# one idea  - look for a bunch of FF FF FF and then go 2 after ???
$offset = 0x200 +2
$b = $($bytes[$offset])
"VALUE0: $($b)"
"Offset0: $offset -- $('{0:x}' -f $offset)"



#x is a failsafe...
$x = 0
$Teams = @()
$NumofSections = 0
do {
	$NumofSections++
	$offset +=  1*$b
	"NumofSections: $NumofSections"
	"This offset: $offset -- $('{0:x}' -f $offset)" | write-host -fore "YELLOW"
	$b= $Null
	$b = $bytes[$offset ] + 256*$bytes[$offset +1  ]

	#The two bytes after are identical & over 250, 
	# I'm not sure why, but figured this would be a good check
	$Check1 = $($bytes[$offset -1 ])
	$Check2 = $($bytes[$offset -2 ])
	"CHECKS: $Check2 - $Check1 "
	
	if (($Check1 -ne $check2) -or ($Check1 + $Check2 -lt 500))
	{
		"Check FAIL" 
		break
	}

	$lastValue = $b 
	
	
	# Show Value
	"Value: $b"
	"Offset: $offset -- $('{0:x}' -f $offset)"
	""

	#Are we in team 1?
	#a0fa
	if ($offset -gt 0x783c)
	{
		"Found Team 1"
		#sleep 5
		$Teams += $NumofSections
	}
	
	if ($offset -gt 0xa0fa)
	{
		"Found Team 32"
		$Teams 
		exit
	}


	$x++
} while (($x -lt 99999) -or ($offset -lt $bytes.count))
"NumofSections: $NumofSections"
# someday
# [System.IO.File]::WriteAllBytes("C:\NewFile.exe", $bytes)