Package.describe({
  name: "mizzao:partitioner",
  summary: "Transparently divide a meteor app into different instances shared between groups of users.",
  version: "0.5.8",
  git: "https://github.com/mizzao/meteor-partitioner.git"
});

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.2");

  // Client & Server deps
  api.use([
    'accounts-base',
    'underscore',
    'coffeescript',
    'check',
    'ddp', // Meteor.publish available
    'mongo' // Mongo.Collection available
  ]);

  api.use("matb33:collection-hooks@0.7.13");

  api.addFiles('common.coffee');

  api.addFiles('grouping.coffee', 'server');
  api.addFiles('grouping_client.coffee', 'client');

  api.export(['Partitioner', 'Grouping']);

  // Package-level variables that should not be exported
  // See http://docs.meteor.com/#/full/coffeescript
  api.export(['ErrMsg', 'Helpers'], {testOnly: true});

  api.export('TestFuncs', {testOnly: true});
});

Package.onTest(function (api) {
  api.use("mizzao:partitioner");

  api.use([
    'accounts-base',
    'accounts-password', // For createUser
    'coffeescript',
    'underscore',
    'ddp', // Meteor.publish available
    'mongo' // Mongo.Collection available
  ]);

  api.use([
    'tinytest',
    'test-helpers'
  ]);

  api.addFiles("tests/insecure_login.js");

  api.addFiles('tests/hook_tests.coffee');
  api.addFiles('tests/grouping_index_tests.coffee', 'server');
  api.addFiles('tests/grouping_tests.coffee');
});
