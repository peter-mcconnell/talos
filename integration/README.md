# Integration tests

The [integration/run](./integration/run) script runs all integration tests.
Integration tests are run on the `tests` docker container.
Infrastructure for tests is set up with docker-compose.

To run the tests:

    make integration
    
## More options in running tests

In order to run tests, you first need to init the environment.
This will run some containers that need to be configured
and configure them.
This need to be done only once (though it can be run again harmlessly).

    integration/run init
    
If you changed the source code, and you want to apply these changes on a running container,
you should build the binaries first (see above), and then run the following command:

    integration/run refresh container_name

When testing are done, and you want to stop all the containers
used for the tests, run the following command:

    integration/run down

After initializing the environment, tests can be run.
To just run the dummy tests, use the following command:

    integration/run dummy

To run a specific test, to tests you can add the test names as
argument for the previous command. For example:

    integration/run tests tests.dummy.test_dummy

Will run all the test in the `test_tunnel` module.
To run only a specific test in a class in a module, use the following command:

    integration/run tests tests.dummy.test_tunnel.TestDummy.test_dummy

This will run the `test_dummy` test.
You can also specify several tests as arguments, and then those will be run.


## Get a shell in the test container

To get a shell in the test container, use the following command:

  integration/run --entrypoint bash tests
  
Once inside the container you can, for example, run tests, by
the following command:

  nose2 -c /setup.cfg -v tests.dummy

    
##  Run service-specific integration tests

Some services have their own specific integration tests.
Those are more lightweight then the system tests, and
run faster.
They also, as the system integration tests, need to
have the basic containers configured with the `run --rm init`
command, mentioned above.

* To run backend tests:

    `integration/run tests-dummy`

* To run data-sink tests:

    `integration/run tests-parallel`

