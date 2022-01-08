# This will Extract parts of ASN
$erroractionpreference='inquire'

$ThePath = (Get-ChildItem $MyInvocation.MyCommand.Definition).DirectoryName

$DefaultFile = "D:\testing\identicals\3\32NEW001.ASN"
$DefaultFile = "D:\_DECRYPT\ASSN\28CAN001.ASN"
$DefaultFile = "D:\testing\trades\32nrb001.ASN"
$DefaultFile = "D:\testing\Assn\32nrb001-ASN.DEFAULT"
$DefaultCSV = "D:\testing\32nrb001-ASN-Roster-All.csv"
$DefaultCSV = "D:\testing\Roster-01.csv"
$DefaultCSV = "D:\testing\08NEW001\08NEW001-Roster-All.csv"
$DefaultFile = "D:\_SourceCode\ASSN\08AAA001.ASN"
$DefaultFile = "D:\testing\identicals\5\08NEW001.ASN"

$ASNFile = Read-host "Enter the path to ASN file [Default: $DefaultFile]"
if ($ASNFile -eq "")
{
	$ASNFile = $DefaultFile
}

$ASNFile = $ASNFile -replace '"',''

if (test-path $ASNFile) {} Else { 
	"No file found: $ASNFile"
	exit 
}

$LeagueName = (gi $ASNFile).basename

# now get the csv file to import-csv
""
"WARNING: You need to import the csv for the entire teams you are editing. " | write-host -fore "RED"
"WARNING: Do NOT exclude any rows. " | write-host -fore "RED"
"WARNING: This script needs to process all ACT/AAA/Order/DEF/etc. " | write-host -fore "RED"
"WARNING: Failing to import a proper csv file " | write-host -fore "RED"
"WARNING: WILL CORRUPT YOUR LEAGUE " | write-host -fore "RED"
""
$CsvFile = Read-host "Enter the path to csv file [Default: $DefaultCSV]"
if ($CsvFile -eq "")
{
	$CsvFile = $DefaultCSV
}
if (test-path $CsvFile) {} Else { 
	"No file found: $CsvFile"
	exit 
}

$CSVData = import-csv $CSVFile
$Header = @($CSVData | gm | ? {$_.membertype -eq 'NoteProperty'}).Name

#eventually add the other types as well
$ImportType = $null
$RosterHeader = @('TeamID','ABRE','Jersey','ACT','AAA','AAAType','Low','Limbo','boLH','boRH','defLH','defRH','Pit')
if ((compare -ReferenceObject $RosterHeader -DifferenceObject $Header) -eq $null)
{
	$ImportType = "Roster"
} 

"ImportType: $ImportType"
#make sure we have a csv we understand
if ($ImportType) {} else {
	"Unrecognized CSV"
	exit
}


#Backup the ASN file
$BackupASN = $ASNFile
$BackupASN = $BackupASN -replace '.asn','' 
$BackupASN = "$BackupASN.$(get-date -format 'yyyyMMdd')"
copy-item -path $ASNFile -destination $BackupASN


# LOAD FILE
$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
$newbytes  = [System.IO.File]::ReadAllBytes($ASNFile)
"FileSize: $($bytes.count)"



#ASN offset is here
$EByte = 0x310
$EncStart = 1*$bytes[$EByte]
$EncOffset = 1*$bytes[$EByte + 1]
"Encryption keys: $EncStart & $EncOffset" | write-host -fore "YELLOW"

$pos = 0 #$start
$val = $EncStart
#Make blank array
$Crypt=$null
$Crypt=@{}
$x = $null
foreach ($x in (0..255))
{
	$Crypt[$x] = -1 
}

"Making Decryption/Encryption Arrays"
# MAKE THE ENCRYPTION ARRAYS
# this is "converted" from .cpp
#while (($Crypt.getenumerator() | ? {$_.value -eq -1 }).count -gt  0 )
foreach ($x in (0..255))
{
	#"X: $x"
	#check if Cryption at offset is not -1
	while ($Crypt[$pos] -ne -1)
	{
		#"Increasing pos to $pos"
		$pos++
		$pos %= 256
	}
	
	#"setting $pos to $val"
	$Crypt[$pos] = $val 
	
	#increment the value by 1
	$val++
	$val %= 256
	
	#increment the position by offset
	$pos +=  $EncOffset
	$pos %= 256
}
#show the array
#$Crypt | ft
#$Crypt.getenumerator() | sort name
#exit
#make the arrays for encrypting and decrypting
$x= $null
$y = $null
$EnCrypt = @{}
$DeCrypt = @{}
foreach ($x in (0..255)){
	$y = 1*$x
	foreach ($z in (0..2) )
	{
		#"$x -- $y "
		$y = $Crypt[$y]
	}
	$EnCrypt[$x] = $y
	$DeCrypt[$y] = $x
}

