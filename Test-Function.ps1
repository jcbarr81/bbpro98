. D:\_ps_scripts\BBPRO98-Functions.ps1

$ASN = "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.ASN"
$PYF = "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.PYF"
$PYR = "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.PYR"

#copy "D:\_backup\08BIN001-2022.2832\Assn\08BIN001-PYF.001" "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.PYF"
#copy "D:\_backup\08BIN001-2022.2832\Assn\08BIN001-ASN.001" "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.ASN"

# LOAD FUNCTION FILE
Get-BBPROFunctions "D:\_ps_scripts\BBPRO98-Functions.ps1"

#Get player ratings
$Players = Get-PYRPlayers -PYRFile $PYR
$Players | select -first 10 | ft * -auto

#Get Team Data
$TeamData = Get-ASNData -ASNFile $ASN 
#$TeamData | select *i*,A* | ft * -auto

#LOAD FREE AGENTS
$FAIDs = get-pyfids $PYF 
$SignFa = @($FAIDs | sort -unique | get-random -count 3)

#LOAD ROSTERS
$Rosters = Get-ASNRoster  -ASNFile $ASN 
#$Rosters = Get-ASNRoster  -ASNFile $ASN 

#GET ROSTER FOR TEAM #3 
#$Rosters | ? {$_.TeamID -eq  1} | ft * -auto
$Rosters | ? {$_.TeamID -eq  3} | ft * -auto

$DropIDs = @(110,178,180,164,192,190)
" --- DROP --- "
BB-DropPlayers  -ASNFile $ASN -PlayerIDs $DropIDs

$PlayerCSV = @()
$PlayerCSV += "ID,TeamID,Slot,FirstName,LastName,TeamABRE"
$PlayerCSV += "$($SignFA[0]),1,ACT,$($(($PLayers | ?{$_.ID -eq $($SignFA[0])})).FirstName),$((($PLayers | ?{$_.ID -eq $($SignFA[0])})).LastName),$(($TeamData | ? {$_.ID -eq 1 } ).ABRE)"
$PlayerCSV += "$($SignFA[1]),2,AAA,$($(($PLayers | ?{$_.ID -eq $($SignFA[1])})).FirstName),$((($PLayers | ?{$_.ID -eq $($SignFA[1])})).LastName),$(($TeamData | ? {$_.ID -eq 2 } ).ABRE)"
$PlayerCSV += "$($SignFA[2]),3,low,$($(($PLayers | ?{$_.ID -eq $($SignFA[2])})).FirstName),$((($PLayers | ?{$_.ID -eq $($SignFA[2])})).LastName),$(($TeamData | ? {$_.ID -eq 3 } ).ABRE)"

$PlayerAdd = convertfrom-csv $PlayerCSV
$PlayerAdd | ft 


#CHECK
$RostersAfter = Get-ASNRoster  -ASNFile $ASN 
compare $ROSTERs $RostersAfter
$RostersAfter | select * | ft * -auto

" --- ADD --- "
BB-AddPlayers  -ASNFile $ASN -PlayerInfo $PlayerAdd


exit

" --- DROP --- "
BB-DropPlayers  -ASNFile $ASN -PlayerIDs @(106)

#CHECK
$RostersAfter = Get-ASNRoster  -ASNFile $ASN 
compare $ROSTERs $RostersAfter
$RostersAfter | ? {$_.TeamID -eq  1} | select * | ft * -auto
exit


exit


copy "D:\_backup\08BIN001-2022.2832\Assn\08BIN001-ASN.000" "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.ASN"
copy "D:\_backup\08BIN001-2022.2832\Assn\08BIN001-PYF.000" "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.PYF"


$T = Get-ASNRoster $ASN
#$Jerseys = ($T | ? {$_.TeamID -eq 3 }).Jersey
#$allJerseys = 1..99
#(compare $Jerseys $AllJerseys | ? {$_.SideIndicator -eq "=>" } | select -first 10 | get-random).InputObject
#exit

$PI = @()
$TempPlayer = "" | select ID,TeamID,SLot
$TempPlayer.ID = 999
$TempPlayer.TeamID = 8
$TempPlayer.Slot = "LOW"
$PI += $TempPlayer

BB-ADDPlayers  -ASNFile $ASN -PlayerInfo $PI | ft * -auto

exit


copy "D:\_backup\08BIN001-2022.2832\Assn\08BIN001-ASN.000" "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.ASN"
copy "D:\_backup\08BIN001-2022.2832\Assn\08BIN001-PYF.000" "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.PYF"

