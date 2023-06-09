/*
*
*		Assignment: 385-Project_ToDo 
*		Date: 4/29/2022
*		Authors:
*			Kent Howell (Section D)
*			Dean Qasem	(Section A)
*
*/


USE master
GO

/****** Object:  Database ToDo     ******/
DROP DATABASE IF EXISTS ToDo;
GO

CREATE DATABASE ToDo
GO 

USE ToDo
GO

/****** Object:  Table Users  ******/   
CREATE TABLE Users(
	UserID		INT				NOT NULL		IDENTITY	PRIMARY KEY,
	password	VARCHAR(150)	NOT NULL,
	UserName	VARCHAR(50)		NOT NULL,
	FirstName	VARCHAR(50)		NULL,
	LastName	VARCHAR(50)		NULL,
	isDeleted	BIT				NOT NULL		DEFAULT(0)


)
GO

/****** Object:  Table ToDoLists     ******/
CREATE TABLE ToDoLists(
	ToDoListID		INT		    NOT NULL		IDENTITY		PRIMARY KEY,
	UserID			INT			NOT NULL		FOREIGN KEY		REFERENCES Users(UserID),
	Name			VarChar(50)	NOT NULL,
	isDeleted		BIT			NOT NULL		DEFAULT(0)



) 
GO

/****** Object:  Table Tasks     ******/

CREATE TABLE Tasks(
	TaskID				INT				NOT NULL		IDENTITY		PRIMARY KEY,
	ToDoListID			INT				NOT NULL		FOREIGN KEY		REFERENCES	ToDoLists(ToDoListID),
	TaskDescription		VARCHAR(MAX)	NOT NULL,
	CompleteByDate		DATE			NULL,
	CompletedDate		DATE			NULL			DEFAULT(NULL),
	isDeleted			BIT				NOT NULL		DEFAULT(0)
)
GO


/****** Object:  Table ErrorTable     ******/

CREATE TABLE ErrorTable (
		errorID			INT				PRIMARY KEY		IDENTITY,
		ERROR_PROCEDURE	VARCHAR(200)	NULL,
		ERROR_LINE		INT				NULL,
		ERROR_MESSAGE	VARCHAR(500)	NULL,
		PARAMETERS		VARCHAR(MAX)	NULL,
		USER_NAME		VARCHAR(100)	NULL,
		ERROR_NUMBER	INT				NULL,
		ERROR_SEVERITY	INT				NULL,
		ERROR_STATE		INT				NULL,
		ERROR_DATE		DATETIME		NOT NULL	DEFAULT(GETDATE()),
		FIXED_DATE		DATETIME		NULL

)
GO

/********************************************* STORED PROCEDURES	*************************************/
CREATE PROCEDURE spRecordError
	@params	VARCHAR(MAX) = NULL
AS BEGIN SET NOCOUNT ON
	INSERT INTO ErrorTable
		SELECT
			 ERROR_PROCEDURE()	
			,ERROR_LINE()		
			,ERROR_MESSAGE()	
			,@params		
			,ORIGINAL_LOGIN()		
			,ERROR_NUMBER()	
			,ERROR_SEVERITY()	
			,ERROR_STATE()		
			,GETDATE()		
			,NULL	
END
GO

CREATE PROCEDURE spValidateLogin
	@UserName	VARCHAR(100),
	@password	VARCHAR(150)
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN
		BEGIN TRY
		
		IF NOT EXISTS(SELECT NULL FROM Users WHERE (HASHBYTES('SHA2_512', @password) = password) AND (@UserName = UserName))
				THROW 90000, 'Password and UserName combination invalid',1

		/*- Login code goes here-*/

		SELECT	UserID
		FROM	Users
		WHERE	
			(UserName = @UserName) AND
			(password = HASHBYTES('SHA2_512', @password))

		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
					 [@UserName]	=	@UserName
					,[@password]	=	@password
				FOR JSON PATH
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
END
GO

