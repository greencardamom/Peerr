#!/usr/bin/tcsh

# Push files from a local directory to a remote directory. If "--delete" then it keeps the directories in sync. Otherwise it only uploads new files.
# More info:
#   https://wikitech.wikimedia.org/wiki/Help:Toolforge/Tool_Accounts#Transfer_files
#
# Self-contained copy for peerr. It previously shared ~/toolforge/scripts/push, which lived
# inside the Iabotwatch repo on another host - when that repo moved, peerr broke.

if($#argv == 0) then
  echo ""
  echo "push - mirror files to toolforge"
  echo ""
  echo "  ./push <name>"
  echo "  ./push <name> v  -- for verbose progress of files uploaded and deleted"
  echo ""
endif

if($2 == "v") then
  set v="--progress"
else
  set v=""
endif

if($1 == "peerr") then
  /usr/bin/rsync $v --delete --delay-updates -F --compress --archive --no-owner --no-group --rsh='/usr/bin/ssh -S none -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -E /dev/null -o LogLevel=error' --rsync-path='sudo -u tools.botwikiawk /usr/bin/rsync' --chmod=Dug=rwx,Dg+s,Do=rx,Fug=rw,Fo=r /home/greenc/toolforge/peerr/www/ login.toolforge.org:/data/project/botwikiawk/www/static/peerr/
endif
