# This will decrypt the pyr file

$DefaultFile = "D:\testing\trades\32nrb001.pyr"

$ASNFile = Read-host "Enter the path to PYR file [Default: $DefaultFile]"
if ($ASNFile -eq "")
{
	$ASNFile = $DefaultFile
}

if (test-path $ASNFile) {} Else { 
	"No file found:"
	exit 
}

#the outfile is .dyr, and delete it if it exists...
$outFIle = $ASNFile  -replace '\.pyr$',''
$outFIle = "$ASNFile.dyr"
if (test-path $outFIle)
{
	remove-item $OutFile -force
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

"START: $Start"
"OFFSET: $offset"

#Build Cryption Array

#Make blank array
$Cryption = @()
foreach ($x in (0..255))
{
	$Crypt.$x = -1 
}

#Use the variables to encrypt the array
$pos = 0 #$start
$val = $start

# this is "converted" from .cpp
foreach ($x in (0..255)){

	#check if Cryption at offset is not -1
	while ($Crypt.$pos -ne -1)
	{
#		"Increasing pos to $pos"
		$pos++
		$pos %= 256
	}
	
#	"setting $pos to $val"
	$Crypt.$pos = $val 
	
	#increment the value by 1
	$val++
	$val %= 256
	
	#increment the position by offset
	$pos +=  $offset
	$pos %= 256
}
#show the array
$Crypt | ft

#make the arrays for encrypting and decrypting
$EnCrypt = @{}
$DeCrypt = @{}
foreach ($x in (0..255)){
	$y = $x
	foreach ($z in (0..2) )
	{
		$y = $Crypt.$y
#		"$x -- $y "
	}
	$EnCrypt.$x = $y
	$DeCrypt.$y = $x
}

"DECRYPTING..." 

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
