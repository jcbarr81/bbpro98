$erroractionpreference = 'inquire'
# THIS WILL GIVE YOU A BUNCH OF FUNCTIONS TO USE WITH BBPRO98
# . source this to add these functions to your script

#######################
# get the decrytpion array 
#######################
Function Get-BBDecrypt {
	param( $EncStart, $EncOffset )

	$pos = 0 #$start
	$val = 1*$EncStart
	#Make blank array
	$Crypt=$null
	$Crypt=@{}
	$x = $null
	foreach ($x in (0..255))
	{
		$Crypt[$x] = -1 
	}

	#"Making Decryption Array"
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
		$pos +=  1*$EncOffset
		$pos %= 256
	}

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
		#$EnCrypt[$x] = $y
		$DeCrypt[$y] = $x
	}

	return $DeCrypt
}


#######################
# get the encrytpion array 
#######################
Function Get-BBEncrypt {
	param(	[int]$EncStart, [int]$EncOffset )

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

	#"Making Decryption Array"
	# MAKE THE ENCRYPTION ARRAYS
	# this is "converted" from .cpp
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
		#$DeCrypt[$y] = $x
	}

	return $EnCrypt
}



##############################
# This will get the roster data
# from the ASN file
##############################
Function Get-ASNRoster {
	param( [string]$ASNFile )
	
	# LOAD FILE
	$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
	#"FileSize: $($bytes.count)"


	#ASN offset is here
	$EByte = 0x310
	$EncStart = 1*$bytes[$EByte]
	$EncOffset = 1*$bytes[$EByte + 1]

	$Decrypt = Get-BBDecrypt -EncStart $EncStart  -EncOffset $EncOffset
	
	# The ASN file is in sections...
	#"Finding all sections..."
	$Offsets = @()
	$offset = 0x200 +2
	$length = $($bytes[$offset])

	$Offsets += "" | select  @{name="offset";expression={$Offset}},  @{name="length";expression={$length}}

	#x is a failsafe...
	$x = 0
	$Teams = @()
	do {
		$offset +=  1*$length
		$length= $Null
		$length = $bytes[$offset ] + 256*$bytes[$offset +1  ]
		
		if ($length -eq 0){
			#"Completed" | write-host -fore "GREEN"
		} else {
			$Offsets += "" | select  @{name="offset";expression={$Offset}},  @{name="length";expression={$length}}
		}
		$x++
	} while (($length -gt 0) -and ($x -lt 99999) -and ($offset -lt $bytes.count))

	##############
	# This is rosters
	$TeamID = 0
	$AllRosters = @()
	foreach ($o in $offsets | ? {$_.length -eq 312})
	{
		$TeamID++ 
		#get the section
		$section = $bytes[(17 + $o.offset)..($o.offset + 309)]

		#for the return data
		$cols = 13
		$data = $null
		$data = @()
		$data += (0..$cols) -join ','
		(1..75) | % {$data += ((0..$cols) | %{","} )-join ''}

		$data = convertfrom-csv $data

		$x = 0
		$row = 0
		$col = 2

		#Jersey
		1..40 | % {
			$x++
			$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]
			$row++
		}
		
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
		$col += 1
		$col += 1
		1..10 | % {
			$x++
			$data[$row]."$col" = 1*$DeCrypt[1*$section[$x]]  + 256*$DeCrypt[1*$section[$x+1]]
			$row++
			$x++
		}

		#Limbo
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
		0..($row-1) | % { 
			$data[$_]."0" = 1*$TeamId
			$data[$_]."1" = $TeamId*100 + 1*$_
			
		}

		$AllRosters += $data

	}	

	$AllRosters = $AllRosters | select @{n='TeamID';E={$_.0}}, 
		@{n='Row' ;E={$_.1}},
		@{n='Jersey';E={$_.2}},
		@{n='ACT';E={$_.3}},
		@{n='AAA';E={$_.4}},
		@{n='AAAType';E={$_.5}},
		@{n='Low';E={$_.6}},
		@{n='Limbo';E={$_.7}},
		@{n='boLH';E={$_.8}},
		@{n='boRH';E={$_.9}},
		@{n='defLH';E={$_.10}},
		@{n='defRH';E={$_.11}},
		@{n='Pit';E={$_.12}} #,
		
		
	return ($AllRosters | select * )
	
}


