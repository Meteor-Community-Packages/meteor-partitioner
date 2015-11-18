testUsername = "hooks_foo"
testGroupId = "hooks_bar"

if Meteor.isClient
  # XXX All async here to ensure ordering

  Tinytest.addAsync "partitioner - hooks - ensure logged in", (test, next) ->
    InsecureLogin.ready next

  Tinytest.addAsync "partitioner - hooks - add client group", (test, next) ->
    Meteor.call "joinGroup", testGroupId, (err, res) ->
      test.isFalse err
      next()

  Tinytest.addAsync "partitioner - hooks - vanilla client find", (test, next) ->
    ctx =
      args: []

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.length ctx.args, 0

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Also nothing changed
    test.length ctx.args, 0

    next()

  Tinytest.addAsync "partitioner - hooks - set admin", (test, next) ->
    Meteor.call "setAdmin", true, (err, res) ->
      test.isFalse err
      test.isTrue Meteor.user().admin
      next()

  Tinytest.addAsync "partitioner - hooks - admin hidden in client find", (test, next) ->
    ctx =
      args: []

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.length ctx.args, 0

    TestFuncs.userFindHook.call(ctx, Meteor.userId(), ctx.args[0], ctx.args[1])
    # Admin removed from find
    test.equal ctx.args[0].admin.$exists, false
    next()

  Tinytest.addAsync "partitioner - hooks - admin hidden in selector find", (test, next) ->
    ctx =
      args: [ { foo: "bar" }]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.length ctx.args, 1
    test.equal ctx.args[0].foo, "bar"

    TestFuncs.userFindHook.call(ctx, Meteor.userId(), ctx.args[0], ctx.args[1])
    # Admin removed from find
    test.equal ctx.args[0].foo, "bar"
    test.equal ctx.args[0].admin.$exists, false
    next()

  # Need to remove admin to avoid fubars in other tests
  Tinytest.addAsync "partitioner - hooks - unset admin", (test, next) ->
    Meteor.call "setAdmin", false, (err, res) ->
      test.isFalse err
      test.isFalse Meteor.user().admin
      next()

