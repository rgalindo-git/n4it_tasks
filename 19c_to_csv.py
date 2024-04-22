import cx_Oracle
import pandas as pd
import time

start_time = time.process_time() 
conn = cx_Oracle.connect('hr/hr@localhost/orclpdb')

for num in range(101,151):
    df = pd.read_sql_query('SELECT item, loc, dept, unit_cost,stock_on_hand, uc_soh FROM item_loc_soh_total WHERE loc = {}'.format(num) , conn)
    df.to_csv('location_{}.csv'.format(num), index=False)

conn.close()     

print((time.process_time() - start_time) , " seconds")