Function Set-ASNRoster {
	param( [string]$ASNFile,$ASNData  )

	#backup the file
	$ASNFolder = (gci $ASNFile).DirectoryName
	$ASNBaseName = (gci $ASNFile).BaseName
		
	$aReturn = @()
		
	$x= -1 
	$BackupName = $null
	do {
		$x++
		$TestName = $ASNFolder + '\' + $ASNBaseName + "-ASN.$('{0:d3}' -f $x)"
		if (test-path $TestName) { } else {
			$BackupName = $TestName
		}	
		
	} until ($BackupName)
	
	$aReturn += "BackupName = $BackupName"
	#
	copy $ASNFile $BackupName
	
	# LOAD FILE
	# twice (newbytes)
	$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
	$newbytes  = [System.IO.File]::ReadAllBytes($ASNFile)

	#Find the offsets
	#ASN offset is here
	$EByte = 0x310
	$EncStart = 1*$bytes[$EByte]
	$EncOffset = 1*$bytes[$EByte + 1]

	$Decrypt = Get-BBDecrypt -EncStart $EncStart  -EncOffset $EncOffset
	$Encrypt = Get-BBEncrypt -EncStart $EncStart  -EncOffset $EncOffset
	
	$aReturn += "Encrypt0 = $($Encrypt[0])"
	
	# The ASN file is in sections...
	#"Finding all sections..."
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
		
		$Offsets += "" | select  @{name="offset";expression={$Offset}},  @{name="length";expression={$length}}

		$x++
	} while (($length -gt 0) -and ($x -lt 99999) -and ($offset -lt $bytes.count))
	#""


	# for each team incoming...
	# do the stuff
	
	#######################################################
	# IMPORT THE ROSTER
	
	#find out what team(s) are needed
	$TeamsToProcess = $null
	$TeamsToProcess = ($ASNData | select TeamID -unique).TeamID
	if ($TeamsToProcess) 
	{
		#Get the offsets for the team(s) data
		$Changes = 0
		foreach ($TeamID in $TeamsToProcess)
		{
			$offset = (($offsets | ? {$_.length -eq 312})[1*$TeamID -1]).offset
			#"TeamID: $TeamID -- $offset "
			
			$TeamData = $null
			$TeamData = $ASNData | ? {$_.TeamID -eq $TeamID}
			#@($TeamData.jersey) | ? {$_}
			
			# first jerseys
			$offset = 1*$offset + 17
			#$aReturn += "offset_$TeamID = $offset"

			$Jerseys = @(($TeamData | sort row).jersey | ? {$_  -match '[0-9]'} )
			foreach ($d in $Jerseys)
			{
				$offset++

				$curval = 1*$DeCrypt[1*$bytes[$offset]]
				#"JERSEY d: $d-- $($EnCrypt[1*$d]) -- $($newbytes[$offset])"
				if (1*$d -ne $curval)
				{
					#"Jersey: $d -- ($offset)" | write-host -fore "YELLOW"
					$Changes++
					$newbytes[$offset]=$EnCrypt[1*$d] 
					
					#$aReturn += "offset_$TeamID = $offset CHANGE (j: $d -- cv: $curval)"

				} else {
					#$aReturn += "offset_$TeamID = $offset KEEP (j: $d -- cv: $curval)"
				}
			}


			
			#$offset++
			$ACT = @(($TeamData | sort row).ACT | ? {$_  -match '[0-9]'} )
			foreach ($d in $ACT )
			{
				$offset++
				#Convert to 2 digit bytes
				#$d
				$curval = 1*$DeCrypt[1*$newbytes[$offset]]  + 256*$DeCrypt[1*$newbytes[$offset+1]]

				#"ACT D: $d --  $curval"
				if ($d -ne $curval)
				{
					#$aReturn += "ACT = $offset CHANGE (j: $d -- cv: $curval)"
					$Changes++
					#split $d into two
					$d1 = $d % 256
					$d2 = [int]([math]::Floor(1*$d/256))

					#$aReturn += " d1= $d1"
					#$aReturn += " d2= $d2"
					#$aReturn += " ed1= $(1*$EnCrypt[1*$d1])"
					#$aReturn += " ed2= $(1*$EnCrypt[1*$d2])"
					
					#"ACT1: $($bytes[$offset]) -- $offset"
					#"ACT1: $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
					# CHANGEME
					$newbytes[$offset]=$EnCrypt[1*$d1]
					$offset++ 				

					#"ACT2: $($bytes[$offset]) -- $offset"
					#"& ACT2: $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
					$newbytes[$offset]=$EnCrypt[1*$d2] 
					
				} else {
					$offset ++
				}
			}
			


			#$offset++
			#$AAARows = @($TeamData | ? {$_  -match '[0-9]'} )
			foreach ($row in ($TeamData | sort row) | ? {$_.AAA -match '[0-9]'})
			{
				foreach ($d in @($row.AAA,$row.AAAType))
				{			
					
					$offset++
					#Convert to 2 digit bytes
					
					$curval = 1*$DeCrypt[1*$newbytes[$offset]]  + 256*$DeCrypt[1*$newbytes[$offset+1]]

				#	"AAA D: $d --  $curval"
					
					if (1*$d -ne $curval)
					{
						$Changes++
						#split $d into two
						$d1 = $d % 256
						$d2 = [int]([math]::Floor($d/256))
						
					
						#"AAA1: $($bytes[$offset]) -- $offset"
						#"AAA1: $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
						#CHANGEME
						$newbytes[$offset]=$EnCrypt[1*$d1]
						$offset++ 				

						#"AAA2: $($bytes[$offset]) -- $offset"
						#"& AAA2: $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
						# CHANGEME
						$newbytes[$offset]=$EnCrypt[1*$d2] 
						
					} else {
						$offset++
					}
				}
			}
			
			#$offset++
		
			foreach ($cat in @("Low","Limbo","boLH","boRH","defLH","defRH","Pit"))
			{
				foreach ($d in @(($TeamData | sort row)."$cat") | ? {$_ -match '[0-9]'})
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
						$d2 = [int]([math]::Floor($d/256))

						#"$cat 1: $($bytes[$offset]) -- $offset"
						#"$cat 1: $($EnCrypt[1*$d1]) -- ($offset)" | write-host -fore "YELLOW"
						
						#CHANGEME
						$newbytes[$offset]=$EnCrypt[1*$d1]
						$offset++ 				

						#"$cat 2: $($bytes[$offset]) -- $offset"
						#"& $cat 2: $($EnCrypt[1*$d2]) -- ($offset)" | write-host -fore "YELLOW"
						$newbytes[$offset]=$EnCrypt[1*$d2] 
						
					} else {
						$offset++
					}
				}
			}

			
		}
		
		$aReturn += "Changes = $Changes"
		
	} else {
			$aReturn += "Overwritten = False"
			#$hReturn.add("Overwritten",$false)
	}
	
	
	
	if ($Changes -gt 0)
	{
		$TotalBytesChanged = .5*(compare -ReferenceObject $newbytes -DifferenceObject $bytes).count
		#$hReturn.add("TotalBytesChanged",$TotalBytesChanged)
		$aReturn += "TotalBytesChanged = $TotalBytesChanged"

		[System.IO.File]::WriteAllBytes($ASNFile,$newbytes)
		$aReturn += "Overwritten = True"

		#$hReturn.add("Overwritten",$true)
		
	} else {
		$aReturn += "Overwritten = False"

		#$hReturn.add("Overwritten",$false)
	
	}
	return $aReturn

	
}

