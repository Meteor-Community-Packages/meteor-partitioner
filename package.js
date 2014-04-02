Package.describe({
    summary: "Transparently divide a single meteor app into several different instances shared between different groups of users."
});

Package.on_use(function (api) {
    // Client & Server deps
    api.use([
        'accounts-base',
        'underscore',
        'coffeescript'
    ]);

    api.use('collection-hooks');

    api.add_files('common.coffee');

    api.add_files('grouping.coffee', 'server');
    api.add_files('grouping_client.coffee', 'client');

    api.export(['Partitioner', 'Grouping']);
    api.export('TestFuncs', {testOnly: true});
});

Package.on_test(function (api) {
    api.use('partitioner');

    api.use([
      'accounts-base',
      'accounts-password', // For createUser
      'coffeescript'
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
