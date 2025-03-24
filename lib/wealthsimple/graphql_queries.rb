# typed: strict
# frozen_string_literal: true

module WealthSimple
  class GraphqlQueries
    class << self
      sig { returns(String) }
      def fetch_all_account_financials
        <<~GRAPHQL
          query FetchAllAccountFinancials($identityId: ID!, $startDate: Date, $pageSize: Int = 25, $cursor: String) {
            identity(id: $identityId) {
              id
              ...AllAccountFinancials
              __typename
            }
          }

          fragment AllAccountFinancials on Identity {
            accounts(filter: {}, first: $pageSize, after: $cursor) {
              pageInfo {
                hasNextPage
                endCursor
                __typename
              }
              edges {
                cursor
                node {
                  ...AccountWithFinancials
                  __typename
                }
                __typename
              }
              __typename
            }
            __typename
          }

          fragment AccountWithFinancials on Account {
            ...AccountWithLink
            ...AccountFinancials
            __typename
          }

          fragment AccountWithLink on Account {
            ...Account
            linkedAccount {
              ...Account
              __typename
            }
            __typename
          }

          fragment Account on Account {
            ...AccountCore
            custodianAccounts {
              ...CustodianAccount
              __typename
            }
            __typename
          }

          fragment AccountCore on Account {
            id
            archivedAt
            branch
            closedAt
            createdAt
            cacheExpiredAt
            currency
            requiredIdentityVerification
            unifiedAccountType
            supportedCurrencies
            nickname
            status
            accountOwnerConfiguration
            accountFeatures {
              ...AccountFeature
              __typename
            }
            accountOwners {
              ...AccountOwner
              __typename
            }
            type
            __typename
          }

          fragment AccountFeature on AccountFeature {
            name
            enabled
            __typename
          }

          fragment AccountOwner on AccountOwner {
            accountId
            identityId
            accountNickname
            clientCanonicalId
            accountOpeningAgreementsSigned
            name
            email
            ownershipType
            activeInvitation {
              ...AccountOwnerInvitation
              __typename
            }
            sentInvitations {
              ...AccountOwnerInvitation
              __typename
            }
            __typename
          }

          fragment AccountOwnerInvitation on AccountOwnerInvitation {
            id
            createdAt
            inviteeName
            inviteeEmail
            inviterName
            inviterEmail
            updatedAt
            sentAt
            status
            __typename
          }

          fragment CustodianAccount on CustodianAccount {
            id
            branch
            custodian
            status
            updatedAt
            __typename
          }

          fragment AccountFinancials on Account {
            id
            custodianAccounts {
              id
              branch
              financials {
                current {
                  ...CustodianAccountCurrentFinancialValues
                  __typename
                }
                __typename
              }
              __typename
            }
            financials {
              currentCombined {
                id
                ...AccountCurrentFinancials
                __typename
              }
              __typename
            }
            __typename
          }

          fragment CustodianAccountCurrentFinancialValues on CustodianAccountCurrentFinancialValues {
            deposits {
              ...Money
              __typename
            }
            earnings {
              ...Money
              __typename
            }
            netDeposits {
              ...Money
              __typename
            }
            netLiquidationValue {
              ...Money
              __typename
            }
            withdrawals {
              ...Money
              __typename
            }
            __typename
          }

          fragment Money on Money {
            amount
            cents
            currency
            __typename
          }

          fragment AccountCurrentFinancials on AccountCurrentFinancials {
            id
            netLiquidationValue {
              ...Money
              __typename
            }
            netDeposits {
              ...Money
              __typename
            }
            simpleReturns(referenceDate: $startDate) {
              ...SimpleReturns
              __typename
            }
            totalDeposits {
              ...Money
              __typename
            }
            totalWithdrawals {
              ...Money
              __typename
            }
            __typename
          }

          fragment SimpleReturns on SimpleReturns {
            amount {
              ...Money
              __typename
            }
            asOf
            rate
            referenceDate
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_activity_feed_items
        <<~GRAPHQL
          query FetchActivityFeedItems($first: Int, $cursor: Cursor, $condition: ActivityCondition, $orderBy: [ActivitiesOrderBy!] = OCCURRED_AT_DESC) {
            activityFeedItems(
              first: $first
              after: $cursor
              condition: $condition
              orderBy: $orderBy
            ) {
              edges {
                node {
                  ...Activity
                  __typename
                }
                __typename
              }
              pageInfo {
                hasNextPage
                endCursor
                __typename
              }
              __typename
            }
          }

          fragment Activity on ActivityFeedItem {
            accountId
            aftOriginatorName
            aftTransactionCategory
            aftTransactionType
            amount
            amountSign
            assetQuantity
            assetSymbol
            canonicalId
            currency
            eTransferEmail
            eTransferName
            externalCanonicalId
            identityId
            institutionName
            occurredAt
            p2pHandle
            p2pMessage
            spendMerchant
            securityId
            billPayCompanyName
            billPayPayeeNickname
            redactedExternalAccountNumber
            opposingAccountId
            status
            subType
            type
            strikePrice
            contractType
            expiryDate
            chequeNumber
            provisionalCreditAmount
            primaryBlocker
            interestRate
            frequency
            counterAssetSymbol
            rewardProgram
            counterPartyCurrency
            counterPartyCurrencyAmount
            counterPartyName
            fxRate
            fees
            reference
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_security_search_result
        <<~GRAPHQL
          query FetchSecuritySearchResult($query: String!) {
            securitySearch(input: {query: $query}) {
              results {
                ...SecuritySearchResult
                __typename
              }
              __typename
            }
          }

          fragment SecuritySearchResult on Security {
            id
            buyable
            status
            stock {
              symbol
              name
              primaryExchange
              __typename
            }
            securityGroups {
              id
              name
              __typename
            }
            quoteV2 {
              ... on EquityQuote {
                marketStatus
                __typename
              }
              __typename
            }
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_security_historical_quotes
        <<~GRAPHQL
          query FetchSecurityHistoricalQuotes($id: ID!, $timerange: String! = "1d") {
            security(id: $id) {
              id
              historicalQuotes(timeRange: $timerange) {
                ...HistoricalQuote
                __typename
              }
              __typename
            }
          }

          fragment HistoricalQuote on HistoricalQuote {
            adjustedPrice
            currency
            date
            securityId
            time
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_accounts_with_balance
        <<~GRAPHQL
          query FetchAccountsWithBalance($ids: [String!]!, $type: BalanceType!) {
            accounts(ids: $ids) {
              ...AccountWithBalance
              __typename
            }
          }

          fragment AccountWithBalance on Account {
            id
            custodianAccounts {
              id
              financials {
                ... on CustodianAccountFinancialsSo {
                  balance(type: $type) {
                    ...Balance
                    __typename
                  }
                  __typename
                }
                __typename
              }
              __typename
            }
            __typename
          }

          fragment Balance on Balance {
            quantity
            securityId
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_security_market_data
        <<~GRAPHQL
          query FetchSecurityMarketData($id: ID!) {
            security(id: $id) {
              id
              ...SecurityMarketData
              __typename
            }
          }

          fragment SecurityMarketData on Security {
            id
            allowedOrderSubtypes
            marginRates {
              ...MarginRates
              __typename
            }
            fundamentals {
              avgVolume
              high52Week
              low52Week
              yield
              peRatio
              marketCap
              currency
              description
              __typename
            }
            quote {
              bid
              ask
              open
              high
              low
              volume
              askSize
              bidSize
              last
              lastSize
              quotedAsOf
              quoteDate
              amount
              previousClose
              __typename
            }
            stock {
              primaryExchange
              primaryMic
              name
              symbol
              __typename
            }
            __typename
          }

          fragment MarginRates on MarginRates {
            clientMarginRate
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_funds_transfer
        <<~GRAPHQL
          query FetchFundsTransfer($id: ID!) {
            fundsTransfer: funds_transfer(id: $id, include_cancelled: true) {
              ...FundsTransfer
              __typename
            }
          }

          fragment FundsTransfer on FundsTransfer {
            id
            status
            cancellable
            rejectReason: reject_reason
            schedule {
              id
              __typename
            }
            source {
              ...BankAccountOwner
              __typename
            }
            destination {
              ...BankAccountOwner
              __typename
            }
            __typename
          }

          fragment BankAccountOwner on BankAccountOwner {
            bankAccount: bank_account {
              ...BankAccount
              __typename
            }
            __typename
          }

          fragment BankAccount on BankAccount {
            id
            accountName: account_name
            corporate
            createdAt: created_at
            currency
            institutionName: institution_name
            jurisdiction
            nickname
            type
            updatedAt: updated_at
            verificationDocuments: verification_documents {
              ...BankVerificationDocument
              __typename
            }
            verifications {
              ...BankAccountVerification
              __typename
            }
            ...CaBankAccount
            ...UsBankAccount
            __typename
          }

          fragment CaBankAccount on CaBankAccount {
            accountName: account_name
            accountNumber: account_number
            __typename
          }

          fragment UsBankAccount on UsBankAccount {
            accountName: account_name
            accountNumber: account_number
            __typename
          }

          fragment BankVerificationDocument on VerificationDocument {
            id
            acceptable
            updatedAt: updated_at
            createdAt: created_at
            documentId: document_id
            documentType: document_type
            rejectReason: reject_reason
            reviewedAt: reviewed_at
            reviewedBy: reviewed_by
            __typename
          }

          fragment BankAccountVerification on BankAccountVerification {
            custodianProcessedAt: custodian_processed_at
            custodianStatus: custodian_status
            document {
              ...BankVerificationDocument
              __typename
            }
            __typename
          }
        GRAPHQL
      end

      sig { returns(String) }
      def fetch_institutional_transfer
        <<~GRAPHQL
          query FetchInstitutionalTransfer($id: ID!) {
            accountTransfer(id: $id) {
              ...InstitutionalTransfer
              __typename
            }
          }

          fragment InstitutionalTransfer on InstitutionalTransfer {
            id
            accountId: account_id
            state
            documentId: document_id
            documentType: document_type
            expectedCompletionDate: expected_completion_date
            timelineExpectation: timeline_expectation {
              lowerBound: lower_bound
              upperBound: upper_bound
              __typename
            }
            estimatedCompletionMaximum: estimated_completion_maximum
            estimatedCompletionMinimum: estimated_completion_minimum
            institutionName: institution_name
            transferStatus: external_state
            redactedInstitutionAccountNumber: redacted_institution_account_number
            expectedValue: expected_value
            transferType: transfer_type
            cancellable
            pdfUrl: pdf_url
            clientVisibleState: client_visible_state
            shortStatusDescription: short_status_description
            longStatusDescription: long_status_description
            progressPercentage: progress_percentage
            type
            rolloverType: rollover_type
            autoSignatureEligible: auto_signature_eligible
            parentInstitution: parent_institution {
              id
              name
              __typename
            }
            stateHistories: state_histories {
              id
              state
              notes
              transitionSubmittedBy: transition_submitted_by
              transitionedAt: transitioned_at
              transitionCode: transition_code
              __typename
            }
            transferFeeReimbursement: transfer_fee_reimbursement {
              id
              feeAmount: fee_amount
              __typename
            }
            docusignSentViaEmail: docusign_sent_via_email
            clientAccountType: client_account_type
            primaryClientIdentityId: primary_client_identity_id
            primaryOwnerSigned: primary_owner_signed
            secondaryOwnerSigned: secondary_owner_signed
            __typename
          }
        GRAPHQL
      end
    end
  end
end
