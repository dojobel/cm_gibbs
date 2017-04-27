#!/bin/bash
#File: gibbs.sh
#Description: Ripper made specifically for: https://www.ncdc.noaa.gov/gibbs/
#Written by: dojobel
#Created: 25/04/2017
#Modified: 26/04/2017
#Version: 1.0


#Don't change these
WorkingDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Timestamp="$(date "+%Y.%m.%d-%H.%M.%S")"

#// Start User editable configuration
#File to write the URLs out for L1 Seed file
OutputL1Seed="$WorkingDir"/L1Seed_"$Timestamp".txt
#File to write the URLs out for L2 Seed file
OutputL2Seed="$WorkingDir"/L2Seed_"$Timestamp".txt
#File to write the URLs out for L3 Seed file
OutputL3Seed="$WorkingDir"/L3Seed_"$Timestamp".txt
#File to write the URLs out for Satellite Image seed file
OutputSatImgSeed="$WorkingDir"/SatImgSeed_"$Timestamp".txt
#File to write out any sat image download failures we couldn't retry for
FailedDLList="$WorkingDir"/failed_downloads.txt
#Root folder to write-out the downloaded images to (No trailing slash)
Destination="$HOME/rip"

#Optional: If you have a seed file containing the links, you can save yourself a lifetime of waiting and provide those here.
#          It is only necessary to specify the highest level (ascending) seed file that you have.
#Note: DO NOT specify something here if you don't have a proper seed file or it may produce unintended results.
L1SeedFile=
L2SeedFile=
L3SeedFile=
SatImgSeedFile=
#//End User editable configuration

#//System Configuration - Changing these might break something
SourceRootURL='https://www.ncdc.noaa.gov/gibbs'
SourceSiteRoot='https://www.ncdc.noaa.gov'
Level1Links=()
Level2Links=()
Level3Links=()
L1Skip=false
L2Skip=false
L3Skip=false
SatImgSkip=false
#//End System Configuration


if [ -z "$(which lynx)" ];then
    echo "ERROR: lynx not installed. Please install it and try again."
    exit 1
fi
if [ -z "$(which wget)" ];then
    echo "ERROR: wget not installed. Please install it and try again."
    exit 1
fi

echo "Gibbs Crawler v1.0"
echo 



echo "Harvesting Level 1 Links..."
if [ ! -z "$L2SeedFile" ]; then
    echo "   -Skipping, L2 Seed File specified"
    L1Skip=true
fi
if [ ! -z "$L3SeedFile" ]; then
    echo "   -Skipping, L3 Seed File specified"
    L1Skip=true
fi
if [ ! -z "$SatImgSeedFile" ]; then
    echo "   -Skipping, Sat Image Seed File specified"
    L1Skip=true
fi
if [ "$L1Skip" == false ]; then
    if [ -z "$L1SeedFile" ]; then
        Level1Links=($(lynx -source "$SourceRootURL" | grep 'yearCell' | grep 'href' | cut -d '"' -f 4))
        for ((z=0; z<${#Level1Links[@]}; ++z)); do
            echo "${Level1Links[$z]}">>"$OutputL1Seed"
        done
    else
        echo "   -Reading L1 Seed File"
        while read URL; do
            Level1Links+=("$URL")
        done <$L1SeedFile
    fi
fi
echo "Done"
echo 

echo "Harvesting Level 2 Links..."
if [ ! -z "$L3SeedFile" ]; then
    echo "   -Skipping, L3 Seed File specified"
    L2Skip=true
fi
if [ ! -z "$SatImgSeedFile" ]; then
    echo "   -Skipping, Sat Image Seed File specified"
    L2Skip=true
fi
if [ "$L2Skip" == false ]; then
    if [ -z "$L2SeedFile" ]; then
        for ((i=0; i<${#Level1Links[@]}; ++i)); do
            echo "Scraping L1 Page: $SourceSiteRoot${Level1Links[$i]}"
            CurrentLink=$(lynx -source "$SourceSiteRoot${Level1Links[$i]}" | grep 'calendarDay' | grep 'href' | cut -d "'" -f 4)
            Level2Links+=($CurrentLink)
            echo "$CurrentLink">>"$OutputL2Seed"
        done
    else
        while read URL; do
            echo "Reading L2 Link from Seed: $URL"
            Level2Links+=("$URL")
        done <$L2SeedFile
    fi
fi
echo "Done"
echo 


echo "Harvesting Level 3 Links..."
if [ ! -z "$SatImgSeedFile" ]; then
    echo "   -Skipping, Sat Image Seed File specified"
    L3Skip=true
fi
if [ "$L3Skip" == false ]; then
    if [ -z "$L3SeedFile" ]; then
        for ((j=0; j<${#Level2Links[@]}; ++j)); do
            echo "Scraping L2 Page: $SourceSiteRoot${Level2Links[$j]}"
            CurrentLink=$(lynx -source "$SourceSiteRoot${Level2Links[$j]}" | grep '/gibbs/html/' | cut -d '"' -f 2)
            Level3Links+=($CurrentLink)
            echo "$CurrentLink">>"$OutputL3Seed"
        done
    else
        while read URL; do
            echo "Reading L3 Link from Seed: $URL"
            Level3Links+=("$URL")
        done <$L3SeedFile
    fi
fi
echo "Done"
echo

echo "Harvesting Satellite Images and links..."
if [ ! -z "$SatImgSeedFile" ]; then
    echo "   -Skipping link harvest to downloading images, Sat Image Seed File specified"
    SatImgSkip=true
fi
if [ "$SatImgSkip" == false ]; then
    for ((l=0; l<${#Level3Links[@]}; ++l)); do
        CurrentPath=$(lynx -source "$SourceSiteRoot${Level3Links[$l]}" | grep 'satImage' | cut -d '"' -f 6)
        echo "$CurrentPath">>"$OutputSatImgSeed"
        CurrentFileName=$(echo "$SourceSiteRoot${Level3Links[$l]}" | rev | cut -d '/' -f 1 | rev)
        DerivedPath=$(echo "$SourceSiteRoot$CurrentPath" | cut -d ':' -f 2 | cut -c 2- | rev | grep -o "/.*" | cut -c 2- | rev)
        wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$CurrentPath"
        if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
            wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$CurrentPath"
        fi
        if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
            wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$CurrentPath"
        fi
        if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
            wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$CurrentPath"
        fi
        if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
            $CurrentPath>>"$FailedDLList"
        fi
    done
else
    while read URL; do
            echo "Reading Sat Image Link from Seed: $SourceSiteRoot$URL"
            CurrentFileName=$(echo "$SourceSiteRoot$URL" | rev | cut -d '/' -f 1 | rev)
            DerivedPath=$(echo "$SourceSiteRoot$URL" | cut -d ':' -f 2 | cut -c 3- | rev | grep -o "/.*" | cut -c 2- | rev)
            wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$URL"
            if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
                wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$URL"
            fi
            if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
                wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$URL"
            fi
            if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
                wget -N -c -P "$Destination$DerivedPath/" "$SourceSiteRoot$URL"
            fi
            if [ ! -f "$Destination$DerivedPath/$CurrentFileName" ]; then
                lynx -source "$SourceSiteRoot$URL" | grep 'satImage' | cut -d '"' -f 6>>"$FailedDLList"
            fi
    done <$SatImgSeedFile
fi
echo "Done"