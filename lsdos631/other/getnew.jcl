.. Getting new operating system..//IF -D//ASSIGN D=2//END//IF -S//ASSIGN S=3//ENDtime 06:31copy sys0/cmd:#S# sys0/sys.system6:#D# (c=n)copy sys1/cmd:#S# sys1/sys.system6:#D# (c=n)copy sys2/cmd:#S# sys2/sys.system6:#D# (c=n)copy sys3/cmd:#S# sys3/sys.system6:#D# (c=n)copy sys4/cmd:#S# sys4/sys.system6:#D# (c=n)copy sys5/cmd:#S# sys5/sys.system6:#D# (c=n)copy sys6/cmd:#S# sys6/sys.system6:#D# (c=n)copy sys7/cmd:#S# sys7/sys.system6:#D# (c=n)copy sys8/cmd:#S# sys8/sys.system6:#D# (c=n)copy sys9/cmd:#S# sys9/sys.system6:#D# (c=n)copy sys10/cmd:#S# sys10/sys.system6:#D# (c=n)copy sys11/cmd:#S# sys11/sys.system6:#D# (c=n)copy sys12/cmd:#S# sys12/sys.system6:#D# (c=n)copy sys13/cmd:#S# sys13/sys.system6:#D# (c=n)copy lowcore/cim:#S# boot/sys.system6:#D# (c=n)..msdostime settime 00.00time(csim s//ALERT 7,0,1,0,7,0,1,0cls.list getnew/txt.//pausedir /sys:#D# (s).//exit