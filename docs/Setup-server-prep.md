# Preparing the servers

## Casper/JSS

### Read-only API access for d3
If you  don't already have one, you'll need to create a single account in the JSS that has read-only access to JSS objects via the API.  If you want to limit which objects, use these:

- advanced computer searches
- buildings
- categories
- computer extension attributes
- computers
- file share distribution points
- ldap servers
- network segments
- packages
- policies
- scripts
- smart computer groups
- static computer groups
- users

(we'll see if thats enough!)

This account will be used by the clients for maintaining d3 packages locally.

### Read-write API access for d3admin
You'll also need one or more accounts that have at least read-only access to the objects listed above, but read-write access to these:

- packages
- scripts

This account will be used by the admins maintaining packages in d3. 

You could use a single account and share it with all the admins, or you could give each admin their own acct (better for tracking changes)

The admins will need to know the credentials for this acct.

## MySQL

d3 accesses the JSS MySQL database directly - yes, we know that JAMF doesn't like this, (and they know it happens) and it isn't wise in general, but this is how d3 enhances Casper's package handling. 

The reason is two-fold: 

1. d3 needs to store and retrieve extra data about packages, and it does so in a custom table called 'd3_packages' in the jamfsoftware database.

2. Accessing some kinds of data through the API is **painfully** slow, requiring looping through and retrieving (potentially thousands of) objects to get basic data about them.  Feature requests have been submitted to deal with this. 

All **writing** of data is via the API, except for the data in the custom table.

We also know that the database schema may change without notice from JAMF. This is why certain versions of d3 are tied to certain versions of Casper.

If you aren't comfortable doing this, then d3 may not be for you.

### Creating the custom d3_packages table

Using your favorite MySQL database tool, connect as a user who can create tables in the 'jamfsoftware' database.

Then execute this SQL statement to create the d3_packages table:

```
CREATE TABLE `d3_packages` (
  `added_by` varchar(30),
  `added_date_epoch` bigint(32) DEFAULT NULL,
  `apple_receipt_data` text,
  `auto_install_groups` text,
  `basename` varchar(60) NOT NULL,
  `excluded_groups` text,
  `expiration` int(11),
  `expiration_app_path` varchar(300),
  `package_id` int(11) NOT NULL,
  `post_install_id` int(11),
  `post_remove_id` int(11),
  `pre_install_id` int(11),
  `pre_remove_id` int(11),
  `prohibiting_process` varchar(100),
  `release_date_epoch` bigint(32)  DEFAULT NULL,
  `released_by` varchar(30),
  `remove_first` tinyint(1) DEFAULT '0',
  `revision` int(4) NOT NULL,
  `status` tinyint(1) DEFAULT 'pilot',
  `version` varchar(30) NOT NULL,
  KEY (`basename`),
  UNIQUE KEY (`package_id`),
  UNIQUE KEY `edition` (`basename`,`version`,`revision`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ;
```

### Read-only sql access for d3
If you don't already have one, you'll need to create a read-only SQL account on your JSS MySQL server. These tables will need to be read: 

- cloud\_distribution\_point
- computers\_denormalized
- d3\_packages (created above)
- extension\_attribute\_values
- package\_contents
- package\_receipts
- packages
- policies
- policy\_packages
- policy\_scripts

This account will be used by the clients for maintaining d3 packages locally.

### Read-write sql access for d3admin
You'll also need one or more accounts that have read-only access to tables above, but also have read-write access to 

- d3_packages (created above)

This will be used by the admins maintaining packages in d3. 

You could use a single account and share it with all the admins, or you could give each admin their own acct (better for tracking changes)

The admins will need to know the credentials for this acct.
