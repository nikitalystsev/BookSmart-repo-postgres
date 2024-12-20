revoke reader from reader_user;

drop user if exists reader_user;

revoke administrator from admin_user;

drop user if exists admin_user;

revoke all privileges on all tables in schema bs from administrator;
revoke usage on schema bs from administrator;

drop role if exists administrator;

delete
from bs.reservation;
delete
from bs.lib_card;
delete
from bs.reader;