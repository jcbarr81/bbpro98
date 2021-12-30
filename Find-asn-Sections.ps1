# This will find all the binary sections of an ASN file

$DefaultFile = "D:\testing\trades\32nrb001.ASN"
$ASNFile = Read-host "Enter the path to ASN file [Default: $DefaultFile]"
if ($ASNFile -eq "")
{
	$ASNFile = $DefaultFile
}

if (test-path $ASNFile) {} Else { 
	"No file found:"
	exit 
}

# LOAD FILE
$bytes  = [System.IO.File]::ReadAllBytes($ASNFile)
"FileSize: $($bytes.count)"

#Start at 0x202 - not sure how to find this...
# one idea  - look for a bunch of FF FF FF and then go 2 after ???
$offset = 0x200 +2
$b = $($bytes[$offset])
"VALUE0: $($b)"
"Offset0: $offset -- $('{0:x}' -f $offset)"



#x is a failsafe...
$x = 0

do {
	$offset +=  1*$b
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
		exit
	}

	$lastValue = $b 
	
	# Show Value
	"Value: $b"
	"Offset: $offset -- $('{0:x}' -f $offset)"
	""
	$x++
} while (($x -lt 99999) -or ($offset -lt $bytes.count))

# someday
# [System.IO.File]::WriteAllBytes("C:\NewFile.exe", $bytes)
