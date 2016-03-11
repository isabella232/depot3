# Adding your first package to d3

## Configuring d3admin

The d3admin utility should be installed in the bin directory of your system-wide gem home (/Library/Ruby/Gems/2.0.0/bin), and you may (should) have symlinked it from /usr/local/

d3admin can never be run as root. It runs as the user of the terminal process, who is expected to be a d3 administrator.

The config process will store read-write credentials for d3 in that users keychain, and d3admin will later retrieve them from there as needed. If d3admin finds them missing, it will re-prompt for them.

Other persistent settings are store in your local d3admin prefs file.

Configure d3admin now with the 'config' action: `d3admin config` and follow the prompts.

Here's what you should see:

```
********  JSS-API LOCATION AND READ-WRITE CREDENTIALS  ********

Enter the server hostname for the JSS API
Hit return for casper.myorg.org
JSS API Server: 

Enter the port number for the JSS API on casper.myorg.org
Hit return for 8443
JSS API port: 
Checking connection to casper.myorg.org
Username for RW access to the JSS API on casper.myorg.org: rw-api-user
Password for chrisl @ the JSS API on casper.myorg.org: 
Thank you, the credentials have been saved in your OS X login keychain

********  JSS MYSQL LOCATION AND READ-WRITE CREDENTIALS  ********

Enter the server hostname for the JSS MySQL DB
Hit return for casper.myorg.org
JSS MySQL DB Server: 

Enter the port number for the JSS MySQL DB on casper.myorg.org
Hit return for 3306
JSS MySQL DB port: 
Checking connection to casper.myorg.org
Username for RW access to the JSS MySQL db at casper.myorg.org: d3admin
Password for d3admin @ the JSS MySQL db at casper.myorg.org: 
Thank you, the credentials have been saved in your OS X login keychain

********  MASTER DIST-POINT READ-WRITE PASSWORD  ********
Password for read-write access to the JSS Master Distribution Point:
Thank you, the credentials have been saved in your OS X login keychain

********  LOCAL PKG/DMG BUILD WORKSPACE  ********

PACKAGE BUILD WORKSPACE
Enter the path to a folder where we can build packages.
This will be stored between uses of d3admin.
Package build workspace (Hit return for '/Users/myacct/build/d3roots'): 
Thank you, the path has been saved in your d3admin prefs

********  .PKG IDENTIFIER PREFIX  ********

PKG IDENTIFIER PREFIX
Enter the prefix to prepend to a basename to create an Apple .pkg indentifier.
E.g. If you enter 'com.mycompany', then when you build a .pkg with basename 'foo'
the default .pkg identifier  will be 'com.mycompany.foo'
Please enter a value (Hit return for 'com.pixar.d3v3'): org.myorg
Thank you, the prefix has been saved in your d3admin prefs

```

## Add a package

Locate a .pkg or .dmg somewhere to use as a test package.

Then run `d3admin add firsttest --walkthru`

d3admin will search for any older packages with the basename 'firsttest' (for inheriting settings)  and the present you with the walkthru-menu for adding a package:

```
------------------------------------
Adding pilot d3 package 'firsttest-1-1'
with global default values
------------------------------------

1) Version: 1
2) Revision: 1
3) JSS Package Name: firsttest-1-1
4) Description: 
----

----
5) Dist. Point Filename: firsttest-1-1.pkg
6) Category: d3-package
7) Limited to OS's: none
8) Limited to CPU type: none
9) Needs Reboot: false
10) Uninstallable: false
11) Uninstalls older installs: false
12) Installation prohibited by processes matching: none
13) Auto installed for groups: none
14) Not installed for groups: none
15) Pre-install script: none
16) Post-install script: none
17) Pre-uninstall script: none
18) Post-uninstall script: none
19) Expration: 0
20) Expration Path: none
21) Source path: ---Required---
Which to change? (1-21, x=done, ^c=cancel):
```

Type a number to change that value. See [Packages](Packages) for definitions of all the settings.

You must provide a source for the new package, so for item 21, enter the path the the .pkg or .dmg  you're using to test with.

When everything looks good type `x` then return.

You should see this:

```
*****************************************
Ahoy there! You are about to:
Create a new package 'firsttest-1-1' in d3
with settings shown above.
*****************************************

Are you SURE? (y/n):
```

Go for it - type `y` !


```
Saving new pilot firsttest-1-1 to the server...
Indexing...
Uploading to the Master Distribution Point...
Done!
To pilot it, run 'sudo d3 install firsttest-1-1' on a test machine.
To make it live, run 'd3admin live firsttest-1-1' on your machine.
```

And there you have it... you'd added a package to d3.  Look in Casper and you'll see your new package there. 

Note that it's name will be whatever you chose for 'JSS Package Name' (the packages edition, by default), not necessarily the name of the .pkg or .dmg you used as a source.

Lets confirm d3 sees it as a pilot package on the server:

```
% d3admin show
#------' ' next, 'b' prev, 'q' exit, 'h' help ------
# All packages in d3
# Edition      Status     Added      By        Released   By        
#-----------------------------------------------------------
firsttest-1-1  pilot      2016-03-10 chrisl    -          -         
```

Wheee....
