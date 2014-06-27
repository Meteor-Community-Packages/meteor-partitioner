## v0.5.2

* Don't include the meta `_groupId` value with `find`/`findOne` operations on the server. This can save a good chunk of network traffic for publications and also makes partitioning more invisible. (#1)
* Fixed an issue with how validators were modified on insecure collections.

## v0.5.1

* Allow for overriding of `Partitioner.group()` via environment variable in addition to in hooks.

## v0.5.0

* First release; refactored out of https://github.com/HarvardEconCS/turkserver-meteor.
