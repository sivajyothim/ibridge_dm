-- phpMyAdmin SQL Dump
-- version 4.9.0.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 29, 2019 at 07:51 PM
-- Server version: 10.4.6-MariaDB
-- PHP Version: 7.3.8

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `ibridgedm`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_AuthenticateUser` (IN `_email` VARCHAR(100), IN `_password` VARCHAR(100))  BEGIN
	SET _email = TRIM(_email);
	SET _password = TRIM(_password);

	SELECT
		L.LoginId, L.UserId, L.Salt, L.Hash, L.IsDefaultPasswordChanged
		INTO 
		@loginId, @userId, @salt, @hash, @isDefaultPasswordChanged
	FROM 
		tblMstLogin L
	WHERE 
		L.eMail = _email
		AND L.IsActive = 1;
	
	SET @IsValidCredential = -1;
	
	IF IFNULL(@userId, -1) = -1 THEN
		/* email does not exists */
		SET @IsValidCredential = -1;
	ELSE
		IF @hash = UNHEX(SHA1(CONCAT(HEX(@salt), _password))) THEN
			SET @IsValidCredential = 1;
		ELSE
			/* EMAIL EXISTS BUT PASSWORD DID NOT MATCH */
			SET @IsValidCredential = -1;
		END IF;
	END IF;
	
	IF @IsValidCredential = -1 THEN
		/* SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credentials are incorrect'; */
		SELECT NULL AS UserId, NULL AS IsDefaultPasswordChanged, -1 AS ErrorCode;
	ELSE
		UPDATE tblMstLogin L SET 
			L.LastLoginOn = SYSDATE()
		WHERE
			L.LoginId = @LoginId;
			
		SELECT @userId AS UserId, @isDefaultPasswordChanged AS IsDefaultPasswordChanged, 0 AS ErrorCode;
	END IF;
END$$

CREATE DEFINER=`cpses_jrkmenhptq`@`localhost` PROCEDURE `usp_GetClients` (IN `clientId` SMALLINT, IN `userId` SMALLINT, OUT `errorCode` TINYINT)  BEGIN

	-- SET userId = IF(TRIM(IFNULL(userId, '')) = '', -1, userId);
	SET clientId = IF(TRIM(IFNULL(clientId, '')) = '', -1, clientId);


	IF clientId = -1 THEN
		SELECT 
			C.ClientId
			, C.ClientName
			, C.ContactNo
			, C.eMail
			, C.WebsiteURL
			, C.FacebookURL
			, C.YoutubeURL
			, C.InstagramURL
			, C.TwitterURL
			, C.PinterestURL
			, C.LinkedInURL
			, C.Active
			, IF(C.Active = 1, 'Active', 'Inactive') AS ActiveText
			, C.LastModifiedOn
			, U.Name
		FROM tblMstClients C
			LEFT JOIN tblMstUsers U ON C.LastModifiedBy = U.UserId;
	ELSE
		SELECT 
			C.ClientId
			, C.ClientName
			, C.ContactNo
			, C.eMail
			, C.WebsiteURL
			, C.FacebookURL
			, C.YoutubeURL
			, C.InstagramURL
			, C.TwitterURL
			, C.PinterestURL
			, C.LinkedInURL
			, C.Active
			, IF(C.Active = 1, 'Active', 'Inactive') AS ActiveText
			, C.LastModifiedOn
			, U.Name
		FROM tblMstClients C
			LEFT JOIN tblMstUsers U ON C.LastModifiedBy = U.UserId
		WHERE
			C.ClientId = clientId;
			
		-- get client services
		
		SELECT
			S.ServiceId
			, S.ServiceTypeId
			, S.ServiceName
			, IF(CS.ServiceId IS NULL, 0, 1) AS IsClientOpted
		FROM
			tblMstServices S
			LEFT JOIN tblClientServices CS ON CS.ServiceId = S.ServiceId
		WHERE
			CS.ClientId = clientId;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetClientServices` (IN `userId` SMALLINT(6), IN `clientId` SMALLINT(6), OUT `errorCode` TINYINT)  BEGIN

	SET userId = TRIM(IFNULL(userId, ''));
	SET clientId = TRIM(IFNULL(clientId, ''));
    SET errorCode = 0;
    
	SELECT 
		S.ServiceId
		, S.ServiceName
		, IF(CS.ServiceId IS NULL, 0, 1) AS IsOptedForThisEvent
	FROM 
		tblMstServices S
		INNER JOIN tblClientServices CS ON S.ServiceId = CS.ServiceId
	WHERE 
		CS.ClientId = clientId;
		
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetEventCategories` ()  BEGIN
	SELECT 
		EC.EventCategoryId
		, EC.CategoryName
		, EC.Active
		, EC.LastModifiedOn
		, EC.LastModifiedBy
	FROM 
		tblMstEventCategories EC
	WHERE 
		EC.Active = 1;
End$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetEventNamesForAjaxSearch` (IN `eventName` VARCHAR(250), IN `clientId` SMALLINT, OUT `errorCode` TINYINT)  BEGIN

	SET eventName = CONCAT(TRIM(IFNULL(eventName, '')), '%');
	SET clientId = IFNULL(clientId, -1);

	SELECT
		E.EventId
		, E.EventName
	FROM
		tblEvents E
	WHERE
		E.ClientId = clientId
		AND E.EventName LIKE eventName;
		
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetEvents` (IN `eventId` MEDIUMINT(9), IN `eventName` VARCHAR(250), IN `eventStatusId` TINYINT(3), IN `venue` VARCHAR(250), IN `guest` VARCHAR(500), IN `startDate_From` DATETIME, IN `startDate_To` DATETIME, IN `userId` SMALLINT(6), IN `clientId` SMALLINT(6), IN `orderByColumn` TINYINT, IN `orderAscDesc` BIT, IN `pageLength` TINYINT, IN `pageIndex` TINYINT, IN `startingRowNumber` SMALLINT(6), OUT `totalRows` MEDIUMINT(6), OUT `errorCode` TINYINT)  BEGIN

	SET eventId = TRIM(IFNULL(eventId, ''));
	SET userId = TRIM(IFNULL(userId, ''));
	SET clientId = TRIM(IFNULL(clientId, ''));
    SET errorCode = 0;
	
	IF eventId = '' OR eventId = '0' THEN
		
		SET eventName = CONCAT(TRIM(IFNULL(eventName, '')),'%');
		SET eventStatusId = TRIM(IFNULL(eventStatusId, ''));
		SET venue = CONCAT(TRIM(IFNULL(venue, '')),'%');
		SET guest = CONCAT('%' , TRIM(IFNULL(guest, '')) , '%');
		SET startDate_From = (IFNULL(startDate_From, '2000-01-01 00:00:00'));
		SET startDate_To = (IFNULL(startDate_To, sysdate()));
		SET startingRowNumber = ((pageIndex - 1) * pageLength) + 1;
		SET totalRows = 0;
	
		SELECT E.EventId
			, C.ClientName
			, E.EventCreatedBy
			, MU.Name AS CoordinatorName
			, E.EventName
			, MU.ContactNo
			, E.StartDateTime
			, E.EndDateTime
			, E.Venue
			, E.Guests
			, E.Speakers
			, ES.EventStatus AS EventStatus
		FROM 
			tblEvents E
			INNER JOIN 
			(
				SELECT 
					E1.EventId
				FROM 
					tblEvents E1
				WHERE
					IF(clientId = '', -1, E1.ClientId) = IF(clientId = '', -1, clientId)
					AND E1.EventName LIKE eventName
					AND IF(eventStatusId = '', -1, E1.EventStatusId) = IF(eventStatusId = '', -1, eventStatusId)
					AND E1.Venue LIKE venue
					AND E1.Guests LIKE guest
					AND E1.StartDateTime >= startDate_From AND E1.StartDateTime <= startDate_To
				ORDER BY
					CASE orderAscDesc
                        WHEN 0 THEN
                            CASE orderByColumn
                                WHEN 2 THEN E1.Venue
                                WHEN 3 THEN E1.StartDateTime
                                WHEN 4 THEN E1.EndDateTime
                                ELSE E1.EventName
                            END
					END,
                	CASE orderAscDesc
                        WHEN 1 THEN
                            CASE orderByColumn
                                WHEN 2 THEN E1.Venue
                                WHEN 3 THEN E1.StartDateTime
                                WHEN 4 THEN E1.EndDateTime
                                ELSE E1.EventName
                            END
					END DESC
				-- LIMIT pageLength OFFSET startingRowNumber 
			 ) AS T USING(EventId)
			INNER JOIN tblMstUsers MU ON MU.UserId = E.EventCreatedBy
			INNER JOIN tblMstClients C ON C.ClientId = E.ClientId
			LEFT JOIN tblMstEventStatuses ES ON ES.EventStatusId = E.EventStatusId;
             -- ON T.EventId = E.EventId;
			 
		 SELECT 
			NULL AS ServiceId
			, NULL AS ServiceName
			, NULL AS IsOptedForThisEvent;
	ELSE
		SELECT E.EventId
			, E.ClientId
			, E.EventCreatedBy
			, E.EventName
			, E.EventCategoryId
			, E.StartDateTime
			, E.EndDateTime
			, E.Venue
			, E.Guests
			, E.Speakers
			, E.Participants
			, E.EventDescription
			
			, E.EventStatusId
			, E.PostponedStartDateTime
			, E.PostponedEndDateTime
			, E.EventStatusDescription
			
			, E.IsNotificationSentToCoordinator
			, E.IsPhotoUploaded
			, E.IsVideoUploaded
			, E.IsSubmitedForDM
		FROM 
			tblEvents E
		WHERE 
			E.EventId = eventId;

		SELECT 
			S.ServiceId
			, S.ServiceName
			, IF(ES.ServiceId IS NULL, 0, 1) AS IsOptedForThisEvent
		FROM 
			tblMstServices S
			INNER JOIN tblClientServices CS ON S.ServiceId = CS.ServiceId
			LEFT JOIN tblEventServices ES ON CS.ServiceId = ES.ServiceId
		WHERE 
			CS.ClientId = clientId
			AND ES.EventId = eventId;
			
		-- PHOTOS AND VIDEOS WILL BE IN FIXED PHYSICAL PATH
		-- LEFT JOIN tblEventServiceData ESD ON ESD.EventServiceId = ES.EventServiceId
	END IF;
		
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetEventsSummary` (IN `userId` SMALLINT, IN `clientId` SMALLINT, OUT `errorCode` TINYINT)  BEGIN

	SET userId = TRIM(IFNULL(userId, -1));
	SET clientId = TRIM(IFNULL(clientId, -1));
	SET errorCode = 0;
	
	SELECT EventStatusId INTO @StatusId_Scheduled FROM tblMstEventStatuses WHERE EventStatus = 'Scheduled';
	SELECT EventStatusId INTO @StatusId_Started FROM tblMstEventStatuses WHERE EventStatus = 'Started';
	SELECT EventStatusId INTO @StatusId_Completed FROM tblMstEventStatuses WHERE EventStatus = 'Completed';
	SELECT EventStatusId INTO @StatusId_SubmittedForDM FROM tblMstEventStatuses WHERE EventStatus = 'SubmittedForDM';
	SELECT EventStatusId INTO @StatusId_DMStarted FROM tblMstEventStatuses WHERE EventStatus = 'DMStarted';
	SELECT EventStatusId INTO @StatusId_DMCompleted FROM tblMstEventStatuses WHERE EventStatus = 'DMCompleted';
	SELECT EventStatusId INTO @StatusId_Cancelled FROM tblMstEventStatuses WHERE EventStatus = 'Cancelled';
	SELECT EventStatusId INTO @StatusId_Postponed FROM tblMstEventStatuses WHERE EventStatus = 'Postponed';

	IF clientId > 0 THEN
		IF userId > 0 THEN 
			-- Client Coordinator
			SELECT
				SUM(IF(E.EventStatusId = @StatusId_DMCompleted, 1, 0)) AS Column1 -- DMCompleted
				, SUM(IF(E.EventStatusId = @StatusId_SubmittedForDM, 1, 0)) AS Column2 -- SubmittedForDM
				, SUM(IF(SYSDATE() > E.EndDateTime AND 
							(
								E.EventStatusId = @StatusId_Scheduled OR 
								E.EventStatusId = @StatusId_Started OR 
								E.EventStatusId = @StatusId_Completed 
							)
							, 1
							, 0
						)
					) AS Column3 -- EventCompletedAndNotSubmittedForDM
				, SUM(IF((SYSDATE() >= E.StartDateTime AND SYSDATE() <= E.EndDateTime) AND 
							(
								E.EventStatusId = @StatusId_Scheduled OR 
								E.EventStatusId = @StatusId_Started 
							)
							, 1
							, 0
						)
					) AS Column4 -- InProgressEvents
				, SUM(IF(SYSDATE() < E.StartDateTime AND E.EventStatusId = @StatusId_Scheduled , 1, 0)) AS Column5 -- UpcomingEvents
				, SUM(IF(E.EventStatusId = @StatusId_Cancelled, 1, 0)) AS Column6 -- Cancelled Events
			FROM
				tblEvents E
			WHERE
				E.ClientId = clientId
				AND E.EventCreatedBy = userId;
		ELSE
			-- Client Admin
			SELECT
				SUM(IF(E.EventStatusId = @StatusId_DMCompleted, 1, 0)) AS Column1 -- DMCompleted
				, SUM(IF(E.EventStatusId = @StatusId_SubmittedForDM, 1, 0)) AS Column2 -- SubmittedForDM
				, SUM(IF(SYSDATE() > E.EndDateTime AND 
							(
								E.EventStatusId = @StatusId_Scheduled OR 
								E.EventStatusId = @StatusId_Started OR 
								E.EventStatusId = @StatusId_Completed 
							)
							, 1
							, 0
						)
					) AS Column3 -- EventCompletedAndNotSubmittedForDM
				, SUM(IF((SYSDATE() >= E.StartDateTime AND SYSDATE() <= E.EndDateTime) AND 
							(
								E.EventStatusId = @StatusId_Scheduled OR 
								E.EventStatusId = @StatusId_Started 
							)
							, 1
							, 0
						)
					) AS Column4 -- InProgressEvents
				, SUM(IF(SYSDATE() < E.StartDateTime AND E.EventStatusId = @StatusId_Scheduled , 1, 0)) AS Column5 -- UpcomingEvents
				, SUM(IF(E.EventStatusId = @StatusId_Cancelled, 1, 0)) AS Column6 -- Cancelled Events
			FROM
				tblEvents E
			WHERE
				E.ClientId = clientId;
		END IF;
	ELSE
		IF userId > 0 THEN
			-- DM Executive
			SELECT
				SUM(IF(E.EventStatusId = @StatusId_DMCompleted, 1, 0)) AS Column1 -- DMCompleted
				, SUM(IF(E.EventStatusId = @StatusId_DMStarted, 1, 0)) AS Column2 -- DMInProgress
				, SUM(IF(E.EventStatusId = @StatusId_SubmittedForDM, 1, 0)) AS Column3 -- SubmittedForDMButDMNotStarted
				, SUM(IF(E.EventStatusId = @StatusId_Scheduled OR 
						E.EventStatusId = @StatusId_Started OR 
						E.EventStatusId = @StatusId_Completed , 1, 0)) AS Column4 -- UpcomingEvents
				, 0 AS Column5 -- Dummy column
				, SUM(IF(E.EventStatusId = @StatusId_Cancelled, 1, 0)) AS Column6 -- Cancelled Events
			FROM
				tblEvents E
				INNER JOIN tblUserClients C ON C.ClientId = E.ClientId
			WHERE
				C.UserId = userId;
		ELSE
			-- Super Admin
			
			SELECT
				SUM(IF(E.EventStatusId = @StatusId_DMCompleted, 1, 0)) AS Column1 -- DMCompleted
				, SUM(IF(E.EventStatusId = @StatusId_SubmittedForDM, 1, 0)) AS Column2 -- SubmittedForDM
				, SUM(IF(SYSDATE() > E.EndDateTime AND 
							(
								E.EventStatusId = @StatusId_Scheduled OR 
								E.EventStatusId = @StatusId_Started OR 
								E.EventStatusId = @StatusId_Completed 
							)
							, 1
							, 0
						)
					) AS Column3 -- EventCompletedAndNotSubmittedForDM
				, SUM(IF((SYSDATE() >= E.StartDateTime AND SYSDATE() <= E.EndDateTime) AND 
							(
								E.EventStatusId = @StatusId_Scheduled OR 
								E.EventStatusId = @StatusId_Started 
							)
							, 1
							, 0
						)
					) AS Column4 -- InProgressEvents
				, SUM(IF(SYSDATE() < E.StartDateTime AND E.EventStatusId = @StatusId_Scheduled , 1, 0)) AS Column5 -- UpcomingEvents
				, SUM(IF(E.EventStatusId = @StatusId_Cancelled, 1, 0)) AS Column6 -- Cancelled Events
			FROM
				tblEvents E;
		END IF;
	END IF;
	
	/*
	SELECT
		SUM(IF(E.IsDMCompleted = 1, 1, 0)) AS DMCompleted
		, SUM(IF(E.IsSubmitedForDM = 1 AND IFNULL(E.IsDMCompleted, 0) = 0 , 1, 0)) AS SubmittedForDM
		, SUM(IF(SYSDATE() > E.EndDateTime AND IFNULL(E.IsSubmitedForDM, 0) = 0 , 1, 0)) AS EventCompletedAndNotSubmittedForDM
		, SUM(IF(SYSDATE() >= E.StartDateTime AND SYSDATE() <= E.EndDateTime AND IFNULL(E.IsSubmitedForDM, 0) = 0 , 1, 0)) AS InProgressEvents
		, SUM(IF(SYSDATE() < E.StartDateTime AND IFNULL(E.IsSubmitedForDM, 0) = 0 , 1, 0)) AS UpcomingEvents
	FROM
		tblEvents E
	WHERE
		IF(clientId = -1, 0, E.ClientId) = IF(clientId = -1, 0, clientId)  
		AND IF(userId = -1, 0, E.EventCreatedBy) = IF(userId = -1, 0, userId);
	*/
		
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetEventStatusList` (OUT `errorCode` TINYINT)  BEGIN
	SET errorCode = 0;
    
	SELECT 
		EventStatusId
        , EventStatus
	FROM 
		tblMstEventStatuses
    ORDER BY 
		EventStatusId;
END$$

CREATE DEFINER=`cpses_jrkmenhptq`@`localhost` PROCEDURE `usp_GetServices` (IN `serviceId` SMALLINT, IN `userId` SMALLINT, OUT `errorCode` TINYINT)  BEGIN

	-- SET userId = IF(TRIM(IFNULL(userId, '')) = '', -1, userId);
	SET serviceId = IF(TRIM(IFNULL(serviceId, '')) = '', -1, serviceId);


	IF serviceId = -1 THEN
		SELECT
			S.ServiceId
			, S.ServiceTypeId
			, S.ServiceName
		FROM
			tblMstServices S;
	ELSE
		SELECT
			S.ServiceId
			, S.ServiceTypeId
			, S.ServiceName
		FROM
			tblMstServices S
		WHERE
			S.ServiceId = serviceId;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetUserClients` (IN `_userId` SMALLINT, OUT `_errorCode` TINYINT)  this_sp : BEGIN

	SET _userId = IFNULL(_userId, -1);
	SET _errorCode = 0;
	
	IF _userId = -1 THEN
		SET _errorCode = -1;
		LEAVE this_sp;
	END IF;

	SELECT
		C.ClientId
		, C.ClientName
		, IF(UC.ClientId IS NULL, 0, 1) AS IsClientAssigned
	FROM
		tblMstClients C
		LEFT JOIN tblUserClients UC ON UC.ClientId = C.ClientId
	WHERE
		UC.UserId = _userId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_GetUserRoleClientDetails` (IN `userId` SMALLINT(6))  BEGIN

	SET userId = TRIM(IFNULL(userId, ''));

		
	SELECT 
		U.UserId AS UserId
		, U.RoleId AS RoleId
		, R.RoleCode AS RoleCode
		, R.Role AS Role

		, U.Name AS UserName
		, U.ContactNo AS UserContactNo
		, U.eMail AS UsereMail
		, U.Designation AS UserDesignation
		
		, U.ClientId AS ClientId
		, C.ClientName AS ClientName
		, C.ContactNo AS ClientContactNo
		, C.eMail AS ClienteMail
		, C.WebsiteURL AS ClientWebsiteURL
		, C.FacebookURL AS ClientFacebookURL
		, C.YoutubeURL AS ClientYoutubeURL
		, C.InstagramURL AS ClientInstagramURL
		, C.TwitterURL AS ClientTwitterURL
		, C.PinterestURL AS ClientPinterestURL
		, C.LinkedInURL AS ClientLinkedInURL
		
	FROM tblMstUsers U
	INNER JOIN tblMstRoles R ON R.RoleId = U.RoleId
	LEFT JOIN tblMstClients C ON C.ClientId = U.ClientId
	WHERE 
		U.UserId = userId
		AND U.Active = 1
		AND R.Active = 1
		AND IF(C.Active IS NULL, 0, C.Active) = IF(C.Active IS NULL, 0, 1);
				
		
END$$

CREATE DEFINER=`cpses_jrkmenhptq`@`localhost` PROCEDURE `usp_SetClient` (IN `clientId` SMALLINT(6), IN `clientName` VARCHAR(100), IN `contactNo` VARCHAR(15), IN `eMail` VARCHAR(100), IN `websiteURL` VARCHAR(100), IN `facebookURL` VARCHAR(250), IN `youtubeURL` VARCHAR(250), IN `instagramURL` VARCHAR(250), IN `twitterURL` VARCHAR(250), IN `pinterestURL` VARCHAR(250), IN `linkedInURL` VARCHAR(250), IN `active` BIT(1), IN `serviceIdsOpted` VARCHAR(2000), IN `userId` SMALLINT(6), OUT `errorCode` TINYINT)  BEGIN
	
	SET clientName = TRIM(IFNULL(clientName, ''));
	SET contactNo = TRIM(IFNULL(contactNo, ''));
	SET eMail = TRIM(IFNULL(eMail, ''));
	SET websiteURL = TRIM(IFNULL(websiteURL, ''));
	SET facebookURL = TRIM(IFNULL(facebookURL, ''));
	SET youtubeURL = TRIM(IFNULL(youtubeURL, ''));
	SET instagramURL = TRIM(IFNULL(instagramURL, ''));
	SET twitterURL = TRIM(IFNULL(twitterURL, ''));
	SET pinterestURL = TRIM(IFNULL(pinterestURL, ''));
	SET linkedInURL = TRIM(IFNULL(linkedInURL, ''));
	SET active = IFNULL(active, 0);
	SET serviceIdsOpted = TRIM(IFNULL(serviceIdsOpted, ''));
	SET @clientId = IF(TRIM(IFNULL(clientId, '')) = '', -1, clientId);
	SET userId = IF(TRIM(IFNULL(userId, '')) = '', -1, userId);


	CREATE TEMPORARY TABLE tmpTblServicesOpted
	(
		ServiceId SMALLINT(6) NOT NULL UNIQUE
	)
	ENGINE=innodb;
	
	/* BEGIN - Get service Ids into a temp table */
	/* Split out the serviceIdsOpted and insert */

	SET @loopCompleted = 0;       
	SET @index = 1;

	WHILE NOT @loopCompleted DO

		SET @serviceId = TRIM(SUBSTRING(serviceIdsOpted, @index, IF(LOCATE(',', serviceIdsOpted, @index) > 0, LOCATE(',', serviceIdsOpted, @index) - @index, LENGTH(serviceIdsOpted))));

		IF LENGTH(@serviceId) > 0 THEN
			SET @index = @index + LENGTH(@serviceId) + 1;
			
			/* add the serviceId IF it doesnt already exist */
			INSERT IGNORE INTO tmpTblServicesOpted (ServiceId) VALUES (@serviceId);
		ELSE
			SET @loopCompleted = 1;
		END IF;
	END WHILE;
	/* END - Get service Ids into a temp table */


	IF @clientId = -1 THEN
		INSERT INTO tblMstClients
		(
			ClientName,
			ContactNo,
			eMail,
			WebsiteURL,
			FacebookURL,
			YoutubeURL,
			InstagramURL,
			TwitterURL,
			PinterestURL,
			LinkedInURL,
			Active,
			LastModifiedOn,
			LastModifiedBy
		)
		VALUES
		(
			clientName,
			contactNo,
			eMail,
			websiteURL,
			facebookURL,
			youtubeURL,
			instagramURL,
			twitterURL,
			pinterestURL,
			linkedInURL,
			active,
			SYSDATE(),
			userId
		);
		
		SET @clientId = LAST_INSERT_ID();
		
		INSERT IGNORE INTO tblClientServices
		(
			ClientId
			, ServiceId
		)
		SELECT 
			@clientId
			, ServiceId 
		FROM 
			tmpTblServicesOpted;
	ELSE
		UPDATE tblMstClients SET
			  ClientName = clientName
			, ContactNo = contactNo
			, eMail = eMail
			, WebsiteURL = websiteURL
			, FacebookURL = facebookURL
			, YoutubeURL = youtubeURL
			, InstagramURL = instagramURL
			, TwitterURL = twitterURL
			, PinterestURL = pinterestURL
			, LinkedInURL = linkedInURL
			, Active = active
			, LastModifiedOn = SYSDATE()
			, LastModifiedBy = userId
		WHERE
			ClientId = @clientId;
			
		/* delete unchecked services from tblClientServices */
		DELETE CS FROM tblClientServices CS
		LEFT JOIN tmpTblServicesOpted T ON T.ServiceId = CS.ServiceId
		WHERE CS.EventId = @eventId
		AND T.ServiceId IS NULL;
		
		/* remove untouched services from temporary table */
		DELETE T FROM tmpTblServicesOpted T
		INNER JOIN tblClientServices CS ON T.ServiceId = CS.ServiceId
		WHERE CS.EventId = @eventId;
		
		/* INSERT REMAINING SERVICES */
		INSERT IGNORE INTO tblClientServices
		(
			ClientId
			, ServiceId
		)
		SELECT 
			@clientId
			, ServiceId 
		FROM 
			tmpTblServicesOpted;
			
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_SetEvent` (IN `_eventId` MEDIUMINT, IN `_userId` SMALLINT, IN `_clientId` SMALLINT, IN `_eventName` VARCHAR(250), IN `_eventCategoryId` TINYINT, IN `_startDateTime` DATETIME, IN `_endDateTime` DATETIME, IN `_venue` VARCHAR(250), IN `_guests` VARCHAR(500), IN `_speakers` VARCHAR(500), IN `_participants` VARCHAR(500), IN `_eventDescription` TEXT, IN `_eventStatusId` TINYINT, IN `_serviceIdsOpted` TEXT, IN `_isSubmitedForDM` BIT(1), IN `_eventStatusDescription` TEXT, IN `_newStartDateTime` DATETIME, IN `_newEndDateTime` DATETIME, IN `_isPhotoUploaded` BIT(1), IN `_photoUploadedPath` TEXT, IN `_isVideoUploaded` BIT(1), IN `_videoUploadedPath` TEXT)  BEGIN

	SET _eventId = IFNULL(_eventId, 0);
	SET @currentDate = SYSDATE();
	DROP TABLE IF EXISTS tmpTblServicesOpted;
	CREATE TEMPORARY TABLE tmpTblServicesOpted
	(
		ServiceId SMALLINT NOT NULL UNIQUE
	)
	ENGINE=innodb;
	
	/* BEGIN - Get service Ids into a temp table */
	/* Split out the _serviceIdsOpted and insert */

	SET @loopCompleted = 0;       
	SET @index = 1;

	WHILE NOT @loopCompleted DO

		SET @serviceId = TRIM(SUBSTRING(_serviceIdsOpted, @index, IF(LOCATE(',', _serviceIdsOpted, @index) > 0, LOCATE(',', _serviceIdsOpted, @index) - @index, LENGTH(_serviceIdsOpted))));

		IF LENGTH(@serviceId) > 0 THEN
			SET @index = @index + LENGTH(@serviceId) + 1;
			
			/* add the state IF it doesnt already exist */
			INSERT IGNORE INTO tmpTblServicesOpted (ServiceId) VALUES (@serviceId);
		ELSE
			SET @loopCompleted = 1;
		END IF;
	END WHILE;
	/* END - Get service Ids into a temp table */
	
	IF _eventId = 0 THEN
		INSERT INTO tblEvents
		(
			ClientId
			, EventCreatedBy
			, EventName
			, EventCategoryId
			, StartDateTime
			, EndDateTime
			, Venue
			, Guests
			, Speakers
			, Participants
			, EventDescription
			, EventStatusId
			, IsSubmitedForDM
			, LastModifiedOn
			, LastModifiedBy
		)
		VALUES
		(
			_clientId
			, _userId
			, _eventName
			, _eventCategoryId
			, _startDateTime
			, _endDateTime
			, _venue
			, _guests
			, _speakers
			, _participants
			, _eventDescription
			, _eventStatusId
			, _isSubmitedForDM
			, @currentDate
			, _userId
		);
		
		SET @eventId = LAST_INSERT_ID();
		
		INSERT IGNORE INTO tblEventServices
		(
			EventId
			, ServiceId
		)
		SELECT 
			@eventId
			, T.ServiceId 
		FROM 
			tmpTblServicesOpted T;
	ELSE
		/* UPDATE EVENT DATA */
		SET @eventId = _eventId;
		
		UPDATE tblEvents E SET
			E.ClientId = _clientId
			, E.EventCreatedBy = _userId
			, E.EventName = _eventName
			, E.EventCategoryId = _eventCategoryId
			, E.StartDateTime = _startDateTime
			, E.EndDateTime = _endDateTime
			, E.Venue = _venue
			, E.Guests = _guests
			, E.Speakers = _speakers
			, E.Participants = _participants
			, E.EventDescription = _eventDescription
			, E.EventStatusId = _eventStatusId
			, E.EventStatusDescription = _eventStatusDescription
			, E.IsSubmitedForDM = _isSubmitedForDM
			, E.LastModifiedOn = @currentDate
			, E.LastModifiedBy = _userId
			, E.IsPhotoUploaded = _isPhotoUploaded
			, E.IsVideoUploaded = _isVideoUploaded
			, E.PostponedStartDateTime = _newStartDateTime
			, E.PostponedEndDateTime = _newEndDateTime
		WHERE
			E.EventId = @eventId;
		
		/* delete unchecked services from tblEventServices */
		DELETE ES FROM tblEventServices ES
		LEFT JOIN tmpTblServicesOpted T ON T.ServiceId = ES.ServiceId
		WHERE ES.EventId = @eventId
		AND T.ServiceId IS NULL;
		
		/* remove untouched services from temporary table */
		DELETE T FROM tmpTblServicesOpted T
		INNER JOIN tblEventServices ES ON T.ServiceId = ES.ServiceId
		WHERE ES.EventId = @eventId;
		
		/* INSERT REMAINING SERVICES */
		INSERT IGNORE INTO tblEventServices
		(
			EventId
			, ServiceId
		)
		SELECT 
			@eventId
			, T.ServiceId 
		FROM 
			tmpTblServicesOpted T;
			
		
		SELECT 
			ES.EventStatusId
			INTO 
			@StatusId_Postponed
		FROM 
			tblMstEventStatuses ES
		WHERE
			ES.EventStatus = 'Postponed';
			
		SELECT 
			ES.EventStatusId
			INTO 
			@StatusId_Scheduled
		FROM 
			tblMstEventStatuses ES
		WHERE
			ES.EventStatus = 'Scheduled';
		
		SELECT 
			ES.EventStatusId
			INTO 
			@StatusId_Completed
		FROM 
			tblMstEventStatuses ES
		WHERE
			ES.EventStatus = 'Completed';
			
		/* BEGIN - Add new entry when event postponed */	
		IF _eventStatusId = @StatusId_Postponed THEN
			INSERT INTO tblEvents
			(
				ClientId
				, EventCreatedBy
				, EventName
				, EventCategoryId
				, StartDateTime
				, EndDateTime
				, Venue
				, Guests
				, Speakers
				, Participants
				, EventDescription
				, EventStatusId
				, IsSubmitedForDM
				, LastModifiedOn
				, LastModifiedBy
			)
			VALUES
			(
				_clientId
				, _userId
				, _eventName
				, _eventCategoryId
				, _newStartDateTime
				, _newEndDateTime
				, _venue
				, _guests
				, _speakers
				, _participants
				, _eventDescription
				, @StatusId_Scheduled
				, _isSubmitedForDM
				, @currentDate
				, _userId
			);
			
			SET @newEventId = LAST_INSERT_ID();
			
			INSERT IGNORE INTO tblEventServices
			(
				EventId
				, ServiceId
			)
			SELECT 
				@newEventId
				, ES.ServiceId 
			FROM 
				tblEventServices ES
			WHERE
				ES.EventId = @eventId;
				
			/* END - Add new entry when event postponed */
		ELSE IF _eventStatusId = @StatusId_Completed THEN
			IF _isPhotoUploaded = 1 THEN
				INSERT INTO tblEventServiceData
				(
					EventServiceId
					, ServiceValue
				)
				SELECT 
					ES.EventServiceId
					, _photoUploadedPath
				FROM 
					tblEventServices ES
					INNER JOIN tblMstServices S 
						ON S.ServiceId = ES.ServiceId
				WHERE
					ES.EventId = @eventId
					AND S.ServiceName = 'Photo';
			ELSE
				DELETE ESD 
				FROM 
					tblEventServiceData ESD
					INNER JOIN tblEventServices ES ON ES.EventServiceId = ESD.EventServiceId
					INNER JOIN tblMstServices S ON S.ServiceId = ES.ServiceId
				WHERE
					ES.EventId = @eventId
					AND S.ServiceName = 'Photo';
					
			END IF;
			
			
			IF _isVideoUploaded = 1 THEN
				INSERT INTO tblEventServiceData
				(
					EventServiceId
					, ServiceValue
				)
				SELECT 
					ES.EventServiceId
					, _videoUploadedPath
				FROM 
					tblEventServices ES
					INNER JOIN tblMstServices S 
						ON S.ServiceId = ES.ServiceId
				WHERE
					ES.EventId = @eventId
					AND S.ServiceName = 'Video';
			ELSE
				DELETE ESD 
				FROM 
					tblEventServiceData ESD
					INNER JOIN tblEventServices ES ON ES.EventServiceId = ESD.EventServiceId
					INNER JOIN tblMstServices S ON S.ServiceId = ES.ServiceId
				WHERE
					ES.EventId = @eventId
					AND S.ServiceName = 'Video';
					
			END IF;
		END IF;
	END IF;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `usp_SetEventByDMExecutive` (IN `_eventId` MEDIUMINT, IN `_clientId` SMALLINT, IN `_eventStatusId` TINYINT, IN `_eventServiceIdsAndData` TEXT, IN `_isPhotoUploaded` BIT(1), IN `_photoUploadedPath` TEXT, IN `_isVideoUploaded` BIT(1), IN `_videoUploadedPath` TEXT, IN `_dm_EventName` VARCHAR(250), IN `_dm_EventCategoryId` TINYINT, IN `_dm_StartDateTime` DATETIME, IN `_dm_EndDateTime` DATETIME, IN `_dm_Venue` VARCHAR(250), IN `_dm_Guests` VARCHAR(500), IN `_dm_Speakers` VARCHAR(500), IN `_dm_Participants` VARCHAR(500), IN `_dm_EventDescription` TEXT, IN `_isDMCompleted` BIT(1), IN `_DMComments` TEXT, IN `_isEventLockReleased` BIT(1), IN `_eventLockReleaseReason` TEXT, IN `_userId` SMALLINT, OUT `_errorCode` TINYINT)  this_proc : BEGIN

	SET _eventId = IFNULL(_eventId, 0);
	
	IF _eventId = 0 THEN
		SET _errorCode = -1;
		LEAVE this_proc;
	END IF;
	
	SET @currentDate = SYSDATE();
	
	DROP TABLE IF EXISTS tmpTblServiceData;
	CREATE TEMPORARY TABLE tmpTblServiceData
	(
		EventServiceDataId INT
		, EventServiceId INT 
		, ServiceValue TEXT
	)
	ENGINE=innodb;
	
	/* BEGIN - Get EventServiceIds and EventServiceData into a temp table */
	SET @loopCompleted = 0;
	SET @rowIndex = 1;
	SET @columnIndex = 1;
	SET @rowSplitter = '#@#';
	SET @columnSplitter = '~@~';
	
	WHILE NOT @loopCompleted DO

		-- WITH FOLLOWING LINE WE GET "EventServiceDataId~@~EventServiceId~@~Data" PORTION FROM _eventServiceIdsAndData
		SET @eventServiceData = TRIM(SUBSTRING(_eventServiceIdsAndData, @rowIndex, IF(LOCATE(@rowSplitter, _eventServiceIdsAndData, @rowIndex) > 0, LOCATE(@rowSplitter, _eventServiceIdsAndData, @rowIndex) - @rowIndex, LENGTH(_eventServiceIdsAndData))));

		IF LENGTH(@eventServiceData) > 0 THEN
			SET @rowIndex = @rowIndex + LENGTH(@eventServiceData) + LENGTH(@rowSplitter);
			
            -- WITH FOLLOWING LINE WE GET INDEX OF FIRST OCCURANCE OF "~@~" PORTION FROM "EventServiceDataId~@~EventServiceId~@~Data" 
			SET @column1SplitterIndex = LOCATE(@columnSplitter, @eventServiceData);
            
            -- WITH FOLLOWING LINE WE GET INDEX OF SECOND OCCURANCE OF "~@~" PORTION FROM "EventServiceDataId~@~EventServiceId~@~Data" 
			SET @column2SplitterIndex = LOCATE(@columnSplitter, @eventServiceData, @column1SplitterIndex + 2);
            
			-- WITH FOLLOWING LINE WE GET "EventServiceDataId" PORTION FROM "EventServiceDataId~@~EventServiceId~@~Data"
			SET @eventServiceDataId = TRIM(SUBSTRING(@eventServiceData, 1, @column1SplitterIndex - 1));
            
            -- WITH FOLLOWING LINE WE GET "EventServiceId" PORTION FROM "EventServiceDataId~@~EventServiceId~@~Data"
			SET @eventServiceId = TRIM(SUBSTRING(@eventServiceData, @column1SplitterIndex + 3, @column2SplitterIndex - (@column1SplitterIndex + 3)));
            
            -- WITH FOLLOWING LINE WE GET "Data" PORTION FROM "EventServiceDataId~@~EventServiceId~@~Data"
			SET @serviceValue = TRIM(SUBSTRING(@eventServiceData, @column2SplitterIndex + 3));

			/* add the service data if it doesnt already exist */
			INSERT IGNORE INTO tmpTblServiceData 
			(
				EventServiceDataId
				, EventServiceId
				, ServiceValue
			)
			VALUES
			(
				IF(@eventServiceDataId = '', NULL, @eventServiceDataId)
				, IF(@eventServiceId = '', NULL, @eventServiceId)
				, IF(@serviceValue = '', NULL, @serviceValue)
			);
		ELSE
			SET @loopCompleted = 1;
		END IF;
	END WHILE;
	/* END - Get service Ids into a temp table */
	
	SELECT
		ES.EventStatusId
		INTO 
		@StatusId_Started
	FROM 
		tblMstEventStatuses ES
	WHERE
		ES.EventStatus = 'Started';
		
	SELECT 
		ES.EventStatusId
		INTO 
		@StatusId_DMStarted
	FROM 
		tblMstEventStatuses ES
	WHERE
		ES.EventStatus = 'DMStarted';
		
	SELECT 
		ES.EventStatusId
		INTO 
		@StatusId_DMCompleted
	FROM 
		tblMstEventStatuses ES
	WHERE
		ES.EventStatus = 'DMCompleted';

	/* UPDATE EVENT DATA */
	SET @eventId = _eventId;
	
	UPDATE tblEvents E SET
		E.DM_EventName = _dm_EventName
		, E.DM_EventCategoryId = _dm_EventCategoryId
		, E.DM_StartDateTime = _dm_StartDateTime
		, E.DM_EndDateTime = _dm_EndDateTime
		, E.DM_Venue = _dm_Venue
		, E.DM_Guests = _dm_Guests
		, E.DM_Speakers = _dm_Speakers
		, E.DM_Participants = _dm_Participants
		, E.DM_EventDescription = _dm_EventDescription
		, E.EventStatusId = IF(_isEventLockReleased = 1, @StatusId_Started, IF(_eventStatusId = @StatusId_DMStarted AND E.EventStatusId = @StatusId_DMCompleted, E.EventStatusId, _eventStatusId))
		, E.EventStatusDescription = IF(_isEventLockReleased = 1, _eventLockReleaseReason, E.EventStatusDescription)
		, E.IsNotificationSentToCoordinator = IF(_isEventLockReleased = 1, 0, E.IsNotificationSentToCoordinator)
		, E.IsSubmitedForDM = IF(_isEventLockReleased = 1, 0, E.IsSubmitedForDM)
		, E.IsDMCompleted = IF(_isEventLockReleased = 1, 0, _isDMCompleted)
		, E.DMCompletedOn = IF(_isEventLockReleased = 1, NULL, @currentDate)
		, E.DMCompletedBy = IF(_isEventLockReleased = 1, NULL, _userId)
		, E.DMComments = _DMComments
		
		, E.IsEventLockReleased = _isEventLockReleased
		, E.EventLockReleaseReason = IF(_isEventLockReleased = 1, _eventLockReleaseReason, NULL)
		, E.EventLockReleasedOn = IF(_isEventLockReleased = 1, @currentDate, NULL)
		, E.EventLockReleasedBy = IF(_isEventLockReleased = 1, _userId, NULL)
		
		, E.IsPhotoUploaded = _isPhotoUploaded
		, E.IsVideoUploaded = _isVideoUploaded

		, E.LastModifiedOn = @currentDate
		, E.LastModifiedBy = _userId
	WHERE
		E.EventId = @eventId;
		
	/* delete 'removed on UI' service data from tblEventServiceData */
	DELETE 
		ESD 
	FROM 
		tblEventServiceData ESD
		LEFT JOIN tmpTblServiceData T 
		ON T.EventServiceDataId = ESD.EventServiceDataId
	WHERE 
		ESD.EventId = @eventId
		AND T.EventServiceDataId IS NULL;
	
	/* update tblEventServiceData with service data which is common in temporary table */
	UPDATE tblEventServiceData ESD 
		INNER JOIN tmpTblServiceData T
		ON T.EventServiceDataId = ESD.EventServiceDataId
	SET
		ESD.ServiceValue = T.ServiceValue
	WHERE
		ESD.EventId = @eventId;
		
	/* Now, delete data in temporary table which is common in tblEventServiceData */
	DELETE 
		T
	FROM
		tmpTblServiceData T
		INNER JOIN tblEventServiceData ESD 
		ON T.EventServiceDataId = ESD.EventServiceDataId
	WHERE 
		ESD.EventId = @eventId;
		
	/* INSERT REMAINING SERVICE data */
	INSERT IGNORE INTO tblEventServiceData
	(
		EventId
		, EventServiceId
		, ServiceValue
	)
	SELECT
		@eventId
		, T.EventServiceId
		, T.ServiceValue 
	FROM 
		tmpTblServiceData T
	WHERE 
		T.EventServiceDataId IS NULL;
	
	IF _isEventLockReleased = 1 THEN -- INSERT EVENT UNLOCK REASON
		INSERT INTO tblReleaseEventLock
		(
			EventId
			, Reason
			, ReleasedOn
			, ReleasedBy
		)
		VALUES
		(
			@eventId
			, _eventLockReleaseReason
			, @currentDate
			, _userId
		);
	END IF;
		
