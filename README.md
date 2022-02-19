# RichMonitoring

RichMonitoring is a SQL Server Inventory soloution that takes information from a number of System Views & DMV's on a schedule you define and loads them into tables for querying and reporting.

# What Is Collected

RichMonitoring currently collects the following data points - as part of RichMonitoring **NOTHING** leaves your SQL Enviroment **EVER**

- Information on Database Files 
- A list of all databases on the instance
- The size of each database on the instance
- All of the SQL Agent Jobs on the instance
- All of the logins on the instance, this covers both Windows & SQL Logins
- All of the objects on the instance, this loops each database and collects each object individually 
- All of the logins on the instance that are sysadmin
- The RichMonitoring soloution also has JobHistory archiving built in allowing SQL Agent Job logs to be moved to an archive table inside RichMonitoring, this is fully configurable from ```Config.AppConfig```. 

All of the above collection points are configurable, you can turn them on or off in the ```Config.Inventory``` table.

# Installation 

Installation is easy, run the ```Installation.sql``` script on your SQL Server and RichMonitoring will be installed. For the installation to suceed you will need the following permissions;

- Create Databases
- Create Objects
- Delete Objects
- Alter Objects
- Insert into objects

Note: A SQL Server Agent job will be created with no schedule attached, you will need to create a schedule to run at a frequency that fits with your needs for the collection to automatically work. 

# Configuration

When the soloution is installed, it is installed with the default settings. All of the collection points are inactive.

### Enabling a collection point 

1. Find which collection points you would like to enable 

```SELECT * FROM RichMonitoring.Config.Inventory```

2. Update Config.Inventory setting the collection points that you wish to use to active (replacing 1,2,3 with the ID of the collection points you want)

```UPDATE RichMonitoring.Config.Inventory SET Active = 1 WHERE ID IN (1,2,3)```

### Managing Data Retention

The RichMonitoring soloution will delete any Inventoried datapoints that are (by default) older then 30 days. If you would like to keep data for longer than this you can 100% do that. 

```UPDATE [RichMonitoring].[Config].[AppConfig] SET INTValue = -180 WHERE ID = 1```

Replace -180 with the amount of days you would like to keep 

# Running RichMonitoring Manually

If you would like to run RichMonitoring manually simply run the following command

```EXEC RichMonitoring.app.usp_RunInventory```

This will start the Inventory collection.

# Can I see what was run and when?

Sure, RichMonitoring has a RunLog, you can query this to see what was run when, this table falls within the Data Retention as mentioned in the Configuration section of this article so data will be purged in line with that configuration. 

```SELECT * FROM RichMonitoring.Inventory.RunLog```


# FAQ

- Q. Does RichMonitoring support Always On Availability groups?
- A. At the moment RichMonitoring doesn't officially support Always On Availability groups, though this is something we want to add in the future. 

- Q. Does RichMonitoring send any emails specific to the data collected?
- A. No RichMonitoring doesn't send any emails, we do plan to add this feature in the future but when we do no sensitive data will ever leave your enviroment and most certainly won't be sent to RichInSQL.

- Q. Do you have plans to add additional datapoints?
- A. 100% Yes, after the initial release, RichInSQL plans to expand RichMonitoring to collect more information about your SQL Server.

# How can we get help? 

RichMonitoring comes as is for all non RichInSQL Clients, if you find a problem with RichMonitoring or it doesn't do something you wish it did, you have a few options available to you;

1. Open a Issue right here on GitHub
2. Fork the Repo, Fix the issue and open a pull request so we can improve RichMonitoring for others. 