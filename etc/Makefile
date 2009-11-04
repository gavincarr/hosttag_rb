all:
	sudo /sbin/service htserver stop || true
	sudo /usr/bin/hosttag_load_data
	sudo /sbin/service htserver start
