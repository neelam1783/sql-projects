use ankitbansal_database;
select count(*) from olympics_history_noc_regions;
/* 1.How many olympics games have been held? */
desc olympics_history;

select count(distinct games) as total_olympics_held from olympics_history;
/*2.List down all Olympics games held so far. */

select distinct year,season,city  from olympics_history order by year;

/* 3. Mention the total no of nations who participated in each olympics game? */

select o.games,count( distinct r.noc) as total_countires_participated 
from olympics_history o
inner join  
olympics_history_noc_regions r 
on r.noc = o.noc 
group by 1 
order by o.games;

/* 4. Which year saw the highest and lowest no of countries participating in olympics */

with cte as (
select o.games,count( distinct r.noc) as total_countires_participated 
from olympics_history o
inner join  
olympics_history_noc_regions r 
on r.noc = o.noc 
group by 1 
order by o.games )
select distinct 
concat(first_value(cte.games) over(order by cte.total_countires_participated desc ), '-',
first_value(cte.total_countires_participated) over(order by cte.total_countires_participated desc ) ) as heighest_participation,

concat(first_value(cte.games) over(order by cte.total_countires_participated ), '-',
first_value(cte.total_countires_participated) over(order by cte.total_countires_participated ) ) as lowest_participation
 from cte
 
 
 /* 5. Which nation has participated in all of the olympic games */;
with cte as( select o.games,r.region as country
from olympics_history o
inner join  
olympics_history_noc_regions r 
on r.noc = o.noc 
group by 1 ,2
),
countires_participated as(select country,count(1) as total_participation from cte group by 1),
total_participation as ( select count(distinct games) as total_games from olympics_history)

select countires_participated.* 
from countires_participated join total_participation 
on  countires_participated.total_participation = total_participation.total_games



     

/*6.Identify the sport which was played in all summer olympics.*/;

with cte as (
select sport ,count(distinct games)as games_played 
from olympics_history 
where season ='Summer' group by 1 order by 1),
cte2 as( select count(distinct games) as total from olympics_history  where season ='Summer')

select cte.*,cte2.* from cte join cte2 on cte2.total = cte.games_played


/* 7. Which Sports were just played only once in the olympics.*/;

with cte as 
(select distinct games,sport from olympics_history ),
tot as( select sport,count(games) as total_played from cte group by 1 )
select tot.*,cte.games  from tot join cte on cte.sport=tot.sport where tot.total_played =1 order by sport;

/* 8. Fetch the total no of sports played in each olympic games. */

select games,count(distinct sport) as total_sprots_played from olympics_history group by games order by total_sprots_played desc;

/* 9. Fetch oldest athletes to win a gold medal */ 

with cte as (select *,(case when age = 'NA' then 0 else age end ) as new_age from olympics_history where medal='Gold')  

select * from (select name,new_age,team,games,city,sport,event,medal,
dense_rank() over(order by new_age desc) rn from cte) a where a.rn=1

/*10. Fetch the top 5 athletes who have won the most gold medals.*/;
select  name,team, total_medal_won from (select name,team,count(medal) as total_medal_won,dense_rank() over(order by count(medal) desc) as rnk from olympics_history 
where medal='Gold' 
group by 1,2 ) a where a.rnk <=5;

/*11. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).*/
with cte as(
select name,team,count(medal) as total_medal_won ,dense_rank() over(order by count(medal) desc) rnk 
from olympics_history 
where medal in ('Gold','Silver','Bronze')  
group by 1,2 )
select name,team,total_medal_won from cte where rnk <=5 

/* 12.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.*/;
with cte as (
select nr.region, count(medal) as total_medals,dense_rank() over(order by count(medal) desc) rnk
            from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal in ('Gold','Silver','Bronze')  
            group by nr.region)


select cte.region,total_medals from cte where rnk<=5;

/*13.List down total gold, silver and bronze medals won by each country.*/;

