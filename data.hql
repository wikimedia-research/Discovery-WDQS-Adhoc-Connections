ADD JAR hdfs:///user/bearloga/refinery-hive-xcache.jar; -- $ hdfs dfs -put ~/Code/analytics-refinery-jars/refinery-hive-xcache.jar /user/bearloga/
CREATE TEMPORARY FUNCTION get_last_server AS 'org.wikimedia.analytics.refinery.hive.GetLastServerContactedUDF';
CREATE TEMPORARY FUNCTION data_center_name AS 'org.wikimedia.analytics.refinery.hive.ServerNameToDataCenterNameUDF';
SELECT
  dt AS `timestamp`, time_firstbyte, -- Time (seconds) from when the request processing starts until the first byte is sent to the client.
  client_ip, x_forwarded_for, REGEXP_REPLACE(PARSE_URL(referer, 'HOST'), 'www.', '') AS referrer,
  REGEXP_REPLACE(user_agent, '\\t', ' ') AS user_agent, agent_type,
  CASE WHEN agent_type = 'spider' THEN 'spider'
       WHEN agent_type = 'user' AND (
         user_agent RLIKE 'https?://'
         OR INSTR(user_agent, 'www.') > 0
         OR INSTR(user_agent, 'github') > 0
         OR LOWER(user_agent) RLIKE '([a-z0-9._%-]+@[a-z0-9.-]+\.(com|us|net|org|edu|gov|io|ly|co|uk))'
       ) THEN 'spider'
       ELSE 'user'
       END AS agent_type_v2,
  x_cache, cache_status,
  hostname AS origin_hostname,
  data_center_name(hostname) AS origin_data_center,
  get_last_server(x_cache) AS terminus_hostname,
  data_center_name(get_last_server(x_cache)) AS terminus_data_center
FROM wmf.webrequest
WHERE
  webrequest_source = 'misc'
  AND year = 2016 AND month = 11 AND day = ${hiveconf:day}
  AND uri_host = 'query.wikidata.org'
  AND uri_path = '/bigdata/namespace/wdq/sparql'
  AND http_status IN('200','304');