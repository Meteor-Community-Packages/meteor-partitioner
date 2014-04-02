partitioner [![Build Status](https://travis-ci.org/mizzao/meteor-partitioner.svg?branch=master)](https://travis-ci.org/mizzao/meteor-partitioner)
===========

Transparently divide a single Meteor app into several different instances shared between different groups of users.

## What's this do?

Provides facilities to transparently separate your Meteor app into different instances where a group of users sees the data in each instance. You can write client-side and server-side code as if one particular set of users has the app all to themselves. This pattern is common in settings where multiple users interact with each other in groups, such as multiplayer games, etc. This package makes it a lot easier to write for your app without thinking about the separation of different groups yourself.

## Installation

```
mrt install partitioner
```

## Usage

Partitioner uses the [collection-hooks](https://github.com/matb33/meteor-collection-hooks) package to transparently intercept collection operations on the client and server side so that writing code for each group of users is almost the same as writing for the whole app. Only minor modifications from a standalone app designed for a single group of users is necessary.