# The ASN file is in sections...
"Finding all sections..."
$AllSections
$Offsets = @()
$offset = 0x200 +2
$length = $($bytes[$offset])

$Offsets += "" | select  @{name="offset";expression={$Offset}},  @{name="length";expression={$length}}

#x is a failsafe...
$x = 0
$Teams = @()
#$NumofSections = 0
do {
	#$NumofSections++
	$offset +=  1*$length
	#"NumofSections: $NumofSections"
	$length= $Null
	#$length = $bytes[$offset ] + 256*$bytes[$offset +1  ]
	$length = $bytes[$offset ] + 256*$bytes[$offset +1  ]
	
	if ($length -eq 0){
		"Completed" | write-host -fore "GREEN"
	} else {
	
	if ($x % 20 -eq 0)
	{
		"." | write-host -NoNewline
	}
	#"This offset: $offset -- $('{0:x}' -f $offset)" | write-host -fore "YELLOW"
	#"This length: $length -- $('{0:x}' -f $length)" | write-host -fore "cyan"

	#The two bytes after are identical & over 250, 
	# I'm not sure why, but figured this would be a good check
	$Check1 = $($bytes[$offset -1 ])
	$Check2 = $($bytes[$offset -2 ])
	#"CHECKS: $Check2 - $Check1 "
	
	$Offsets += "" | select  @{name="offset";expression={$Offset}},  @{name="length";expression={$length}}
	
	if (($Check1 -ne $check2) -or ($Check1 + $Check2 -lt 500))
	{
		"Check FAIL" 
		break
	}

	#$lastValue = $length
	
	
	# Show Value
	#"Value: $b"
	#"Offset: $offset -- $('{0:x}' -f $offset)"
	#""
	}
	$x++
} while (($length -gt 0) -and ($x -lt 99999) -and ($offset -lt $bytes.count))
""

#####################################################################
# OK SO HERE WE NEED TO FIGURE OUT WHAT TYPE OF CSV WE ARE PROCESSING
#####################################################################
# EVERYTHING GOES INTO $newbytes

