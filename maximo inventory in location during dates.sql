-- requested to find any items in bin 231F between 2023-08-02 and 2023-08-04

use 'maximo database'

Select ib.location as [Location], ib.itemnum as [Item Number], i.description as [Description], ib.lotnum as [Lot Number], ib.binnum as [Bin Number], ib.curbal [Balance], ib.eaudittimestamp as [Balance Date]

From a_invbalances ib
	Join item i on i.itemnum = ib.itemnum

where ib.binnum like '%231F%'
  and ib.eaudittimestamp <= '2023-08-05'
  -- remove any records that might have ever transferred to similar locations/bins or out of 231F before the dates in question
  and not exists(select top 1 * from matrectrans where fromstoreloc = ib.location and itemnum = ib.itemnum and fromlot = ib.lotnum and frombin = ib.binnum and (tobin not like '%231F%' or (tobin like '%231F%' and tostoreloc = fromstoreloc) or (tobin like '%231F%' and tostoreloc != fromstoreloc)) and transdate < '2023-08-02')
  -- grab the most recent record for the locations/item/lot/bin combo based on invbalancesid
  and ib.eaudittransid = (select top 1 eaudittransid from a_invbalances where invbalancesid = ib.invbalancesid
																	and eaudittimestamp <= '2023-08-05'
																	order by eaudittimestamp desc)
  -- remove any records that had been zeroed out before the earliest date in question
  and ib.eaudittransid not in (select top 1 eaudittransid from a_invbalances where invbalancesid = ib.invbalancesid and eaudittimestamp < '2023-08-02' and curbal = 0 order by eaudittimestamp desc)

order by ib.location, ib.itemnum, ib.lotnum, ib.binnum