END$$

CREATE DEFINER=`cpses_jrkmenhptq`@`localhost` PROCEDURE `usp_SetService` (IN `serviceId` SMALLINT, IN `serviceTypeId` SMALLINT, `serviceName` VARCHAR(100), IN `userId` SMALLINT, OUT `errorCode` TINYINT)  BEGIN
	SET userId = IF(TRIM(IFNULL(userId, '')) = '', -1, userId);
	SET serviceId = IF(TRIM(IFNULL(serviceId, '')) = '', -1, serviceId);

	IF serviceId = -1 THEN
		INSERT INTO tblMstServices
		(
			ServiceTypeId
			, ServiceName
			, LastModifiedOn
			, LastModifiedBy
		)
		VALUES
		(
			serviceTypeId
			, serviceName
			, SYSDATE()
			, userId
		);
	ELSE
		UPDATE tblMstServices SET
			ServiceTypeId = serviceTypeId
			, ServiceName = serviceName
			, LastModifiedOn = SYSDATE()
			, LastModifiedBy = userId
		WHERE
			ServiceId = serviceId;
	END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tblclientservices`
--

CREATE TABLE `tblclientservices` (
  `ClientServiceId` mediumint(9) UNSIGNED NOT NULL,
  `ClientId` smallint(6) DEFAULT NULL,
  `ServiceId` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblclientservices`
