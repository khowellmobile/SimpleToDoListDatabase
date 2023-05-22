# SimpleToDoListDatabase

A database to be used for a simple To Do List Application

## Description

The script included can be used to create a data base for a simple To Do List Application. The database supports adding, updating, and deleting users, lists, and tasks.
It also supports the begining infrastructure of a login system and funtionality to store error information in a seperate table.

## Project Requirements

- The system will be used by more than 1 person (so you need to be able to log in, and log out)
- There must be a way to Add / Update / soft Delete a user account
- Users can log in and log out (note: the system may not have to do anything when a user logs out but you should have a PROC in place for it)
- UserNames must be unique
- Passwords must be hashed - (optional: consider implementing SALT into your hash)
- Users should be able to create a ToDo List ( eg, Home, Shopping, Projects, etc... )
- Users should be able to add to-do items under a ToDo List ( eg, Home { cut lawn, clean kitchen, walk dog, ... } )
- Users should be able to Update/Delete to-do items (optional: consider the ability to move a to-do item from one list to another)

![ERD](ToDoListDBERD.drawio.pdf)

## Authors

Contributors names and contact info

Kent Howell - khowellmobile@gmail.com <br>
Dean Qasem - qasemdf@miamioh.edu