#Get-BBPROFunctions "D:\_ps_scripts\BBPRO98-Functions.ps1"
BB-DropPlayers $ASN @(138,178,179,232,139,163)  #| sort row | ft


exit


#(Get-ChildItem $MyInvocation.MyCommand.Definition) | select * | fl

$ASN = "D:\_backup\08BIN001-2022.2832\Assn\08BIN001.ASN"

BB-DropPlayers $ASN @(138,178,179,232,139,163)  | sort row | ft
exit

$TeamData = Get-ASNRoster $ASN #| select * 

$ACT1 = @($TeamData.AAA | ? {$_  -match '[0-9]'} )
$ACT2 = @(($TeamData | sort row).AAA | ? {$_  -match '[0-9]'} )

$TeamData | sort Row | ? {$_.TeamID -eq 2 } | ft

#$RostersA | ? {$_.TeamID -eq 2 } |  ft  #| select AAAType | sort AAAType -unique

exit
Get-BBPROFunctions "D:\_ps_scripts\BBPRO98-Functions.ps1"

exit

# (Get-ChildItem $MyInvocation.MyCommand.Definition).DirectoryName
$FileData = gc ".\BBPRO98-Functions.ps1" 
#$Functions = gci ".\BBPRO98-Functions.ps1" | select-string '^(Function[^\{]+)'
$Functions = $FileData | select-string '^(Function[^\{]+)'
# | % {$_.Matches.Groups[1]} | Select Value )
$FunctionData = @()
foreach ($f in $Functions)
{
	$LineN = $f.LineNumber
	[string]$Fn = $f.Matches.Groups[1].Value
	$par = $null
	$Par = $FileData[1*$LineN]
	"$LineN -- $Fn -- $par"
	$tempData = "" | select "Function","Params"
	$Tempdata.Function = $Fn
	$Tempdata.Params = $Par
	
	$FunctionData += $TempData
}

$FunctionData
# | % {$_ -replace 'W  ([0-9])','W +$1'} | % {$_ -replace "<[^>]*>", ""} | % {$_ -replace '[\s]{2,}',','}

#gci ".\BBPRO98-Functions.ps1" | select-string '^(Function[^\{]+)' | fl
exit

DropPlayers -ASNFile "D:\_backup\08BIN001-2022.270\Assn\08BIN001.ASN" -PlayerIDs @(100,150)

exit
copy "D:\_backup\08BIN001-2022.270\Assn\08BIN001-PYF.000" "D:\_backup\08BIN001-2022.270\Assn\08BIN001.PYF"

$IDs = get-PYFIDs -PYFFile "D:\_backup\08BIN001-2022.270\Assn\08BIN001.PYF" #-PYFData @()
#$IDs = $IDs | select -first 10
#exit
Set-PYFIDs -PYFFile "D:\_backup\08BIN001-2022.270\Assn\08BIN001.PYF" -PYFData $IDs

$IDs2 = Get-PYFIDs  -PYFFile "D:\_backup\08BIN001-2022.270\Assn\08BIN001.PYF"

$Same = (compare $IDs $IDs2 -IncludeEqual).count
$Diff = (compare $IDs $IDs2 ).count
"SAME: $Same"
"DIFF: $Diff"

exit

$ASN = "D:\_backup\08BIN001-2022.270\Assn\08BIN001.ASN"

copy "D:\_backup\08BIN001-2022.270\Assn\08BIN001-ASN.000" "D:\_backup\08BIN001-2022.270\Assn\08BIN001.ASN"

#exit
$RostersA = Get-ASNRoster $ASN #| select * 
#$RostersA.count
#exit
$RostersA | select -first 1 | % {$_.Jersey = 99 } 
$RostersA | select -first 2 | select -last 1 |  % {$_.Jersey = 98 } 
$RostersA  | ? {$_.TeamID -eq 1 } | ? {$_.Jersey -match '[0-9]' } | ft

#$RostersA  | ? {$_.TeamID -eq 1 } | ? {$_.ACT -match '[0-9]'}

exit
$Results = Set-ASNRoster -ASNFile $ASN -ASNData $RostersA

$Results 

#sleep 5
exit
$RostersB = Get-ASNRoster $ASN | select *
$RostersB  | ? {$_.TeamID -eq 1 } | ? {$_.Jersey -match '[0-9]' } | ft
#$Rosters | select -first 1 | % {$_.Jersey = 99 } 
exit
sleep 5

#$RostersB | select * | ft * -auto

compare $RostersA $RostersB | ft 