@ErrMsg =
  userIdErr: "Must be logged in to operate on partitioned collection"
  groupErr: "Must have group assigned to operate on partitioned collection"

@Helpers =
  isDirectUserSelector: (selector) -> _.isString(selector) or
    (selector? and ("_id" of selector or "username" of selector))