if Meteor.isServer
  Meteor.methods
    setAdmin: (value) ->
      userId = Meteor.userId()
      throw new Meteor.Error(403, "not logged in") unless userId
      if value
        Meteor.users.update userId, $set: admin: true
      else
        Meteor.users.update userId, $unset: admin: null

  userId = null
  ungroupedUserId = null
  try
    userId = Accounts.createUser
        username: testUsername
  catch
    userId = Meteor.users.findOne(username: testUsername)._id

  try
    ungroupedUserId = Accounts.createUser
      username: "blahblah"
  catch
    ungroupedUserId = Meteor.users.findOne(username: "blahblah")._id

  Partitioner.clearUserGroup userId
  Partitioner.setUserGroup userId, testGroupId

  Tinytest.add "partitioner - hooks - find with no args", (test) ->
    ctx =
      args: []

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should replace undefined with { _groupId: ... }
    test.isTrue ctx.args[0]?
    test.equal ctx.args[0]._groupId, testGroupId

    test.isTrue ctx.args[1]?
    test.equal ctx.args[1].fields._groupId, 0

  Tinytest.add "partitioner - hooks - find with no group", (test) ->
    ctx =
      args: []

    # Should throw if user is not logged in
    test.throws ->
      TestFuncs.findHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    , (e) -> e.error is 403 and e.reason is ErrMsg.userIdErr

  Tinytest.add "partitioner - hooks - find with string id", (test) ->
    ctx =
      args: [ "yabbadabbadoo" ]

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a string
    test.equal ctx.args[0], "yabbadabbadoo"

    test.isFalse ctx.args[1]?

  Tinytest.add "partitioner - hooks - find with single _id", (test) ->
    ctx =
      args: [ {_id: "yabbadabbadoo"} ]

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch an object with _id
    test.equal ctx.args[0]._id, "yabbadabbadoo"
    test.isFalse ctx.args[0]._groupId

    test.isFalse ctx.args[1]?

  Tinytest.add "partitioner - hooks - find with complex _id", (test) ->
    ctx =
      args: [ {_id: {$ne: "yabbadabbadoo"} } ]

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should modify for complex _id
    test.equal ctx.args[0]._id.$ne, "yabbadabbadoo"
    test.equal ctx.args[0]._groupId, testGroupId

    test.isTrue ctx.args[1]?
    test.equal ctx.args[1].fields._groupId, 0

  Tinytest.add "partitioner - hooks - find with selector", (test) ->
    ctx =
      args: [ { foo: "bar" } ]

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    test.equal ctx.args[0].foo, "bar"
    test.equal ctx.args[0]._groupId, testGroupId

    test.isTrue ctx.args[1]?
    test.equal ctx.args[1].fields._groupId, 0

  Tinytest.add "partitioner - hooks - find with inclusion fields", (test) ->
    ctx =
      args: [
        { foo: "bar" },
        { fields: { foo: 1 } }
      ]

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a string
    test.equal ctx.args[0].foo, "bar"
    test.equal ctx.args[0]._groupId, testGroupId

    test.isTrue ctx.args[1]?
    test.equal ctx.args[1].fields.foo, 1
    test.isFalse ctx.args[1].fields._groupId?

  Tinytest.add "partitioner - hooks - find with exclusion fields", (test) ->
    ctx =
      args: [
        { foo: "bar" },
        { fields: { foo: 0 } }
      ]

    TestFuncs.findHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a string
    test.equal ctx.args[0].foo, "bar"
    test.equal ctx.args[0]._groupId, testGroupId

    test.isTrue ctx.args[1]?
    test.equal ctx.args[1].fields.foo, 0
    test.equal ctx.args[1].fields._groupId, 0

  Tinytest.add "partitioner - hooks - insert doc", (test) ->
    ctx =
      args: [ { foo: "bar" } ]

    TestFuncs.insertHook.call(ctx, userId, ctx.args[0])
    # Should add the group id
    test.equal ctx.args[0].foo, "bar"
    test.equal ctx.args[0]._groupId, testGroupId

  Tinytest.add "partitioner - hooks - user find with no args", (test) ->
    ctx =
      args: []

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.length ctx.args, 0

    # Ungrouped user should throw an error
    test.throws ->
      TestFuncs.userFindHook.call(ctx, ungroupedUserId, ctx.args[0], ctx.args[1])
    (e) -> e.error is 403 and e.reason is ErrMsg.groupErr

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should replace undefined with { _groupId: ... }
    test.equal ctx.args[0].group, testGroupId
    test.equal ctx.args[0].admin.$exists, false

  Tinytest.add "partitioner - hooks - user find with environment group but no userId", (test) ->
    ctx =
      args: []

    Partitioner.bindGroup testGroupId, ->
      TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
      # Should have set the extra arguments
      test.equal ctx.args[0].group, testGroupId
      test.equal ctx.args[0].admin.$exists, false

  Tinytest.add "partitioner - hooks - user find with string id", (test) ->
    ctx =
      args: [ "yabbadabbadoo" ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0], "yabbadabbadoo"

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a string
    test.equal ctx.args[0], "yabbadabbadoo"

  Tinytest.add "partitioner - hooks - user find with single _id", (test) ->
    ctx =
      args: [ {_id: "yabbadabbadoo"} ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0]._id, "yabbadabbadoo"
    test.isFalse ctx.args[0].group

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a single object
    test.equal ctx.args[0]._id, "yabbadabbadoo"
    test.isFalse ctx.args[0].group

  Tinytest.add "partitioner - hooks - user find with _id: $in", (test) ->
    ctx =
      args: [ {_id: $in: [ "yabbadabbadoo"] } ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0]._id.$in[0], "yabbadabbadoo"
    test.isFalse ctx.args[0].group

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a single object
    test.equal ctx.args[0]._id.$in[0], "yabbadabbadoo"
    test.isFalse ctx.args[0].group

  Tinytest.add "partitioner - hooks - user find with complex _id", (test) ->
    ctx =
      args: [ {_id: {$ne: "yabbadabbadoo"} } ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0]._id.$ne, "yabbadabbadoo"
    test.isFalse ctx.args[0].group

    # Ungrouped user should throw an error
    test.throws ->
      TestFuncs.userFindHook.call(ctx, ungroupedUserId, ctx.args[0], ctx.args[1])
    (e) -> e.error is 403 and e.reason is ErrMsg.groupErr

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should be modified
    test.equal ctx.args[0]._id.$ne, "yabbadabbadoo"
    test.equal ctx.args[0].group, testGroupId
    test.equal ctx.args[0].admin.$exists, false

  Tinytest.add "partitioner - hooks - user find with username", (test) ->
    ctx =
      args: [ {username: "yabbadabbadoo"} ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0].username, "yabbadabbadoo"
    test.isFalse ctx.args[0].group

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should not touch a single object
    test.equal ctx.args[0].username, "yabbadabbadoo"
    test.isFalse ctx.args[0].group

  Tinytest.add "partitioner - hooks - user find with complex username", (test) ->
    ctx =
      args: [ {username: {$ne: "yabbadabbadoo"} } ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0].username.$ne, "yabbadabbadoo"
    test.isFalse ctx.args[0].group

    # Ungrouped user should throw an error
    test.throws ->
      TestFuncs.userFindHook.call(ctx, ungroupedUserId, ctx.args[0], ctx.args[1])
    (e) -> e.error is 403 and e.reason is ErrMsg.groupErr

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should be modified
    test.equal ctx.args[0].username.$ne, "yabbadabbadoo"
    test.equal ctx.args[0].group, testGroupId
    test.equal ctx.args[0].admin.$exists, false

  Tinytest.add "partitioner - hooks - user find with selector", (test) ->
    ctx =
      args: [ { foo: "bar" } ]

    TestFuncs.userFindHook.call(ctx, undefined, ctx.args[0], ctx.args[1])
    # Should have nothing changed
    test.equal ctx.args[0].foo, "bar"
    test.isFalse ctx.args[0].group

    # Ungrouped user should throw an error
    test.throws ->
      TestFuncs.userFindHook.call(ctx, ungroupedUserId, ctx.args[0], ctx.args[1])
    (e) -> e.error is 403 and e.reason is ErrMsg.groupErr

    TestFuncs.userFindHook.call(ctx, userId, ctx.args[0], ctx.args[1])
    # Should modify the selector
    test.equal ctx.args[0].foo, "bar"
    test.equal ctx.args[0].group, testGroupId
    test.equal ctx.args[0].admin.$exists, false
