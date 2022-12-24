# STS-capture-from-cursor-cache-oracle
This is a shell script to capture the high load sql from cursor cache and dump it into a STS which is then packed to a staging table and backed up using export utility. This script can be specifically used before an upgrade which ping the cursor cache every 30 seconds till 15 minutes to collect all the sql information.
