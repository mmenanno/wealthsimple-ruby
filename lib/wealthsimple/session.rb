# typed: strict
# frozen_string_literal: true

module WealthSimple
  class Session
    sig { returns(T.nilable(String)) }
    attr_accessor :client_id, :access_token, :refresh_token, :session_id, :session_device_id

    sig { returns(T.nilable(T::Hash[String, T.untyped])) }
    attr_accessor :token_info

    sig do
      params(
        client_id: T.nilable(String),
        access_token: T.nilable(String),
        refresh_token: T.nilable(String),
        session_id: T.nilable(String),
        session_device_id: T.nilable(String),
        token_info: T.nilable(T::Hash[String, T.untyped]),
      ).void
    end
    def initialize(client_id: nil, access_token: nil, refresh_token: nil, session_id: nil, session_device_id: nil,
      token_info: nil)
      @client_id = T.let(client_id, T.nilable(String))
      @access_token = T.let(access_token, T.nilable(String))
      @refresh_token = T.let(refresh_token, T.nilable(String))
      @session_id = T.let(session_id, T.nilable(String))
      @session_device_id = T.let(session_device_id, T.nilable(String))
      @token_info = T.let(token_info, T.nilable(T::Hash[String, T.untyped]))
    end
  end
end