##############################
# This will get the team data
# from the ASN file
##############################
Function Get-ASNData {
	param( [string]$ASNFile )
	
	# LOAD FILE
	$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
	#"FileSize: $($bytes.count)"


	#ASN offset is here
	$EByte = 0x310
	$EncStart = 1*$bytes[$EByte]
	$EncOffset = 1*$bytes[$EByte + 1]

	$Decrypt = Get-BBDecrypt -EncStart $EncStart  -EncOffset $EncOffset
	
	# The ASN file is in sections...
	#"Finding all sections..."
	#$AllSections
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
			#"Completed" | write-host -fore "GREEN"
		} else {
		
			$Offsets += "" | select  @{name="offset";expression={$Offset}},  @{name="length";expression={$length}}

		}
		$x++
	} while (($length -gt 0) -and ($x -lt 99999) -and ($offset -lt $bytes.count))
	#""

	############################

	$TeamData = @()
	$TeamHeader = @()
	$TeamHeader += (1..16) | % {"Un-$_"}
	$TeamHeader += "ID"
	$TeamHeader += @('LG','Div','DivTeam','CityNum','mOnly','gmReAssign','gmProTrades','gmResTrades','gmFA','gmAmDraft','gmFADraft','PCowner','PCmanager','PCpitching','PChitting','PCfielding','PCRunning')
	#$TeamHeader += (1..6) | % {"D-$_"}
	$TeamHeader += @('City','Nickname','Manager','ABRE','Stadium','Stad')
	$TeamHeader += (1..45) | % {"Col-$_"}
	$TeamHeader += @('Turf','OnePitch')
	$TeamHeader += (1..23) | % {"End-$_"}
	$TeamData += ($TeamHeader -join "`t")

	foreach ($o in ($Offsets | ? {$_.Length -eq 274 } | select -skip 1))
	{
		#Take the first 16 unencrypted
		$TempData = @()
		$TempData +=  $bytes[($o.offset)..($o.offset + 16)]
		
		#Decrypt the whole rest of the section
		$dBytes = $bytes[(17 +  $o.offset)..($o.offset + 271)] | % {$DeCrypt[1*$_] } 
		#($dBytes | select -first 20) -join " - "  | write-host -fore "YELLOW"
		$TempData += $dBytes[0..16]
		$TextData = @()
		$TextData += (([System.Text.Encoding]::ASCII.GetString($dBytes[17..33])).split([char]0))[0]
		$TextData += (([System.Text.Encoding]::ASCII.GetString($dBytes[34..50])).split([char]0))[0]
		$TextData += (([System.Text.Encoding]::ASCII.GetString($dBytes[51..67])).split([char]0))[0]
		$TextData += (([System.Text.Encoding]::ASCII.GetString($dBytes[68..81])).split([char]0))[0]
		$TextData += (([System.Text.Encoding]::ASCII.GetString($dBytes[82..114])).split([char]0))[0]
		$TextData += (([System.Text.Encoding]::ASCII.GetString($dBytes[115..123])).split([char]0))[0]
		#$TextData 
		$TempData += $TextData
		#colors come now and there are bytes 3 * 5 * 3
		#$TempData += ($dBytes[124..168]) #| measure
		$TempData += ($dBytes[124..193]) #Added 25 because I think some data is here like one pitch

		# not adding them unless I need to...
		
		#$TempData -join "-" #+= ($dBytes[124..168]) #| measure
		#$TeamHeader | measure
		#$TempData | measure
		$TeamData += $TempData -join "`t"
		
	}
	$retTeamData = $TeamData | convertfrom-csv -Delimiter "`t" #| select ID,City,Ma*,AB*,Stad* | ft

	return $retTeamData 
	
}

