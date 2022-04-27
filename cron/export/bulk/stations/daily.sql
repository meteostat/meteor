set statement max_statement_time = 300 for
SELECT `date`,
       cast(substring_index(group_concat(`tavg` ORDER BY `tavg_flag` asc), ",", 1) as decimal(3, 1)) as `tavg`,
       cast(substring_index(group_concat(`tmin` ORDER BY `tmin_flag` asc), ",", 1) as decimal(3, 1)) as `tmin`,
       cast(substring_index(group_concat(`tmax` ORDER BY `tmax_flag` asc), ",", 1) as decimal(3, 1)) as `tmax`,
       cast(substring_index(group_concat(`prcp` ORDER BY `prcp_flag` asc), ",", 1) as decimal(5, 1)) as `prcp`,
       cast(substring_index(group_concat(`snow` ORDER BY `snow_flag` asc), ",", 1) as int) as `snow`,
       cast(substring_index(group_concat(`wdir` ORDER BY `wdir_flag` asc), ",", 1) as int) as `wdir`,
       cast(substring_index(group_concat(`wspd` ORDER BY `wspd_flag` asc), ",", 1) as decimal(4, 1)) as `wspd`,
       cast(substring_index(group_concat(`wpgt` ORDER BY `wpgt_flag` asc), ",", 1) as decimal(4, 1)) as `wpgt`,
       cast(substring_index(group_concat(`pres` ORDER BY `pres_flag` asc), ",", 1) as decimal(5, 1)) as `pres`,
       cast(substring_index(group_concat(`tsun` ORDER BY `tsun_flag` asc), ",", 1) as int) as `tsun`,
       if(count(`tavg`) = 0,
          null,
          substring_index(group_concat(`tavg_flag`), ',', 1)) as `tavg_flag`,
       if(count(`tmin`) = 0,
          null,
          substring_index(group_concat(`tmin_flag`), ',', 1)) as `tmin_flag`,
       if(count(`tmax`) = 0,
          null,
          substring_index(group_concat(`tmax_flag`), ',', 1)) as `tmax_flag`,
       if(count(`prcp`) = 0,
          null,
          substring_index(group_concat(`prcp_flag`), ',', 1)) as `prcp_flag`,
       if(count(`snow`) = 0,
          null,
          substring_index(group_concat(`snow_flag`), ',', 1)) as `snow_flag`,
       if(count(`wdir`) = 0,
          null,
          substring_index(group_concat(`wdir_flag`), ',', 1)) as `wdir_flag`,
       if(count(`wspd`) = 0,
          null,
          substring_index(group_concat(`wspd_flag`), ',', 1)) as `wspd_flag`,
       if(count(`wpgt`) = 0,
          null,
          substring_index(group_concat(`wpgt_flag`), ',', 1)) as `wpgt_flag`,
       if(count(`pres`) = 0,
          null,
          substring_index(group_concat(`pres_flag`), ',', 1)) as `pres_flag`,
       if(count(`tsun`) = 0,
          null,
          substring_index(group_concat(`tsun_flag`), ',', 1)) as `tsun_flag`
