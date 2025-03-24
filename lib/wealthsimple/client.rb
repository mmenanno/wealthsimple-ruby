# typed: strict
# frozen_string_literal: true

require_relative "errors"
require_relative "session"
require_relative "graphql_queries"
module WealthSimple
  class Client
    OAUTH_BASE_URL = "https://api.production.wealthsimple.com/v1/oauth/v2"
    GRAPHQL_URL = "https://my.wealthsimple.com/graphql"
    GRAPHQL_VERSION = "12"
    SCOPE_READ_ONLY = "invest.read trade.read tax.read"
    SCOPE_READ_WRITE = "invest.read trade.read tax.read invest.write trade.write tax.write"

    sig { returns(WealthSimple::Session) }
    attr_reader :session

    sig { params(session: T.nilable(WealthSimple::Session)).void }
    def initialize(session: nil)
      @security_market_data_cache_getter = T.let(nil, T.nilable(Proc))
      @security_market_data_cache_setter = T.let(nil, T.nilable(Proc))
      @session = T.let(session || WealthSimple::Session.new, WealthSimple::Session)
      start_session(session)
      @account_cache = T.let({}, T::Hash[String, T::Array[T::Hash[String, T.untyped]]])
    end

    class << self
      sig do
        params(
          username: String,
          password: String,
          otp_answer: T.nilable(String),
          scope: String,
        ).returns(WealthSimple::Client)
      end
      def login(username:, password:, otp_answer: nil, scope: SCOPE_READ_ONLY)
        client = WealthSimple::Client.new
        client.login_internal(
          username: username,
          password: password,
          otp_answer: otp_answer,
          scope: scope,
        )

        client
      end

      sig { params(session: WealthSimple::Session).returns(WealthSimple::Client) }
      def from_token(session)
        client = WealthSimple::Client.new(session: session)
        client.check_oauth_token
        client
      end
    end

    sig do
      params(
        url: String,
        method: String,
        data: T.nilable(T::Hash[String, String]),
        headers: T.nilable(T::Hash[String, String]),
        return_headers: T::Boolean,
      ).returns(Faraday::Response)
    end
    def send_http_request(url:, method: "POST", data: nil, headers: {}, return_headers: false)
      session_id = @session.session_id
      session_device_id = @session.session_device_id

      headers ||= {}
      headers["Content-Type"] = "application/json" if method == "POST"
      headers["x-ws-session-id"] = session_id if session_id
      headers["x-ws-device-id"] = session_device_id if session_device_id

      connection = Faraday.new do |conn|
        if @session.access_token && (!data || data["grant_type"] != "refresh_token")
          conn.request(:authorization, :Bearer, @session.access_token)
        end

        conn.headers = headers unless headers.empty?

        conn.request(:json)
        conn.response(:json)
      end

      response = if method == "GET"
        connection.get(url)
      else
        connection.post(url) do |request|
          request.body = data
        end
      end

      response
    rescue Faraday::Error => error
      raise WealthSimple::APIError, "HTTP request failed: #{error}"
    end

    sig do
      params(
        url: String,
        headers: T.nilable(T::Hash[String, String]),
        return_headers: T::Boolean,
      ).returns(Faraday::Response)
    end
    def send_get(url, headers: nil, return_headers: false)
      send_http_request(url: url, method: "GET", headers: headers, return_headers: return_headers)
    end

    sig do
      params(
        url: String,
        data: T.nilable(T::Hash[String, String]),
        headers: T.nilable(T::Hash[String, String]),
        return_headers: T::Boolean,
      ).returns(Faraday::Response)
    end
    def send_post(url, data, headers: nil, return_headers: false)
      send_http_request(url: url, method: "POST", data: data, headers: headers, return_headers: return_headers)
    end

    sig { params(session: T.nilable(WealthSimple::Session)).void }
    def start_session(session = nil)
      app_js_url = nil

      if !@session.session_device_id || !@session.client_id
        response = send_get("https://my.wealthsimple.com/app/login")

        if !@session.session_device_id && response.headers["set-cookie"].include?("wssdi")
          if (match = response.headers["set-cookie"].match(/wssdi=([a-f0-9]+);/i))
            @session.session_device_id = match[1]
          end
        end

        if response.body.include?("<script")
          if (match = response.body.match(%r{<script.*src="(.+/app-[a-f0-9]+\.js)}i))
            app_js_url = match[1]
          end
        end

        raise WealthSimple::APIError,
          "Couldn't find wssdi in login page response headers." unless @session.session_device_id
      end

      unless @session.client_id
        raise WealthSimple::APIError, "Couldn't find app JS URL in login page response body." unless app_js_url

        response = send_get(app_js_url)

        if (match = response.body.match(/production:.*clientId:"([a-f0-9]+)"/i))
          @session.client_id = match[1]
        end

        raise WealthSimple::APIError, "Couldn't find clientId in app JS." unless @session.client_id
      end

      @session.session_id ||= SecureRandom.uuid
    end

    sig { void }
    def check_oauth_token
      if @session.access_token
        begin
          search_security("XEQT")
          return
        rescue WealthSimple::APIError => error
          raise error if error.message.exclude?("Not Authorized.")
        end
      end

      if @session.refresh_token
        data = {
          "grant_type" => "refresh_token",
          "refresh_token" => @session.refresh_token,
          "client_id" => @session.client_id,
        }
        headers = {
          "x-wealthsimple-client" => "@wealthsimple/wealthsimple",
          "x-ws-profile" => "invest",
        }
        response = send_post("#{OAUTH_BASE_URL}/token", data, headers: headers)
        @session.access_token = response.body["access_token"]
        @session.refresh_token = response.body["refresh_token"]
      end

      raise WealthSimple::ManualLoginRequired, "OAuth token invalid and cannot be refreshed."
    end

    sig do
      params(
        username: String,
        password: String,
        otp_answer: T.nilable(String),
        scope: String,
      ).returns(WealthSimple::Session)
    end
    def login_internal(username:, password:, otp_answer: nil, scope: SCOPE_READ_ONLY)
      data = {
        "grant_type" => "password",
        "username" => username,
        "password" => password,
        "skip_provision" => "true",
        "scope" => scope,
        "client_id" => @session.client_id,
        "otp_claim" => nil,
      }

      headers = {
        "x-wealthsimple-client" => "@wealthsimple/wealthsimple",
        "x-ws-profile" => "undefined",
      }

      if otp_answer
        headers["x-wealthsimple-otp"] = "#{otp_answer};remember=true"
      end

      response = send_post(
        "#{OAUTH_BASE_URL}/token",
        data,
        headers: headers,
      )

      raise WealthSimple::OTPRequired,
        "2FA code required" if response.body["error"] == "invalid_grant" && otp_answer.nil?

      raise WealthSimple::LoginFailed, "Login failed" if response.body["error"]

      @session.access_token = response.body["access_token"]
      @session.refresh_token = response.body["refresh_token"]

      @session
    end

    sig do
      params(
        query_name: Symbol,
        variables: T::Hash[String, String],
        data_response_path: String,
        expect_type: String,
        filter_fn: T.untyped,
      ).returns(T::Array[T::Hash[String, T.untyped]])
    end
    def graphql_query(query_name, variables, data_response_path, expect_type, filter_fn = nil)
      query = {
        "operationName" => query_name.to_s.split("_").map(&:capitalize).join,
        "query" => WealthSimple::GraphqlQueries.public_send(query_name),
        "variables" => variables,
      }

      headers = {
        "x-ws-profile" => "trade",
        "x-ws-api-version" => GRAPHQL_VERSION,
        "x-ws-locale" => "en-CA",
        "x-platform-os" => "web",
      }

      response = send_post(
        GRAPHQL_URL,
        query,
        headers: headers,
      )

      raise(
        WealthSimple::APIError.new,
        "GraphQL query failed: #{query_name} #{response.body}",
      ) unless response.body["data"]

      data = response.body["data"]

      data_response_path.split(".").each do |key|
        raise(
          WealthSimple::APIError.new,
          "GraphQL query failed: #{query_name} #{response.body}",
        ) unless data.key?(key)

        data = data[key]
      end

      if (expect_type == "array" && !data.is_a?(Array)) ||
          (expect_type == "object" && !data.is_a?(Hash))
        raise(
          WealthSimple::APIError.new,
          "GraphQL query failed: #{query_name} #{response.body}",
        )
      end

      if data_response_path.end_with?("edges")
        data = data.map { |edge| edge["node"] }
      end

      data = data.select(&filter_fn) if filter_fn

      data
    end

    sig { returns(T.nilable(T::Hash[String, T.untyped])) }
    def token_info
      return @session.token_info if @session.token_info

      headers = {
        "x-wealthsimple-client" => "@wealthsimple/wealthsimple",
      }
      response = send_get("#{OAUTH_BASE_URL}/token/info", headers: headers)

      @session.token_info = response.body
    end

    sig { params(open_only: T::Boolean, use_cache: T::Boolean).returns(T.untyped) }
    def get_accounts(open_only: true, use_cache: true)
      cache_key = open_only ? "open" : "all"

      if !use_cache || !@account_cache.key?(cache_key)
        filter_fn = open_only ? ->(acc) { acc["status"] == "open" } : nil

        accounts = graphql_query(
          :fetch_all_account_financials,
          {
            "pageSize" => 25,
            "identityId" => token_info&.fetch("identity_canonical_id"),
          },
          "identity.accounts.edges",
          "array",
          filter_fn: filter_fn,
        )

        accounts.each { |account| account_add_description(account) }
        @account_cache[cache_key] = accounts
      end

      @account_cache[cache_key]
    end

    sig { params(account: T::Hash[String, T.untyped]).void }
    def account_add_description(account)
      account["number"] = account["id"]
      # This is the account number visible in the WS app:
      account["custodianAccounts"].each do |ca|
        if ["WS", "TR"].include?(ca["branch"]) && ca["status"] == "open"
          account["number"] = ca["id"]
        end
      end

      # Default
      account["description"] = account["unifiedAccountType"]

      if account["nickname"]
        account["description"] = account["nickname"]
      elsif account["unifiedAccountType"] == "CASH"
        account["description"] = account["accountOwnerConfiguration"] == "MULTI_OWNER" ? "Cash: joint" : "Cash"
      elsif account["unifiedAccountType"] == "SELF_DIRECTED_RRSP"
        account["description"] = "RRSP: self-directed - #{account["currency"]}"
      elsif account["unifiedAccountType"] == "MANAGED_RRSP"
        account["description"] = "RRSP: managed - #{account["currency"]}"
      elsif account["unifiedAccountType"] == "SELF_DIRECTED_TFSA"
        account["description"] = "TFSA: self-directed - #{account["currency"]}"
      elsif account["unifiedAccountType"] == "MANAGED_TFSA"
        account["description"] = "TFSA: managed - #{account["currency"]}"
      elsif account["unifiedAccountType"] == "SELF_DIRECTED_JOINT_NON_REGISTERED"
        account["description"] = "Non-registered: self-directed - joint"
      elsif account["unifiedAccountType"] == "SELF_DIRECTED_NON_REGISTERED_MARGIN"
        account["description"] = "Non-registered: self-directed margin"
      elsif account["unifiedAccountType"] == "MANAGED_JOINT"
        account["description"] = "Non-registered: managed - joint"
      elsif account["unifiedAccountType"] == "SELF_DIRECTED_CRYPTO"
        account["description"] = "Crypto"
      end
    end

    sig { params(account_id: String).returns(T::Hash[String, T.untyped]) }
    def get_account_balances(account_id)
      accounts = graphql_query(
        :fetch_accounts_with_balance,
        {
          "type" => "TRADING",
          "ids" => [account_id],
        },
        "accounts",
        "array",
      )

      # Extracting balances and returning them in a hash
      balances = {}
      first_result = accounts[0]

      return {} if first_result.nil?

      # TODO: This does not seem to be the correct hash keys for balances anymore
      first_result["custodianAccounts"].each do |account|
        account["financials"]["balance"]&.each do |balance|
          security = balance["securityId"]
          if security != "sec-c-cad" && security != "sec-c-usd"
            security = security_id_to_symbol(security)
          end
          balances[security] = balance["quantity"]
        end
      end

      balances
    end

    sig do
      params(
        account_id: String,
        how_many: Integer,
        order_by: String,
        ignore_rejected: T::Boolean,
      ).returns(T::Array[T::Hash[String, T.untyped]])
    end
    def get_activities(account_id, how_many = 50, order_by = "OCCURRED_AT_DESC", ignore_rejected = true)
      # Calculate the end date for the condition
      end_date = Time.zone.now + (24 * 60 * 60) - 1

      # Filter function to ignore rejected/cancelled activities
      filter_fn = lambda do |activity|
        act_type = (activity["type"] || "").upcase
        status = (activity["status"] || "").downcase
        act_type != "LEGACY_TRANSFER" && (!ignore_rejected || status.empty? || (status.exclude?("rejected") && status.exclude?("cancelled")))
      end

      activities = graphql_query(
        :fetch_activity_feed_items,
        {
          "orderBy" => order_by,
          "first" => how_many,
          "condition" => {
            "endDate" => end_date.strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
            "accountIds" => [account_id],
          },
        },
        "activityFeedItems.edges",
        "array",
        filter_fn: filter_fn,
      )

      activities.each { |act| activity_add_description(act) }

      activities
    end

    sig { params(activity: T::Hash[String, T.untyped]).void }
    def activity_add_description(activity)
      activity["description"] = "#{activity["type"]}: #{activity["subType"]}"

      case activity["type"]
      when "INTERNAL_TRANSFER"
        accounts = get_accounts(false)
        target_account = accounts.find { |acc| acc["id"] == activity["opposingAccountId"] }
        account_description = if target_account
          "#{target_account["description"]} (#{target_account["number"]})"
        else
          activity["opposingAccountId"]
        end

        activity["description"] = if activity["subType"] == "SOURCE"
          "Transfer out: Transfer to Wealthsimple #{account_description}"
        else
          "Transfer in: Transfer from Wealthsimple #{account_description}"
        end

      when "DIY_BUY", "DIY_SELL"
        verb = activity["subType"].tr("_", " ").capitalize
        action = activity["type"] == "DIY_BUY" ? "buy" : "sell"
        security = security_id_to_symbol(activity["securityId"])
        activity["description"] = "#{verb}: #{action} #{activity["assetQuantity"].to_f} x " \
          "#{security} @ #{activity["amount"].to_f / activity["assetQuantity"].to_f}"

      when "DEPOSIT", "WITHDRAWAL"
        if ["E_TRANSFER", "E_TRANSFER_FUNDING"].include?(activity["subType"])
          direction = activity["type"] == "DEPOSIT" ? "from" : "to"
          activity["description"] = "Deposit: Interac e-transfer #{direction} " \
            "#{activity["eTransferName"]} #{activity["eTransferEmail"]}"
        elsif activity["type"] == "DEPOSIT" && activity["subType"] == "PAYMENT_CARD_TRANSACTION"
          type = activity["type"].downcase.capitalize
          activity["description"] = "#{type}: Debit card funding"
        end

      else
        if activity["subType"] == "EFT"
          details = get_etf_details(activity["externalCanonicalId"])
          type = activity["type"].downcase.capitalize
          direction = activity["type"] == "DEPOSIT" ? "from" : "to"
          prop = activity["type"] == "DEPOSIT" ? "source" : "destination"
          bank_account = details[prop]["bankAccount"]
          nickname = bank_account["nickname"] || bank_account["accountName"]
          activity["description"] = "#{type}: EFT #{direction} #{nickname} #{bank_account["accountNumber"]}"

        elsif activity["type"] == "REFUND" && activity["subType"] == "TRANSFER_FEE_REFUND"
          activity["description"] = "Reimbursement: account transfer fee"

        elsif activity["type"] == "INSTITUTIONAL_TRANSFER_INTENT" && activity["subType"] == "TRANSFER_IN"
          details = get_transfer_details(activity["externalCanonicalId"])
          verb = details["transferType"].tr("_", "-").capitalize
          activity["description"] = "Institutional transfer: #{verb} #{details["clientAccountType"].upcase} " \
            "account transfer from #{details["institutionName"]} " \
            "****#{details["redactedInstitutionAccountNumber"]}"

        elsif activity["type"] == "INTEREST"
          activity["description"] = if activity["subType"] == "FPL_INTEREST"
            "Stock Lending Earnings"
          else
            "Interest"
          end

        elsif activity["type"] == "DIVIDEND"
          security = security_id_to_symbol(activity["securityId"])
          activity["description"] = "Dividend: #{security}"

        elsif activity["type"] == "FUNDS_CONVERSION"
          from_currency = activity["currency"] == "CAD" ? "USD" : "CAD"
          activity["description"] = "Funds converted: #{activity["currency"]} from #{from_currency}"

        elsif activity["type"] == "NON_RESIDENT_TAX"
          activity["description"] = "Non-resident tax"
        end
      end
    end

    sig { params(security_id: String).returns(String) }
    def security_id_to_symbol(security_id)
      security_symbol = "[#{security_id}]"
      if @security_market_data_cache_getter
        market_data = get_security_market_data(security_id)
        if market_data["stock"]
          stock = market_data["stock"]
          security_symbol = "#{stock["primaryExchange"]}:#{stock["symbol"]}"
        end
      end

      security_symbol
    end

    sig { params(funding_id: String).returns(T::Array[T::Hash[String, T.untyped]]) }
    def get_etf_details(funding_id)
      graphql_query(
        :fetch_funds_transfer,
        { "id" => funding_id },
        "fundsTransfer",
        "object",
      )
    end

    sig { params(transfer_id: String).returns(T::Array[T::Hash[String, T.untyped]]) }
    def get_transfer_details(transfer_id)
      graphql_query(
        :fetch_institutional_transfer,
        { "id" => transfer_id },
        "accountTransfer",
        "object",
      )
    end

    sig { params(security_market_data_cache_getter: Proc, security_market_data_cache_setter: Proc).void }
    def set_security_market_data_cache(security_market_data_cache_getter:, security_market_data_cache_setter:)
      @security_market_data_cache_getter = security_market_data_cache_getter
      @security_market_data_cache_setter = security_market_data_cache_setter
    end

    sig { params(security_id: String, use_cache: T::Boolean).returns(T::Hash[String, T.untyped]) }
    def get_security_market_data(security_id, use_cache: true)
      use_cache = false if !@security_market_data_cache_getter || !@security_market_data_cache_setter

      if use_cache
        cached_value = @security_market_data_cache_getter.call(security_id)
        return cached_value if cached_value
      end

      value = graphql_query(
        :fetch_security_market_data,
        { "id" => security_id },
        "security",
        "object",
      )

      if use_cache
        value = @security_market_data_cache_setter&.call(security_id, value)
      end

      value
    end

    sig { params(query: String).returns(T::Array[T::Hash[String, T.untyped]]) }
    def search_security(query)
      graphql_query(
        :fetch_security_search_result,
        { "query" => query },
        "securitySearch.results",
        "array",
      )
    end

    sig { params(security_id: String, time_range: String).returns(T::Array[T::Hash[String, T.untyped]]) }
    def get_security_historical_quotes(security_id, time_range = "1m")
      graphql_query(
        :fetch_security_historical_quotes,
        {
          "id" => security_id,
          "timerange" => time_range,
        },
        "security.historicalQuotes",
        "array",
      )
    end
  end
end
