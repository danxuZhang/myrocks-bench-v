source ./sql/vectordb/include/init_ivf.sql;
source ./sql/vectordb/include/ivfpq_vector_data.sql;


SELECT *, fb_vector_l2(vector1, '[3, 2]')  as dis 
FROM t1 
ORDER BY dis 
LIMIT 10;

SELECT *, fb_vector_l2(vector1, '[6, 8]')  as dis1, fb_vector_l2(vector1, '[3, 2]')  as dis2
FROM t1 
ORDER BY 0.2 * dis1 + 0.8 * dis2 
LIMIT 10;

SELECT NTOTAL, HIT, MIN_LIST_SIZE, MAX_LIST_SIZE, AVG_LIST_SIZE  FROM INFORMATION_SCHEMA.ROCKSDB_VECTOR_INDEX WHERE TABLE_NAME = 't1';

source ./sql/vectordb/include/cleanup_ivf.sql;
