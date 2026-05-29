The Honda Dealership Management System (Honda DMS) is a full-stack desktop application designed to digitize and streamline the complete operational lifecycle of a Honda Motor Company authorized dealership network. The system addresses a critical gap in existing dealership software: most solutions manage only the point-of-sale transaction, ignoring the upstream manufacturing pipeline and the downstream after-sale service chain. Honda DMS solves this by implementing a 10-table relational database that models the entire flow from factory floor to service workshop. 

setup.sql runs all of the 'Create Tables' 'Insert' and creating triggers, procedures and indexes. 

Project_Documentation.md gives you a rundown of everything tackled in this project

Data relationships and importance shows you the relation between tables and how they are linked with each other

First create the tables by running setup.sql in a sql program for instance, i made my sql tables in Sql Management Server 2022
After creating the tables you need to update the get_connection parameters in api.py.

To get the server name when SSMS opens, you usually see:

Connect to Server

Look at the Server name field.

Examples:

DESKTOP-ABC123,
DESKTOP-ABC123\SQLEXPRESS,
localhost,
(localdb)\MSSQLLocalDB,

That exact text is your server name.
If we talk about SQL Management server 2022, the server name is 'DESKTOP-ABC123'. 
Add this in the server name
and in the parameter below server name in api.py, add the name of the database which for this instance is 'honda_dms'
You can change the database name in the setup.sql to your liking when youll copy paste that file as a new query in the sql managemenet server.