Function Write-DSNFile {
	param( [string]$ASNFile )

	$aReturn = @()

	#backup the file
	$DSNFile = (gci $ASNFile).DirectoryName
	$DSNFile += "\"
	$DSNFile += (gci $ASNFile).BaseName
	$DSNFile += ".DSN"
	
	$aReturn += "DSNFIle = $DSNFile"
	
	# LOAD FILE
	$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
	$FileSize = $bytes.count
	#"FileSize: $($bytes.count)"


	#ASN offset is here
	$EByte = 0x310
	$EncStart = 1*$bytes[$EByte]
	$EncOffset = 1*$bytes[$EByte + 1]

	$Decrypt = Get-BBDecrypt -EncStart $EncStart  -EncOffset $EncOffset
	
	#$bytes | % {$_ = 1*$DeCrypt[1*$_] }
	
	# decrypt everything after the keys
	foreach ($x in ((0)..($FileSize - 1)))
	{
		$b = 1* $bytes[$x]
		$y = $DeCrypt[$b]
		#"$b -- $y "
		$bytes[$x] = $y
	}

	
	#$aReturn += "DSNFIle = $DSNFile"
	[System.IO.File]::WriteAllBytes($DSNFile,$bytes)
	$aReturn += "FileWritten = True"

	return $aReturn
}

