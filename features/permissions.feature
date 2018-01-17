#
# Copyright (C) 2018 Giuseppe Lobraico

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Feature: Permissions

    Background:
        Given I have deployed the business network definition ..
        And I have added the following participants of type b2b.isa.transfers.Provider
            | name     | address       |
            | Barclays | 1 Fake Street |
            | HSBC     | 2 Fake Street |
            | Lloyds   | 3 Fake Street |
        And I have added the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 1  | 130001   | BCLYS0001        | Cash         | 2016       | 5000    | Barclays |
            | 2  | 130002   | BCLYS0002        | Stock&Shares | 2017       | 10000   | Barclays |
            | 3  | 490001   | HSBC00001        | Stock&Shares | 2017       | 10000   | HSBC     |
            | 4  | 390001   | LLYODS001        | Cash         | 2018       | 15000   | Lloyds   |
        And I have added the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | HSBC      |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 5000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |
            | 3  | 390001   | LLYODS001        | Cash         | 2018       | 15000           | 0          | 0              | CREATED    | Request created | -   | HSBC      | Lloyds    |
            | 4  | 390002   | LLYODS002        | Cash         | 2018       | 7000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | Lloyds    |
        And I have issued the participant b2b.isa.transfers.Provider#Barclays with the identity Barclays
        And I have issued the participant b2b.isa.transfers.Provider#HSBC with the identity HSBC

    Scenario: Barclays can read ISAs that he owns
        When I use the identity Barclays
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 1  | 130001   | BCLYS0001        | Cash         | 2016       | 5000    | Barclays |
            | 2  | 130002   | BCLYS0002        | Stock&Shares | 2017       | 10000   | Barclays |

    Scenario: HSBC can read ISAs that he owns
        When I use the identity HSBC
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 3  | 490001   | HSBC00001        | Stock&Shares | 2017       | 10000   | HSBC     |

    Scenario: Barclays can add ISAs that he owns
        When I use the identity Barclays
        And I add the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 5  | 130004   | BCLYS0004        | Stock&Shares | 2017       | 90000   | Barclays |
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 5  | 130004   | BCLYS0004        | Stock&Shares | 2017       | 90000   | Barclays |

    Scenario: Barclays cannot add ISAs that HSBC owns
        When I use the identity Barclays
        And I add the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 5  | 490002   | HSBC00002        | Cash         | 2017       | 1000    | HSBC     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: HSBC can add ISAs that he owns
        When I use the identity HSBC
        And I add the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 5  | 490003   | HSBC00003        | Cash         | 2017       | 1000    | HSBC     |
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 5  | 490003   | HSBC00003        | Cash         | 2017       | 1000    | HSBC     |

    Scenario: HSBC cannot add ISAs that Barclays owns
        When I use the identity Barclays
        And I add the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 5  | 490004   | HSBC00004        | Cash         | 2017       | 1000    | HSBC     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Barclays can update ISAs that he owns
        When I use the identity Barclays
        And I update the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 1  | 130001   | BCLYS0001        | Cash         | 2016       | 0       | Barclays |
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 1  | 130001   | BCLYS0001        | Cash         | 2016       | 0       | Barclays |

    Scenario: Barclays cannot update ISAs that HSBC owns
        When I use the identity Barclays
        And I update the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 3  | 490001   | HSBC00001        | Stock&Shares | 2017       | 0       | HSBC     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: HSBC can update ISAs that he owns
        When I use the identity HSBC
        And I update the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 3  | 490001   | HSBC00001        | Stock&Shares | 2017       | 0       | HSBC     |
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 3  | 490001   | HSBC00001        | Stock&Shares | 2017       | 0       | HSBC     |

    Scenario: Barclays cannot update ISAs that HSBC owns
        When I use the identity Barclays
        And I update the following asset of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 3  | 490001   | HSBC00001        | Stock&Shares | 2017       | 100     | HSBC     |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Barclays can remove ISAs that he owns
        When I use the identity Barclays
        And I remove the following asset of type b2b.isa.transfers.ISA
            | id |
            | 1  |
        Then I should not have the following assets of type b2b.isa.transfers.ISA
            | id |
            | 1  |

    Scenario: Barclays cannot remove ISAs that HSBC owns
        When I use the identity Barclays
        And I remove the following asset of type b2b.isa.transfers.ISA
            | id |
            | 3  |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: HSBC can remove ISAs that he owns
        When I use the identity HSBC
        And I remove the following asset of type b2b.isa.transfers.ISA
            | id |
            | 3  |
        Then I should not have the following assets of type b2b.isa.transfers.ISA
            | id |
            | 3  |

    Scenario: HSBC cannot remove ISAs that Barlcays owns
        When I use the identity HSBC
        And I remove the following asset of type b2b.isa.transfers.ISA
            | id |
            | 1  |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Barclays can read TransferRequests that he submitted
        When I use the identity Barclays
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | HSBC      |

    Scenario: Barclays can read TransferRequests that HSBC submitted to him
        When I use the identity Barclays
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 5000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |

    Scenario: Barclays cannot read TransferRequests that HSBC submitted to Lloyds
        When I use the identity Barclays
        Then I should not have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 3  | 390001   | LLYODS001        | Cash         | 2018       | 15000           | 0          | 0              | CREATED    | Request created | -   | HSBC      | Lloyds    |

    Scenario: HSBC can read TransferRequests that he submitted
        When I use the identity HSBC
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 5000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |

    Scenario: HSBC can read TransferRequests that Barclays submitted to him
        When I use the identity HSBC
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | HSBC      |

    Scenario: HSBC cannot read TransferRequests that Barclays submitted to Lloyds
        When I use the identity HSBC
        Then I should not have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 4  | 390002   | LLYODS002        | Cash         | 2018       | 7000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | Lloyds    |

    Scenario: Barclays can add TransferRequests that he submitted
        When I use the identity Barclays
        And I add the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 5  | 490001   | HSBC00001        | Stock&Shares | 2017       | 2000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | HSBC      |
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 5  | 490001   | HSBC00001        | Stock&Shares | 2017       | 2000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | HSBC      |

    Scenario: Barclays cannot add TransferRequests submitted by HSBC
        When I use the identity Barclays
        And I add the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 5  | 130001   | BCLYS0001        | Cash         | 2016       | 5000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: HSBC can add TransferRequests that he submitted
        When I use the identity HSBC
        And I add the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 5  | 130002   | BCLYS0002        | Cash         | 2016       | 5000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 5  | 130002   | BCLYS0002        | Cash         | 2016       | 5000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |

    Scenario: HSBC cannot add TransferRequests that Barclays submitted
        When I use the identity HSBC
        And I add the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 5  | 490002   | HSBC00002        | Stock&Shares | 2017       | 7000            | 0          | 0              | CREATED    | Request created | -   | Barclays  | HSBC      |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Barclays can update TransferRequests that he submitted
        When I use the identity Barclays
        And I update the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 8000.01    | 0              | MONEY_SENT | Sent by wire    | -   | Barclays  | HSBC      |
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 8000.01    | 0              | MONEY_SENT | Sent by wire    | -   | Barclays  | HSBC      |

    Scenario: Barclays can update TransferRequests that HSBC submitted to him
        When I use the identity Barclays
        And I update the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 5000            | 4999.99    | 0              | MONEY_SENT | Sent by wire    | -   | HSBC      | Barclays  |
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 5000            | 4999.99    | 0              | MONEY_SENT | Sent by wire    | -   | HSBC      | Barclays  |

    Scenario: Barclays cannot update TransferRequests that HSBC submitted to Lloyds
        When I use the identity Barclays
        And I update the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 3  | 390001   | LLYODS001        | Cash         | 2018       | 15000           | 15000      | 0              | MONEY_SENT | Sent by wire    | -   | HSBC      | Lloyds    |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: HSBC can update TransferRequests that he submitted
        When I use the identity HSBC
        And I update the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 8000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 2  | 130001   | BCLYS0001        | Cash         | 2016       | 8000            | 0          | 0              | CREATED    | Request created | -   | HSBC      | Barclays  |

    Scenario: HSBC can update TransferRequests that Barclays submitted to him
        When I use the identity HSBC
        And I update the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 0          | 0              | REJECTED   | Bad request     | -   | Barclays  | HSBC      |
        Then I should have the following assets of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 1  | 490001   | HSBC00001        | Stock&Shares | 2017       | 8000            | 0          | 0              | REJECTED   | Bad request     | -   | Barclays  | HSBC      |

    Scenario: HSBC cannot update TransferRequests that Barclays submitted to Lloyds
        When I use the identity HSBC
        And I update the following asset of type b2b.isa.transfers.TransferRequest
            | id | sortCode | accountReference | type         | fiscalYear | amountRequested | amountSent | amountReceived | state      | comment         | isa | submitter | recipient |
            | 4  | 390002   | LLYODS002        | Cash         | 2018       | 7000            | 0          | 0              | REJECTED   | Bad request     | -   | Barclays  | Lloyds    |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: Barclays can remove TransferRequests that he submitted
        When I use the identity Barclays
        And I remove the following asset of type b2b.isa.transfers.TransferRequest
            | id |
            | 1  |
        Then I should not have the following assets of type b2b.isa.transfers.TransferRequest
            | id |
            | 1  |

    Scenario: Barclays cannot remove TransferRequests that HSBC submitted
        When I use the identity Barclays
        And I remove the following asset of type b2b.isa.transfers.TransferRequest
            | id |
            | 2  |
        Then I should get an error matching /does not have .* access to resource/

    Scenario: HSBC can remove TransferRequests that he submitted
        When I use the identity HSBC
        And I remove the following asset of type b2b.isa.transfers.TransferRequest
            | id |
            | 2  |
        Then I should not have the following assets of type b2b.isa.transfers.TransferRequest
            | id |
            | 2  |

    Scenario: HSBC cannot remove TransferRequests that Barlcays submitted
        When I use the identity HSBC
        And I remove the following asset of type b2b.isa.transfers.TransferRequest
            | id |
            | 1  |
        Then I should get an error matching /does not have .* access to resource/