$Changes = 0 
if ($ImportType -eq "Roster")
{
	# IMPORT THE ROSTER
	
	#find out what team(s) are needed
	$TeamsToProcess = ($CSVData | select TeamID -unique).TeamID
	#$TeamsToProcess | % {$_ = 1*$_} #| sort
	"TeamsToProcess: $TeamsToProcess"
	
	#Get the offsets for the team(s) data
	foreach ($TeamID in $TeamsToProcess)
	{
		$offset = (($offsets | ? {$_.length -eq 312})[1*$TeamID -1]).offset
		"TeamID: $TeamID -- $offset "
		
		$TeamData = $null
		$TeamData = $CsvData | ? {$_.TeamID -eq $TeamID}
		#@($TeamData.jersey) | ? {$_}
		
		# first jerseys
		$offset = 1*$offset + 17
		foreach ($d in @($TeamData.jersey) | ? {$_})
		{
			$offset++
			$curval = 1*$DeCrypt[1*$newbytes[$offset]]
			#"JERSEY d: $d-- $($EnCrypt[1*$d]) -- $($newbytes[$offset])"
			if ($d -ne $curval)
			{
				"Jersey: $d -- ($offset)" | write-host -fore "YELLOW"
				$Changes++
				$newbytes[$offset]=$EnCrypt[1*$d] 
			} else {
				
			}
		}

		#$offset++
		foreach ($d in @($TeamData.ACT) | ? {$_})
		{
			$offset++
			#Convert to 2 digit bytes
			#$d
			$curval = 1*$DeCrypt[1*$newbytes[$offset]]  + 256*$DeCrypt[1*$newbytes[$offset+1]]

			#"ACT D: $d --  $curval"
			
			if ($d -ne $curval)
			{
				$Changes++
				#split $d into two
				$d1 = $d % 256
				$d2 = [int]($d / 256)
				
				#"ACT1: $($bytes[$offset]) -- $offset"
				"ACT1: $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
				$newbytes[$offset]=$EnCrypt[1*$d1]
				$offset++ 				

				#"ACT2: $($bytes[$offset]) -- $offset"
				"& ACT2: $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
				$newbytes[$offset]=$EnCrypt[1*$d2] 
				
			} else {
				$offset++
			}
		}
		
		#$offset++
		foreach ($row in $TeamData | ? {$_.AAA})
		{
			foreach ($d in @($row.AAA,$row.AAAType))
			{			
				
				$offset++
				#Convert to 2 digit bytes
				
				$curval = 1*$DeCrypt[1*$newbytes[$offset]]  + 256*$DeCrypt[1*$newbytes[$offset+1]]

			#	"AAA D: $d --  $curval"
				
				if ($d -ne $curval)
				{
					$Changes++
					#split $d into two
					$d1 = $d % 256
					$d2 = [int]($d / 256)
					
				
					#"AAA1: $($bytes[$offset]) -- $offset"
					"AAA1: $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
					$newbytes[$offset]=$EnCrypt[1*$d1]
					$offset++ 				

					#"AAA2: $($bytes[$offset]) -- $offset"
					"& AAA2: $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
					$newbytes[$offset]=$EnCrypt[1*$d2] 
					
				} else {
					$offset++
				}
			}
		}
		
		#$offset++
		foreach ($cat in @("Low","Limbo","boLH","boRH","defLH","defRH","Pit"))
		{
			foreach ($d in @($TeamData."$cat") | ? {$_})
			{
				$offset++
				#Convert to 2 digit bytes
				#$d
				$curval = 1*$DeCrypt[1*$newbytes[$offset]]  + 256*$DeCrypt[1*$newbytes[$offset+1]]

				#"$cat D: $d --  $curval"
				
				if ($d -ne $curval)
				{
					$Changes++
					#split $d into two
					$d1 = $d % 256
					$d2 = [int]($d / 256)

					#"$cat 1: $($bytes[$offset]) -- $offset"
					"$cat 1: $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
					
					$newbytes[$offset]=$EnCrypt[1*$d1]
					$offset++ 				

					#"$cat 2: $($bytes[$offset]) -- $offset"
					"& $cat 2: $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
					$newbytes[$offset]=$EnCrypt[1*$d2] 
					
				} else {
					$offset++
				}
			}
		}

		
	}
}	


"Number of Changes: $Changes"
$TotalBytesChanged = (compare -ReferenceObject $newbytes -DifferenceObject $bytes).count
"TotalBytesChanged: $TotalBytesChanged "

$YesNo = read-host "Do you want to overwrite $ASNFile? (y/N)"
if ($YesNo -notmatch '^y')
{
	"CANCELLED" | write-host -fore "RED"
	exit
}

#write the file
[System.IO.File]::WriteAllBytes($ASNFile,$newbytes)
$ASNFile | write-host -fore "RED"
exit

exit

#length of 312 is the team roster sections
# decrypt and extract those into csv?
$Decrypted = @()

$ASCII = [System.Text.Encoding]::ASCII


# this is team info 
$TeamInfo = @()
$TeamInfo += "TeamID,City,Manager,Abre,Stadium"