Function Get-PYRPlayers {
	param( [string]$PYRFile )
		
	$bytes  = [System.IO.File]::ReadAllBytes($PYRFile)
	#$newbytes  = [System.IO.File]::ReadAllBytes($PYRFile)
	$FileSize = $($bytes.count)

	$EncStart = 1*$bytes[0]
	$EncOffset = 1*$bytes[1]
	
	$Decrypt = Get-BBDecrypt -EncStart $EncStart  -EncOffset $EncOffset

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

	$null = $PlayerData.Add($Header -join ',')
	#"Parsing Player Ratings/Data"
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
		
		#if ((1*$data[0] % 25) -eq 0) { $data[0] }
		
		#$PlayerData+= $data
		$null = $PlayerData.Add($data -join ",")
		
	}
	#break;

	#$PlayerData | ft *
	$PlayerCSV = $null
	$PlayerCSV = convertfrom-csv $PlayerData
	$PlayerCSV = $PlayerCSV | ? {$_.ID -match '[0-9]'}

	return $PlayerCSV
}

Function Get-PYFIDs {
	param( [string]$PYFFile )

	$bytes  = [System.IO.File]::ReadAllBytes($PYFFile)
	#$newbytes  = [System.IO.File]::ReadAllBytes($PYRFile)
	$FileSize = $($bytes.count)

	# an empty ArrayList is used as a bucket to collect results:
	$PlayerIDs = $null
	$PlayerIDs = [System.Collections.ArrayList]@()

	$offset = 10
	while ($offset -lt ($FileSize - 1))
	{
		$Data = $null
		$Data += 1*$bytes[$offset]  + 256*$bytes[$offset+1]
		$offset += 2
		$null = $PlayerIDs.Add($Data)
	}

	Return $PlayerIDs
}

Function Set-PYFIDs {
	param( [string]$PYFFile ,$PYFData )
	
	#backup the file
	$PYFFolder = (gci $PYFFile).DirectoryName
	$PYFBaseName = (gci $PYFFile).BaseName
	$PYFExtName = (gci $PYFFile).Extension -replace '\.',''
		
	$aReturn = @()
		
	$x= -1 
	$BackupName = $null
	do {
		$x++
		$TestName = $PYFFolder + '\' + $PYFBaseName + "-$PYFExtName.$('{0:d3}' -f $x)"
		if (test-path $TestName) { } else {
			$BackupName = $TestName
		}	
		
	} until ($BackupName)
	
	$aReturn += "BackupName = $BackupName"
	
	$IDCount = $PYFData.count 
	
	copy $PYFFile $BackupName
	
	# LOAD FILE
	# twice (newbytes)
	$bytes  = [System.IO.File]::ReadAllBytes($PYFFile)
	$NewBytes = new-object byte[] (10 + 2*($IDCount))
	#$aReturn += "bytes: $($bytes.gettype())"
	#$newbytes  = [System.IO.File]::ReadAllBytes($PYFFile)
	#$FileSize = $($bytes.count)
	
	0..3 | % { $NewBytes[$_] = $bytes[$_] }
	
	
	$d = 2*($IDCount) + 2
	$d1 = $d % 256
	$d2 = [int]([math]::Floor($d/256))
	#$d2 = [int]($d / 256)
	#$aReturn += "d: $d"
	#$aReturn += "d1: $d1"
	#$aReturn += "d2: $d2"

	$NewBytes[04] = $d1
	$NewBytes[05] = $d2
	$NewBytes[06] = 0
	$NewBytes[07] = 0

	$d = 1*($IDCount) 
	$d1 = $d % 256
	$d2 = [int]([math]::Floor($d/256))

	$NewBytes[08] = $d1
	$NewBytes[09] = $d2
	
	$offset = 10 
	foreach ($ID in ($PYFData | ? {$_ -match '[0-9]'}))
	{

		$d = 1*($ID) 
		$d1 = $d % 256
		$d2 = [int]([math]::Floor($d/256))

		$NewBytes[$offset] = $d1
		$NewBytes[$offset+1] = $d2
		
		$offset += 2
	}
	
	[System.IO.File]::WriteAllBytes($PYFFile,$newbytes)
	$aReturn += "FileWritten = True"
	
	$TotalBytesChanged = .5*(compare -ReferenceObject $newbytes -DifferenceObject $bytes).count
	$aReturn += "TotalBytesChanged = $TotalBytesChanged"
	return $aReturn
}

