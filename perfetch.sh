#!/bin/bash

# Set the environment variables for multiple databases.
_set_env(){

cat /etc/oratab|grep -v '#'|grep -v '^$' > /home/oracle/oratab_new
while read x
   do
     IFS=':' read -r -a array <<< $x
                ORACLE_SID="${array[0]}"
                ORACLE_HOME="${array[1]}"
                echo $ORACLE_SID
                echo $ORACLE_HOME
                export PATH=$PATH:$ORACLE_HOME/bin
   done < /home/oracle/oratab_new


}


#Capture the high load sql to STS and pack them into staging table
_capture_sql_load(){
t=30
loop="true"
c=0
ela_s=$(date +%s)
while [ $loop == "true" ]
        do
        sleep $t

        $ORACLE_HOME/bin/sqlplus -S '/ as sysdba' <<EOF
        EXEC dbms_workload_repository.create_snapshot();
        conn c##hydra/hydra
        EXEC DBMS_SQLTUNE.CAPTURE_CURSOR_CACHE_SQLSET( -
                                                sqlset_name     => 'B4UPGLOAD', -
                                                time_limit      =>  30, -
                                        repeat_interval =>  5);
        conn / as sysdba
        BEGIN
            DBMS_SQLTUNE.create_stgtab_sqlset(table_name => 'STS',
            schema_name => 'KISH',
            tablespace_name => 'HYDRA');
        END;
        /
        BEGIN
            DBMS_SQLTUNE.pack_stgtab_sqlset(sqlset_name => 'B4UPGLOAD',
            sqlset_owner => 'C##HYDRA',
            staging_table_name => 'STS',
            staging_schema_owner => 'KISH');
            END;
         /
exit;
EOF
ela_e=$(date +%s)
c=$c+1
ela_t=$(expr $ela_s + $ela_e)
if [[ $c -gt 30 ]]
    then
    loop=False
elif [[ $c -eq 30 ]]
    then
    _exp_sqlset
    break
fi
done

}


#Export the STS to a dump file out of the database
_exp_sqlset(){
exp USERID=kish/password file=expsts.dmp log=stsbkp.log buffer=500 tables=kish.sts
}

_set_env
_capture_sql_load
