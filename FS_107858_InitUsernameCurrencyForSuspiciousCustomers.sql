/*
Creator: 20190219@LongLuu
Task:  Init Username and Currency for SuspiciousCustomers table [Redmine ID: #107858]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

UPDATE sc WITH(ROWLOCK, UPDLOCK)
SET		sc.Username		= c.username
	,	sc.CurrencyId	= c.currency
	,	sc.CurrencyName = e.currency
FROM dbo.SuspiciousCustomer sc
	INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON sc.Custid = c.custid
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON c.currency = e.exchangeid;