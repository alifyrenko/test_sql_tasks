--1. Create function

CREATE FUNCTION fnGetOrdersAmount
(
    @StartDate DATETIME,
    @EndDate DATETIME
)
RETURNS INT
AS
BEGIN
    DECLARE @ordersAmount INT;

    SELECT @ordersAmount = COUNT(1)
    FROM [dbo].[tbl_order$]
    WHERE order_time
    BETWEEN @StartDate AND @EndDate;

    RETURN @ordersAmount;
END;


2. Create proc								
CREATE PROC spGetOrdersVsClicksAgregatedInfo (@click_slot_amount INT)								
AS								
BEGIN								
								
    DECLARE @last_number INT;								
    DECLARE @last_date DATETIME;								
	--DECLARE @click_slot_amount int = 10;							
								
    SELECT @last_number = COUNT(1)								
    FROM [dbo].[tbl_click$];								
								
    SELECT @last_date = MAX(click_time)								
    FROM [dbo].[tbl_click$];								
								
    SELECT click_time,								
           (ROW_NUMBER() OVER (ORDER BY click_time)) - 1 AS rn								
    INTO #tbl_click								
    FROM [dbo].[tbl_click$];								
    ------------------------------------------------------------------------------------------------								
								
	SELECT							
           click_time,								
           LEAD(click_time, @click_slot_amount, @last_date) OVER (ORDER BY click_time) AS next_click_time,								
           rn,								
           LEAD(rn, @click_slot_amount, @last_number) OVER (ORDER BY rn) AS next_rn,								
           CASE								
               WHEN (rn % @click_slot_amount) = 0								
                    AND rn <> 1 THEN 1								
               ELSE	0								
           END AS smth								
    INTO #tbl_click_temp								
    FROM #tbl_click								
    ORDER BY click_time;								
    ------------------------------------------------------------------------------------------------								
								
    SELECT click_time,								
           next_click_time,								
           SUM(next_rn - rn) amount								
    INTO #tbl_click_final								
    FROM #tbl_click_temp								
    WHERE smth = 1								
    GROUP BY click_time,								
             next_click_time								
    ORDER BY 2 DESC;								
    ------------------------------------------------------------------------------------------------								
								
    SELECT a.*,								
           dbo.fnGetOrdersAmount(click_time, next_click_time) AS ordersAmount								
    FROM #tbl_click_final a								
    ORDER BY 1;								
								
------------------------------------------------------------------------------------------------								
END;								


--3. Exec proc with custom clickslot
EXEC dbo.spGetOrdersVsClicksAgregatedInfo @click_slot_amount = 10
