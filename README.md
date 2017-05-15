# Puppet Lumogon

#### Table of Contents

1. [Overview](#overview)
1. [Example](#example)
1. [Face](#face)

## Overview

Use Lumogon for Puppet data. Queries PuppetDB for latest report.

## Example

```
[root@puppet ~]# puppet lumogon reports $(puppet config print certname)
http://reporter.app.lumogon.com/vBgvtQyeTqFc2SXB2QFDrGVRLmbY-emGKICqJYRR6AG=
```

## Face

```
USAGE: puppet lumogon <action>

Post puppet report data to Lumogon

OPTIONS:
  --render-as FORMAT             - The rendering format to use.
  --verbose                      - Whether to log verbosely.
  --debug                        - Whether to log debug information.

ACTIONS:
  facts      Upload a node's facts to Lumogon
  reports    Upload a node's latest report to Lumogon

See 'puppet man lumogon' or 'man puppet-lumogon' for full help.
```

## Maintainers

This repositority is largely the work of some Puppet community members.
It is not officially maintained by Puppet, or any individual in
particular. Issues should be opened in Github. Questions should be directed
at the individuals responsible for committing that particular code.
