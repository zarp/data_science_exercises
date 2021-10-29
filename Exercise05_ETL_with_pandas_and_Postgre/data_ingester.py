import os, sys
import psycopg2
from pgspecial.main import PGSpecial
import pandas as pd

def update_dataset(dsn_str,
                   input_data_folder = "dataset",
                   verbose = True,
                   db_from_clean_state = False,
                   temp_file_folder_loc = "/tmp"):

     temp_folder_name = os.path.join(temp_file_folder_loc, "temp_exercise") 
     if not os.path.isdir(temp_folder_name): os.mkdir(temp_folder_name)
     temp_log_path = os.path.join(temp_folder_name, "ingested_files.txt")
     temp_combined_csv_path = os.path.join(temp_folder_name, "btc_trades_combined.csv")
     
     conn = None
     try:
          conn = psycopg2.connect(dsn_str)
          conn.autocommit = False 
          cur = conn.cursor()

          if db_from_clean_state:
               cur.execute("DROP SCHEMA interview CASCADE;")
               cur.execute("CREATE SCHEMA interview;")
               # We will keep a separate table containing the names of ingested files to speed things up
               # Strictly speaking, it's not necessary - each row in interview.btc will contain source file name column, so we could get it with SELECT DISTINCT
               cur.execute("""
                        CREATE TABLE interview.ingested_files 
                        (
                         fname varchar PRIMARY KEY
                        );
                         """)
               cur.execute("""
                        CREATE TABLE interview.btc 
                        (
                        DateTime timestamp PRIMARY KEY
                        , Open numeric
                        , High numeric
                        , Low numeric
                        , Close numeric
                        , Volume_BTC numeric
                        , Volume_Currency numeric
                        , Weighted_Price numeric
                        , source varchar REFERENCES interview.ingested_files (fname)
                        );
                         """)
               if verbose: print('Schema & table created from scratch')
               ingested_files = []
               
          else:
               cur.execute("SELECT * FROM interview.ingested_files")
               ingested_files = cur.fetchall()
               ingested_files = list(list(zip(*ingested_files))[0])
               if verbose: print('Number of ingested files before the update = ', len(ingested_files))


          if verbose:
               if (len(ingested_files) > 0) and not db_from_clean_state:
                    print('Ingested file log detected. Executing incremental update')
               else:
                    print('No log was detected or db_from_clean_state was set to True. Creating new log and combined dataset from scratch')

          file_list = [fname for fname in sorted(os.listdir(input_data_folder)) if fname[-4:] == '.csv']

          if verbose: print(f"Found {len(file_list)} files (either old or new)")
          file_list = [fname for fname in file_list if fname not in ingested_files] #leaving only files to be ingested (incremental update)
          if verbose: print(f"Found {len(file_list)} new files")


          if len(file_list) > 0:
               input_schema = {"Time": str,
                        "Open" : float,
                        "High" : float,
                        "Low" : float,
                        "Close" : float,
                        "Volume_(BTC)" : float,
                        "Volume_(Currency)" : float,
                        "Weighted_Price" : float}

               daily_data = [pd.read_csv(os.path.join(input_data_folder, fname), dtype = input_schema).
                             assign(source = fname) for fname in file_list] 


               main_df = pd.concat(daily_data, axis = 0, ignore_index = True) #main_df contains only new (incremental) data
               main_df['Time'] = main_df['source'].apply(lambda x: x.replace("btcusd-","").split(".")[0])  + " " + main_df['Time'] 
               main_df.rename(columns = {"Time" : "DateTime", 'Volume_(BTC)' : 'Volume_BTC', 'Volume_(Currency)' : 'Volume_Currency'}, inplace = True)
               
               with open(temp_log_path, 'w', encoding='utf-8') as fname:
                   fname.write("\n".join(file_list))

               main_df.to_csv(temp_combined_csv_path, index = False)

               ## Note: we'll use psql-like \copy through PGSpecial lib instead of the basic SQL "copy ... from ..." due to some disk access permissions issues with running postgre inside a conda env
               ## Strictly speaking, I don't remember how PGSpecial handles autocommit and if the two execute commands below occur within a single transaction or not.
               ## But I prefer to run these kind of exercises in conda environments to keep the base environment on my home PC nice and clean
               ## In the proper environment, those would be normal a SQL command which would be guaranteed to run within the same transaction and thus, ensure no potential data loss (because we run .commit() only once at the very end)
               pgspecial = PGSpecial()
               pgspecial.execute(cur, sql = "\copy interview.ingested_files from " + "'" +  temp_log_path + "'") 
               pgspecial.execute(cur, sql = "\copy interview.btc from '" +  temp_combined_csv_path + "' csv header")

               


          elif verbose: print('Dataset not updated - no new files to ingest')

          if verbose:
               cur.execute("SELECT COUNT(*) FROM interview.ingested_files")
               print('Total number of ingested files after the update:', cur.fetchall()[0][0])

               cur.execute("SELECT COUNT(*) FROM interview.btc")
               print('Total number of entries in btc table after the update:', cur.fetchall()[0][0])

          conn.commit()
          cur.close()
     except psycopg2.DatabaseError as error: print(error)
     finally:
          if conn is not None: conn.close()
          if os.path.isfile(temp_log_path): os.remove(temp_log_path)
          if os.path.isfile(temp_combined_csv_path): os.remove(temp_combined_csv_path)
          if os.path.isdir(temp_folder_name): os.rmdir(temp_folder_name)


if __name__ == "__main__":
     update_dataset(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
     
##     ## Usage example:
##     dsn_example = "user=temp_user password=temp_users_password dbname=exercise_db host=/tmp/"
##     update_dataset(dsn_example, input_data_folder = 'dataset', verbose = True, db_from_clean_state = True,  temp_file_folder_loc = "/tmp")