CREATE PROCEDURE spLogOut
	@UserID		INT
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN
		BEGIN TRY
			IF NOT EXISTS(SELECT NULL FROM Users WHERE UserID = @UserID)
				THROW 90002, 'UserId does not exist',1

			/*- Log out code goes here-*/

			UPDATE Users SET isDeleted = 1 WHERE UserID = @UserID
		END TRY BEGIN CATCH
				IF(@@TRANCOUNT  > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT [@UserID] = @UserID 
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
GO

------------------------------------------------ Users Add/Update/Delete ------------------------------------

CREATE PROCEDURE spUsers_Add			
	 @password	VARCHAR(150)		
	,@UserName	VARCHAR(50)		
	,@FirstName	VARCHAR(50)		
	,@LastName	VARCHAR(50)		
	,@isDeleted BIT = NULL
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN 
		BEGIN TRY
			IF EXISTS(SELECT NULL FROM Users WHERE UserName = @UserName)
				THROW 90001, 'Duplicate user-name not allowed',1
			INSERT INTO Users
				SELECT
					 HASHBYTES('SHA2_512', @password)
					,@UserName	
					,@FirstName	
					,@LastName
					,0    
		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
					 [@password]	=	HASHBYTES('SHA2_512', @password)
					,[@UserName]	=	@UserName
					,[@FirstName]	=	@FirstName
					,[@LastName]	=	@LastName
					,[@isDeleted]	=	@isDeleted
				FOR JSON PATH
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO


CREATE PROCEDURE spUsers_Delete
	@UserID		INT
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN
		BEGIN TRY
			IF NOT EXISTS(SELECT NULL FROM Users WHERE UserID = @UserID)
				THROW 90002, 'UserId does not exist',1
			IF EXISTS(SELECT NULL FROM Users WHERE (UserID = @UserID) AND (isDeleted = 1))
				THROW 90003, 'User was already deleted', 1
			UPDATE Users SET isDeleted = 1 WHERE UserID = @UserID
		END TRY BEGIN CATCH
				IF(@@TRANCOUNT  > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT [@UserID] = @UserID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
GO

CREATE PROCEDURE spUsers_Update
		 @UserID	INT
		,@password	VARCHAR(50)		= NULL
		,@UserName	VARCHAR(50)		= NULL
		,@FirstName	VARCHAR(50)		= NULL
		,@LastName	VARCHAR(50)		= NULL
		,@isDeleted	BIT				= NULL

    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF NOT EXISTS(SELECT NULL FROM Users WHERE UserID = @UserID)
					THROW 90002, 'UserID does not exist', 1
				IF EXISTS(SELECT NULL FROM Users WHERE (UserID = @UserID) AND (isDeleted = 1))
					THROW 90004, 'Cannot update User because it is marked as deleted', 1
				SELECT
					 @password		= ISNULL(@password	 , password)
					,@UserName		= ISNULL(@UserName	 , UserName)
					,@FirstName		= ISNULL(@FirstName  , FirstName)
					,@LastName		= ISNULL(@LastName	 , LastName)
					,@isDeleted		= ISNULL(@isDeleted  , isDeleted)

				FROM Users
				WHERE UserID = @UserID
			
				IF EXISTS(SELECT NULL FROM Users WHERE UserName = @UserName)
					THROW 90001, 'Duplicate user-name not allowed',1


				-- Do the actual UPDATE HERE
				UPDATE Users SET	 
					 password	  	=  	@password	
					,UserName	  	=  	@UserName	
					,FirstName  	=  	@FirstName
					,LastName	  	=  	@LastName	
					,isDeleted  	=  	@isDeleted
				WHERE UserID = @UserID

			END TRY BEGIN CATCH			   
				IF(@@TRANCOUNT  > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT 
						 [@password]	=	@password  
						,[@UserName]	=	@UserName  
						,[@FirstName]	=	@FirstName  
						,[@LastName]	=	@LastName  
						,[@isDeleted]	=	@isDeleted
					FOR JSON PATH
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
GO

-------------------------------------------------------- Tasks Add/Update/Delete -----------------------------

CREATE PROCEDURE spTasks_Add
	 @ToDoListID		    INT,
	 @TaskDescription		VARCHAR(MAX),
	 @CompleteByDate		DATE			= NULL,		
	 @CompletedDate			DATE			= NULL,		
	 @isDeleted				BIT				= NULL		
	AS BEGIN SET NOCOUNT ON
		BEGIN TRAN 
			BEGIN TRY

				INSERT INTO Tasks
					SELECT
						@ToDoListID,		
						@TaskDescription,	
						@CompleteByDate,	
						@CompletedDate,
						0

			END TRY BEGIN CATCH
				IF(@@TRANCOUNT > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(max) = (
					SELECT
						[@ToDoListID]			=		@ToDoListID,			
						[@TaskDescription]		=		@TaskDescription,	
						[@CompleteByDate]		=		@CompleteByDate,	
						[@CompletedDate]		=		@CompletedDate,
						[@isDeleted]			=		@isDeleted
					FOR JSON PATH
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

CREATE PROCEDURE spTasks_Update

		 @TaskID			INT
		,@ToDoListID		INT					= NULL
		,@TaskDescription	VARCHAR(MAX)		= NULL
		,@CompleteByDate	DATE				= NULL
		,@CompletedDate		DATE				= NULL
		,@isDeleted			BIT					= NULL

    AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF NOT EXISTS(SELECT NULL FROM Tasks WHERE TaskID = @TaskID)
					THROW 90005, 'TaskID does not exist', 1
				IF EXISTS(SELECT NULL FROM Tasks WHERE (TaskID = @TaskID) AND (isDeleted = 1))
					THROW 90006, 'Cannot update Task because it is marked as deleted', 1

				SELECT
					 @ToDoListID		= ISNULL(@ToDoListID		, ToDoListID)
					,@TaskDescription	= ISNULL(@TaskDescription	, TaskDescription)
					,@CompleteByDate	= ISNULL(@CompleteByDate	, CompleteByDate)
					,@CompletedDate		= ISNULL(@CompletedDate		, CompletedDate)
					,@isDeleted			= ISNULL(@isDeleted			, isDeleted)

				FROM Tasks
				WHERE TaskID = @TaskID

				-- Do the actual UPDATE HERE
				UPDATE Tasks SET	 
					 ToDoListID			=  	@ToDoListID
					,TaskDescription	=  	@TaskDescription
					,CompleteByDate		=  	@CompleteByDate
					,CompletedDate		=  	@CompletedDate
					,isDeleted			=  	@isDeleted
				WHERE TaskID = @TaskID

			END TRY BEGIN CATCH			   
				IF(@@TRANCOUNT  > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT
						 [@TaskID]			=	@TaskID
						,[@ToDoListID]		=	@ToDoListID
						,[@TaskDescription]	=	@TaskDescription
						,[@CompleteByDate]	=	@CompleteByDate
						,[@CompletedDate]	=	@CompletedDate
						,[@isDeleted]		=	@isDeleted
					FOR JSON PATH
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

CREATE PROCEDURE spTasks_Delete
	@TaskID	INT
	AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF NOT EXISTS(SELECT NULL FROM Tasks WHERE TaskID = @TaskID)
					THROW 90005, 'TaskID does not exist',1
				IF EXISTS(SELECT NULL FROM Tasks WHERE (TaskID = @TaskID) AND (isDeleted = 1))
					THROW 90006, 'TaskID was already deleted', 1
			UPDATE Tasks SET isDeleted = 1 WHERE TaskID = @TaskID

			END TRY BEGIN CATCH
				IF(@@TRANCOUNT  > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT [@TaskID] = @TaskID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO


--------------------------------------------------------- ToDo Add/Delete --------------------------------------

CREATE PROCEDURE spToDoLists_Add
	 @UserID		INT,	
	 @Name			VARCHAR(50),
	 @isDeleted		BIT				= NULL
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN 
		BEGIN TRY
			INSERT INTO ToDoLists
			SELECT
				@UserID,
				@Name,
				0
		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
					[@UserID]		=	@UserID,
					[@Name]			=	@Name,
					[@isDeleted]	=	@isDeleted
				FOR JSON PATH
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

CREATE PROCEDURE spToDoLists_Delete
	@ToDoListID		INT
	AS BEGIN SET NOCOUNT ON
		BEGIN TRAN
			BEGIN TRY
				IF NOT EXISTS(SELECT NULL FROM ToDoLists WHERE ToDoListID = @ToDoListID)
					THROW 90005, 'ToDOListID does not exist',1
				IF EXISTS(SELECT NULL FROM ToDoLists WHERE (ToDoListID = @ToDoListID) AND (isDeleted = 1))
					THROW 90006, 'ToDoListID was already deleted', 1
				UPDATE ToDoLists SET isDeleted = 1 WHERE ToDoListID = @ToDoListID
			END TRY BEGIN CATCH
				IF(@@TRANCOUNT  > 0) ROLLBACK TRAN
				DECLARE @p VARCHAR(MAX) = (
					SELECT [@ToDoListID] = @ToDoListID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				EXEC spRecordError @p
			END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
    END
GO


-------------------------------------------------- Functionality Stored Procedures ----------------------------


/* Shows all the tasks on a certain to do list */
CREATE PROCEDURE spTasksOnToDoList
	 @ToDoListID		VARCHAR(50)
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN 
		BEGIN TRY
			IF NOT EXISTS(SELECT NULL FROM ToDoLists WHERE ToDoListID = @ToDoListID)
					THROW 90007, 'ToDoListID does not exist', 1

			/* Getting the associated tasks */
			SELECT
				TaskDescription,
				CompleteByDate,
				CompletedDate
			FROM
				Tasks
			WHERE
				ToDoListID = @ToDoListID

		END TRY BEGIN CATCH

			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
						[@ToDoListID]		=		@ToDoListID
			)
			EXEC spRecordError @p

		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

/* Shows a users uncompleted tasks */
CREATE PROCEDURE spUsers_UncompletedTasks
	 @UserID		VARCHAR(50)
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN 
		BEGIN TRY
			IF NOT EXISTS(SELECT NULL FROM Users WHERE (UserID = @UserID))
					THROW 90002, 'UserID does not exist', 1

			SELECT
				tdl.name,
				t.TaskID,
				t.TaskDescription,
				t.CompleteByDate
			FROM
						Users		u
				JOIN	ToDoLists	tdl		ON u.UserID = tdl.UserID
				JOIN	Tasks		t		ON t.ToDoListID = tdl.ToDoListID
			WHERE
				(@UserID = u.userID) AND
				(t.CompletedDate IS NULL)

		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
					[@UserID]		=	@UserID
				FOR JSON PATH
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

/* Shows a users completed tasks */
CREATE PROCEDURE spUsers_CompletedTasks
	 @UserID		VARCHAR(50)
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN 
		BEGIN TRY
			IF NOT EXISTS(SELECT NULL FROM Users WHERE (UserID = @UserID))
					THROW 90002, 'UserID does not exist', 1

			SELECT
				tdl.name,
				t.TaskID,
				t.TaskDescription,
				t.CompleteByDate,
				t.CompletedDate
			FROM
						Users		u
				JOIN	ToDoLists	tdl		ON u.UserID = tdl.UserID
				JOIN	Tasks		t		ON t.ToDoListID = tdl.ToDoListID
			WHERE
				(@UserID = u.userID) AND
				(t.CompletedDate IS NOT NULL)

		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
						[@UserID]	=	@UserID
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

/* Shows a users to do lists */
CREATE PROCEDURE spUsers_ToDoLists
	@UserID			INT
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN
		BEGIN TRY
			IF NOT EXISTS (SELECT NULL FROM Users WHERE UserID	= @UserID)
				THROW 90002, 'UserID does not exist',1
			SELECT
				u.UserID,
				u.UserName,
				tdl.Name
			FROM
						Users		u
				JOIN	ToDoLists	tdl		ON		u.UserID	=	tdl.UserID
			WHERE
				u.UserID		=		@UserID
		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
						[@UserID]	=	@UserID
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

/* Shows a complete list of a users to do lists and all tasks on that to do list in a JSON Object */
CREATE PROCEDURE spUsers_ToDoLists_Tasks
	 @UserID		VARCHAR(50)
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN 
		BEGIN TRY
			IF NOT EXISTS(SELECT NULL FROM Users WHERE UserID = @UserID)
					THROW 90002, 'UserID does not exist', 1

			SELECT(
				SELECT 
					UserID,
					UserName,
					[ToDoLists] = (
						SELECT	
							ToDoListID,
							Name,
							[Tasks] = (
								SELECT	TaskDescription, CompleteByDate, CompletedDate
								FROM	Tasks t
								WHERE	(t.ToDoListId = tdl.ToDoListId) AND (t.isDeleted = 0)
								FOR JSON PATH
							)
						FROM	ToDoLists tdl
						WHERE	(tdl.UserID = u.UserID) AND (tdl.isDeleted = 0) 
						FOR JSON PATH
					)
				FROM
					Users u
				WHERE
					(u.UserID = @UserID)
				FOR JSON AUTO
			)FOR XML PATH('')

		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
						[@UserID]	=	@UserID
			)
			EXEC spRecordError @p
		END CATCH
	IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

/* Will update a task to completed */
CREATE PROCEDURE spTasks_CompleteTask
	@TaskID		INT		
AS BEGIN SET NOCOUNT ON
	BEGIN TRAN
		BEGIN TRY
			IF EXISTS(SELECT NULL FROM Tasks WHERE (TaskID = @TaskID) AND (CompletedDate != NULL))
				THROW 90009, 'Task was already completed', 1
			IF EXISTS(SELECT NULL FROM Tasks WHERE (TaskID = @TaskID) AND (isDeleted = 1))
				THROW 90010, 'This Task has been deleted', 1
			UPDATE Tasks SET
				CompletedDate		=	GETDATE()
			WHERE
				@TaskID = TaskID
		END TRY BEGIN CATCH
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			DECLARE @p VARCHAR(max) = (
				SELECT
						[@TaskID]	=	@TaskID
			)
			EXEC spRecordError @p
		END CATCH
		IF(@@TRANCOUNT > 0) COMMIT TRAN
	END
GO

USE master
GO