Function Get-PYCIDs {
	param( [string]$PYCFile )

	return (Get-PYFIDs -PYFFile $PYCFile)
}

Function BB-DropPlayers {
	param( $ASNFile, $PlayerIDs )
	
	#Get the PYF FileName
	$PYFFolder = (gci $ASNFile).DirectoryName
	$PYFBaseName = (gci $ASNFile).BaseName
	$PYFName = "$PYFFolder\$PYFBaseName.PYF"
	
	
	
	$aReturn = @()
	$aReturn += "PYFName = $PYFName"
	#$aReturn += "PlayerIDs = $($PlayerIDs.gettype())"

	#Get ASNROsters
	$Rosters = Get-ASNRoster $ASNFile
	
	$TeamIDs = @()
	#Check if PlayerID is in a row
	
	# Record the TeamID
	#	change that row to 0
	#Change orders with row on the bottom of their section
	foreach ($ID in $PlayerIDs){
		#$row = $null
		# LOW, LIMBO is easy 
		if ($Rosters | ? {$_.LOW -eq $ID}) {
			$Rosters | ? {$_.LOW -eq $ID} | % {$_.Low = 0;$_.Row += 50; $TeamIDs += $_.TeamID } 
		} elseif ($Rosters | ? {$_.LIMBO -eq $ID}) {
			$Rosters | ? {$_.LIMBO -eq $ID} | % {$_.LIMBO = 0;$_.Row+= 50; $TeamIDs += $_.TeamID } 
		} elseif ($Rosters | ? {$_.AAA -eq $ID}) {
			$Rosters | ? {$_.AAA -eq $ID} | % {$_.AAA = 0;$_.Row+= 50; $_.AAAType =0; $_.jersey = 0; $TeamIDs += $_.TeamID } 

		} elseif ($Rosters | ? {$_.ACT -eq $ID}) {
			$Rosters | ? {$_.ACT -eq $ID} | % {$_.ACT = 0;$_.Row+= 50; $_.jersey = 0; $TeamIDs += $_.TeamID } 
			# ALSO CHECK Rosters
			
			foreach ($cat in @("boLH","boRH","defLH","defRH","Pit")){
				$Rosters | ? {$_."$cat" -eq $ID} | % {$_."$cat" = 0} 
			}
			#foreach ($d in @(($TeamData | sort row)."$cat") | ? {$_ -match '[0-9]'})

			
		} else {
			$aReturn += "ERROR Can't find $ID"
			return $aReturn;
		}
	}
	


	#write the changes (set-ASNRoster)
	$aReturn += "------------- writing new ASN -------------"
	$TeamData = $Rosters | ? {$TeamIDs -contains $_.TeamID} 
	$aReturn += Set-ASNRoster -ASNFile $ASNFile -ASNData $TeamData 
	
	#return $aReturn;
	#get the free agent list
	$PYFIds = Get-PYFIDs -PYFFile $PYFName
	$aReturn += "PYFIDs from file  = $($PYFIds.count)"
	$PYFIds = $PYFIDs | sort -unique
	#$PYFIds = $PYFIds | ? {$_ -match '[0-9]+'} 
	$aReturn += "PYFIDs unique = $($PYFIds.count)"
	
	#add these IDs
	$PYFIDs += @($PlayerIDs)
	$aReturn += "PYFIDs add = $($PYFIds.count)"
	$PYFIDs = $PYFIDs | sort -unique
	$aReturn += "PYFIDs unique = $($PYFIds.count)"
	#write the free agent list
	$aReturn += "------------- writing new PYF -------------"
	$aReturn += Set-PYFIDs  -PYFFile $PYFName -PYFData $PYFIDs
	#return $aReturn
	$aReturn += "------------- COMPLETE -------------"
	return $aReturn

}


