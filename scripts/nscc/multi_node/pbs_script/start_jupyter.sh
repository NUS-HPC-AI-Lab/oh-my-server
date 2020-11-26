#!/bin/bash

source /home/users/ntu/c170166/anaconda3/bin/activate base
DATESTAMP=`date +'%y%m%d%H%M%S'`
LOGFILE=./jupyter.o$DATESTAMP
jupyter lab --no-browser --ip=0.0.0.0 --port=8888 \
 --NotebookApp.terminado_settings='{"shell_command": ["/bin/bash"]}' \
 --NotebookApp.allow_remote_access=True --FileContentsManager.delete_to_trash=False |& tee $LOGFILE
