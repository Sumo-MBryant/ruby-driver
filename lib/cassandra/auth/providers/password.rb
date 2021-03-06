# encoding: utf-8

#--
# Copyright 2013-2016 DataStax, Inc.
#
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
#++

module Cassandra
  module Auth
    module Providers
      # Auth provider used for Cassandra's built in authentication.
      #
      # @note No need to instantiate this class manually, use `:username` and
      #   `:password` options when calling {Cassandra.cluster} and one will be
      #   created automatically for you.
      class Password < Provider
        # Authenticator used for Cassandra's built in authentication,
        # see {Cassandra::Auth::Providers::Password}
        # @private
        class Authenticator
          # @private
          def initialize(username, password)
            @username = username
            @password = password
          end

          def initial_response
            "\x00#{@username}\x00#{@password}"
          end

          def challenge_response(token)
          end

          def authentication_successful(token)
          end
        end

        # @param username [String] username to use for authentication to Cassandra
        # @param password [String] password to use for authentication to Cassandra
        def initialize(username, password)
          @username = username
          @password = password
        end

        # Returns a Password Authenticator only if
        # `org.apache.cassandra.auth.PasswordAuthenticator` is given.
        # @param authentication_class [String] must equal to
        #   `org.apache.cassandra.auth.PasswordAuthenticator`
        # @return [Cassandra::Auth::Authenticator] when `authentication_class ==
        #    "org.apache.cassandra.auth.PasswordAuthenticator"`
        # @return [nil] for all other values of `authentication_class`
        def create_authenticator(authentication_class)
          if authentication_class == PASSWORD_AUTHENTICATOR_FQCN
            Authenticator.new(@username, @password)
          end
        end

        private

        # @private
        PASSWORD_AUTHENTICATOR_FQCN =
          'org.apache.cassandra.auth.PasswordAuthenticator'.freeze
      end
    end
  end
end
