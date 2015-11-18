ErrMsg =
  userIdErr: "Must be logged in to operate on partitioned collection"
  groupErr: "Must have group assigned to operate on partitioned collection"

Helpers =
  isDirectSelector: (selector) ->
    _.isString(selector) or _.isString(selector?._id)

  # Because of https://github.com/HarvardEconCS/turkserver-meteor/issues/44
  # _id: { $in: [ ... ] } queries should be short-circuited as well for users
  isDirectUserSelector: (selector) ->
    _.isString(selector) or
      _.isString(selector?._id) or
      _.isString(selector?.username) or
      ( _.isObject(selector?._id) and selector._id.$in? )