with cte  as(select nr.region ,sum(case when medal = 'Gold' then 1 else 0 end) as Gold_Medal
,sum(case when medal = 'Silver' then 1 else 0 end )as Silver_Medal,
sum(case when medal = 'Bronze' then 1 else 0 end )as Bronze_Medal

from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            
            group by nr.region )
		
select * from 
(select region,Gold_Medal,Silver_Medal, Bronze_Medal, (Gold_Medal + Silver_Medal+ Bronze_Medal)as total_medal 
from cte 
order by total_medal desc)a

/*14. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.*/;
select games, nr.region ,sum(case when medal = 'Gold' then 1 else 0 end) as Gold_Medal
,sum(case when medal = 'Silver' then 1 else 0 end )as Silver_Medal,
sum(case when medal = 'Bronze' then 1 else 0 end )as Bronze_Medal

from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            
            group by 1,2 order by 1,2

/*15.  Identify which country won the most gold, most silver and most bronze medals in each olympic games*/;
with cte as(select games, nr.region ,sum(case when medal = 'Gold' then 1 else 0 end) as Gold_Medal
,sum(case when medal = 'Silver' then 1 else 0 end )as Silver_Medal,
sum(case when medal = 'Bronze' then 1 else 0 end )as Bronze_Medal

from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            
            group by 1,2 order by 1,2)
     
     select  distinct games,
    concat(first_value(cte.region) over(partition by games order by Gold_Medal desc),'-' ,
     first_value(Gold_medal) over(partition by games order by Gold_Medal desc)) as Most_won_Gold,
     concat(first_value(cte.region) over(partition by games order by Silver_Medal desc),'-' ,
     first_value(Silver_medal) over(partition by games order by Silver_Medal desc)) as Most_won_silver,
     concat(first_value(cte.region) over(partition by games order by Bronze_Medal desc),'-' ,
     first_value(Bronze_medal) over(partition by games order by Bronze_Medal desc)) as Most_won_bronze
     
     from cte ;
     
     
/*16.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.*/;

with cte as (select distinct oh.games,nr.region,count(medal) as medal_won,
sum(case when medal ='Gold' then 1 else 0 end) as gold_won,
sum(case when medal ='Silver' then 1 else 0 end) as Silver_won,
sum(case when medal ='Bronze' then 1 else 0 end) as Bronze_won
 from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <>'NA'
            
            group by 1,2 order by 1,2)
	select distinct games, 
    concat(first_value(region) over(partition by games order by medal_won desc),'-',
    first_value(medal_won) over(partition by games order by medal_won desc)) as Max_medal_won,
    
     concat(first_value(region) over(partition by games order by gold_won desc),'-',
    first_value(gold_won) over(partition by games order by gold_won desc)) as Max_gold_won,
    
      concat(first_value(region) over(partition by games order by gold_won desc),'-',
    first_value(silver_won) over(partition by games order by silver_won desc)) as Max_silver_won,
    
     concat(first_value(region) over(partition by games order by bronze_won desc),'-',
    first_value(bronze_won) over(partition by games order by bronze_won desc)) as Max_bronze_won
    
    
    from cte ;

/*17. Which countries have never won gold medal but have won silver/bronze medals?*/

with cte as(select nr.region,
sum(case when medal ='Gold' then 1 else 0 end) as gold_won,
sum(case when medal ='Silver' then 1 else 0 end) as Silver_won,
sum(case when medal ='Bronze' then 1 else 0 end) as Bronze_won
 from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <>'NA' group by 1 order by 1

) select * from cte where gold_won=0;


/* 18.In which Sport/event, India has won highest medals.*/

select sport,medal_won from (select  oh.sport,count(medal) as medal_won,dense_rank() over(order by count(medal) desc) rnk
from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <>'NA' and nr.region='India'
            
            group by 1 ) a where a.rnk=1
/* 19.In which Sport/event, India has won highest medals.*/   ; 
        
  select  oh.team,oh.sport,oh.games,count(medal) as medal_won
from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <>'NA' and nr.region='India' and oh.sport='Hockey'
            
            group by 1,2,3 order by medal_won desc      
            