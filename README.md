# ISA Transfer Authority Network

This is a *permissioned* blockchain network joinable by ISA providers (UK) and, potentially, regulators to quickly run investigations.

A meticulous ACL defines what resource are accessible, with what permission(s) and by which peers exaclty.

## Network definition

**Participants**: `Regulator` `Provider`

**Assets**: `ISA` `TransferRequest`

**Transactions**: `ValidateRequest` `SendMoney` `DistributeMoney`

## Prerequisites

[Hyperledger Composer](https://hyperledger.github.io/composer/) is up and running.

Please note that this is a project built on top of [Hyperledger Fabric v1.0](https://www.hyperledger.org/projects/fabric).

## Quick setup
### 1. Generate the business network

```
cd isa-transfers-network && \
  composer archive create -t dir -n .
```

### 2. Deploy the business network

Import the generated *banana* file into the [Hyperledger local playground](https://hyperledger.github.io/composer/installing/using-playground-locally.html).

### 3. Play in the playground

`\o/`

## Why this complicated stuff

- I ~~like~~ love Hyperledged Fabric distributed ledger technology
- Blockchain is not just about mining Bitcoin ($$$)
- Ethereum is permissionless (*open* != *safe*)
- [ISA transfer procedure looks so 90s](https://www.gov.uk/individual-savings-accounts/transferring-your-isa)

## Tests

Written using [mocha](https://github.com/mochajs/mocha), to be refactored asap.

```
  #b2b.isa.transfers
    validateRequest()
      when there is no ISA account matching the request
        ✓ rejects the request (89ms)
      when there is a valid ISA account matching the request
        when the fiscal year is not matching the one in the request
          ✓ rejects the request (72ms)
        when there is not sufficient balance to transfer out
          ✓ rejects the request (76ms)
        when the request is valid
          ✓ accepts the requests (67ms)
    sendMoney()
      ✓ moves the balance out of the existing ISA and updates the transfer request (58ms)
    distributeMoney()
      ✓ adds the the balance to a new destination ISA and updates the transfer request (65ms)


  6 passing (2s)
```

## License: Apache 2.0

Copyright (C) 2018 Giuseppe Lobraico

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