Function BB-ADDPlayers {
	param( [string]$ASNFile, $PlayerInfo )
	
	#Load all teams
	#Get ASNROsters
	$Rosters = Get-ASNRoster $ASNFile
		
	$aReturn = @()
	##############################################
	##############################################
	foreach ($row in $PlayerInfo)
	{
		#all you need is the ID, TeamID, & Slot
		#$Checks = @()
		$ID = $row.ID 
		$TeamID = $row.TeamID
		$Slot = $row.Slot
		
		#insert the player on the teamID in the slot instead of a zero
		$RosterRow = ($Rosters | ? {$_.TeamID -eq $TeamID} | ? { $_."$slot" -eq 0} | select -first 1 ).row
		if ($RosterRow)
		{
			$aReturn += "Found slot [TEAM: $TeamID], [SLOT: $slot], [RosterRow: $RosterRow]"
			#get jersey number
			$Jerseys = ($Rosters | ? {$_.TeamID -eq $TeamID} ).Jersey
			$allJerseys = 1..99
			$ThisJersey = (compare $Jerseys $AllJerseys | ? {$_.SideIndicator -eq "=>" } | select -first 10 | get-random).InputObject
			
			if ($slot -eq 'AAA'){ 
				$Rosters | ? {$_.TeamID -eq $TeamID} | ? { $_."$slot" -eq 0} | select -first 1 | % { $_."$slot" = $ID; $_.Jersey = $ThisJersey; $_.aaaType = 1 ; }
			} elseif ($slot -eq 'ACT'){ 
				$Rosters | ? {$_.TeamID -eq $TeamID} | ? { $_."$slot" -eq 0} | select -first 1 | % { $_."$slot" = $ID; $_.Jersey = $ThisJersey; }
			} elseif ($slot -eq 'LOW'){
				$Rosters | ? {$_.TeamID -eq $TeamID} | ? { $_."$slot" -eq 0} | select -first 1 | % { $_."$slot" = $ID; }
				#$aReturn += "
			} else {
				$aReturn += "ERROR: OPEN SLOT NOT Found [TEAM: $TeamID], [SLOT: $slot]"
				return $aReturn
		
			}

			
		} else {
			$aReturn += "ERROR: NO Found slot [TEAM: $TeamID], [SLOT: $slot], [RosterRow: $RosterRow]"
			return $aReturn
		}
		
		
	}
	
	#write the ASN
	#write the changes (set-ASNRoster)
	$aReturn += "------------- writing new ASN -------------"
	#$TeamData = $Rosters | ? {@($PlayerInfo.TeamID) -contains $_.TeamID} 
	$aReturn += Set-ASNRoster -ASNFile $ASNFile -ASNData $Rosters 
	
	
	#Get the PYF FileName
	$PYFFolder = (gci $ASNFile).DirectoryName
	$PYFBaseName = (gci $ASNFile).BaseName
	$PYFName = "$PYFFolder\$PYFBaseName.PYF"
	$aReturn += "PYFName = $PYFName"

	#get the free agent list
	$PYFIds = Get-PYFIDs -PYFFile $PYFName
	#add these IDs
	$PYFIDs = $PYFIDs | ? {$_ -notin @(($PlayerInfo).ID)}
	#$PYFIDs = $PYFIDs | sort -unique # ? {$_ -notin @(($PlayerInfo).ID)}
	#write the free agent list
	$aReturn += "------------- writing new PYF -------------"
	$aReturn += Set-PYFIDs  -PYFFile $PYFName -PYFData $PYFIDs
	#return $aReturn
	$aReturn += "------------- COMPLETE -------------"

	
	return $aReturn
	

}



Function Get-BBPROFunctions {
	param( [string]$ThisFile)	
	
	$FileData = gc $ThisFile # "D:\_ps_scripts\BBPRO98-Functions.ps1"
	$Functions = $FileData | select-string '^(Function[^\{]+)'

	$FunctionData = @()
	foreach ($f in $Functions)
	{
		$LineN = $f.LineNumber
		[string]$Fn = $f.Matches.Groups[1].Value
		$par = $null
		$Par = $FileData[1*$LineN]
		if ($par -match 'Param')
		{} else {
			$par=$null
		}
		#"$LineN -- $Fn -- $par"
		$tempData = "" | select "Function","Params"
		$Tempdata.Function = $Fn
		$Tempdata.Params = $Par
		
		$FunctionData += $TempData
	}

	#return ($MyInvocation | select * )
	return $FunctionData

}

Function Template {
	param( [int]$Price, [int]$Tax )
	$Price + $Tax
}