# Installing d3 on your first admin machine

Be sure to follow the steps in ["Preparing the servers"](Setup-server-prep.md) first!



To continue setup, you need to install d3 onto your own machine, and start using d3admin.

d3 and d3admin are command-line tools. You'll be doing all this in a terminal.

## Installing the depot3 gem

the command `sudo gem install depot3` should install the d3 libraries, the ruby-jss libraries and all other dependencies.

If you store rubygems in non-standard places, you might want to use the --install-dir option. By default, OS X (10.9 and up, which d3 requires) it should end up in 

/Library/Ruby/Gems/2.0.0/(gems/doc/bin..)

Once installed you should be able to access the executables in the bin directory of your system-wide gem home (/Library/Ruby/Gems/2.0.0/bin)

You should leave those there, but symlink to them from elsewhere, like /usr/local/bin or /usr/local/sbin.

Test out that it's installed by typing `d3 --version`

## Initial configuration

### ruby-jss.conf for API and Database access
Make a copy of the default ruby-jss config file located in the "data" folder of the newly-installed gem. (e.g. /Library/Ruby/Gems/2.0.0/gems/ruby-jss-\<version>/data/ruby-jss.conf.default)

Open up your copy of ruby-jss.conf.default, and **read through it**, adding values as appropriate.  

**IMPORTANT:**  This is where you'll put the **read-only** account names you created in 
["Preparing the servers"](Setup-server-prep.md)

When finished, put your edited copy into /etc/ruby-jss.conf.  You'll also eventually be distributing this file to all your client computers.

### d3.conf for d3 client and admin settings.
Make a copy of the default d3 config file located in the "data" folder of the newly-installed gem. (e.g. //Library/Ruby/Gems/2.0.0/gems/depot3-\<version>/data/d3.conf.default)

Open up your copy of d3.conf.default, and **read through it**, adding values as appropriate.  

For some basic vocabulary that might be useful, see [The d3 wiki](https://github.com/PixarAnimationStudios/depot3/wiki#basic-vocabulary)

**IMPORTANT:**   Credentials for read-write access will be dealt with in [Setup-d3admin](Setup-d3admin.md)

When finished, put your edited copy into /etc/d3.conf.  You'll also eventually be distributing this file to all your client computers.
