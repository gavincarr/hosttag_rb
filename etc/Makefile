all: import export
	
import:
	# redis has essentially open write permissions, so htimport is limited to root
	sudo /usr/sbin/htimport

export:
	# htexport is already limited by filesystem permissions, so doesn't need to be root
	/usr/bin/htexport

