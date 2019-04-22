/*
	Creator:	20180313@Billy
	Task:		Create database for new Fraud Sensor system - [Redmine: #91450]
	Server:		DB054
*/


USE	master;
GO

CREATE DATABASE	bodb_FraudSensor
	ON	PRIMARY (
			NAME		= N'bodb_FraudSensor'
		,	FILENAME	= N'M:\IBC_DB\bodb_FraudSensor\bodb_FraudSensor.mdf'
		,	SIZE		= 16384KB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 16384KB
		)
	,	FILEGROUP DATA	DEFAULT (
			NAME		= N'DATA'
		,	FILENAME	= N'M:\IBC_DB\bodb_FraudSensor\data_01.ndf'
		,	SIZE		= 32768KB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 32768KB
		)
	,	FILEGROUP IDX (
			NAME		= N'IDX'
		,	FILENAME	= N'M:\IBC_DB\bodb_FraudSensor\idx_01.ndf'
		,	SIZE		= 32768KB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 32768KB
		)
	,	FILEGROUP UserLog (
			NAME		= N'UserLog'
		,	FILENAME	= N'M:\IBC_DB\bodb_FraudSensor\UserLog_01.ndf'
		,	SIZE		= 32768KB
		,	MAXSIZE		= UNLIMITED
		,	FILEGROWTH	= 32768KB
		)
	LOG ON (
		NAME		= N'bodb_FraudSensor_log'
	,	FILENAME	= N'M:\IBC_DB\bodb_FraudSensor\bodb_FraudSensor_log.ldf'
	,	SIZE		= 1048576KB
	,	MAXSIZE		= 2048GB
	,	FILEGROWTH	= 131072KB
	);
GO

ALTER DATABASE bodb_FraudSensor SET COMPATIBILITY_LEVEL = 100;
GO

IF	FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') = 1
BEGIN;
	EXECUTE	bodb_FraudSensor.dbo.sp_fulltext_database @action = 'enable';
END;
GO

ALTER DATABASE bodb_FraudSensor SET ANSI_NULL_DEFAULT OFF;
ALTER DATABASE bodb_FraudSensor SET ANSI_NULLS OFF;
ALTER DATABASE bodb_FraudSensor SET ANSI_PADDING OFF;
ALTER DATABASE bodb_FraudSensor SET ANSI_WARNINGS OFF;
ALTER DATABASE bodb_FraudSensor SET ARITHABORT OFF;
ALTER DATABASE bodb_FraudSensor SET AUTO_CLOSE OFF;
ALTER DATABASE bodb_FraudSensor SET AUTO_SHRINK OFF;
ALTER DATABASE bodb_FraudSensor SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE bodb_FraudSensor SET CURSOR_CLOSE_ON_COMMIT OFF;
ALTER DATABASE bodb_FraudSensor SET CURSOR_DEFAULT  GLOBAL;
ALTER DATABASE bodb_FraudSensor SET CONCAT_NULL_YIELDS_NULL OFF;
ALTER DATABASE bodb_FraudSensor SET NUMERIC_ROUNDABORT OFF;
ALTER DATABASE bodb_FraudSensor SET QUOTED_IDENTIFIER OFF;
ALTER DATABASE bodb_FraudSensor SET RECURSIVE_TRIGGERS OFF;
ALTER DATABASE bodb_FraudSensor SET  DISABLE_BROKER;
ALTER DATABASE bodb_FraudSensor SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
ALTER DATABASE bodb_FraudSensor SET DATE_CORRELATION_OPTIMIZATION OFF;
ALTER DATABASE bodb_FraudSensor SET TRUSTWORTHY OFF;
ALTER DATABASE bodb_FraudSensor SET ALLOW_SNAPSHOT_ISOLATION OFF;
ALTER DATABASE bodb_FraudSensor SET PARAMETERIZATION SIMPLE;
ALTER DATABASE bodb_FraudSensor SET READ_COMMITTED_SNAPSHOT OFF;
ALTER DATABASE bodb_FraudSensor SET HONOR_BROKER_PRIORITY OFF;
ALTER DATABASE bodb_FraudSensor SET RECOVERY SIMPLE;
ALTER DATABASE bodb_FraudSensor SET MULTI_USER;
ALTER DATABASE bodb_FraudSensor SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE bodb_FraudSensor SET DB_CHAINING OFF 
GO

ALTER DATABASE bodb_FraudSensor SET READ_WRITE;
GO

CREATE USER vnBilly FOR LOGIN vnBilly WITH DEFAULT_SCHEMA = dbo;
EXECUTE sys.sp_addrolemember @rolename = N'db_owner', @membername = N'vnBilly';
GRANT CONNECT TO vnBilly;
GO

CREATE USER vnteam FOR LOGIN vnteam WITH DEFAULT_SCHEMA = dbo;
EXECUTE sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'vnteam';
GRANT CONNECT TO vnteam;
GO

CREATE USER vnDBA FOR LOGIN vnDBA WITH DEFAULT_SCHEMA = dbo;
EXECUTE sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'vnDBA';
GRANT CONNECT TO vnDBA;
GO

CREATE USER SqlLink FOR LOGIN SqlLink WITH DEFAULT_SCHEMA = dbo;
EXECUTE sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'SqlLink';
GRANT CONNECT TO SqlLink;
GO

CREATE USER bodbSPUNet FOR LOGIN bodbSPUNet WITH DEFAULT_SCHEMA = dbo;
EXECUTE sys.sp_addrolemember @rolename = N'db_datareader', @membername = N'bodbSPUNet';
GRANT CONNECT TO bodbSPUNet;
GO

