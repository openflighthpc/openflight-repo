# OpenFlight Repository Manager

A repository manager for OpenFlight RPM and DEB repositories.

## Overview

This is a tool that helps publish and manage the lifecycle of RPMs and
DEBs built using the builders in the openflight-omnibus-builder
repository.

## Installation

```
git clone https://github.com/openflighthpc/openflight-repo
cd openflight-repo
bundle install --path=vendor
```

## Configuration

Create configuration profiles in `etc/<profile>.yml` files. The
shipped profile works with the OpenFlight repos.

## Operation

```
bin/repo --help
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

OpenFlight Repository Manager is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
