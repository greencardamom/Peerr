Peerr
===================
by User:GreenC (en.wikipedia.org)

April 2021

MIT License

Purpose
========

Peerr removes the template {{Peer review}} from talk pages when it is no longer
needed - ie. the template was added more than 7 days ago, indicating the peer
review process stalled or was never properly initiated.

Bot job: [User:GreenC bot/Job 20](https://en.wikipedia.org/wiki/User:GreenC_bot/Job_20)

Files
========

* `peerr.awk`   - the bot (run daily from cron)
* `project.cfg` - project configuration
* `push.csh`    - mirrors ~/www output to Toolforge
* `crontab.txt` - the cron entry

Output is published at
[botwikiawk/peerr](https://botwikiawk.toolforge.org/static/peerr/).
