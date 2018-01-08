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

/**
 * @param {b2b.isa.transfers.ValidateRequest} tx
 * @transaction
 */
function validateRequest(tx) {
    var transferRequest = tx.transferRequest;

    if (transferRequest.state !== 'CREATED') {
        throw new Error('Cannot validate a request that has not just been created');
    }

    if (transferRequest.amountRequested <= 0 ||
      transferRequest.amountSent !== 0.0 ||
      transferRequest.amountReceived !== 0.0) {
        throw new Error('Something is horribly wrong with some amounts in the request');
    }

    return query('findISABySortCodeAndAccountNumber',
        { sortCode: transferRequest.sortCode, accountNumber: transferRequest.accountNumber }).then(function(isas) {
        var isa = isas[0];
        var rejectReason;

        if (!isa) {
            rejectReason = 'ISA not found';
        } else {
            if (isa.fiscalYear !== transferRequest.fiscalYear) {
                rejectReason = 'Wrong ISA fiscal year';
            } else if (isa.balance < transferRequest.amountRequested) {
                rejectReason = 'ISA insufficient balance';
            } else {
                transferRequest.isa = isa;
            }
        }

        if (rejectReason) {
            transferRequest.state = 'REJECTED';
            transferRequest.comment = rejectReason;
        } else {
            transferRequest.state = 'ACCEPTED';
            transferRequest.comment = 'Request has been automatically accepted';
        }
    }).then(function() {
        getAssetRegistry('b2b.isa.transfers.TransferRequest').then(function(transferRequestRegistry) {
            return transferRequestRegistry.update(transferRequest);
        });
    }).catch(function(error) {
        throw new Error(error);
    });
}

/**
 * @param {b2b.isa.transfers.SendMoney} tx
 * @transaction
 */
function sendMoney(tx) {
    var transferRequest = tx.transferRequest;
    var isa = transferRequest.isa;

    if (transferRequest.state !== 'ACCEPTED') {
        throw new Error('Cannot send money for a transfer request that has not been accepted.');
    }

    if (tx.amount <= 0) {
        throw new Error('Amount must be a positive number.');
    }

    if (isa.balance < tx.amount) {
        throw new Error('Amount must be less or equal to the existing ISA balance.');
    }

    transferRequest.state = 'MONEY_SENT';
    transferRequest.comment = tx.comment;
    transferRequest.amountSent = tx.amount;

    isa.balance -= transferRequest.amountSent;

    return getAssetRegistry('b2b.isa.transfers.TransferRequest').then(function(transferRequestRegistry) {
        return transferRequestRegistry.update(transferRequest);
    }).then(function() {
        return getAssetRegistry('b2b.isa.transfers.ISA').then(function(ISARegistry) {
            return ISARegistry.update(isa);
        });
    });
}

/**
 * @param {b2b.isa.transfers.DistributeMoney} tx
 * @transaction
 */
function distributeMoney(tx) {
    var ISA_ALLOWANCE = 20000; // using a `var` because the playground web editor does not understand `const`. sigh
    var transferRequest = tx.transferRequest;
    var destinationIsa = tx.isa;

    if (transferRequest.state !== 'MONEY_SENT') {
        throw new Error('Cannot distribute money for a transfer request if money has not been sent.');
    }

    transferRequest.state = 'MONEY_DISTRIBUTED';
    transferRequest.comment = tx.comment;
    transferRequest.amountReceived = tx.amount;

    destinationIsa.balance += transferRequest.amountReceived;

    if (destinationIsa.balance > ISA_ALLOWANCE) {
        throw new Error('Out of ISA allowance');
    }

    return getAssetRegistry('b2b.isa.transfers.TransferRequest').then(function(transferRequestRegistry) {
        return transferRequestRegistry.update(transferRequest);
    }).then(function() {
        return getAssetRegistry('b2b.isa.transfers.ISA').then(function(ISARegistry) {
            return ISARegistry.update(destinationIsa);
        });
    });
}
