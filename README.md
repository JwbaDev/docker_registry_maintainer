What?
=====

A script to query a certain namespace in a Docker Registry
and for each found repository delete old tags.

**NOTE:** The docker registry v1 API does not seem to return
creation dates in tags which makes it hard to delete old ones
specifically.  So this scripts assume tags are named as numbers
and sorts them accordingly.

This is tested and known to work on ```quay.io```.  By default
it will not do anything until you set ```--phasers-to-kill```

It will not delete a tag named ```latest``` even if you tell it
to keep 0 tags.

It supports reading ```~/.dockercfg``` and environment variables
```DOCKER_USER```, ```DOCKER_PASS```, ```DOCKER_HOST```,
```DOCKER_KEEP``` and ```DOCKER_NAMESPACE```

Contact?
========

R.I.Pienaar / rip@devco.net / @ripienaar / http://devco.net/
