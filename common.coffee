ErrMsg =
  userIdErr: "Must be logged in to operate on partitioned collection"
  groupErr: "Must have group assigned to operate on partitioned collection"

Helpers =
  isDirectSelector: (selector) ->
    _.isString(selector) or _.isString(selector?._id)

  isDirectUserSelector: (selector) ->
    _.isString(selector) or
      _.isString(selector?._id) or
      _.isString(selector?.username)

