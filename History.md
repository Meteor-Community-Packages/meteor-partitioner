## vNEXT

## v0.5.9

* Fix a bug that would create blank records for users who are deleted. (#14) 

## v0.5.8 

* Use a workaround to short-circuit `_id: {$in: [...]}` style queries, which 
would cause an error for some user login processes because of the way 
collection hooks retrieved documents. (See HarvardEconCS/turkserver-meteor#44). 

## v0.5.7 

* Correct behavior when a complex `_id` is specified. (#4, #13). Note, 
  however, that direct searches using `_id` still short-circuit partitioning 
  for performance reasons (#9). This may be changed in the future.
     
## v0.5.6

* Allow for options to be specified on partitioned indexes.

## v0.5.5

* Remove package-level variables from the global namespace. (#2, #11)

## v0.5.4

* Update usage of Collection API for Meteor 0.9.1+, and use updated version of collection hooks.

## v0.5.3

* **Re-release for Meteor 0.9.**

## v0.5.2

* Don't include the meta `_groupId` value with `find`/`findOne` operations on the server. This can save a good chunk of network traffic for publications and also makes partitioning more invisible. (#1)
* Fixed an issue with how validators were modified on insecure collections.

## v0.5.1

* Allow for overriding of `Partitioner.group()` via environment variable in addition to in hooks.

## v0.5.0

* First release; refactored out of https://github.com/HarvardEconCS/turkserver-meteor.