foreach ($o in ($Offsets | ? {$_.Length -eq 274 } | select -skip 1))
{
	#$o | select * 

	#get the section
	"Offset: $($o.offset)"
	#"Length: $($o.length)"
	#Team ID = 16 bytes
	$TeamID = $bytes[(16 + $o.offset)]
	"TeamID : $TeamID " | write-host -fore "GREEN"

	$section = $bytes[(17 +  $o.offset)..($o.offset + 271)]
	($section | select -first 20) -join " - "  | write-host -fore "YELLOW"

	$dSection = @()
	foreach ($s in $section)
	{
		#"s: $s"
		$dSection += $DeCrypt[1*$s]
	}	
	#$dSection | select -first 30
	($dSection | select -first 50) -join " - "  | write-host -fore "CYAN"

	# 18 bytes in is the city
	$dSection[17..50] -join " - "  | write-host -fore "MAGENTA"

	# you need to stop at the first 0...
	$City = [System.Text.Encoding]::ASCII.GetString($dSection[17..50])
	$Manager = [System.Text.Encoding]::ASCII.GetString($dSection[51..67])
	$ABRE = [System.Text.Encoding]::ASCII.GetString($dSection[68..81])
	$Stadium = [System.Text.Encoding]::ASCII.GetString($dSection[82..114])
	
	$City = ($City -split [char]0)[0]
	$Manager = ($Manager -split [char]0)[0]
	$ABRE = ($ABRE -split [char]0)[0]
	$Stadium = ($Stadium -split [char]0)[0]
	
	$TeamInfo += "$TeamID,$City,$Manager,$Abre,$Stadium"
	
	#$CITYH = [System.Text.Encoding]::ASCII.GetString($dSection[115..123])
	#"$City - $ABRE - $Manager - $Stadium - $CITYH" #-join " - "  |	write-host -fore "MAGENTA"
	# PROBABLY COLORS AFTER CITYH
	#exit
	
}
""
$TeamInfo = $TeamInfo | convertfrom-csv 
$TeamInfo | ft

$OutputFileName = "$ThePath\$LeagueName-Team-Info.csv"
$TeamInfo | Export-Csv -Path $OutputFileName -Force -notype


# This is rosters
$TeamID = 0
$AllRosters = @()
foreach ($o in $offsets | ? {$_.length -eq 312})
{
	$TeamID++ 
	#get the section
	"Offset: $($o.offset)"
	"Length: $($o.length)"
	
	$section = $bytes[(17 + $o.offset)..($o.offset + 309)]
	"Length: $($section.length)" #= $bytes[(17 + $o.offset)..($o.offset + 309)]
	#$section | select -first 20
	""
	$cols = 13
	$data = $null
	$data = @()
	$data += (0..$cols) -join ','
	(1..75) | % {$data += ((0..$cols) | %{","} )-join ''}

	$data = convertfrom-csv $data

	#$data | ft * -autosize

	$x = 0
	$row = 0
	$col = 2
	#Jersey
	1..40 | % {
		$x++
		$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]
		$row++
	}
	#$data | ft
	
	#ACT
	$row = 0 
	$col += 1
	1..25 | % {
		$x++
		$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
		$row++
		$x++
	}

	#AAA/DL
	#$row = 0 
	$col += 1
	$col2 = $col + 1
	1..15 | % {
		$x++
		$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
		$data[$row]."$col2" = 1*$DeCrypt[1*$section[$x+2]]  + 256*$DeCrypt[1*$section[$x+3]]
		$row++
		$x += 3
	}
	
	#LOW
	#$row = 0 
	$col += 1
	$col += 1
	1..10 | % {
		$x++
		$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
		$row++
		$x++
	}

	#Limbo
	#$row = 0 
	$col += 1
	1..12 | % {
		$x++
		$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
		$row++
		$x++
	}

	#boLHRH + def
	1..4 | % {
		$row = 62
		$col += 1
		1..9 | % {
			$x++
			$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
			$row++
			$x++
		}
	}

	#Pit
	$row = 62
	$col += 1
	1..13 | % {
		$x++
		$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
		$row++
		$x++
	}

	#put the teamid in row
	$Abre = ($TeamInfo | ? {$_.TeamID -eq $TeamID}).Abre 
	0..($row-1) | % { 
		$data[$_]."0" = 1*$TeamId
		$data[$_]."1" = $Abre
		
	}

	#$data | ft * -autosize

	$OutputFileName = "$ThePath\Roster-" +  ("{0:D2}" -f $TeamID) + ".csv"
	
	$data | Export-Csv -Path $OutputFileName -Force -notype
	#fix headers
	$data = import-csv -Path $OutputFileName -Header @('TeamID','ABRE','Jersey','ACT','AAA','AAAType','Low','Limbo','boLH','boRH','defLH','defRH','Pit') | select * -skip 1 #|#| select * | Export-Csv -Path $OutputFileName -Force -notype


	$AllRosters += $data
	$data | Export-Csv -Path $OutputFileName -Force -notype # -Delimiter "`t"
	
	#$data = $null
	$OutputFileName | write-host -fore "RED"

}	

# compile all 
$AllRosters	|  Export-Csv -Path "$ThePath\$LeagueName-Roster-All.csv" -Force -notype 
"$ThePath\$LeagueName-Roster-All.csv" | write-host -fore "RED"