Package.describe({
  summary: "Transparently divide a single meteor app into several different instances shared between different groups of users.",
  version: "0.5.2",
  git: "https://github.com/mizzao/meteor-partitioner.git"
});

Package.onUse(function (api) {
  api.versionsFrom("METEOR-CORE@0.9.0-atm");

  // Client & Server deps
  api.use([
    'accounts-base',
    'underscore',
    'coffeescript',
    'check'
  ]);

  api.use("matb33:collection-hooks");

  api.add_files('common.coffee');

  api.add_files('grouping.coffee', 'server');
  api.add_files('grouping_client.coffee', 'client');

  api.export(['Partitioner', 'Grouping']);
  api.export('TestFuncs', {testOnly: true});
});

Package.onTest(function (api) {
  api.use("mizzao:partitioner");

  api.use([
    'accounts-base',
    'accounts-password', // For createUser
    'coffeescript',
    'underscore'
  ]);

  api.use([
    'tinytest',
    'test-helpers'
  ]);

  api.add_files("tests/insecure_login.js");

  api.add_files('tests/hook_tests.coffee');
  api.add_files('tests/grouping_index_tests.coffee', 'server');
  api.add_files('tests/grouping_tests.coffee');
});
