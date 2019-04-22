CREATE PROCEDURE [dbo].[FS_SuspiciousCustomer_FraudCases_Get]
		@CustId	INT
	,	@Environment		INT = 3
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Get Suspicous Customer Details_FraudCasesVerify
	DB: bodb_FraudSensor
	Original:

	Revisions:
			- 20181002@JohnNgo: Check @Environment for Fraudcase
			- 20190114@John: Exclude Internal Fraud on Suspicious Customer report [Redmine ID:#107858]
	
	Param's Explanation:    
			+ @Environment: 3-Production get Istest=0 ELSE All (Clone from [FS_FraudCase_GetAll])  
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @IsInternal BIT = 0;

	SELECT	[FraudCaseId]		=	fs.FraudCaseId
		,	[FraudCaseName]		=	fs.FraudCaseName
		,	[Violations]		=	fs.Vilolations
		,	[Verified]			=	fs.Verified
		,	[Unverified]		=	fs.Vilolations - fs.Verified
		,	[LastVerifiedDate]	=	fs.LastVerifiedDate
		,	[LastVerifiedBy]	=	(SELECT TOP(1) ct.username 
									FROM bodb02.dbo.Customer AS ct WITH(NOLOCK) 
										INNER JOIN dbo.SuspiciousInfo AS su WITH(NOLOCK) ON su.VerifiedBy = ct.custid
									WHERE su.VerifiedDate=fs.LastVerifiedDate
											AND su.FraudCaseId = fs.FraudCaseId)
	FROM (
			SELECT	[FraudCaseId]		=	si.FraudCaseId
				,	[FraudCaseName]		=	(SELECT TOP(1) fc.FraudCaseName FROM dbo.FraudCase AS fc WITH(NOLOCK) WHERE fc.FraudCaseId = si.FraudCaseId AND fc.IsInternal = @IsInternal)
				,	[Vilolations]		=	SUM(si.ViolationCounter)
				,	[Verified]			=	SUM(CASE WHEN si.IsVerified = '1' THEN ViolationCounter ELSE 0 END) 
				,	[LastVerifiedDate]	=	MAX(si.VerifiedDate)
			FROM dbo.SuspiciousInfo AS si WITH(NOLOCK)
			WHERE CustId = @CustId
			GROUP BY si.FraudCaseId) AS fs
	INNER JOIN dbo.FraudCase c WITH (NOLOCK) ON c.FraudCaseId = fs.FraudCaseId
	WHERE c.IsTest = (CASE WHEN @Environment = 3 THEN 0 ELSE c.IsTest END) AND c.IsInternal = @IsInternal
	ORDER BY fs.FraudCaseName Asc;

END;

GO
/*<info serverAlias="DBSPU-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/