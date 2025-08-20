# Baseball Pro '98 Tools

This repository contains PowerShell scripts and helper functions for editing Baseball Pro '98 league files. The tools decrypt the game's binary formats, expose team and player data in CSV form, and write modifications back to the encrypted files.

> **Make backups** – many scripts overwrite your `.ASN` and `.PYR` files. Always keep a copy before running any importer.

## Script-by-Script Documentation

### `ASN-Extractor-A.ps1`
Prototype exporter that prompts for an `.ASN` file, decrypts each 312‑byte team section, and writes a roster/lineup/rotation CSV per team plus a combined "Roster-All" CSV.

### `ASN-Extractor-B.ps1`
Refined extractor that accepts file paths as parameters, sanitizes input, creates a league-named folder, and exports team CSVs along with a master CSV.

### `ASN-Importer-A.ps1`
Imports edited roster CSVs back into an `.ASN` file. Backs up the original, rebuilds encryption tables, rewrites roster slots, batting orders, defensive alignments, and pitcher rotations, and outputs the updated file.

### `BBPRO98-Functions.ps1`
Reusable function library providing:

- **Get-BBDecrypt / Get-BBEncrypt** – build lookup tables for decrypting/encrypting using start and offset keys.
- **Get-ASNRoster / Set-ASNRoster** – parse or rewrite team sections in `.ASN` files.
- **Get-ASNData** – read team metadata (IDs, cities, nicknames, colors, etc.).
- **Write-DSNFile** – create a fully decrypted `.DSN` copy of an `.ASN` file.
- **Get-PYRPlayers** – decrypt a `.PYR` player database and emit player records.
- **Get-PYFIDs / Set-PYFIDs** – read or update the free‑agent ID list in `.PYF` files; `Get-PYCIDs` wraps these for `.PYC` files.
- **BB-DropPlayers / BB-ADDPlayers** – remove or insert players while keeping free‑agent lists in sync.
- **Get-BBPROFunctions** – list functions defined in the library.
- **Template** – minimal example function.

### `Decrypt-pyr-E.ps1`
Stand‑alone `.PYR` decrypter that zeroes the header and writes a raw `.dyr` file.

### `Export-pyr-A.ps1`
Exports player data from a `.PYR` file to CSV. Decrypts each 192‑byte player block, decoding IDs, biographical info, handedness, ratings, and modifiers.

### `Find-asn-Sections.ps1`
Diagnostic tool that walks through an `.ASN` file from offset `0x202`, printing section offsets and validating the trailing checksum bytes.

### `Import-pyr-A.ps1`
Imports edited player CSVs back into a `.PYR` file. Backs up the original, converts CSV values into encrypted bytes, and rewrites each player block.

### `Test-Function.ps1`
Ad‑hoc demo script showing how to invoke the function library (loading functions, reading players and teams, dropping/adding players, and updating free‑agent lists).

## Usage Notes

1. **Backups:** Many scripts automatically create timestamped backups before overwriting league files. Ensure you have sufficient disk space.
2. **CSV Integrity:** Import scripts require complete CSVs; missing rows or columns will corrupt the league. Roster CSV header: `TeamID,ABRE,Jersey,ACT,AAA,AAAType,Low,Limbo,boLH,boRH,defLH,defRH,Pit`. Player CSV contains 144 columns covering IDs, names, ratings, and modifiers.
3. **Encryption Keys:** Each `.ASN` and `.PYR` file stores two key bytes (start and offset). The scripts rebuild lookup tables for proper decryption/encryption before reading or writing data.
4. **Free Agent Lists:** `.PYF` (and `.PYC`) files maintain the list of unsigned player IDs. `BB-DropPlayers` and `BB-ADDPlayers` automatically synchronize these lists when rosters change.
5. **Prerequisites:** Scripts are PowerShell (`.ps1`) and expect Windows-style paths. Adjust `$DefaultFile` variables or provide full paths when prompted.

## Basic Workflows

### Rosters, Lineups, and Rotations
1. Run `ASN-Extractor-B.ps1` and provide the full path to the `.ASN` file.
2. Edit the generated CSVs inside the league-named folder.
3. Run `ASN-Importer-A.ps1` on the edited CSV to apply changes. A backup of the original `.ASN` will be created automatically.

### Editing Players
1. Run `Export-pyr-A.ps1` on your `.PYR` file to export player data to CSV.
2. Modify the CSV, keeping all columns intact.
3. Run `Import-pyr-A.ps1` to write the edits back into the `.PYR` file. A backup copy will be created.

Enjoy managing your Baseball Pro '98 league!

