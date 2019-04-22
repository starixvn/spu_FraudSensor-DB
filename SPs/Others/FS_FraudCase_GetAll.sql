ALTER PROCEDURE [dbo].[FS_FraudCase_GetAll]
		@IsInternal		BIT = NULL
	,	@IsActive		BIT	= NULL	
	,	@Environment	INT	= 3
AS
/*
	Created: 20180306@Aaron
	Task : Get all fraud cases
	DB: bodb_FraudSensor

	Original:

	Revisions: 
	 + 20180414@Casey: Add parameters @IsInternal, @IsActive, @IsTest
	 + 20180605@CaseyHuynh: Update @IsInternal Default Value is NULL
	 + 20190326@Long.Luu:	Manage for query fraud cases on variety environments [Redmine ID: #109592]

	Param's Explanation (filtered by):
	 + @IsInternal: NULL-All, 0-NotInternal, 1-Internal
	 + @IsAcitve: NULL-All, 0-Inactive, 1-Active
	 + @Environment: 3-Production get Istest=0 ELSE All	
*/
BEGIN
	SET NOCOUNT ON;	
    SELECT	fc.FraudCaseId
		,	fc.FraudCaseName
		,	fc.FraudCaseDesc
		,	fc.FraudCaseInterval
		,	fc.IsActive
		,	fc.IsTest
	FROM	dbo.FraudCase fc WITH (NOLOCK)
	WHERE	fc.IsInternal = ISNULL(@IsInternal, fc.IsInternal)
			AND fc.IsActive = ISNULL(@IsActive, fc.IsActive)
			AND fc.IsTest = (	CASE WHEN @Environment = 3 THEN 0 
									WHEN @Environment = 2 THEN 1
									ELSE fc.IsTest 
								END)
	ORDER BY FraudCaseId;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
