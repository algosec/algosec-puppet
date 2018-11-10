

# algosec [![Build Status](https://travis-ci.com/algosec/algosec-puppet.svg?branch=master)](https://travis-ci.com/algosec/algosec-puppet) [![codecov](https://codecov.io/gh/algosec/algosec-puppet/branch/master/graph/badge.svg)](https://codecov.io/gh/algosec/algosec-puppet)


#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with AlgoSec](#setup)
    * [Setup requirements](#setup-requirements)
    * [Getting started with AlgoSec](#getting-started-with-algosec)
3. [Usage - Configuration options and additional functionality](#usage)
    * [How to use the tasks in the module](#tasks)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)


## Module Description

The AlgoSec module configures BusinessFlow applications and flows on AlgoSec version 2017.2.0 and up.

When making changes to AlgoSec BusinessFlow applications or flows, include `algosec_apply_draft` in your manifest, or execute the `apply_drafts` task. You must do this before the changes are applied for further processing in AlgoSec FireFlow. 

The module provides a Puppet task to manually `apply_drafts` which will apply outstanding application drafts for all the managed applications.

The module is intended to manage __all__ applications on BusinessFlow unless configured to manage only specific applications. When it is configured to manage only specific list of applications, it is avoiding __ANY__ changes to unmanaged applications. To configure managed applications, see the [Getting started with AlgoSec](#getting-started-with-algosec) section.  

__NOTE__: Be very careful to define the managed applications when using the automatic __purge__ metadata option to make sure you don't accident delete all of your apps :)

## Setup

Install the module on either a Puppet master or Puppet agent machine, by running `puppet module install algosec-algosec`. To install from source, download the tar file from GitHub and run `puppet module install <file_name>.tar.gz --force`.

### Setup Requirements

The AlgoSec module requires access to the AlgoSec server API. You will also need to install the dependencies.

The module has a dependency on the `resource_api` puppet module - it will be installed when the module is installed. Alternatively, it can be manually installed by running `puppet module install puppetlabs-resource_api`, or by following the setup instructions in the [Resource API README](https://github.com/puppetlabs/puppetlabs-resource_api#resource_api).

The module also depend upon the [algosec-sdk](https://github.com/algosec/algosec-ruby) ruby gem that will installed on the agent if using the `algosec::agent` class provided with this module. Please see the next section for more details. 

### Manual Test Setup

Once the module has been installed, classify the appropriate class:

* On each puppetserver or PE master that needs to communicate with the AlgoSec API, classify or apply the `algosec::server` by running `puppet apply -e 'include algosec::server'`.
* On each Puppet agent that needs to communicate with the AlgoSec API, classify or apply the `algosec::agent` class by running `puppet apply -e 'include algosec::agent'`.

### Getting started with AlgoSec

To get started, create or edit `/etc/puppetlabs/puppet/device.conf`, add a section for the device (this will become the device's `certname`), specify a type of `algosec`, and specify a `url` to a credentials file. For example:

```INI
[local.algosec.com]
type algosec
url file:////etc/puppetlabs/puppet/devices/local.algosec.com.conf
```

Next, create a credentials file. See the [HOCON documentation](https://github.com/lightbend/config/blob/master/HOCON.md) for information on quoted/unquoted strings and connecting the device.

The credential file should look like this:

* The basic configuration file contains the host, user, password in plain text, for example:
  ```
    host: 10.0.0.10
    user: admin
    password: algosec
  ```
  
* Two additional fields are optionally available for configuration in the credentials file:
    * __ssl_enabled__ - used in demo environments and can be set to false to allow non certified ssl connections.
    * __managed_applications__ - Used to limit the applications managed by this device to a specific list. If this is not defined, all applications are available to the puppet module.

  ```
    host: 10.0.0.10
    user: admin
    password: algosec
    ssl_enabled: false
    managed_applications: [ puppet-app1 puppet-app2 ]
  ```

__NOTE__: Be very careful to define the managed applications when using the automatic __purge__ metadata option to make sure you don't accident delete all of your apps :)

Test your setup and get the certificate signed:

`puppet device --verbose --target local.algosec.com`

This will sign the certificate and set up the device for Puppet.

See the [`puppet device` documentation](https://puppet.com/docs/puppet/6.0/puppet_device.html)

## Usage

Now you can manage applications and flows on AlgoSec BusinessFlow and apply application drafts. Full and exact reference can be found at [REFERENCE.md](https://github.com/algosec/algosec-puppet/blob/master/REFERENCE.md).

The repo's acceptance test examples contain a [useful reference](https://github.com/algosec/algosec-puppet/blob/master/spec/fixtures/create.pp) on the use of the module's Types.


### Puppet Device

To get information from the device, use the `puppet device --resource` command. For example, to retrieve available BusinessFlow applications on the AlgoSec server, run the following:

`puppet device --resource --target local.algosec.com algosec_flow`

To create a application, write a manifest. Start by making a file named `manifest.pp` with the following content:

```
algosec_application { 'some-application':
  ensure => 'present',
}
```

__Note__: The `algosec_application` resource currently support only name attribute. Wider support for other application attributes is planned.

Execute the following command:

`puppet device  --target local.algosec.com --apply manifest.pp`

This will apply the manifest. Puppet will check if the address already exists and if it is absent it will create it (idempotency check). When you query for addresses you will see that the new BusinessFlow application is available. To do this, run the following command again:

`puppet device --resource --target local.algosec.com algosec_application`

Note that if you get errors, run the above commands with `--verbose` - this will give you error message output.

### Tasks

The AlgoSec module define currently one task `algosec::apply_drafts`. When executed, it will apply any outstanding drafts of the managed applications (as defined in the `device.conf`). To execute the task against the AlgoSec server using the device config, run:

Before running this task, install the module on your machine, along with [Puppet Bolt](https://puppet.com/docs/bolt/0.x/bolt_installing.html). When complete, execute the following command:

```
bolt task run algosec::apply_drafts --nodes localhost --transport local --modulepath <module_installation_dir> --params @credentials.json
```

The `--modulepath` param can be retrieved by typing `puppet config print modulepath`. The credentials file needs to be valid JSON parallel to the fields defined in the `device.conf` described in the [Getting started](#Getting-started-with-AlgoSec) section.


## Reference

For full type reference documentation, see the [REFERENCE.md](https://github.com/algosec/algosec-puppet/blob/master/REFERENCE.md)

## Limitations

This module has only been tested with AlgoSec 2017.2.0 and 2017.3.0

## Development

Contributions are welcome, especially if they can be of use to other users.

Checkout the [repo](https://github.com/algosec/algosec-puppet) by forking and creating your feature branch.

### Type

Use the `pdk` tool to create new types/providers as you fit. Good candidates are BusinessFlow's Network Objects, Network Services and the similar if you find it useful for your organization.
We use the [Resource API format](https://github.com/puppetlabs/puppet-resource_api/blob/master/README.md).

The first command to start creating new types is `pdk new provider type_name`. This will create 4 new files - one for the provider, the type and corresponding unit test files.

### Provider

See the [Type](#type) section above. We use the Puppet Resource API for types and providers.

### Testing

There are two levels of testing found under `spec`.

To test this module's with acceptance tests you will need to have an AlgoSec machine available. The demo machine from our download area work fine in VirtualBox and VMware.

#### Unit Testing

Unit tests test the parsing and command generation logic, executed locally.

First execute `pdk bundle exec rake spec` to ensure that the local types are made available to the spec tests. Then execute with `bundle exec rake spec`.

#### Acceptance Testing

Acceptance tests are executed on actual AlgoSec running server.

Use test application and make sure that these are non-destructive.

The acceptance tests locate AlgoSec box that is used for testing through environment variables:

* Set `ALGOSEC_TEST_HOST` to the FQDN/IP of the box.
* To specify the username and password used to connect to the box:
    * `ALGOSEC_TEST_USER` 
    * `ALGOSEC_TEST_PASSWORD`.
    
AlgoSec's Demo VMs default to `admin`/`algosec`, which is also used as a default, if you don't specify anything.

After you have configured the system under test, you can run the acceptance tests directly using:

```
pdk bundle exec rspec spec/acceptance
```

### Cutting a release

To cut a new release, from a current `master` checkout:

* Start the release branch with `git checkout -b release-prep`
* Execute the [Puppet Strings](https://puppet.com/docs/puppet/6.0/puppet_strings.html) rake task to update the [REFERENCE.md](https://github.com/algosec/algosec-puppet/blob/master/REFERENCE.md):

```
pdk bundle exec rake 'strings:generate[,,,,,REFERENCE.md,true]'
```

* Make sure that all PRs are tagged appropriately