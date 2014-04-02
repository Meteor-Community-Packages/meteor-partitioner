Tinytest.add "partitioner - indexing - no index specified", (test) ->
  index = TestFuncs.getPartitionedIndex(undefined)

  test.length Object.keys(index), 1
  test.equal index._groupId, 1

Tinytest.add "partitioner - indexing - simple index object", (test) ->
  input = {foo: 1}
  index = TestFuncs.getPartitionedIndex(input)

  keyArr = Object.keys(index)
  test.length keyArr, 2
  test.equal keyArr[0], "_groupId"
  test.equal keyArr[1], "foo"
