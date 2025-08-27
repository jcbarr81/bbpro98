# This will Extract parts of ASN
param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$ASNFile
)

$ErrorActionPreference = 'Stop'

$ScriptPath = (Get-ChildItem $MyInvocation.MyCommand.Definition).DirectoryName
$DefaultFile = Join-Path $ScriptPath 'data_files/28DEV001.ASN'

if (-not $ASNFile) {
    if ([Console]::IsInputRedirected) {
        $ASNFile = [Console]::In.ReadLine()
    } else {
        $ASNFile = Read-Host "Enter the path to ASN file [Default: $DefaultFile]"
    }
}
if (-not $ASNFile) {
    $ASNFile = $DefaultFile
}

$ASNFile = $ASNFile -replace '"',''

if (-not (Test-Path $ASNFile)) {
    Write-Error "No file found: $ASNFile"
    exit 1
}

$LeagueName = (Get-Item $ASNFile).BaseName
$OutputDir = Join-Path $ScriptPath $LeagueName
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}


# LOAD FILE
$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
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

"Making Decryption Array"
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
	
	if ($x % 10 -eq 9)
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


#length of 312 is the team roster sections
# decrypt and extract those into csv?
$Decrypted = @()

$ASCII = [System.Text.Encoding]::ASCII


#Export different things as csv files
# this is team info 
$TeamInfo = @()
$TeamInfo += "TeamID,City,Manager,Abre,Stadium"

foreach ($o in ($Offsets | ? {$_.Length -eq 274 } | select -skip 1))
{
	#$o | select * 

	#get the section
	#"Length: $($o.length)"
	#Team ID = 16 bytes
	$TeamID = $bytes[(16 + $o.offset)]
	"TeamID : $TeamID " + 	"Offset: $($o.offset)" | write-host -fore "GREEN"

	$section = $bytes[(17 +  $o.offset)..($o.offset + 271)]
	#($section | select -first 20) -join " - "  | write-host -fore "YELLOW"

	$dSection = @()
	foreach ($s in $section)
	{
		#"s: $s"
		$dSection += $DeCrypt[1*$s]
	}	
	#$dSection | select -first 30
	#($dSection | select -first 50) -join " - "  | write-host -fore "CYAN"

	# 18 bytes in is the city
	#$dSection[17..50] -join " - "  | write-host -fore "MAGENTA"

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

$OutputFileName = "$ThePath\$LeagueName\$LeagueName-Team-Info.csv"
$TeamInfo | Export-Csv -Path $OutputFileName -Force -notype


# This is rosters
$TeamID = 0
$AllRosters = @()
foreach ($o in $offsets | ? {$_.length -eq 312})
{
	$TeamID++ 
	#get the section
	"Offset: $($o.offset) -- Length: $($o.length)"
	
	$section = $bytes[(17 + $o.offset)..($o.offset + 309)]
	#"Length: $($section.length)" #= $bytes[(17 + $o.offset)..($o.offset + 309)]
	#$section | select -first 20
	""
        # build a blank table with 13 columns for roster data
        $cols = 12
        $data = $null
        $data = @()
        $data += (0..$cols) -join ','
        (1..75) | % { $data += ((1..$cols) | %{","}) -join '' }

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

        $OutputFileName = Join-Path $OutputDir ("Roster-{0:D2}.csv" -f $TeamID)

        $data | Export-Csv -Path $OutputFileName -Force -NoTypeInformation
        #fix headers
        $data = Import-Csv -Path $OutputFileName -Header @('TeamID','ABRE','Jersey','ACT','AAA','AAAType','Low','Limbo','boLH','boRH','defLH','defRH','Pit') | Select-Object * -Skip 1

        $AllRosters += $data
        $data | Export-Csv -Path $OutputFileName -Force -NoTypeInformation # -Delimiter "`t"

        #$data = $null
        $OutputFileName | Write-Host -ForegroundColor "RED"

}

# compile all
$AllRosters | Export-Csv -Path (Join-Path $OutputDir "$LeagueName-Roster-All.csv") -Force -NoTypeInformation
(Join-Path $OutputDir "$LeagueName-Roster-All.csv") | Write-Host -ForegroundColor "RED"
