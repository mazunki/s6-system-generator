# builder for s6 services

By using `./s6-new-service.sh` to generate a single runner+logger set for a service from the `mock/` templates, and a set of scripts with corresponding dependencies in `./generate-services.sh`, we should be able to fully generate the required services to have a minimal working system.

The goal of this exercise is to avoid having to rewrite a bunch of the boilerplate which is repeated when creating services, and to have a single location where you can easily modify your system, and track what changes you've done to your boot through some form of VCS. The mock templates should, hopefully, be robust enough to handle different config environments and chainloading of such.

## Templates
The mock templates assume a shebang of /bin/sh being available, and should otherwise should follow POSIX. I've considered making it possible to load a file into the template placeholders, instead of simply a string, perhaps with the prefix of `@`, as seen in curl and other commands. 

## Generation
The syntax for generating services in the generation template is as follows:
```sh
${service_type} ${service_name} ${command} ${dependencies...}
```

The dependencies are optional, and the service types can be oneshot, bundle or longrun. If you wish to run several commands, you must do so within a single argument, perhaps with the usage of `;` or `&&`. For now, if you need more complicated scripts, just do something like `longrun complicated_service '/path/to/full/service.sh' files` or something.


