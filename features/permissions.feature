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
        And I have added the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 1  | 001100   | REF01234         | Cash         | 2016       | 5000    | Barclays |
            | 2  | 002200   | REF56789         | Stock&Shares | 2017       | 10000   | HSBC     |
        And I have issued the participant b2b.isa.transfers.Provider#Barclays with the identity Barclays
        And I have issued the participant b2b.isa.transfers.Provider#HSBC with the identity HSBC

    Scenario: Barclays can read all of his owns assets
        When I use the identity Barclays
        Then I should have the following assets of type b2b.isa.transfers.ISA
            | id | sortCode | accountReference | type         | fiscalYear | balance | provider |
            | 1  | 001100   | REF01234         | Cash         | 2016       | 5000    | Barclays |
