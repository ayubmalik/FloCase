SELECT 
ba.[Matter_Uno],
ba.[Bill_Tran_uno],
b.[Bill_Date],
ba.[Billp_uno],
bp.[FEES_AR]+bp.[HARD_AR]+bp.[SOFT_AR]+bp.[TAX_AR]+bp.[OAFEE_AR]+bp.[OADISB_AR]+bp.[RETAINER_AR]+bp.[PREMDISC_AR]+bp.[INTEREST_AR]				as	"Tot_AR"
INTO
#LVBTMP1
FROM 
[blt_bill_amt]			ba 
inner join 
	[blt_bill]			b 
	on ba.bill_tran_uno = b.tran_uno
inner join
	[blt_billp]			bp
	on ba.billp_uno = bp.billp_uno
WHERE 
ba.[tran_type] In ('BL','BLX','CN','CNX') 
and b.bill_num <> 0 
and ba.[payr_client_uno] In (select client_uno from hbm_client where clnt_cat_code In (select  clnt_cat_code from hbl_clnt_cat where group_code = 'LV'))
and ba.[Matter_uno] In (select matter_uno from hbm_matter where status_code In('CLOSE','FINAL'))


SELECT
t.[Matter_Uno],
t.[Bill_Date],
t.[Billp_uno],
t.[Tot_AR],
CASE
	WHEN t.[Tot_AR]>0
	THEN DATEADD(yy,10,getdate())
	ELSE COALESCE(paydate.[Lst_Bill_Paid],t.[Bill_Date])
END			as	"FBill_Paid_Date"

INTO 
#LVBTMP2

FROM
#LVBTMP1			t

inner join
	(SELECT Matter_uno, MAX(Bill_Date) as "Lst_Bill"
	FROM #LVBTMP1 GROUP BY Matter_Uno
	)				tsum
	on	t.matter_uno = tsum.matter_uno
	and	t.bill_date = tsum.lst_bill
	
left outer join
	(SELECT Billp_uno, MAX(TRAN_DATE) as "Lst_Bill_Paid"
	FROM [blt_bill_amt] 
	WHERE tran_type In ('RA','CR') GROUP BY Billp_uno
	)				paydate
	on t.billp_uno = paydate.billp_uno




--SELECT 
--[Matter_uno],
--MAX([Bill_Date])		as	"Final_Bill_Date"
--FROM
--#LVBTMP2
--GROUP BY
--matter_uno

SELECT 
[Matter_uno],
MAX([FBill_Paid_Date])		as	"Date_of_Last_Action"
FROM
#LVBTMP2
GROUP BY
matter_uno
HAVING
MAX([FBill_Paid_Date])<=getdate()



DROP TABLE #LVBTMP1
DROP TABLE #LVBTMP2