--

INSERT INTO `tblclientservices` (`ClientServiceId`, `ClientId`, `ServiceId`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 1, 7),
(4, 1, 8),
(5, 1, 11);

-- --------------------------------------------------------

--
-- Table structure for table `tblevents`
--

CREATE TABLE `tblevents` (
  `EventId` mediumint(9) UNSIGNED NOT NULL,
  `ClientId` smallint(6) DEFAULT NULL,
  `EventCreatedBy` smallint(6) DEFAULT NULL,
  `EventName` varchar(250) DEFAULT NULL,
  `EventCategoryId` tinyint(4) DEFAULT NULL,
  `StartDateTime` datetime DEFAULT NULL,
  `EndDateTime` datetime DEFAULT NULL,
  `Venue` varchar(250) DEFAULT NULL,
  `Guests` varchar(500) DEFAULT NULL COMMENT 'Comma seperated values',
  `Speakers` varchar(500) DEFAULT NULL COMMENT 'Comma seperated values',
  `Participants` varchar(500) DEFAULT NULL,
  `EventDescription` text DEFAULT NULL,
  `DM_EventName` varchar(250) DEFAULT NULL,
  `DM_EventCategoryId` tinyint(4) DEFAULT NULL,
  `DM_StartDateTime` datetime DEFAULT NULL,
  `DM_EndDateTime` datetime DEFAULT NULL,
  `DM_Venue` varchar(250) DEFAULT NULL,
  `DM_Guests` varchar(500) DEFAULT NULL COMMENT 'Comma seperated values',
  `DM_Speakers` varchar(500) DEFAULT NULL COMMENT 'Comma seperated values',
  `DM_Participants` varchar(500) DEFAULT NULL,
  `DM_EventDescription` text DEFAULT NULL,
  `EventStatusId` tinyint(1) DEFAULT NULL,
  `EventStatusDescription` text DEFAULT NULL,
  `IsNotificationSentToCoordinator` bit(1) DEFAULT NULL,
  `IsPhotoUploaded` bit(1) DEFAULT NULL,
  `IsVideoUploaded` bit(1) DEFAULT NULL,
  `IsSubmitedForDM` bit(1) DEFAULT NULL,
  `IsDMCompleted` bit(1) DEFAULT NULL,
  `DMComments` text DEFAULT NULL,
  `DMCompletedOn` datetime DEFAULT NULL,
  `DMCompletedBy` smallint(6) DEFAULT NULL,
  `IsEventLockReleased` bit(1) DEFAULT NULL,
  `EventLockReleaseReason` text DEFAULT NULL,
  `EventLockReleasedOn` datetime DEFAULT NULL,
  `EventLockReleasedBy` smallint(6) DEFAULT NULL,
  `PostponedStartDateTime` datetime DEFAULT NULL,
  `PostponedEndDateTime` datetime DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblevents`
--

INSERT INTO `tblevents` (`EventId`, `ClientId`, `EventCreatedBy`, `EventName`, `EventCategoryId`, `StartDateTime`, `EndDateTime`, `Venue`, `Guests`, `Speakers`, `Participants`, `EventDescription`, `DM_EventName`, `DM_EventCategoryId`, `DM_StartDateTime`, `DM_EndDateTime`, `DM_Venue`, `DM_Guests`, `DM_Speakers`, `DM_Participants`, `DM_EventDescription`, `EventStatusId`, `EventStatusDescription`, `IsNotificationSentToCoordinator`, `IsPhotoUploaded`, `IsVideoUploaded`, `IsSubmitedForDM`, `IsDMCompleted`, `DMComments`, `DMCompletedOn`, `DMCompletedBy`, `IsEventLockReleased`, `EventLockReleaseReason`, `EventLockReleasedOn`, `EventLockReleasedBy`, `PostponedStartDateTime`, `PostponedEndDateTime`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(1, 1, 2, 'Hangamaaaa', 1, '2019-08-28 06:00:00', '2019-08-29 07:00:00', 'vennue1', 'g1', 's1', 'p1', 'something happened', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '', NULL, b'0', b'0', b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-20 00:25:21', 2),
(2, 3, 2, 'test', 1, '2019-08-21 00:59:34', '2019-08-22 00:59:34', 'hyderrabad', 'ram', 'ram', 'sai', 'test desc', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 02:12:22', 2),
(3, 3, 3, 'test1', 1, '2019-08-21 00:59:34', '2019-08-22 00:59:34', 'hyderrabad', 'ram', 'ram', 'sai', 'test desc', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 02:16:18', 3),
(4, 3, 3, 'test1', 1, '2019-08-21 00:59:34', '2019-08-22 00:59:34', 'hyderrabad', 'ram', 'ram', 'sai', 'test desc', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 02:16:49', 3),
(5, 3, 3, 'test1', 1, '2019-08-21 00:59:34', '2019-08-22 00:59:34', 'hyderrabad', 'ram', 'ram', 'sai', 'test desc', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 02:17:50', 3),
(6, 3, 2, 'test12', 2, '2019-08-21 00:59:34', '2019-08-22 00:59:34', 'hyderrabad', 'ram', 'ram', 'sai', 'test desc', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 02:47:04', 2),
(7, 3, 4, 'test123', 23, '2019-08-21 00:59:34', '2019-08-22 00:59:34', 'hyderrabad', 'ram1', 'ram1', 'sai', 'test desc', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 02:54:16', 4),
(8, 3, 5, 'siva', 2, '2019-08-23 00:59:34', '2019-08-24 00:59:34', 'secuderabad', 'veda', 'lakshman', 'sai', 'new event description', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 04:10:27', 5),
(9, 3, 6, 'siva', 2, '2019-08-23 00:59:34', '2019-08-24 00:59:34', 'secuderabad', 'veda', 'lakshman', 'sai', 'new event description', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-21 04:22:59', 6),
(10, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 20:00:07', 7),
(11, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 20:01:49', 7),
(12, 1, 7, 'test', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 21:40:44', 7),
(13, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 21:41:30', 7),
(14, 1, 7, 'test', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 21:41:43', 7),
(15, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 21:42:19', 7),
(16, 1, 7, 'test', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 21:55:17', 7),
(17, 1, 7, 'test', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 21:57:11', 7),
(18, 1, 7, 'test', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji;jyothi;', '1;2;', 'p1;p2;', 'test des', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'test event des', NULL, b'0', b'0', b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '2019-08-27 22:43:30', 7),
(19, 1, 7, 'test', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'hyd', 'anji;jyothi;', '1;2;', 'p1;p2;', 'test des', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 22:43:31', 7),
(20, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:23:44', 7),
(21, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:27:15', 7),
(22, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test\r\n			c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:29:14', 7),
(23, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:33:28', 7),
(24, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:36:30', 7),
(25, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:40:55', 7),
(26, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:46:16', 7),
(27, 1, 7, 'jyothi birthday', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyd', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:46:53', 7),
(28, 1, 7, 'jyothi birthday updated', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyderabad', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'zxczxc', NULL, b'0', b'0', b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '2019-08-27 23:49:28', 7),
(29, 1, 7, 'jyothi birthday 29 edit 12', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyderabad', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test\r\n			c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'zxczxc', NULL, b'0', b'0', b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '2019-08-27 23:59:16', 7),
(30, 1, 7, 'event of SOP', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'hyderabad', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', 'event of SOP', 0, '2019-08-28 10:00:00', '2019-08-28 11:00:00', 'Hyderabad', 'e,f,j', 'x,y,z', 'a,b,c', 'Event Desc', 5, '0', b'0', b'1', b'1', b'0', b'0', 'No comments', NULL, NULL, b'1', '0', '2019-08-29 22:01:40', 2, NULL, NULL, '2019-08-29 22:01:40', 2),
(31, 1, 7, 'jyothi birthday  29 edit', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'hyderabad', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-27 23:58:24', 7),
(32, 1, 7, 'jyothi birthday update test', 2, '2019-08-28 10:00:12', '2019-08-28 11:00:12', 'hyderabad', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'zxczxc', NULL, b'0', b'0', b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '2019-08-28 14:12:53', 7),
(33, 1, 7, 'jyothi birthday update test', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'hyderabad', 'anji,naga,jyothi,gafoor', 'anji,naga,jyothi,gafoor', 'a,b,c', 'test c', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 14:12:54', 7),
(34, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:05:00', 7),
(35, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:05:23', 7),
(36, 1, 7, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '', '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, b'0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:06:21', 7),
(37, 1, 7, 'anjitest', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'madhapur', 'mla', 'mp', 'a,b,c', 'party meeting', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:21:46', 7),
(38, 1, 7, 'anjitest', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'madhapur', 'mla', 'mp', 'a,b,c', 'party meeting', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:23:52', 7),
(39, 1, 7, 'anjitest', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'madhapur', 'mla', 'mp', 'a,b,c', 'party meeting', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:24:49', 7),
(40, 1, 7, 'anjitest', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'madhapur', 'mla', 'mp', 'a,b,c', 'party meeting', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:25:23', 7),
(41, 1, 7, 'anjitest', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'madhapur', 'mla', 'mp', 'a,b,c', 'party meeting', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:25:58', 7),
(42, 1, 7, 'anjitest forupdate', 2, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 'madhapur', 'mla', 'mp', 'a,b,c', 'party meeting', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'no yet started', NULL, b'0', b'0', b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '0000-00-00 00:00:00', '0000-00-00 00:00:00', '2019-08-28 21:27:42', 7);

-- --------------------------------------------------------

--
-- Table structure for table `tbleventservicedata`
--

CREATE TABLE `tbleventservicedata` (
  `EventServiceDataId` int(10) UNSIGNED NOT NULL,
  `EventId` mediumint(9) DEFAULT NULL,
  `EventServiceId` int(10) DEFAULT NULL,
  `ServiceValue` text DEFAULT NULL COMMENT 'Possible Values:\nlive URL,file path,text etc'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbleventservicedata`
--

INSERT INTO `tbleventservicedata` (`EventServiceDataId`, `EventId`, `EventServiceId`, `ServiceValue`) VALUES
(1, 30, 2, 'dmcheck');

-- --------------------------------------------------------

--
-- Table structure for table `tbleventservices`
--

CREATE TABLE `tbleventservices` (
  `EventServiceId` int(10) UNSIGNED NOT NULL,
  `EventId` mediumint(9) DEFAULT NULL,
  `ServiceId` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbleventservices`
--

INSERT INTO `tbleventservices` (`EventServiceId`, `EventId`, `ServiceId`) VALUES
(9, 1, 1),
(12, 1, 200),
(13, 1, 300),
(15, 2, 0),
(16, 3, 0),
(17, 4, 0),
(18, 5, 0),
(19, 6, 0),
(20, 7, 0),
(21, 8, 0),
(22, 9, 0),
(23, 16, 2),
(24, 16, 7),
(25, 16, 8),
(26, 17, 2),
(27, 17, 7),
(28, 17, 8),
(29, 18, 2),
(31, 18, 8),
(32, 18, 6),
(33, 19, 1),
(34, 19, 200),
(35, 19, 300),
(36, 19, 0),
(37, 19, 0),
(38, 19, 0),
(39, 19, 0),
(40, 19, 0),
(41, 19, 0),
(42, 19, 0),
(43, 19, 0),
(44, 19, 2),
(45, 19, 7),
(46, 19, 8),
(47, 19, 2),
(48, 19, 7),
(49, 19, 8),
(50, 19, 2),
(51, 19, 8),
(52, 19, 6),
(64, 20, 2),
(65, 20, 7),
(66, 20, 8),
(67, 21, 2),
(68, 21, 7),
(69, 21, 8),
(70, 22, 2),
(71, 22, 7),
(72, 22, 8),
(73, 23, 2),
(74, 23, 7),
(75, 23, 8),
(76, 24, 2),
(77, 24, 7),
(78, 24, 8),
(79, 25, 2),
(80, 25, 7),
(81, 25, 8),
(82, 26, 2),
(83, 26, 7),
(84, 26, 8),
(85, 27, 2),
(86, 27, 7),
(87, 27, 8),
(88, 28, 2),
(89, 28, 7),
(90, 28, 8),
(102, 29, 2),
(103, 29, 7),
(104, 29, 8),
(105, 29, 2),
(106, 29, 7),
(107, 29, 8),
(108, 29, 2),
(109, 29, 8),
(122, 29, 2),
(123, 29, 7),
(124, 29, 8),
(125, 29, 2),
(126, 29, 7),
(127, 29, 8),
(128, 29, 2),
(129, 29, 8),
(131, 29, 2),
(132, 29, 7),
(133, 29, 8),
(134, 29, 2),
(135, 29, 7),
(136, 29, 8),
(137, 29, 2),
(138, 29, 7),
(139, 29, 8),
(140, 29, 2),
(141, 29, 7),
(142, 29, 8),
(143, 29, 2),
(144, 29, 7),
(145, 29, 8),
(146, 29, 2),
(147, 29, 7),
(148, 29, 8),
(149, 29, 2),
(150, 29, 7),
(151, 29, 8),
(152, 29, 2),
(153, 29, 7),
(154, 29, 8),
(155, 29, 2),
(156, 29, 7),
(157, 29, 8),
(218, 30, 1),
(219, 30, 200),
(220, 30, 300),
(221, 30, 0),
(222, 30, 0),
(223, 30, 0),
(224, 30, 0),
(225, 30, 0),
(226, 30, 0),
(227, 30, 0),
(228, 30, 0),
(229, 30, 2),
(230, 30, 7),
(231, 30, 8),
(232, 30, 2),
(233, 30, 7),
(234, 30, 8),
(235, 30, 2),
(236, 30, 8),
(237, 30, 6),
(238, 30, 1),
(239, 30, 200),
(240, 30, 300),
(241, 30, 0),
(242, 30, 0),
(243, 30, 0),
(244, 30, 0),
(245, 30, 0),
(246, 30, 0),
(247, 30, 0),
(248, 30, 0),
(249, 30, 2),
(250, 30, 7),
(251, 30, 8),
(252, 30, 2),
(253, 30, 7),
(254, 30, 8),
(255, 30, 2),
(256, 30, 8),
(257, 30, 6),
(258, 30, 2),
(259, 30, 7),
(260, 30, 8),
(261, 30, 2),
(262, 30, 7),
(263, 30, 8),
(264, 30, 2),
(265, 30, 7),
(266, 30, 8),
(267, 30, 2),
(268, 30, 7),
(269, 30, 8),
(270, 30, 2),
(271, 30, 7),
(272, 30, 8),
(273, 30, 2),
(274, 30, 7),
(275, 30, 8),
(276, 30, 2),
(277, 30, 7),
(278, 30, 8),
(279, 30, 2),
(280, 30, 7),
(281, 30, 8),
(282, 30, 2),
(283, 30, 7),
(284, 30, 8),
(285, 30, 2),
(286, 30, 7),
(287, 30, 8),
(288, 30, 2),
(289, 30, 7),
(290, 30, 8),
(291, 30, 2),
(292, 30, 8),
(293, 30, 2),
(294, 30, 7),
(295, 30, 8),
(296, 30, 2),
(297, 30, 7),
(298, 30, 8),
(299, 30, 2),
(300, 30, 8),
(301, 30, 2),
(302, 30, 7),
(303, 30, 8),
(304, 30, 2),
(305, 30, 7),
(306, 30, 8),
(307, 30, 2),
(308, 30, 7),
(309, 30, 8),
(310, 30, 2),
(311, 30, 7),
(312, 30, 8),
(313, 30, 2),
(314, 30, 7),
(315, 30, 8),
(316, 30, 2),
(317, 30, 7),
(318, 30, 8),
(319, 30, 2),
(320, 30, 7),
(321, 30, 8),
(322, 30, 2),
(323, 30, 7),
(324, 30, 8),
(325, 30, 2),
(326, 30, 7),
(327, 30, 8),
(345, 31, 1),
(346, 31, 200),
(347, 31, 300),
(348, 31, 0),
(349, 31, 0),
(350, 31, 0),
(351, 31, 0),
(352, 31, 0),
(353, 31, 0),
(354, 31, 0),
(355, 31, 0),
(356, 31, 2),
(357, 31, 7),
(358, 31, 8),
(359, 31, 2),
(360, 31, 7),
(361, 31, 8),
(362, 31, 2),
(363, 31, 8),
(364, 31, 6),
(365, 31, 1),
(366, 31, 200),
(367, 31, 300),
(368, 31, 0),
(369, 31, 0),
(370, 31, 0),
(371, 31, 0),
(372, 31, 0),
(373, 31, 0),
(374, 31, 0),
(375, 31, 0),
(376, 31, 2),
(377, 31, 7),
(378, 31, 8),
(379, 31, 2),
(380, 31, 7),
(381, 31, 8),
(382, 31, 2),
(383, 31, 8),
(384, 31, 6),
(385, 31, 2),
(386, 31, 7),
(387, 31, 8),
(388, 31, 2),
(389, 31, 7),
(390, 31, 8),
(391, 31, 2),
(392, 31, 7),
(393, 31, 8),
(394, 31, 2),
(395, 31, 7),
(396, 31, 8),
(397, 31, 2),
(398, 31, 7),
(399, 31, 8),
(400, 31, 2),
(401, 31, 7),
(402, 31, 8),
(403, 31, 2),
(404, 31, 7),
(405, 31, 8),
(406, 31, 2),
(407, 31, 7),
(408, 31, 8),
(409, 31, 2),
(410, 31, 7),
(411, 31, 8),
(412, 31, 2),
(413, 31, 7),
(414, 31, 8),
(415, 31, 2),
(416, 31, 7),
(417, 31, 8),
(418, 31, 2),
(419, 31, 8),
(420, 31, 2),
(421, 31, 7),
(422, 31, 8),
(423, 31, 2),
(424, 31, 7),
(425, 31, 8),
(426, 31, 2),
(427, 31, 8),
(428, 31, 2),
(429, 31, 7),
(430, 31, 8),
(431, 31, 2),
(432, 31, 7),
(433, 31, 8),
(434, 31, 2),
(435, 31, 7),
(436, 31, 8),
(437, 31, 2),
(438, 31, 7),
(439, 31, 8),
(440, 31, 2),
(441, 31, 7),
(442, 31, 8),
(443, 31, 2),
(444, 31, 7),
(445, 31, 8),
(446, 31, 2),
(447, 31, 7),
(448, 31, 8),
(449, 31, 2),
(450, 31, 7),
(451, 31, 8),
(452, 31, 2),
(453, 31, 7),
(454, 31, 8),
(455, 31, 1),
(456, 31, 200),
(457, 31, 300),
(458, 31, 0),
(459, 31, 0),
(460, 31, 0),
(461, 31, 0),
(462, 31, 0),
(463, 31, 0),
(464, 31, 0),
(465, 31, 0),
(466, 31, 2),
(467, 31, 7),
(468, 31, 8),
(469, 31, 2),
(470, 31, 7),
(471, 31, 8),
(472, 31, 2),
(473, 31, 8),
(474, 31, 6),
(475, 31, 1),
(476, 31, 200),
(477, 31, 300),
(478, 31, 0),
(479, 31, 0),
(480, 31, 0),
(481, 31, 0),
(482, 31, 0),
(483, 31, 0),
(484, 31, 0),
(485, 31, 0),
(486, 31, 2),
(487, 31, 7),
(488, 31, 8),
(489, 31, 2),
(490, 31, 7),
(491, 31, 8),
(492, 31, 2),
(493, 31, 8),
(494, 31, 6),
(495, 31, 2),
(496, 31, 7),
(497, 31, 8),
(498, 31, 2),
(499, 31, 7),
(500, 31, 8),
(501, 31, 2),
(502, 31, 7),
(503, 31, 8),
(504, 31, 2),
(505, 31, 7),
(506, 31, 8),
(507, 31, 2),
(508, 31, 7),
(509, 31, 8),
(510, 31, 2),
(511, 31, 7),
(512, 31, 8),
(513, 31, 2),
(514, 31, 7),
(515, 31, 8),
(516, 31, 2),
(517, 31, 7),
(518, 31, 8),
(519, 31, 2),
(520, 31, 7),
(521, 31, 8),
(522, 31, 2),
(523, 31, 7),
(524, 31, 8),
(525, 31, 2),
(526, 31, 7),
(527, 31, 8),
(528, 31, 2),
(529, 31, 8),
(530, 31, 2),
(531, 31, 7),
(532, 31, 8),
(533, 31, 2),
(534, 31, 7),
(535, 31, 8),
(536, 31, 2),
(537, 31, 8),
(538, 31, 2),
(539, 31, 7),
(540, 31, 8),
(541, 31, 2),
(542, 31, 7),
(543, 31, 8),
(544, 31, 2),
(545, 31, 7),
(546, 31, 8),
(547, 31, 2),
(548, 31, 7),
(549, 31, 8),
(550, 31, 2),
(551, 31, 7),
(552, 31, 8),
(553, 31, 2),
(554, 31, 7),
(555, 31, 8),
(556, 31, 2),
(557, 31, 7),
(558, 31, 8),
(559, 31, 2),
(560, 31, 7),
(561, 31, 8),
(562, 31, 2),
(563, 31, 7),
(564, 31, 8),
(611, 32, 2),
(612, 32, 7),
(613, 32, 8),
(614, 32, 2),
(615, 32, 7),
(616, 32, 8),
(617, 32, 2),
(618, 32, 8),
(631, 32, 2),
(632, 32, 7),
(633, 32, 8),
(634, 32, 2),
(635, 32, 7),
(636, 32, 8),
(637, 32, 2),
(638, 32, 8),
(640, 32, 2),
(641, 32, 7),
(642, 32, 8),
(643, 32, 2),
(644, 32, 7),
(645, 32, 8),
(646, 32, 2),
(647, 32, 7),
(648, 32, 8),
(649, 32, 2),
(650, 32, 7),
(651, 32, 8),
(652, 32, 2),
(653, 32, 7),
(654, 32, 8),
(655, 32, 2),
(656, 32, 7),
(657, 32, 8),
(658, 32, 2),
(659, 32, 7),
(660, 32, 8),
(661, 32, 2),
(662, 32, 7),
(663, 32, 8),
(664, 32, 2),
(665, 32, 7),
(666, 32, 8),
(667, 32, 2),
(668, 32, 7),
(669, 32, 8),
(670, 32, 2),
(671, 32, 7),
(672, 32, 8),
(673, 32, 2),
(674, 32, 8),
(675, 32, 2),
(676, 32, 7),
(677, 32, 8),
(678, 32, 2),
(679, 32, 7),
(680, 32, 8),
(681, 32, 2),
(682, 32, 8),
(683, 32, 2),
(684, 32, 7),
(685, 32, 8),
(686, 32, 2),
(687, 32, 7),
(688, 32, 8),
(689, 32, 2),
(690, 32, 7),
(691, 32, 8),
(692, 32, 2),
(693, 32, 7),
(694, 32, 8),
(695, 32, 2),
(696, 32, 7),
(697, 32, 8),
(698, 32, 2),
(699, 32, 7),
(700, 32, 8),
(701, 32, 2),
(702, 32, 7),
(703, 32, 8),
(704, 32, 2),
(705, 32, 7),
(706, 32, 8),
(707, 32, 2),
(708, 32, 7),
(709, 32, 8),
(721, 32, 2),
(722, 32, 7),
(723, 32, 8),
(724, 32, 2),
(725, 32, 7),
(726, 32, 8),
(727, 32, 2),
(728, 32, 8),
(741, 32, 2),
(742, 32, 7),
(743, 32, 8),
(744, 32, 2),
(745, 32, 7),
(746, 32, 8),
(747, 32, 2),
(748, 32, 8),
(750, 32, 2),
(751, 32, 7),
(752, 32, 8),
(753, 32, 2),
(754, 32, 7),
(755, 32, 8),
(756, 32, 2),
(757, 32, 7),
(758, 32, 8),
(759, 32, 2),
(760, 32, 7),
(761, 32, 8),
(762, 32, 2),
(763, 32, 7),
(764, 32, 8),
(765, 32, 2),
(766, 32, 7),
(767, 32, 8),
(768, 32, 2),
(769, 32, 7),
(770, 32, 8),
(771, 32, 2),
(772, 32, 7),
(773, 32, 8),
(774, 32, 2),
(775, 32, 7),
(776, 32, 8),
(777, 32, 2),
(778, 32, 7),
(779, 32, 8),
(780, 32, 2),
(781, 32, 7),
(782, 32, 8),
(783, 32, 2),
(784, 32, 8),
(785, 32, 2),
(786, 32, 7),
(787, 32, 8),
(788, 32, 2),
(789, 32, 7),
(790, 32, 8),
(791, 32, 2),
(792, 32, 8),
(793, 32, 2),
(794, 32, 7),
(795, 32, 8),
(796, 32, 2),
(797, 32, 7),
(798, 32, 8),
(799, 32, 2),
(800, 32, 7),
(801, 32, 8),
(802, 32, 2),
(803, 32, 7),
(804, 32, 8),
(805, 32, 2),
(806, 32, 7),
(807, 32, 8),
(808, 32, 2),
(809, 32, 7),
(810, 32, 8),
(811, 32, 2),
(812, 32, 7),
(813, 32, 8),
(814, 32, 2),
(815, 32, 7),
(816, 32, 8),
(817, 32, 2),
(818, 32, 7),
(819, 32, 8),
(831, 32, 2),
(832, 32, 7),
(833, 32, 8),
(834, 32, 2),
(835, 32, 7),
(836, 32, 8),
(837, 32, 2),
(838, 32, 8),
(851, 32, 2),
(852, 32, 7),
(853, 32, 8),
(854, 32, 2),
(855, 32, 7),
(856, 32, 8),
(857, 32, 2),
(858, 32, 8),
(860, 32, 2),
(861, 32, 7),
(862, 32, 8),
(863, 32, 2),
(864, 32, 7),
(865, 32, 8),
(866, 32, 2),
(867, 32, 7),
(868, 32, 8),
(869, 32, 2),
(870, 32, 7),
(871, 32, 8),
(872, 32, 2),
(873, 32, 7),
(874, 32, 8),
(875, 32, 2),
(876, 32, 7),
(877, 32, 8),
(878, 32, 2),
(879, 32, 7),
(880, 32, 8),
(881, 32, 2),
(882, 32, 7),
(883, 32, 8),
(884, 32, 2),
(885, 32, 7),
(886, 32, 8),
(887, 32, 2),
(888, 32, 7),
(889, 32, 8),
(890, 32, 2),
(891, 32, 7),
(892, 32, 8),
(893, 32, 2),
(894, 32, 8),
(895, 32, 2),
(896, 32, 7),
(897, 32, 8),
(898, 32, 2),
(899, 32, 7),
(900, 32, 8),
(901, 32, 2),
(902, 32, 8),
(903, 32, 2),
(904, 32, 7),
(905, 32, 8),
(906, 32, 2),
(907, 32, 7),
(908, 32, 8),
(909, 32, 2),
(910, 32, 7),
(911, 32, 8),
(912, 32, 2),
(913, 32, 7),
(914, 32, 8),
(915, 32, 2),
(916, 32, 7),
(917, 32, 8),
(918, 32, 2),
(919, 32, 7),
(920, 32, 8),
(921, 32, 2),
(922, 32, 7),
(923, 32, 8),
(924, 32, 2),
(925, 32, 7),
(926, 32, 8),
(927, 32, 2),
(928, 32, 7),
(929, 32, 8),
(941, 32, 2),
(942, 32, 7),
(943, 32, 8),
(944, 32, 2),
(945, 32, 7),
(946, 32, 8),
(947, 32, 2),
(948, 32, 8),
(961, 32, 2),
(962, 32, 7),
(963, 32, 8),
(964, 32, 2),
(965, 32, 7),
(966, 32, 8),
(967, 32, 2),
(968, 32, 8),
(970, 32, 2),
(971, 32, 7),
(972, 32, 8),
(973, 32, 2),
(974, 32, 7),
(975, 32, 8),
(976, 32, 2),
(977, 32, 7),
(978, 32, 8),
(979, 32, 2),
(980, 32, 7),
(981, 32, 8),
(982, 32, 2),
(983, 32, 7),
(984, 32, 8),
(985, 32, 2),
(986, 32, 7),
(987, 32, 8),
(988, 32, 2),
(989, 32, 7),
(990, 32, 8),
(991, 32, 2),
(992, 32, 7),
(993, 32, 8),
(994, 32, 2),
(995, 32, 7),
(996, 32, 8),
(997, 32, 2),
(998, 32, 7),
(999, 32, 8),
(1000, 32, 2),
(1001, 32, 7),
(1002, 32, 8),
(1003, 32, 2),
(1004, 32, 8),
(1005, 32, 2),
(1006, 32, 7),
(1007, 32, 8),
(1008, 32, 2),
(1009, 32, 7),
(1010, 32, 8),
(1011, 32, 2),
(1012, 32, 8),
(1013, 32, 2),
(1014, 32, 7),
(1015, 32, 8),
(1016, 32, 2),
(1017, 32, 7),
(1018, 32, 8),
(1019, 32, 2),
(1020, 32, 7),
(1021, 32, 8),
(1022, 32, 2),
(1023, 32, 7),
(1024, 32, 8),
(1025, 32, 2),
(1026, 32, 7),
(1027, 32, 8),
(1028, 32, 2),
(1029, 32, 7),
(1030, 32, 8),
(1031, 32, 2),
(1032, 32, 7),
(1033, 32, 8),
(1034, 32, 2),
(1035, 32, 7),
(1036, 32, 8),
(1037, 32, 2),
(1038, 32, 7),
(1039, 32, 8),
(1111, 33, 1),
(1112, 33, 200),
(1113, 33, 300),
(1114, 33, 0),
(1115, 33, 0),
(1116, 33, 0),
(1117, 33, 0),
(1118, 33, 0),
(1119, 33, 0),
(1120, 33, 0),
(1121, 33, 0),
(1122, 33, 2),
(1123, 33, 7),
(1124, 33, 8),
(1125, 33, 2),
(1126, 33, 7),
(1127, 33, 8),
(1128, 33, 2),
(1129, 33, 8),
(1130, 33, 6),
(1131, 33, 1),
(1132, 33, 200),
(1133, 33, 300),
(1134, 33, 0),
(1135, 33, 0),
(1136, 33, 0),
(1137, 33, 0),
(1138, 33, 0),
(1139, 33, 0),
(1140, 33, 0),
(1141, 33, 0),
(1142, 33, 2),
(1143, 33, 7),
(1144, 33, 8),
(1145, 33, 2),
(1146, 33, 7),
(1147, 33, 8),
(1148, 33, 2),
(1149, 33, 8),
(1150, 33, 6),
(1151, 33, 2),
(1152, 33, 7),
(1153, 33, 8),
(1154, 33, 2),
(1155, 33, 7),
(1156, 33, 8),
(1157, 33, 2),
(1158, 33, 7),
(1159, 33, 8),
(1160, 33, 2),
(1161, 33, 7),
(1162, 33, 8),
(1163, 33, 2),
(1164, 33, 7),
(1165, 33, 8),
(1166, 33, 2),
(1167, 33, 7),
(1168, 33, 8),
(1169, 33, 2),
(1170, 33, 7),
(1171, 33, 8),
(1172, 33, 2),
(1173, 33, 7),
(1174, 33, 8),
(1175, 33, 2),
(1176, 33, 7),
(1177, 33, 8),
(1178, 33, 2),
(1179, 33, 7),
(1180, 33, 8),
(1181, 33, 2),
(1182, 33, 7),
(1183, 33, 8),
(1184, 33, 2),
(1185, 33, 8),
(1186, 33, 2),
(1187, 33, 7),
(1188, 33, 8),
(1189, 33, 2),
(1190, 33, 7),
(1191, 33, 8),
(1192, 33, 2),
(1193, 33, 8),
(1194, 33, 2),
(1195, 33, 7),
(1196, 33, 8),
(1197, 33, 2),
(1198, 33, 7),
(1199, 33, 8),
(1200, 33, 2),
(1201, 33, 7),
(1202, 33, 8),
(1203, 33, 2),
(1204, 33, 7),
(1205, 33, 8),
(1206, 33, 2),
(1207, 33, 7),
(1208, 33, 8),
(1209, 33, 2),
(1210, 33, 7),
(1211, 33, 8),
(1212, 33, 2),
(1213, 33, 7),
(1214, 33, 8),
(1215, 33, 2),
(1216, 33, 7),
(1217, 33, 8),
(1218, 33, 2),
(1219, 33, 7),
(1220, 33, 8),
(1221, 33, 1),
(1222, 33, 200),
(1223, 33, 300),
(1224, 33, 0),
(1225, 33, 0),
(1226, 33, 0),
(1227, 33, 0),
(1228, 33, 0),
(1229, 33, 0),
(1230, 33, 0),
(1231, 33, 0),
(1232, 33, 2),
(1233, 33, 7),
(1234, 33, 8),
(1235, 33, 2),
(1236, 33, 7),
(1237, 33, 8),
(1238, 33, 2),
(1239, 33, 8),
(1240, 33, 6),
(1241, 33, 1),
(1242, 33, 200),
(1243, 33, 300),
(1244, 33, 0),
(1245, 33, 0),
(1246, 33, 0),
(1247, 33, 0),
(1248, 33, 0),
(1249, 33, 0),
(1250, 33, 0),
(1251, 33, 0),
(1252, 33, 2),
(1253, 33, 7),
(1254, 33, 8),
(1255, 33, 2),
(1256, 33, 7),
(1257, 33, 8),
(1258, 33, 2),
(1259, 33, 8),
(1260, 33, 6),
(1261, 33, 2),
(1262, 33, 7),
(1263, 33, 8),
(1264, 33, 2),
(1265, 33, 7),
(1266, 33, 8),
(1267, 33, 2),
(1268, 33, 7),
(1269, 33, 8),
(1270, 33, 2),
(1271, 33, 7),
(1272, 33, 8),
(1273, 33, 2),
(1274, 33, 7),
(1275, 33, 8),
(1276, 33, 2),
(1277, 33, 7),
(1278, 33, 8),
(1279, 33, 2),
(1280, 33, 7),
(1281, 33, 8),
(1282, 33, 2),
(1283, 33, 7),
(1284, 33, 8),
(1285, 33, 2),
(1286, 33, 7),
(1287, 33, 8),
(1288, 33, 2),
(1289, 33, 7),
(1290, 33, 8),
(1291, 33, 2),
(1292, 33, 7),
(1293, 33, 8),
(1294, 33, 2),
(1295, 33, 8),
(1296, 33, 2),
(1297, 33, 7),
(1298, 33, 8),
(1299, 33, 2),
(1300, 33, 7),
(1301, 33, 8),
(1302, 33, 2),
(1303, 33, 8),
(1304, 33, 2),
(1305, 33, 7),
(1306, 33, 8),
(1307, 33, 2),
(1308, 33, 7),
(1309, 33, 8),
(1310, 33, 2),
(1311, 33, 7),
(1312, 33, 8),
(1313, 33, 2),
(1314, 33, 7),
(1315, 33, 8),
(1316, 33, 2),
(1317, 33, 7),
(1318, 33, 8),
(1319, 33, 2),
(1320, 33, 7),
(1321, 33, 8),
(1322, 33, 2),
(1323, 33, 7),
(1324, 33, 8),
(1325, 33, 2),
(1326, 33, 7),
(1327, 33, 8),
(1328, 33, 2),
(1329, 33, 7),
(1330, 33, 8),
(1331, 33, 1),
(1332, 33, 200),
(1333, 33, 300),
(1334, 33, 0),
(1335, 33, 0),
(1336, 33, 0),
(1337, 33, 0),
(1338, 33, 0),
(1339, 33, 0),
(1340, 33, 0),
(1341, 33, 0),
(1342, 33, 2),
(1343, 33, 7),
(1344, 33, 8),
(1345, 33, 2),
(1346, 33, 7),
(1347, 33, 8),
(1348, 33, 2),
(1349, 33, 8),
(1350, 33, 6),
(1351, 33, 1),
(1352, 33, 200),
(1353, 33, 300),
(1354, 33, 0),
(1355, 33, 0),
(1356, 33, 0),
(1357, 33, 0),
(1358, 33, 0),
(1359, 33, 0),
(1360, 33, 0),
(1361, 33, 0),
(1362, 33, 2),
(1363, 33, 7),
(1364, 33, 8),
(1365, 33, 2),
(1366, 33, 7),
(1367, 33, 8),
(1368, 33, 2),
(1369, 33, 8),
(1370, 33, 6),
(1371, 33, 2),
(1372, 33, 7),
(1373, 33, 8),
(1374, 33, 2),
(1375, 33, 7),
(1376, 33, 8),
(1377, 33, 2),
(1378, 33, 7),
(1379, 33, 8),
(1380, 33, 2),
(1381, 33, 7),
(1382, 33, 8),
(1383, 33, 2),
(1384, 33, 7),
(1385, 33, 8),
(1386, 33, 2),
(1387, 33, 7),
(1388, 33, 8),
(1389, 33, 2),
(1390, 33, 7),
(1391, 33, 8),
(1392, 33, 2),
(1393, 33, 7),
(1394, 33, 8),
(1395, 33, 2),
(1396, 33, 7),
(1397, 33, 8),
(1398, 33, 2),
(1399, 33, 7),
(1400, 33, 8),
(1401, 33, 2),
(1402, 33, 7),
(1403, 33, 8),
(1404, 33, 2),
(1405, 33, 8),
(1406, 33, 2),
(1407, 33, 7),
(1408, 33, 8),
(1409, 33, 2),
(1410, 33, 7),
(1411, 33, 8),
(1412, 33, 2),
(1413, 33, 8),
(1414, 33, 2),
(1415, 33, 7),
(1416, 33, 8),
(1417, 33, 2),
(1418, 33, 7),
(1419, 33, 8),
(1420, 33, 2),
(1421, 33, 7),
(1422, 33, 8),
(1423, 33, 2),
(1424, 33, 7),
(1425, 33, 8),
(1426, 33, 2),
(1427, 33, 7),
(1428, 33, 8),
(1429, 33, 2),
(1430, 33, 7),
(1431, 33, 8),
(1432, 33, 2),
(1433, 33, 7),
(1434, 33, 8),
(1435, 33, 2),
(1436, 33, 7),
(1437, 33, 8),
(1438, 33, 2),
(1439, 33, 7),
(1440, 33, 8),
(1441, 33, 1),
(1442, 33, 200),
(1443, 33, 300),
(1444, 33, 0),
(1445, 33, 0),
(1446, 33, 0),
(1447, 33, 0),
(1448, 33, 0),
(1449, 33, 0),
(1450, 33, 0),
(1451, 33, 0),
(1452, 33, 2),
(1453, 33, 7),
(1454, 33, 8),
(1455, 33, 2),
(1456, 33, 7),
(1457, 33, 8),
(1458, 33, 2),
(1459, 33, 8),
(1460, 33, 6),
(1461, 33, 1),
(1462, 33, 200),
(1463, 33, 300),
(1464, 33, 0),
(1465, 33, 0),
(1466, 33, 0),
(1467, 33, 0),
(1468, 33, 0),
(1469, 33, 0),
(1470, 33, 0),
(1471, 33, 0),
(1472, 33, 2),
(1473, 33, 7),
(1474, 33, 8),
(1475, 33, 2),
(1476, 33, 7),
(1477, 33, 8),
(1478, 33, 2),
(1479, 33, 8),
(1480, 33, 6),
(1481, 33, 2),
(1482, 33, 7),
(1483, 33, 8),
(1484, 33, 2),
(1485, 33, 7),
(1486, 33, 8),
(1487, 33, 2),
(1488, 33, 7),
(1489, 33, 8),
(1490, 33, 2),
(1491, 33, 7),
(1492, 33, 8),
(1493, 33, 2),
(1494, 33, 7),
(1495, 33, 8),
(1496, 33, 2),
(1497, 33, 7),
(1498, 33, 8),
(1499, 33, 2),
(1500, 33, 7),
(1501, 33, 8),
(1502, 33, 2),
(1503, 33, 7),
(1504, 33, 8),
(1505, 33, 2),
(1506, 33, 7),
(1507, 33, 8),
(1508, 33, 2),
(1509, 33, 7),
(1510, 33, 8),
(1511, 33, 2),
(1512, 33, 7),
(1513, 33, 8),
(1514, 33, 2),
(1515, 33, 8),
(1516, 33, 2),
(1517, 33, 7),
(1518, 33, 8),
(1519, 33, 2),
(1520, 33, 7),
(1521, 33, 8),
(1522, 33, 2),
(1523, 33, 8),
(1524, 33, 2),
(1525, 33, 7),
(1526, 33, 8),
(1527, 33, 2),
(1528, 33, 7),
(1529, 33, 8),
(1530, 33, 2),
(1531, 33, 7),
(1532, 33, 8),
(1533, 33, 2),
(1534, 33, 7),
(1535, 33, 8),
(1536, 33, 2),
(1537, 33, 7),
(1538, 33, 8),
(1539, 33, 2),
(1540, 33, 7),
(1541, 33, 8),
(1542, 33, 2),
(1543, 33, 7),
(1544, 33, 8),
(1545, 33, 2),
(1546, 33, 7),
(1547, 33, 8),
(1548, 33, 2),
(1549, 33, 7),
(1550, 33, 8),
(1551, 33, 2),
(1552, 33, 7),
(1553, 33, 8),
(1554, 33, 2),
(1555, 33, 7),
(1556, 33, 8),
(1557, 33, 2),
(1558, 33, 8),
(1559, 33, 2),
(1560, 33, 7),
(1561, 33, 8),
(1562, 33, 2),
(1563, 33, 7),
(1564, 33, 8),
(1565, 33, 2),
(1566, 33, 8),
(1567, 33, 2),
(1568, 33, 7),
(1569, 33, 8),
(1570, 33, 2),
(1571, 33, 7),
(1572, 33, 8),
(1573, 33, 2),
(1574, 33, 7),
(1575, 33, 8),
(1576, 33, 2),
(1577, 33, 7),
(1578, 33, 8),
(1579, 33, 2),
(1580, 33, 7),
(1581, 33, 8),
(1582, 33, 2),
(1583, 33, 7),
(1584, 33, 8),
(1585, 33, 2),
(1586, 33, 7),
(1587, 33, 8),
(1588, 33, 2),
(1589, 33, 7),
(1590, 33, 8),
(1591, 33, 2),
(1592, 33, 7),
(1593, 33, 8),
(1594, 33, 2),
(1595, 33, 7),
(1596, 33, 8),
(1597, 33, 2),
(1598, 33, 7),
(1599, 33, 8),
(1600, 33, 2),
(1601, 33, 8),
(1602, 33, 2),
(1603, 33, 7),
(1604, 33, 8),
(1605, 33, 2),
(1606, 33, 7),
(1607, 33, 8),
(1608, 33, 2),
(1609, 33, 8),
(1610, 33, 2),
(1611, 33, 7),
(1612, 33, 8),
(1613, 33, 2),
(1614, 33, 7),
(1615, 33, 8),
(1616, 33, 2),
(1617, 33, 7),
(1618, 33, 8),
(1619, 33, 2),
(1620, 33, 7),
(1621, 33, 8),
(1622, 33, 2),
(1623, 33, 7),
(1624, 33, 8),
(1625, 33, 2),
(1626, 33, 7),
(1627, 33, 8),
(1628, 33, 2),
(1629, 33, 7),
(1630, 33, 8),
(1631, 33, 2),
(1632, 33, 7),
(1633, 33, 8),
(1634, 33, 2),
(1635, 33, 7),
(1636, 33, 8),
(1637, 33, 2),
(1638, 33, 7),
(1639, 33, 8),
(1640, 33, 2),
(1641, 33, 7),
(1642, 33, 8),
(1643, 33, 2),
(1644, 33, 8),
(1645, 33, 2),
(1646, 33, 7),
(1647, 33, 8),
(1648, 33, 2),
(1649, 33, 7),
(1650, 33, 8),
(1651, 33, 2),
(1652, 33, 8),
(1653, 33, 2),
(1654, 33, 7),
(1655, 33, 8),
(1656, 33, 2),
(1657, 33, 7),
(1658, 33, 8),
(1659, 33, 2),
(1660, 33, 7),
(1661, 33, 8),
(1662, 33, 2),
(1663, 33, 7),
(1664, 33, 8),
(1665, 33, 2),
(1666, 33, 7),
(1667, 33, 8),
(1668, 33, 2),
(1669, 33, 7),
(1670, 33, 8),
(1671, 33, 2),
(1672, 33, 7),
(1673, 33, 8),
(1674, 33, 2),
(1675, 33, 7),
(1676, 33, 8),
(1677, 33, 2),
(1678, 33, 7),
(1679, 33, 8),
(1680, 33, 2),
(1681, 33, 7),
(1682, 33, 8),
(1683, 33, 2),
(1684, 33, 7),
(1685, 33, 8),
(1686, 33, 2),
(1687, 33, 8),
(1688, 33, 2),
(1689, 33, 7),
(1690, 33, 8),
(1691, 33, 2),
(1692, 33, 7),
(1693, 33, 8),
(1694, 33, 2),
(1695, 33, 8),
(1696, 33, 2),
(1697, 33, 7),
(1698, 33, 8),
(1699, 33, 2),
(1700, 33, 7),
(1701, 33, 8),
(1702, 33, 2),
(1703, 33, 7),
(1704, 33, 8),
(1705, 33, 2),
(1706, 33, 7),
(1707, 33, 8),
(1708, 33, 2),
(1709, 33, 7),
(1710, 33, 8),
(1711, 33, 2),
(1712, 33, 7),
(1713, 33, 8),
(1714, 33, 2),
(1715, 33, 7),
(1716, 33, 8),
(1717, 33, 2),
(1718, 33, 7),
(1719, 33, 8),
(1720, 33, 2),
(1721, 33, 7),
(1722, 33, 8),
(1723, 33, 2),
(1724, 33, 7),
(1725, 33, 8),
(1726, 33, 2),
(1727, 33, 7),
(1728, 33, 8),
(1729, 33, 2),
(1730, 33, 8),
(1731, 33, 2),
(1732, 33, 7),
(1733, 33, 8),
(1734, 33, 2),
(1735, 33, 7),
(1736, 33, 8),
(1737, 33, 2),
(1738, 33, 8),
(1739, 33, 2),
(1740, 33, 7),
(1741, 33, 8),
(1742, 33, 2),
(1743, 33, 7),
(1744, 33, 8),
(1745, 33, 2),
(1746, 33, 7),
(1747, 33, 8),
(1748, 33, 2),
(1749, 33, 7),
(1750, 33, 8),
(1751, 33, 2),
(1752, 33, 7),
(1753, 33, 8),
(1754, 33, 2),
(1755, 33, 7),
(1756, 33, 8),
(1757, 33, 2),
(1758, 33, 7),
(1759, 33, 8),
(1760, 33, 2),
(1761, 33, 7),
(1762, 33, 8),
(1763, 33, 2),
(1764, 33, 7),
(1765, 33, 8),
(1766, 33, 2),
(1767, 33, 7),
(1768, 33, 8),
(1769, 33, 2),
(1770, 33, 7),
(1771, 33, 8),
(1772, 33, 2),
(1773, 33, 8),
(1774, 33, 2),
(1775, 33, 7),
(1776, 33, 8),
(1777, 33, 2),
(1778, 33, 7),
(1779, 33, 8),
(1780, 33, 2),
(1781, 33, 8),
(1782, 33, 2),
(1783, 33, 7),
(1784, 33, 8),
(1785, 33, 2),
(1786, 33, 7),
(1787, 33, 8),
(1788, 33, 2),
(1789, 33, 7),
(1790, 33, 8),
(1791, 33, 2),
(1792, 33, 7),
(1793, 33, 8),
(1794, 33, 2),
(1795, 33, 7),
(1796, 33, 8),
(1797, 33, 2),
(1798, 33, 7),
(1799, 33, 8),
(1800, 33, 2),
(1801, 33, 7),
(1802, 33, 8),
(1803, 33, 2),
(1804, 33, 7),
(1805, 33, 8),
(1806, 33, 2),
(1807, 33, 7),
(1808, 33, 8),
(1809, 33, 2),
(1810, 33, 7),
(1811, 33, 8),
(1812, 33, 2),
(1813, 33, 7),
(1814, 33, 8),
(1815, 33, 2),
(1816, 33, 8),
(1817, 33, 2),
(1818, 33, 7),
(1819, 33, 8),
(1820, 33, 2),
(1821, 33, 7),
(1822, 33, 8),
(1823, 33, 2),
(1824, 33, 8),
(1825, 33, 2),
(1826, 33, 7),
(1827, 33, 8),
(1828, 33, 2),
(1829, 33, 7),
(1830, 33, 8),
(1831, 33, 2),
(1832, 33, 7),
(1833, 33, 8),
(1834, 33, 2),
(1835, 33, 7),
(1836, 33, 8),
(1837, 33, 2),
(1838, 33, 7),
(1839, 33, 8),
(1840, 33, 2),
(1841, 33, 7),
(1842, 33, 8),
(1843, 33, 2),
(1844, 33, 7),
(1845, 33, 8),
(1846, 33, 2),
(1847, 33, 7),
(1848, 33, 8),
(1849, 33, 2),
(1850, 33, 7),
(1851, 33, 8),
(1852, 33, 2),
(1853, 33, 7),
(1854, 33, 8),
(1855, 33, 2),
(1856, 33, 7),
(1857, 33, 8),
(1858, 33, 2),
(1859, 33, 8),
(1860, 33, 2),
(1861, 33, 7),
(1862, 33, 8),
(1863, 33, 2),
(1864, 33, 7),
(1865, 33, 8),
(1866, 33, 2),
(1867, 33, 8),
(1868, 33, 2),
(1869, 33, 7),
(1870, 33, 8),
(1871, 33, 2),
(1872, 33, 7),
(1873, 33, 8),
(1874, 33, 2),
(1875, 33, 7),
(1876, 33, 8),
(1877, 33, 2),
(1878, 33, 7),
(1879, 33, 8),
(1880, 33, 2),
(1881, 33, 7),
(1882, 33, 8),
(1883, 33, 2),
(1884, 33, 7),
(1885, 33, 8),
(1886, 33, 2),
(1887, 33, 7),
(1888, 33, 8),
(1889, 33, 2),
(1890, 33, 7),
(1891, 33, 8),
(1892, 33, 2),
(1893, 33, 7),
(1894, 33, 8),
(2134, 37, 2),
(2135, 37, 6),
(2136, 37, 8),
(2137, 38, 2),
(2138, 38, 6),
(2139, 38, 8),
(2140, 39, 2),
(2141, 39, 6),
(2142, 39, 8),
(2143, 40, 2),
(2144, 40, 6),
(2145, 40, 8),
(2146, 41, 2),
(2147, 41, 6),
(2148, 41, 8),
(2149, 42, 2),
(2150, 42, 6),
(2151, 42, 8);

-- --------------------------------------------------------

--
-- Table structure for table `tblmstclients`
--

CREATE TABLE `tblmstclients` (
  `ClientId` smallint(6) NOT NULL,
  `ClientName` varchar(100) DEFAULT NULL,
  `ContactNo` varchar(15) DEFAULT NULL,
  `eMail` varchar(100) DEFAULT NULL,
  `WebsiteURL` varchar(100) DEFAULT NULL,
  `FacebookURL` varchar(250) DEFAULT NULL,
  `YoutubeURL` varchar(250) DEFAULT NULL,
  `InstagramURL` varchar(250) DEFAULT NULL,
  `TwitterURL` varchar(250) DEFAULT NULL,
  `PinterestURL` varchar(250) DEFAULT NULL,
  `LinkedInURL` varchar(250) DEFAULT NULL,
  `Active` bit(1) DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblmstclients`
--

INSERT INTO `tblmstclients` (`ClientId`, `ClientName`, `ContactNo`, `eMail`, `WebsiteURL`, `FacebookURL`, `YoutubeURL`, `InstagramURL`, `TwitterURL`, `PinterestURL`, `LinkedInURL`, `Active`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(1, 'Winpath', '9000999309', 'gafoor.md@winpathit.com', 'https://www.winpathit.com', 'https://www.facebook.com/', 'https://www.youtube.com/', 'https://www.instagram.com/', 'https://twitter.com', 'https://in.pinterest.com/', 'https://in.linkedin.com/', b'1', NULL, NULL),
(2, 'Google', '9000999309', 'gafoor.md@winpathit.com', 'https://www.winpathit.com', 'https://www.facebook.com/', 'https://www.youtube.com/', 'https://www.instagram.com/', 'https://twitter.com', 'https://in.pinterest.com/', 'https://in.linkedin.com/', b'1', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tblmsteventcategories`
--

CREATE TABLE `tblmsteventcategories` (
  `EventCategoryId` tinyint(4) NOT NULL,
  `CategoryName` varchar(100) DEFAULT NULL,
  `Active` bit(1) DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblmsteventcategories`
--

INSERT INTO `tblmsteventcategories` (`EventCategoryId`, `CategoryName`, `Active`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(1, 'Annual Day', b'1', NULL, 0),
(2, 'Wedding', b'1', NULL, 0);

-- --------------------------------------------------------

--
-- Table structure for table `tblmsteventstatuses`
--

CREATE TABLE `tblmsteventstatuses` (
  `EventStatusId` tinyint(3) UNSIGNED NOT NULL,
  `EventStatus` varchar(20) DEFAULT NULL,
  `SortOrder` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tblmsteventstatuses`
--

INSERT INTO `tblmsteventstatuses` (`EventStatusId`, `EventStatus`, `SortOrder`) VALUES
(1, 'Scheduled', 6),
(5, 'Started', 7),
(10, 'Completed', 2),
(15, 'SubmittedForDM', 8),
(20, 'DMStarted', 4),
(25, 'DMCompleted', 3),
(30, 'Cancelled', 1),
(35, 'Postponed', 5);

-- --------------------------------------------------------

--
-- Table structure for table `tblmstlogin`
--

CREATE TABLE `tblmstlogin` (
  `LoginId` smallint(5) UNSIGNED NOT NULL,
  `eMail` varchar(100) NOT NULL,
  `Salt` binary(20) NOT NULL,
  `Hash` binary(20) NOT NULL,
  `UserId` smallint(6) NOT NULL,
  `IsDefaultPasswordChanged` bit(1) DEFAULT NULL,
  `DefaultPasswordChangedOn` datetime DEFAULT NULL,
  `IsLinkSentToResetPassword` bit(1) DEFAULT NULL,
  `LinkSentToResetPasswordOn` datetime DEFAULT NULL,
  `GUIDToResetPassword` varchar(36) DEFAULT NULL,
  `LastPasswordResetOn` datetime DEFAULT NULL,
  `LastLoginOn` datetime DEFAULT NULL,
  `IsActive` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tblmstlogin`
--

INSERT INTO `tblmstlogin` (`LoginId`, `eMail`, `Salt`, `Hash`, `UserId`, `IsDefaultPasswordChanged`, `DefaultPasswordChangedOn`, `IsLinkSentToResetPassword`, `LinkSentToResetPasswordOn`, `GUIDToResetPassword`, `LastPasswordResetOn`, `LastLoginOn`, `IsActive`) VALUES
(1, 'mdgafoor1@gmail.com', 0xaed3addc330b975ed5b7705dff22466cb583ca7f, 0x4e9d7e57403d2ec0bd84c29a637af573d2d99b34, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-29 20:29:34', b'1'),
(2, 'test@gmail.com', 0x7996026f60c13ccac63cc041121704e861f3489b, 0xd4e930831b3056e64eddba8e67a7b878db33cfff, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(3, 'test2@gmail.com', 0xf96657f1d7868a9b2b322958928f3ce2146e3e6a, 0xb0d48fdc530ee90fed90d561b81405844ebea5eb, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(4, 'test3@gmail.com', 0x10b0bf706c5f4d71a03ee7a91141467fed5f5e4f, 0x9a34f595d7cbc05f178b71e1a2b8ba6452aa0250, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(5, 'test35@gmail.com', 0xc07dfd4c4c10961f6fdc4046512d2bc50fadd81f, 0x476a6788010cc60ac9a5eb8ea08a3bb993d813e2, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(6, 'srinivas846@gmail.com', 0xaed3addc330b975ed5b7705dff22466cb583ca7f, 0x4e9d7e57403d2ec0bd84c29a637af573d2d99b34, 7, NULL, NULL, NULL, NULL, NULL, NULL, '2019-08-28 21:03:32', b'1'),
(7, 'rrr@gmail.com', 0xafbaf8f52edd9276b2e296cd4d6b85d55b0fd264, 0x7b006b5a1e28ce0ca81e33e7e4756150a0d93914, 8, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(8, 'rrr3@gmail.com', 0x57a879cc94ac6beea8edd8debc2b4cdf4c6ab3b2, 0x7bb94ac339bbcb72f24c406179f7fad00991432a, 9, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(9, 'rrr33@gmail.com', 0x5a44937570eb3d5cb33ae42c69d7a0f558c2ed53, 0x8de9e59308c80fb2902da6ce96cb04b4e35f2023, 10, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(10, 'rrr334@gmail.com', 0x750bffef3e916138a3142475be1888ce859143be, 0x34170085adc1f410bacc0188fce7f2a60be54d02, 11, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(11, 'rrr3345@gmail.com', 0xc2d8777f8e40931e465560abfea4e662f1ba3cae, 0xc4fea4cdb7d1af546268839dc22157adc2cd31b0, 12, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(12, 'rrr33451@gmail.com', 0x647f257c270aac335e0deb0fca7e2f447791070f, 0xf5d3fb0e40139fe1c89ba4dfdc4891cde312eaea, 13, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(13, 'rrr334512@gmail.com', 0x703461af65a03b718a3b2d145f8046adb3f3ffc8, 0x3a286bb064c4945779793c1ad7b0f3a0e259e6ea, 14, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(14, 'rr4@gmail.com', 0x775d78656d25c4b77c1e2452b153f54ee79a2f49, 0x06731a91b945f5bb3249f095657ad546ff10a648, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(15, 'rr41@gmail.com', 0x341d88a74d63a25fe151eaed565a6a9f7287fc5b, 0xd125ebfc40016ea68e7c4001d7f2c8f6aacb1944, 16, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(16, 'rr412@gmail.com', 0xad535627e43ef704e22520835ef916a15ff5fcea, 0xbc7f94b388fea2c5e7f1f6fe80e69fb2bf72c238, 17, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(17, 'rr4126@gmail.com', 0xf6ab2757b46a9f92ecbcc42825686328311e9da8, 0xa2432d3795d698d4c2e0cf8b92fb9611ab86fed9, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(18, 'sai@gmail.com', 0xaed3addc330b975ed5b7705dff22466cb583ca7f, 0xfaaad0a8e5f93139a96a5d0dff7e97fbf5737804, 19, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(19, 'sai2@gmail.com', 0x8e7c64294350c06e7ee26d9c99ca86b6b3d5f819, 0xe7a424249c10c4fff144a5ca2f10a7606266664c, 20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(20, 'sai21@gmail.com', 0xb983eb92300449bf17c2dc716f0bd10b84185e99, 0x95cf7a2afa4089125dca7c82d27e5cb2ac517b59, 21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(21, 'sai212@gmail.com', 0x3158ef8cfe8db55d91004c5b3bb89e94690d98ca, 0x3c360a7cfa67d5ad4fc27e7b10d21ac62454601a, 22, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(22, 'sai2125@gmail.com', 0x5fcff53a5a1091e16c3c1fa0e4c74dc4a4cb687c, 0x56abdc7f4c714c5cc59eb03639b9a855afa40fbf, 23, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(23, 'sai21256@gmail.com', 0x67b2e3eb94d5931a761ae9adb62c445f880a7675, 0x15533e68032d20d72c2a00d0fc99c794a1d20cf3, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(24, 'sai31@gmail.com', 0x70f225065c0b9511b3e07f079dd0431664fb9dd5, 0x60ada9343616df4764d2cd42dcc2c472286041e9, 25, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(25, 'sai321@gmail.com', 0xbd0c8a4a01eaba8dc6d912db503e8859f36de87f, 0xdfcb09bb90dc6d0edec428dc8875183744862ed1, 26, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(26, 'sai4@gmail.com', 0x1f5b7c241a185ed2f94f8146256b7946dd903ccc, 0xdf453969b56a1786af23678ff82fbdc8d6b3563e, 27, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(27, 'sai44@gmail.com', 0x43556dd6216e7f7a455678d3c26f1c994c8ead01, 0x83748611c6499e5a67bf7dcab6e9a4bd9814613f, 28, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(28, '', 0xd672c4f2db4a3d21dfcd3d82e80777460b786cc5, 0xfe0ccd5f47a174daf2a36e89c05bb16b827f70dd, 29, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(29, 'AAA@AA.AA', 0x95ba624c3e847814eadb92acc96527cb682efe3d, 0xc6126c1fc949b0f78a67136e5308ed159580c020, 30, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(30, 'BBB@BB.BB', 0xd497550af68237624e822e1cbe0e001688c184de, 0x713c6d0314234317444bc14d8a1d11156d06322e, 31, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(31, 'sai46@gmail.com', 0x9f215270beb1ce872b94057fd2668ac41b456fd0, 0x083a358c144849c489d91b24c767b73f7ab9f8d3, 32, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(32, 'sai467@gmail.com', 0x51252589916fee204e4a5411b2102ca273c1b259, 0x9b1f4ee35abf841960c8930fdd45160a18ced8f6, 33, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(33, 'sai468@gmail.com', 0x605139ffbf1da21e3b58eface3ca9c1675f2ce01, 0xcf60f48e5bd6d0bb7313e0e46af2d95eaa93e9f7, 34, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1'),
(34, 'sai469@gmail.com', 0xd05b68d217f95c24c1650d0c1b0bea23f56bed76, 0xd2aa86fe567b8c6573bfd2744617cc34bb2814fc, 35, NULL, NULL, NULL, NULL, NULL, NULL, NULL, b'1');

-- --------------------------------------------------------

--
-- Table structure for table `tblmstroles`
--

CREATE TABLE `tblmstroles` (
  `RoleId` tinyint(2) UNSIGNED NOT NULL,
  `RoleCode` varchar(12) NOT NULL,
  `Role` varchar(20) NOT NULL,
  `Active` bit(1) DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblmstroles`
--

INSERT INTO `tblmstroles` (`RoleId`, `RoleCode`, `Role`, `Active`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(1, 'SuperAdmin', 'Super Admin', b'1', '2019-08-16 05:43:00', 0),
(2, 'Coordinator', 'Coordinator', b'1', '2019-08-16 05:43:00', 0),
(3, 'DM EX', 'DM executive', b'1', '2019-08-16 05:43:00', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tblmstservices`
--

CREATE TABLE `tblmstservices` (
  `ServiceId` smallint(6) UNSIGNED NOT NULL,
  `ServiceTypeId` smallint(6) DEFAULT NULL,
  `ServiceName` varchar(100) DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblmstservices`
--

INSERT INTO `tblmstservices` (`ServiceId`, `ServiceTypeId`, `ServiceName`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(1, 1, 'Facebook', '2019-08-19 09:23:40', 0),
(2, 1, 'Youtube', '2019-08-19 09:23:40', 0),
(3, 1, 'Twitter', '2019-08-19 09:23:40', 0),
(4, 1, 'Instagram', '2019-08-19 09:23:40', 0),
(5, 1, 'Pinterest', '2019-08-19 09:23:40', 0),
(6, 1, 'LinkedIn', '2019-08-19 09:23:40', 0),
(7, 2, 'Photo', '2019-08-19 09:23:40', 0),
(8, 2, 'Video', '2019-08-19 09:23:40', 0),
(9, 4, 'Cap', '2019-08-19 09:23:40', 0),
(10, 4, 'Pen', '2019-08-19 09:23:40', 0),
(11, 4, 'T-Shirt', '2019-08-19 09:23:40', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tblmstservicetypes`
--

CREATE TABLE `tblmstservicetypes` (
  `ServiceTypeId` smallint(6) UNSIGNED NOT NULL,
  `ServiceTypeCode` varchar(10) DEFAULT NULL,
  `ServiceTypeName` varchar(100) DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblmstservicetypes`
--

INSERT INTO `tblmstservicetypes` (`ServiceTypeId`, `ServiceTypeCode`, `ServiceTypeName`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(1, 'URL', 'URL', '2019-08-19 09:16:04', 0),
(2, 'Path', 'File Path', '2019-08-19 09:16:04', 0),
(3, 'Text', 'Text', '2019-08-19 09:16:04', 0),
(4, 'Gift', 'File Path', '2019-08-19 09:16:04', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tblmstusers`
--

CREATE TABLE `tblmstusers` (
  `UserId` smallint(6) UNSIGNED NOT NULL,
  `RoleId` tinyint(2) DEFAULT NULL,
  `ClientId` smallint(6) DEFAULT NULL,
  `Name` varchar(100) DEFAULT NULL,
  `ContactNo` varchar(15) DEFAULT NULL,
  `eMail` varchar(100) DEFAULT NULL,
  `Designation` varchar(45) DEFAULT NULL,
  `Active` bit(1) DEFAULT NULL,
  `LastModifiedOn` datetime DEFAULT NULL,
  `LastModifiedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tblmstusers`
--

INSERT INTO `tblmstusers` (`UserId`, `RoleId`, `ClientId`, `Name`, `ContactNo`, `eMail`, `Designation`, `Active`, `LastModifiedOn`, `LastModifiedBy`) VALUES
(0, 1, NULL, 'System', '9000999309', 'mdgafoor@gmail.com', NULL, b'1', '2019-08-16 05:51:36', 0),
(2, 1, 1, 'AAA', '9000999309', 'mdgafoor1@gmail.com', 'director', b'1', '2019-08-19 00:20:24', 0),
(3, 1, 2, 'test', '123456789', 'test@gmail.com', 'test', b'1', '2019-08-20 06:38:04', 3),
(4, 1, 2, 'test', '123456789', 'test2@gmail.com', 'test', b'1', '2019-08-20 06:42:30', 3),
(5, 2, 3, 'test1', '1234567223', 'test3@gmail.com', 'test33', b'1', '2019-08-20 06:44:07', 4),
(6, 2, 3, 'test1', '1234567223', 'test35@gmail.com', 'test33', b'1', '2019-08-20 06:47:46', 4),
(7, 2, 1, 'srinivas', '924755123', 'srinivas846@gmail.com', 'Co Ordinater', b'1', '2019-08-20 06:50:33', 0),
(8, 1, 3, 'rrr', '6655443322', 'rrr@gmail.com', 'user', b'1', '2019-08-20 23:24:57', 2),
(9, 1, 3, 'rrr', '6655443322', 'rrr3@gmail.com', 'user', b'1', '2019-08-20 23:25:21', 2),
(10, 1, 3, 'rrr', '6655443322', 'rrr33@gmail.com', 'user', b'1', '2019-08-20 23:28:00', 2),
(11, 1, 3, 'rrr', '6655443322', 'rrr334@gmail.com', 'user', b'1', '2019-08-20 23:30:48', 2),
(12, 1, 3, 'rrr', '6655443322', 'rrr3345@gmail.com', 'user', b'1', '2019-08-20 23:34:01', 2),
(13, 1, 3, 'rrr', '6655443322', 'rrr33451@gmail.com', 'user', b'1', '2019-08-20 23:48:54', 2),
(14, 1, 3, 'rrr', '6655443322', 'rrr334512@gmail.com', 'user', b'1', '2019-08-20 23:51:00', 2),
(15, 1, 3, 'rrr', '6655443322', 'rr4@gmail.com', 'user', b'1', '2019-08-20 23:55:08', 2),
(16, 1, 3, 'rrr', '6655443322', 'rr41@gmail.com', 'user', b'1', '2019-08-20 23:55:36', 2),
(17, 1, 3, 'rrr', '6655443322', 'rr412@gmail.com', 'user', b'1', '2019-08-21 00:26:45', 2),
(18, 0, 0, 'rrr', '6655443322', 'rr4126@gmail.com', 'user', b'1', '2019-08-21 00:49:45', 0),
(19, 0, 0, 'sai', '8899664433', 'sai@gmail.com', 'user', b'1', '2019-08-21 00:55:15', 0),
(20, 2, 3, 'sai', '8899664433', 'sai2@gmail.com', 'user', b'1', '2019-08-21 00:57:00', 3),
(21, 2, 3, 'sai21', '8899664433', 'sai21@gmail.com', 'user', b'1', '2019-08-21 00:59:34', 3),
(22, 3, 3, 'sai212', '8899664411', 'sai212@gmail.com', 'moderator', b'1', '2019-08-21 02:59:50', 3),
(23, 3, 3, 'sai212', '8899664411', 'sai2125@gmail.com', 'moderator', b'1', '2019-08-21 03:06:39', 3),
(24, 3, 3, 'sai212', '8899664411', 'sai21256@gmail.com', 'moderator', b'1', '2019-08-21 03:07:13', 3),
(25, 3, 3, 'sai212', '8899664411', 'sai31@gmail.com', 'moderator', b'1', '2019-08-21 03:15:15', 3),
(26, 3, 3, 'sai212', '8899664411', 'sai321@gmail.com', 'moderator', b'1', '2019-08-21 03:26:32', 3),
(27, 2, 3, 'sai212', '8899664411', 'sai4@gmail.com', 'moderator', b'1', '2019-08-21 03:39:17', 3),
(28, 2, 3, 'sai212', '8899664411', 'sai44@gmail.com', 'moderator', b'1', '2019-08-21 03:40:43', 3),
(29, 0, 0, '', '', '', '', b'0', '2019-08-21 04:40:17', 0),
(30, 1, 1, 'AAA', '999', 'AAA@AA.AA', '', b'0', '2019-08-21 04:42:47', 0),
(31, 1, 1, 'BBB', '999', 'BBB@BB.BB', '', b'0', '2019-08-21 04:43:21', 0),
(32, 2, 3, 'sai212', '8899664411', 'sai46@gmail.com', 'moderator', b'1', '2019-08-21 05:39:04', 3),
(33, 2, 3, 'sai212', '8899664411', 'sai467@gmail.com', 'moderator', b'1', '2019-08-21 05:59:37', 3),
(34, 2, 3, 'sai212', '8899664411', 'sai468@gmail.com', 'moderator', b'1', '2019-08-21 06:17:26', 3),
(35, 2, 3, 'sai212', '8899664411', 'sai469@gmail.com', 'moderator', b'1', '2019-08-21 06:21:48', 3);

-- --------------------------------------------------------

--
-- Table structure for table `tblreleaseeventlock`
--

CREATE TABLE `tblreleaseeventlock` (
  `ReleaseEventLockId` mediumint(9) UNSIGNED NOT NULL,
  `EventId` mediumint(9) DEFAULT NULL,
  `Reason` text DEFAULT NULL,
  `ReleasedOn` datetime DEFAULT NULL,
  `ReleasedBy` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tblreleaseeventlock`
--

INSERT INTO `tblreleaseeventlock` (`ReleaseEventLockId`, `EventId`, `Reason`, `ReleasedOn`, `ReleasedBy`) VALUES
(1, 30, '0', '2019-08-29 21:20:41', 2),
(2, 30, '0', '2019-08-29 21:24:24', 2),
(3, 30, '0', '2019-08-29 21:24:48', 2),
(4, 30, '0', '2019-08-29 21:24:51', 2),
(5, 30, '0', '2019-08-29 21:24:53', 2),
(6, 30, '0', '2019-08-29 21:25:13', 2),
(7, 30, '0', '2019-08-29 21:35:40', 2),
(8, 30, '0', '2019-08-29 21:36:02', 2),
(9, 30, '0', '2019-08-29 21:46:09', 2),
(10, 30, '0', '2019-08-29 21:46:23', 2),
(11, 30, '0', '2019-08-29 22:01:40', 2);

-- --------------------------------------------------------

--
-- Table structure for table `tbluserclients`
--

CREATE TABLE `tbluserclients` (
  `UserId` smallint(6) DEFAULT NULL,
  `ClientId` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbluserclients`
--

INSERT INTO `tbluserclients` (`UserId`, `ClientId`) VALUES
(2, 1),
(2, 2);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tblclientservices`
--
ALTER TABLE `tblclientservices`
  ADD PRIMARY KEY (`ClientServiceId`);

--
-- Indexes for table `tblevents`
--
ALTER TABLE `tblevents`
  ADD PRIMARY KEY (`EventId`),
  ADD UNIQUE KEY `EventId_UNIQUE` (`EventId`);

--
-- Indexes for table `tbleventservicedata`
--
ALTER TABLE `tbleventservicedata`
  ADD PRIMARY KEY (`EventServiceDataId`),
  ADD UNIQUE KEY `EventServiceDataId_UNIQUE` (`EventServiceDataId`);

--
-- Indexes for table `tbleventservices`
--
ALTER TABLE `tbleventservices`
  ADD PRIMARY KEY (`EventServiceId`),
  ADD UNIQUE KEY `EventServiceId_UNIQUE` (`EventServiceId`);

--
-- Indexes for table `tblmstclients`
--
ALTER TABLE `tblmstclients`
  ADD PRIMARY KEY (`ClientId`),
  ADD UNIQUE KEY `ClientId_UNIQUE` (`ClientId`);

--
-- Indexes for table `tblmsteventcategories`
--
ALTER TABLE `tblmsteventcategories`
  ADD PRIMARY KEY (`EventCategoryId`);

--
-- Indexes for table `tblmsteventstatuses`
--
ALTER TABLE `tblmsteventstatuses`
  ADD PRIMARY KEY (`EventStatusId`),
  ADD UNIQUE KEY `EventStatusId_UNIQUE` (`EventStatusId`);

--
-- Indexes for table `tblmstlogin`
--
ALTER TABLE `tblmstlogin`
  ADD PRIMARY KEY (`LoginId`),
  ADD UNIQUE KEY `LoginId_UNIQUE` (`LoginId`);

--
-- Indexes for table `tblmstroles`
--
ALTER TABLE `tblmstroles`
  ADD PRIMARY KEY (`RoleId`),
  ADD UNIQUE KEY `RoleId_UNIQUE` (`RoleId`);

--
-- Indexes for table `tblmstservices`
--
ALTER TABLE `tblmstservices`
  ADD PRIMARY KEY (`ServiceId`),
  ADD UNIQUE KEY `ServiceId_UNIQUE` (`ServiceId`);

--
-- Indexes for table `tblmstservicetypes`
--
ALTER TABLE `tblmstservicetypes`
  ADD PRIMARY KEY (`ServiceTypeId`),
  ADD UNIQUE KEY `ServiceTypeId_UNIQUE` (`ServiceTypeId`);

--
-- Indexes for table `tblmstusers`
--
ALTER TABLE `tblmstusers`
  ADD PRIMARY KEY (`UserId`),
  ADD UNIQUE KEY `UserId_UNIQUE` (`UserId`);

--
-- Indexes for table `tblreleaseeventlock`
--
ALTER TABLE `tblreleaseeventlock`
  ADD PRIMARY KEY (`ReleaseEventLockId`),
  ADD UNIQUE KEY `ReleaseEventLockId_UNIQUE` (`ReleaseEventLockId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tblclientservices`
--
ALTER TABLE `tblclientservices`
  MODIFY `ClientServiceId` mediumint(9) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tblevents`
--
ALTER TABLE `tblevents`
  MODIFY `EventId` mediumint(9) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `tbleventservicedata`
--
ALTER TABLE `tbleventservicedata`
  MODIFY `EventServiceDataId` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbleventservices`
--
ALTER TABLE `tbleventservices`
  MODIFY `EventServiceId` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2152;

--
-- AUTO_INCREMENT for table `tblmstclients`
--
ALTER TABLE `tblmstclients`
  MODIFY `ClientId` smallint(6) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tblmstlogin`
--
ALTER TABLE `tblmstlogin`
  MODIFY `LoginId` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `tblmstroles`
--
ALTER TABLE `tblmstroles`
  MODIFY `RoleId` tinyint(2) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tblmstservices`
--
ALTER TABLE `tblmstservices`
  MODIFY `ServiceId` smallint(6) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `tblmstservicetypes`
--
ALTER TABLE `tblmstservicetypes`
  MODIFY `ServiceTypeId` smallint(6) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `tblmstusers`
--
ALTER TABLE `tblmstusers`
  MODIFY `UserId` smallint(6) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `tblreleaseeventlock`
--
ALTER TABLE `tblreleaseeventlock`
  MODIFY `ReleaseEventLockId` mediumint(9) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
