SELECT date(min(`time`)) as `date`,
       date_format(min(`time`), '%H') as `hour`,
        `temp`,
        `rhum`,
        `wdir`,
        `wspd`,
        `pres`,
        `coco`
FROM   `hourly_metar`
WHERE  `station` = :station
GROUP BY date_format(`time`, '%Y %m %d %H')
ORDER BY `time`