FROM   ((SELECT `date`,
                `tavg`,
                `tmin`,
                `tmax`,
                `prcp`,
                `snow`,
                null as `wdir`,
                `wspd`,
                `wpgt`,
                `pres`,
                `tsun`,
                if(`tavg`, 'A', null) as `tavg_flag`,
                if(`tmin`, 'A', null) as `tmin_flag`,
                if(`tmax`, 'A', null) as `tmax_flag`,
                if(`prcp`, 'A', null) as `prcp_flag`,
                if(`snow`, 'A', null) as `snow_flag`,
                null as `wdir_flag`,
                if(`wspd`, 'A', null) as `wspd_flag`,
                if(`wpgt`, 'A', null) as `wpgt_flag`,
                if(`pres`, 'A', null) as `pres_flag`,
                if(`tsun`, 'A', null) as `tsun_flag`
         FROM   `daily_national`
         WHERE  `station` = :station)
UNION all (SELECT `date`,
                  `tavg`,
                  `tmin`,
                  `tmax`,
                  `prcp`,
                  `snow`,
                  `wdir`,
                  `wspd`,
                  `wpgt`,
                  null as `pres`,
                  `tsun`,
                  if(`tavg`, 'B', null) as `tavg_flag`,
                  if(`tmin`, 'B', null) as `tmin_flag`,
                  if(`tmax`, 'B', null) as `tmax_flag`,
                  if(`prcp`, 'B', null) as `prcp_flag`,
                  if(`snow`, 'B', null) as `snow_flag`,
                  if(`wdir`, 'B', null) as `wdir_flag`,
                  if(`wspd`, 'B', null) as `wspd_flag`,
                  if(`wpgt`, 'B', null) as `wpgt_flag`,
                  null as `pres_flag`,
                  if(`tsun`, 'B', null) as `tsun_flag`
           FROM   `daily_ghcn`
           WHERE  `station` = :station)
UNION all (SELECT date(`time`) as `date`,
                  if(count(`temp`) < 24, null, round(avg(`temp`), 1)) as `tavg`,
                  if(count(`temp`) < 24, null, min(`temp`)) as `tmin`,
                  if(count(`temp`) < 24, null, max(`temp`)) as `tmax`,
                  if(count(`prcp`) < 24, null, round(sum(`prcp`), 1)) as `prcp`,
                  if(count(`snow`) < 24, null, max(`snow`)) as `snow`,
                  if(count(`wdir`) < 24,
                     null,
                     round(degavg(sum(sin(radians(`wdir`))), sum(cos(radians(`wdir`)))), 1)) as `wdir`,
                  if(count(`wspd`) < 24, null, round(avg(`wspd`), 1)) as `wspd`,
                  if(count(`wpgt`) < 24, null, max(`wpgt`)) as `wpgt`,
                  if(count(`pres`) < 24, null, round(avg(`pres`), 1)) as `pres`,
                  null as `tsun`,
                  group_concat(distinct `temp_flag` separator '') as `tavg_flag`,
                  group_concat(distinct `temp_flag` separator '') as `tmin_flag`,
                  group_concat(distinct `temp_flag` separator '') as `tmax_flag`,
                  group_concat(distinct `prcp_flag` separator '') as `prcp_flag`,
                  group_concat(distinct `snow_flag` separator '') as `snow_flag`,
                  group_concat(distinct `wdir_flag` separator '') as `wdir_flag`,
                  group_concat(distinct `wspd_flag` separator '') as `wspd_flag`,
                  group_concat(distinct `wpgt_flag` separator '') as `wpgt_flag`,
                  group_concat(distinct `pres_flag` separator '') as `pres_flag`,
                  group_concat(distinct `tsun_flag` separator '') as `tsun_flag`
           FROM   (SELECT convert_tz(min(`time`), 'UTC', :timezone) as `time`,
                          cast(substring_index(group_concat(`temp` ORDER BY `flag` asc), ',', 1) as decimal(3, 1)) as `temp`,
                          cast(substring_index(group_concat(`prcp` ORDER BY `flag` asc), ',', 1) as decimal(4, 1)) as `prcp`,
                          cast(substring_index(group_concat(`snow` ORDER BY `flag` asc), ',', 1) as int) as `snow`,
                          cast(substring_index(group_concat(`wdir` ORDER BY `flag` asc), ',', 1) as int) as `wdir`,
                          cast(substring_index(group_concat(`wspd` ORDER BY `flag` asc), ',', 1) as decimal(4, 1)) as `wspd`,
                          cast(substring_index(group_concat(`wpgt` ORDER BY `flag` asc), ',', 1) as decimal(4, 1)) as `wpgt`,
                          cast(substring_index(group_concat(`pres` ORDER BY `flag` asc), ',', 1) as decimal(5, 1)) as `pres`,
                          cast(substring_index(group_concat(`tsun` ORDER BY `flag` asc), ',', 1) as int) as `tsun`,
                          substr(substring_index(group_concat(concat(`temp`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `temp_flag`,
                          substr(substring_index(group_concat(concat(`prcp`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `prcp_flag`,
                          substr(substring_index(group_concat(concat(`snow`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `snow_flag`,
                          substr(substring_index(group_concat(concat(`wdir`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `wdir_flag`,
                          substr(substring_index(group_concat(concat(`wspd`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `wspd_flag`,
                          substr(substring_index(group_concat(concat(`wpgt`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `wpgt_flag`,
                          substr(substring_index(group_concat(concat(`pres`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `pres_flag`,
                          substr(substring_index(group_concat(concat(`tsun`, ':', `flag`) ORDER BY `flag` asc), ',', 1),
                                 -1,
                                 1) as `tsun_flag`
                   FROM   ((SELECT `time`,
                                   `temp`,
                                   `prcp`,
                                   null as `snow`,
                                   `wdir`,
                                   `wspd`,
                                   null as `wpgt`,
                                   `pres`,
                                   `tsun`,
                                   'C' as `flag`
                            FROM   `hourly_national`
                            WHERE  `station` = :station)
                   UNION all (SELECT `time`,
                                     `temp`,
                                     `prcp`,
                                     null as `snow`,
                                     `wdir`,
                                     `wspd`,
                                     null as `wpgt`,
                                     `pres`,
                                     null as `tsun`,
                                     'D' as `flag`
                              FROM   `hourly_isd`
                              WHERE  `station` = :station)
                   UNION all (SELECT `time`,
                                     `temp`,
                                     `prcp`,
                                     `snow`,
                                     `wdir`,
                                     `wspd`,
                                     `wpgt`,
                                     `pres`,
                                     `tsun`,
                                     'E' as `flag`
                              FROM   `hourly_synop`
                              WHERE  `station` = :station)
                   UNION all (SELECT `time`,
                                     `temp`,
                                     null as `prcp`,
                                     null as `snow`,
                                     `wdir`,
                                     `wspd`,
                                     null as `wpgt`,
                                     `pres`,
                                     null as `tsun`,
                                     'F' as `flag`
                              FROM   `hourly_metar`
                              WHERE  `station` = :station)
                   UNION all (SELECT `time`,
                                     `temp`,
                                     `prcp`,
                                     null as `snow`,
                                     `wdir`,
                                     `wspd`,
                                     `wpgt`,
                                     `pres`,
                                     null as `tsun`,
                                     'G' as `flag`
                              FROM   `hourly_model`
                              WHERE  `station` = :station)) as `hourly_derived`
                   WHERE  `time` <= date_add(now(), interval 10 day)
                   GROUP BY date_format(`time`, '%Y %m %d %H')
                   ORDER BY `time`) as `hourly_derived`
           GROUP BY `date`)) as `daily_derived`
WHERE  (`tavg` is not null
    or `tmin` is not null
    or `tmax` is not null
    or `prcp` is not null)
   and `date` <= date_add(current_date(), interval 10 day)
GROUP BY `date`
ORDER BY `date`
