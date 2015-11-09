###
  SERVER METHODS
  Hook in group id to all operations, including find

  Grouping contains _id: userId and groupId: groupId
###

Partitioner = {}
Grouping = new Mongo.Collection("ts.grouping")

# Meteor environment variables for scoping group operations
Partitioner._currentGroup = new Meteor.EnvironmentVariable()
Partitioner._directOps = new Meteor.EnvironmentVariable()

updateUserGroup = (userId) ->
  return Meteor.users.update(userId, {
    $set: {"group": Partitioner.getAllUserGroups(userId)?.fetch()}
  })

disableAllGroups = (userId) ->
  Grouping.update({userId: userId, active:true}, {
    $set: {active: false}
  })


###
   Public API
###

Partitioner.setUserGroup = (userId, groupId, active=true) ->
  check(userId, String)
  check(groupId, String)
  group = Grouping.findOne userId: userId, groupId: groupId

  if !group
    disableAllGroups(userId) if active
    Grouping.insert
      userId: userId
      groupId: groupId
      active: active
    return updateUserGroup(userId)

  if group.active is true
    throw new Meteor.Error(403, "User is already in group #{groupId}")

  disableAllGroups(userId)
  Grouping.update group._id,
    $set: {active: true}
  updateUserGroup(userId)

Partitioner.getActiveGroup = (userId) ->
  check(userId, String)
  Grouping.findOne({userId: userId, active: true})

Partitioner.getUserGroup = (userId) ->
  Partitioner.getActiveGroup(userId)?.groupId

Partitioner.getAllUserGroups = (userId) ->
  Grouping.find({userId: userId})

Partitioner.clearUserGroup = (userId) ->
  check(userId, String)
  Grouping.update({userId: userId, active:true}, {
    $set: {active: false}
  })
  updateUserGroup(userId)

Partitioner.group = ->
  # If group is overridden, return that instead
  if (groupId = Partitioner._currentGroup.get())?
    return groupId
  try # We may be outside of a method
    userId = Meteor.userId()
  return unless userId
  Partitioner.getUserGroup(userId)

Partitioner.bindGroup = (groupId, func) ->
  Partitioner._currentGroup.withValue(groupId, func)
Partitioner.bindUserGroup = (userId, func) ->
  groupId = Partitioner.getUserGroup(userId)
  unless groupId
    Meteor._debug "Dropping operation because #{userId} is not in a group"
    return
  Partitioner.bindGroup(groupId, func)

Partitioner.directOperation = (func) ->
  Partitioner._directOps.withValue(true, func)

# This can be replaced - currently not documented
Partitioner._isAdmin = (userId) -> Meteor.users.findOne(userId).admin is true

getPartitionedIndex = (index) ->
  defaultIndex = { _groupId : 1 }
  return defaultIndex unless index
  return _.extend( defaultIndex, index )

Partitioner.partitionCollection = (collection, options) ->
  # Because of the deny below, need to create an allow validator
  # on an insecure collection if there isn't one already
  if collection._isInsecure()
    collection.allow
      insert: -> true
      update: -> true
      remove: -> true

  # Idiot-proof the collection against admin users
  collection.deny
    insert: Partitioner._isAdmin
    update: Partitioner._isAdmin
    remove: Partitioner._isAdmin

  collection.before.find findHook
  collection.before.findOne findHook

  # These will hook the _validated methods as well
  collection.before.insert insertHook

  ###
    No update/remove hook necessary, see
    https://github.com/matb33/meteor-collection-hooks/issues/23
  ###

  # Index the collections by groupId on the server for faster lookups across groups
  collection._ensureIndex getPartitionedIndex(options?.index), options?.indexOptions

# Publish admin and group for users that have it
Meteor.publish null, ->
  return unless @userId
  return Meteor.users.find @userId,
    fields: {
      admin: 1
      group: 1
    }

# Special hook for Meteor.users to scope for each group
userFindHook = (userId, selector, options) ->
  return true if Partitioner._directOps.get() is true
  return true if Helpers.isDirectUserSelector(selector)

  groupId = Partitioner._currentGroup.get()
  # This hook doesn't run if we're not in a method invocation or publish
  # function, and Partitioner._currentGroup is not set
  return true if (!userId and !groupId)

  unless groupId
    user = Meteor.users.findOne(userId)
    groupId = Partitioner.getUserGroup(userId)
    # If user is admin and not in a group, proceed as normal (select all users)
    return true if user.admin and !groupId
    # Normal users need to be in a group
    throw new Meteor.Error(403, ErrMsg.groupErr) unless groupId

  # Since user is in a group, scope the find to the group
  filter =
    "group" : {$elemMatch: {groupId: groupId}}
    "admin": {$exists: false}

  unless @args[0]
    @args[0] = filter
  else
    _.extend(selector, filter)

  return true

# Attach the find hooks to Meteor.users
Meteor.users.before.find userFindHook
Meteor.users.before.findOne userFindHook
Meteor.users._ensureIndex 'group.groupId': 1

# No allow/deny for find so we make our own checks
findHook = (userId, selector, options) ->
  # Don't scope for direct operations
  return true if Partitioner._directOps.get() is true

  # for find(id) we should not touch this
  # TODO this may allow arbitrary finds across groups with the right _id
  # We could amend this in the future to {_id: someId, _groupId: groupId}
  # https://github.com/mizzao/meteor-partitioner/issues/9
  # https://github.com/mizzao/meteor-partitioner/issues/10
  return true if Helpers.isDirectSelector(selector)

  # Check for global hook
  groupId = Partitioner._currentGroup.get()
  unless groupId
    throw new Meteor.Error(403, ErrMsg.userIdErr) unless userId
    groupId = Partitioner.getUserGroup(userId)
    throw new Meteor.Error(403, ErrMsg.groupErr) unless groupId

  # if object (or empty) selector, just filter by group
  unless selector?
    @args[0] = { _groupId : groupId }
  else
    selector._groupId = groupId

  # Adjust options to not return _groupId
  unless options?
    @args[1] = { fields: {_groupId: 0} }
  else
    # If options already exist, add {_groupId: 0} unless fields has {foo: 1} somewhere
    options.fields ?= {}
    options.fields._groupId = 0 unless _.any(options.fields, (v) -> v is 1)

  return true

insertHook = (userId, doc) ->
  # Don't add group for direct inserts
  return true if Partitioner._directOps.get() is true

  groupId = Partitioner._currentGroup.get()
  unless groupId
    throw new Meteor.Error(403, ErrMsg.userIdErr) unless userId
    groupId = Partitioner.getUserGroup(userId)
    throw new Meteor.Error(403, ErrMsg.groupErr) unless groupId

  doc._groupId = groupId
  return true

TestFuncs =
  getPartitionedIndex: getPartitionedIndex
  userFindHook: userFindHook
  findHook: findHook
  insertHook: insertHook
