'use strict';

/*
 * Copyright (C) 2018 Giuseppe Lobraico

 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const AdminConnection = require('composer-admin').AdminConnection;
const BusinessNetworkConnection = require('composer-client').BusinessNetworkConnection;
const BusinessNetworkDefinition = require('composer-common').BusinessNetworkDefinition;
const IdCard = require('composer-common').IdCard;
const MemoryCardStore = require('composer-common').MemoryCardStore;

const path = require('path');

require('chai').should();

const namespace = 'b2b.isa.transfers';
const mainAssetType = 'TransferRequest';

describe('#' + namespace, () => {
    // In-memory card store for testing so cards are not persisted to the file system
    const cardStore = new MemoryCardStore();
    let adminConnection;
    let businessNetworkConnection;
    let factory;

    before(() => {
        // Embedded connection used for local testing
        const connectionProfile = {
            name: 'embedded',
            type: 'embedded'
        };
        // Embedded connection does not need real credentials
        const credentials = {
            certificate: 'FAKE CERTIFICATE',
            privateKey: 'FAKE PRIVATE KEY'
        };

        // PeerAdmin identity used with the admin connection to deploy business networks
        const deployerMetadata = {
            version: 1,
            userName: 'PeerAdmin',
            roles: [ 'PeerAdmin', 'ChannelAdmin' ]
        };
        const deployerCard = new IdCard(deployerMetadata, connectionProfile);
        deployerCard.setCredentials(credentials);

        const deployerCardName = 'PeerAdmin';
        adminConnection = new AdminConnection({ cardStore: cardStore });

        return adminConnection.importCard(deployerCardName, deployerCard).then(() => {
            return adminConnection.connect(deployerCardName);
        });
    });

    beforeEach(() => {
        businessNetworkConnection = new BusinessNetworkConnection({ cardStore: cardStore });

        const adminUserName = 'admin';
        let adminCardName;
        let businessNetworkDefinition;

        return BusinessNetworkDefinition.fromDirectory(path.resolve(__dirname, '..')).then(definition => {
            businessNetworkDefinition = definition;
            // Install the Composer runtime for the new business network
            return adminConnection.install(businessNetworkDefinition.getName());
        }).then(() => {
            // Start the business network and configure an network admin identity
            const startOptions = {
                networkAdmins: [
                    {
                        userName: adminUserName,
                        enrollmentSecret: 'adminpw'
                    }
                ]
            };
            return adminConnection.start(businessNetworkDefinition, startOptions);
        }).then(adminCards => {
            // Import the network admin identity for us to use
            adminCardName = `${adminUserName}@${businessNetworkDefinition.getName()}`;
            return adminConnection.importCard(adminCardName, adminCards.get(adminUserName));
        }).then(() => {
            // Connect to the business network using the network admin identity
            return businessNetworkConnection.connect(adminCardName);
        }).then(() => {
            factory = businessNetworkConnection.getBusinessNetwork().getFactory();
        });
    });

    describe('validateRequest()', () => {
        let validateRequestTx;
        let submitter;
        let recipient;
        let transferRequest;
        let isa;
        let assetRegistry;

        beforeEach(() => {
            submitter = factory.newResource(namespace, 'Provider', 'Provider_1');
            submitter.address = '1 Fake Address';

            recipient = factory.newResource(namespace, 'Provider', 'Provider_2');
            recipient.address = '2 Fake Address';

            transferRequest = factory.newResource(namespace, mainAssetType, 'TransferRequest_1');
            transferRequest.sortCode = '000000';
            transferRequest.accountReference = 'REF0123456789';
            transferRequest.fiscalYear = 2017;
            transferRequest.amountRequested = 5000;
            transferRequest.state = 'CREATED';
            transferRequest.submitter = factory.newRelationship(namespace, 'Provider', submitter.$identifier);
            transferRequest.recipient = factory.newRelationship(namespace, 'Provider', recipient.$identifier);

            validateRequestTx = factory.newTransaction(namespace, 'ValidateRequest');
            validateRequestTx.transferRequest = factory.newRelationship(namespace, mainAssetType, transferRequest.$identifier);
        });

        describe('when there is no ISA account matching the request', () => {
            it('rejects the request', () => {
                return businessNetworkConnection.getAssetRegistry(namespace + '.' + mainAssetType).then(registry => {
                    assetRegistry = registry;
                    return registry.add(transferRequest);
                }).then(() => {
                    return businessNetworkConnection.getParticipantRegistry(namespace + '.Provider');
                }).then(providerRegistry => {
                    return providerRegistry.addAll([submitter, recipient]);
                }).then(() => {
                    return businessNetworkConnection.submitTransaction(validateRequestTx);
                }).then(registry => {
                    return assetRegistry.get(transferRequest.$identifier);
                }).then(function(newTransferRequest) {
                    newTransferRequest.state.should.equal('REJECTED');
                    newTransferRequest.comment.should.equal('ISA not found');
                });
            });
        });

        describe('when there is a valid ISA account matching the request', () => {
            beforeEach(() => {
                isa = factory.newResource(namespace, 'ISA', 'ISA_1');
                isa.sortCode = transferRequest.sortCode;
                isa.accountReference = transferRequest.accountReference;
                isa.type = transferRequest.type;
                isa.fiscalYear = transferRequest.fiscalYear;
                isa.balance = transferRequest.amountRequested;
                isa.provider = factory.newRelationship(namespace, 'Provider', recipient.$identifier);

                transferRequest.isa = factory.newRelationship(namespace, 'ISA', isa.$identifier);
            });

            describe('when the fiscal year is not matching the one in the request', () => {
                beforeEach(() => {
                    isa.fiscalYear = 2016;
                });

                it('rejects the request', () => {
                    return businessNetworkConnection.getAssetRegistry(namespace + '.ISA').then(registry => {
                        return registry.add(isa);
                    }).then(() => {
                        return businessNetworkConnection.getAssetRegistry(namespace + '.' + mainAssetType).then(registry => {
                            assetRegistry = registry;
                            return registry.add(transferRequest);
                        });
                    }).then(() => {
                        return businessNetworkConnection.getParticipantRegistry(namespace + '.Provider');
                    }).then(providerRegistry => {
                        return providerRegistry.addAll([submitter, recipient]);
                    }).then(() => {
                        return businessNetworkConnection.submitTransaction(validateRequestTx);
                    }).then(registry => {
                        return assetRegistry.get(transferRequest.$identifier);
                    }).then(function(newTransferRequest) {
                        newTransferRequest.state.should.equal('REJECTED');
                        newTransferRequest.comment.should.equal('Wrong ISA fiscal year');
                    });
                });
            });

            describe('when there is not sufficient balance to transfer out', () => {
                beforeEach(() => {
                    isa.balance = 1;
                });

                it('rejects the request', () => {
                    return businessNetworkConnection.getAssetRegistry(namespace + '.ISA').then(registry => {
                        return registry.add(isa);
                    }).then(() => {
                        return businessNetworkConnection.getAssetRegistry(namespace + '.' + mainAssetType).then(registry => {
                            assetRegistry = registry;
                            return registry.add(transferRequest);
                        });
                    }).then(() => {
                        return businessNetworkConnection.getParticipantRegistry(namespace + '.Provider');
                    }).then(providerRegistry => {
                        return providerRegistry.addAll([submitter, recipient]);
                    }).then(() => {
                        return businessNetworkConnection.submitTransaction(validateRequestTx);
                    }).then(registry => {
                        return assetRegistry.get(transferRequest.$identifier);
                    }).then(function(newTransferRequest) {
                        newTransferRequest.state.should.equal('REJECTED');
                        newTransferRequest.comment.should.equal('ISA insufficient balance');
                    });
                });
            });

            describe('when the request is valid', () => {
                it('accepts the requests', () => {
                    return businessNetworkConnection.getAssetRegistry(namespace + '.ISA').then(registry => {
                        return registry.add(isa);
                    }).then(() => {
                        return businessNetworkConnection.getAssetRegistry(namespace + '.' + mainAssetType).then(registry => {
                            assetRegistry = registry;
                            return registry.add(transferRequest);
                        });
                    }).then(() => {
                        return businessNetworkConnection.getParticipantRegistry(namespace + '.Provider');
                    }).then(providerRegistry => {
                        return providerRegistry.addAll([submitter, recipient]);
                    }).then(() => {
                        return businessNetworkConnection.submitTransaction(validateRequestTx);
                    }).then(registry => {
                        return assetRegistry.get(transferRequest.$identifier);
                    }).then(function(newTransferRequest) {
                        newTransferRequest.state.should.equal('ACCEPTED');
                        newTransferRequest.comment.should.equal('Request has been automatically accepted');
                    });
                });
            });
        });
    });

    describe('sendMoney()', () => {
        let sendMoneyTx;
        let submitter;
        let recipient;
        let transferRequest;
        let isa;
        let assetRegistry;

        beforeEach(() => {
            submitter = factory.newResource(namespace, 'Provider', 'Provider_1');
            submitter.address = '1 Fake Address';

            recipient = factory.newResource(namespace, 'Provider', 'Provider_2');
            recipient.address = '2 Fake Address';

            transferRequest = factory.newResource(namespace, mainAssetType, 'TransferRequest_1');
            transferRequest.sortCode = '000000';
            transferRequest.accountReference = 'REF0123456789';
            transferRequest.fiscalYear = 2017;
            transferRequest.amountRequested = 5000;
            transferRequest.state = 'ACCEPTED';
            transferRequest.submitter = factory.newRelationship(namespace, 'Provider', submitter.$identifier);
            transferRequest.recipient = factory.newRelationship(namespace, 'Provider', recipient.$identifier);

            isa = factory.newResource(namespace, 'ISA', 'ISA_1');
            isa.sortCode = transferRequest.sortCode;
            isa.accountReference = transferRequest.accountReference;
            isa.type = transferRequest.type;
            isa.fiscalYear = transferRequest.fiscalYear;
            isa.balance = transferRequest.amountRequested;
            isa.provider = factory.newRelationship(namespace, 'Provider', recipient.$identifier);

            transferRequest.isa = factory.newRelationship(namespace, 'ISA', isa.$identifier);

            sendMoneyTx = factory.newTransaction(namespace, 'SendMoney');
            sendMoneyTx.transferRequest = factory.newRelationship(namespace, mainAssetType, transferRequest.$identifier);
            sendMoneyTx.amount = 4000;
            sendMoneyTx.comment = 'Amount sent by cheque';
        });

        it('moves the balance out of the existing ISA and updates the transfer request', () => {
            return businessNetworkConnection.getAssetRegistry(namespace + '.ISA').then(registry => {
                return registry.add(isa);
            }).then(() => {
                return businessNetworkConnection.getAssetRegistry(namespace + '.' + mainAssetType).then(registry => {
                    assetRegistry = registry;
                    return registry.add(transferRequest);
                });
            }).then(() => {
                return businessNetworkConnection.getParticipantRegistry(namespace + '.Provider');
            }).then(providerRegistry => {
                return providerRegistry.addAll([submitter, recipient]);
            }).then(() => {
                return businessNetworkConnection.submitTransaction(sendMoneyTx);
            }).then(registry => {
                return assetRegistry.get(transferRequest.$identifier);
            }).then(function(newTransferRequest) {
                newTransferRequest.amountSent = sendMoneyTx.amount;
                newTransferRequest.state.should.equal('MONEY_SENT');
                newTransferRequest.comment.should.equal(sendMoneyTx.comment);
                newTransferRequest.isa.balance = newTransferRequest.isa.balance - sendMoneyTx.amount;
            });
        });
    });

    describe('distributeMoney()', () => {
        let distributeMoneyTx;
        let submitter;
        let recipient;
        let transferRequest;
        let destinationIsa;
        let assetRegistry;

        beforeEach(() => {
            submitter = factory.newResource(namespace, 'Provider', 'Provider_1');
            submitter.address = '1 Fake Address';

            recipient = factory.newResource(namespace, 'Provider', 'Provider_2');
            recipient.address = '2 Fake Address';

            transferRequest = factory.newResource(namespace, mainAssetType, 'TransferRequest_1');
            transferRequest.sortCode = '000000';
            transferRequest.accountReference = 'REF0123456789';
            transferRequest.fiscalYear = 2017;
            transferRequest.amountRequested = 5000;
            transferRequest.amountSent = 4000;
            transferRequest.state = 'MONEY_SENT';
            transferRequest.submitter = factory.newRelationship(namespace, 'Provider', submitter.$identifier);
            transferRequest.recipient = factory.newRelationship(namespace, 'Provider', recipient.$identifier);

            destinationIsa = factory.newResource(namespace, 'ISA', 'ISA_2');
            destinationIsa.sortCode = '888888';
            destinationIsa.accountReference = '9999999';
            destinationIsa.type = 'Stock&Shares';
            destinationIsa.fiscalYear = 2017;
            destinationIsa.balance = 10000;
            destinationIsa.provider = factory.newRelationship(namespace, 'Provider', submitter.$identifier);

            distributeMoneyTx = factory.newTransaction(namespace, 'DistributeMoney');
            distributeMoneyTx.transferRequest = factory.newRelationship(namespace, mainAssetType, transferRequest.$identifier);
            distributeMoneyTx.amount = 3900;
            distributeMoneyTx.comment = 'Amount received partially - 3900 out of 4000';
            distributeMoneyTx.isa = factory.newRelationship(namespace, 'ISA', destinationIsa.$identifier);
        });

        it('adds the the balance to a new destination ISA and updates the transfer request', () => {
            return businessNetworkConnection.getAssetRegistry(namespace + '.ISA').then(registry => {
                return registry.add(destinationIsa);
            }).then(() => {
                return businessNetworkConnection.getAssetRegistry(namespace + '.' + mainAssetType).then(registry => {
                    assetRegistry = registry;
                    return registry.add(transferRequest);
                });
            }).then(() => {
                return businessNetworkConnection.getParticipantRegistry(namespace + '.Provider');
            }).then(providerRegistry => {
                return providerRegistry.addAll([submitter, recipient]);
            }).then(() => {
                return businessNetworkConnection.submitTransaction(distributeMoneyTx);
            }).then(registry => {
                return assetRegistry.get(transferRequest.$identifier);
            }).then(function(newTransferRequest) {
                newTransferRequest.amountReceived = distributeMoneyTx.amount;
                newTransferRequest.state.should.equal('MONEY_DISTRIBUTED');
                newTransferRequest.comment.should.equal(distributeMoneyTx.comment);
                destinationIsa.balance = destinationIsa.balance + distributeMoneyTx.amount;
            });
        });
    });
});
