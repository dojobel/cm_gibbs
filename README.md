# cm_gibbs
Script built specifically for ripping the Satellite Images from the GIBBS website, made for Climate Mirror. 

# Description
cm_gibbs.sh is a Bash script that will crawl the GIBBS website (https://www.ncdc.noaa.gov/gibbs/) and find links to any Satellite Images, then download them. The script works by crawling the site from the top-level, all the way down to the page containing the actual image and its viewer.

# Usage
Edit the script and adjust the "Destination" variable to the folder you want the files to be downloaded into. Feel free to adjust any other variables, but bear in mind this may produce unintended results.

Feel free to use one of the provided seed files to save yourself at least 12 hours of crawling (explained below).

Finally, add Execute attribute and run the script with:

```
chmod +x cm_gibbs.sh
./gibbs.sh
```

# Seed Files
The script generates what is referred to as a "Seed File" at each level of the website it drills down to. The seed file is simply a text file, populated with all of the crawled links from the site. This saves tremendous time as the site essentially only needs to be crawled once to have all of the links.

The seed files are broken down into 3 levels, then a final 4th level which is purely the image links (not any page). You only need the highest numbered seed file to pick up the crawler (i.e. if you have a Level 3 Seed file, you don't need to specify or even have level 1 and 2 seed files).

Level 1 = The home page (with all of the Years displayed)
Level 2 = The Year page (with all of the months and dates displayed)
Level 3 = The Image selection page
"SatImg" = The actual link to the images

I have pre-seeded all the way up to Level 3; a total time cost of well over 12 hours to harvest these links. They are a part of the repository under the https://github.com/dojobel/cm_gibbs/tree/master/seed folder.

To use the seed file, simply populate the variable in the script with the name of the text file extracted from the seed's tar.gz. Choose the highest numbered seed file that is available as it will have made the most progress crawling the site.

# Fault-tolerance
There are some basic fault-tolerance mechanisms built-in.

The script will not overwrite a file that already exists, and if a file is attempted for download but is missing after the download command, it will attempt 3 further times before giving up on the file. In the event that this happens, the script will write-out the link to the skipped file to a failed downloads text file for the user to obtain manually. 
