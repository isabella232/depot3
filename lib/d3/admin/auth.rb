### Copyright 2016 Pixar
###
###    Licensed under the Apache License, Version 2.0 (the "Apache License")
###    with the following modification; you may not use this file except in
###    compliance with the Apache License and the following modification to it:
###    Section 6. Trademarks. is deleted and replaced with:
###
###    6. Trademarks. This License does not grant permission to use the trade
###       names, trademarks, service marks, or product names of the Licensor
###       and its affiliates, except as required to comply with Section 4(c) of
###       the License and to reproduce the content of the NOTICE file.
###
###    You may obtain a copy of the Apache License at
###
###        http://www.apache.org/licenses/LICENSE-2.0
###
###    Unless required by applicable law or agreed to in writing, software
###    distributed under the Apache License with the above modification is
###    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
###    KIND, either express or implied. See the Apache License for the specific
###    language governing permissions and limitations under the Apache License.
###
###


module D3
  module Admin

    ### This module contains methods for dealing with d3 admin authentication
    ### getting, & storing the passwords needed to connect to the JSS and the
    ### database as a d3 admin.
    ###
    module Auth
      extend self

      ################# Module Constants #################

      RW_CREDENTIAL_KINDS = [:jss, :db, :dist]

      KEYCHAIN_SERVICE_BASE  = "d3admin"
      KEYCHAIN_LABEL_BASE = "com.pixar.d3.admin"

      KEYCHAIN_JSS_SERVICE = KEYCHAIN_SERVICE_BASE + ".jss-api"
      KEYCHAIN_JSS_LABEL = KEYCHAIN_LABEL_BASE + ".jss-api"

      KEYCHAIN_DB_SERVICE = KEYCHAIN_SERVICE_BASE + ".db"
      KEYCHAIN_DB_LABEL = KEYCHAIN_LABEL_BASE + ".db"

      KEYCHAIN_DIST_ACCT = "defined_in_jss"
      KEYCHAIN_DIST_SERVICE = KEYCHAIN_SERVICE_BASE + ".distribution"
      KEYCHAIN_DIST_LABEL = KEYCHAIN_LABEL_BASE + ".distribution"

      ### Connect to the JSS API and MySQL DB
      ### with admin credentials from the keychain
      ###
      ### @return [String] the JSS hostname to which the connection was made
      ###
      def connect (alt_db = false)
        api = rw_credentials :jss
        db = rw_credentials :db

        JSS::DB_CNX.connect :user => db[:user], :pw => db[:password], :connect_timeout => 10
        JSS::API.connect :user => api[:user], :pw => api[:password], :open_timeout => 10
        D3::Database.check_schema_version
        return JSS::API.cnx.options[:server]
      end

      # Disconnect admin credentials from the JSS API and MySQL DB
      def disconnect
        JSS::API.disconnect
        JSS::DB_CNX.disconnect
      end

      ### Fetch read-write credentials from the login keychain
      ###
      ### If the login keychain is locked, the user will be prompted
      ### to unlock it in the GUI.
      ###
      ### @param kind[Symbol] which kind of credentials? :jss, :db, or :dist
      ###
      ### @param checking_for_existence[Boolean] Are we just checking to see if
      ###   this value has been set? If so, and it hasn't, don't prompt for
      ###   saving, just return an empty hash.
      ###
      ### @return [Hash{Symbol => String}] A Hash with :user and :password values.
      ###   or empty if unset and checking for existence.
      ###
      def rw_credentials(kind, checking_for_existence = false)
        Keychain.user_interaction_allowed = true
        unlock_keychain
        search_conditions = case kind
        when :jss
          {:service => KEYCHAIN_JSS_SERVICE, :label => KEYCHAIN_JSS_LABEL}
        when :db
          {:service => KEYCHAIN_DB_SERVICE, :label => KEYCHAIN_DB_LABEL}
        when :dist
          {:service => KEYCHAIN_DIST_SERVICE, :account => KEYCHAIN_DIST_ACCT, :label => KEYCHAIN_DIST_LABEL}
        else
          raise JSS::InvalidDataError, "argument must be one of :#{RW_CREDENTIAL_KINDS.join ', :'}"
        end #pw_item = case kind

        pw_item = Keychain.default.generic_passwords.where(search_conditions).first
        return {} if pw_item.nil? and checking_for_existence

        if pw_item
          return {:user => pw_item.account, :password =>  pw_item.password}
        else
          # doesn't exist in the keychain, so get from the user and save in the keychain
          ask_for_rw_credentials(kind)
        end # if pw_item
      end

      ### Prompt for a JSS or MySQL server hostname & port.
      ### Test that its a valid server,
      ### and save it to the User-level JSS config file
      ###
      ### @param type[Symbol] either :jss or :db
      ###
      ### @return [void]
      ###
      def get_server (type)

        case type
        when :jss
          thing = "API"
          current = JSS::CONFIG.api_server_name
          current_port = JSS::CONFIG.api_server_port
          current_port ||= JSS::APIConnection::SSL_PORT
        when :db
          thing = "MySQL DB"
          current = JSS::CONFIG.db_server_name
          current_port = JSS::CONFIG.db_server_port
          current_port ||= JSS::DBConnection::DFT_PORT
        else
          raise JSS::InvalidDataError, "Argument must be :jss or :db"
        end

        got_it = false
        until got_it
          puts
          puts "Enter the server hostname for the JSS #{thing}"
          puts "Hit return for #{current}" if current
          print "JSS #{thing} Server: "
          server_entered = $stdin.gets.chomp
          server_entered = current if server_entered.empty?

          next if server_entered.empty?

          puts
          puts "Enter the port number for the JSS #{thing} on #{server_entered}"
          puts "Hit return for #{current_port}" if current_port
          print "JSS #{thing} port: "
          port_entered = $stdin.gets.chomp
          port_entered = current_port if port_entered.empty?

          got_it = test_server_available(type, server_entered, port_entered)

          if got_it
            case type
            when :jss then
              JSS::CONFIG.api_server_name = server_entered
              JSS::CONFIG.api_server_port = port_entered
            when :db
              JSS::CONFIG.db_server_name = server_entered
              JSS::CONFIG.db_server_port = port_entered
            end # case
            JSS::CONFIG.save :user
          end # if got_it
        end # until
        return server_entered
      end # def get server

      ### Test that a given hostname is actually a server of the given type
      ### by testing the connection without actually logging in.
      ### Displays the connection error if unable to connect.
      ###
      ### @param type[Symbol] either :jss or :db
      ###
      ### @param server[String] the hostname to try connecting to
      ###
      ### @return [Boolean] does the host run a server of that type?
      ###
      def test_server_available (type, server, port)
        puts "Checking connection to #{server}"
        case type
        when :jss then
          if JSS::API.valid_server? server
            JSS::CONFIG.api_server_name = server
            JSS::CONFIG.save :user
            return true
          else
            failure = "'#{server}' does not host a JSS API server"
          end # if

        when :db
          if JSS::DB_CNX.valid_server? server, port
            JSS::CONFIG.db_server_name = server
            JSS::CONFIG.save :user
            return true
          else
            failure = "'#{server}' does not host a MySQL server"
          end # if

        else
          failure = "Unknown Server Type: #{type}"
        end # case

        puts "Sorry, that server is invalid: #{failure}"
        return false
      end # test_server_available

      ### Prompt for read-write credentials & store them in the default (login) keychain
      ###
      ### Raises an exception after 3 failures
      ###
      ### @param kind[Symbol] which kind of credentials? :jss, :db, or :dist
      ###
      ### @return [Hash{Symbol => String}] A Hash with :user and :password values.
      ###
      def ask_for_rw_credentials(kind)

        #$stdin.reopen("/dev/tty")

        # make sure we have a server, which will be stored in the user-level JSS::Configuration
        get_server (kind) unless kind == :dist

        # make sure the keychain is unlocked
        unlock_keychain

        thing_to_access = case kind
        when :jss then "the JSS API on #{JSS::API.hostname}"
        when :db then "the JSS MySQL db at #{JSS::DB_CNX.hostname}"
        when :dist then "read-write access to the JSS Master Distribution Point"
        else raise JSS::InvalidDataError, "argument must be one of :#{RW_CREDENTIAL_KINDS.join ', :'}"
        end # case kind

        # three tries
        begin
          pw = nil
          tries = 0
          while tries != 3

            # for dist we only need a password
            if kind == :dist
              user = KEYCHAIN_DIST_ACCT
              user_text = ''
            else
              print "Username for RW access to #{thing_to_access}: "
              user = $stdin.gets.chomp
              user_text = "#{user} @ "
            end

            print "Password for #{user_text}#{thing_to_access}: "
            system "stty -echo"
            pw = $stdin.gets.chomp
            system "stty echo"
            break if check_credentials(kind, user, pw)

            puts "\nSorry, that was incorrect"
            tries += 1
          end # while

          # did we get it in 3 tries?
          raise JSS::InvalidDataError, "Three wrong attempts, please contact a Casper administrator." if 3 == tries

          save_credentials(kind, user, pw)
          puts "\nThank you, the credentials have been saved in your OS X login keychain"
        ensure
          # make sure terminal is usable at the end of this
          system "stty echo"
          puts ""
        end # begin

        # we should now have user and pw
        return {:user => user, :password =>  pw}
      end #   def ask_for_rw_credentials(kind)

      ### Check a user and password for validity
      ###
      ### @param kind[Symbol] which kind of credentials? :jss, :db, or :dist
      ###
      ### @param user[String] the username to check
      ###
      ### @param pw[String] the password to try with the username
      ###
      ### @return [Boolean] were the user and  password valid?
      ###
      def check_credentials(kind, user = "", pw = "")
        case kind
        when :jss then check_jss_credentials(user,pw)
        when :db then check_db_credentials(user,pw)
        when :dist then check_dist_credentials(pw)
        else raise JSS::InvalidDataError, "First argument must be one of :#{RW_CREDENTIAL_KINDS.join ', :'}"
        end # case kind
      end

      ### Check a username and passwd for rw access to the JSS API
      ###
      ### Note: this only checks for connectivity, not permissions once connected.
      ###
      ### @param user[String] the username to check
      ###
      ### @param pw[String] the password to try with the username
      ###
      ### @return [Boolean] were the user and  password valid?
      ###
      def check_jss_credentials(user,pw)
        begin
          JSS::API.disconnect
          JSS::API.connect :user => user, :pw => pw, :server => JSS::CONFIG.api_server_name
        rescue JSS::AuthenticationError
          return false
        end
        JSS::API.disconnect
        return true
      end

      ### Check a username and passwd for rw access to the JSS MySQL DB
      ###
      ### Note: this only checks for connectivity, not permissions once connected.
      ###
      ### @param user[String] the username to check
      ###
      ### @param pw[String] the password to try with the username
      ###
      ### @return [Boolean] were the user and  password valid?
      ###
      def check_db_credentials(user,pw)
        begin
          JSS::DB_CNX.disconnect
          JSS::DB_CNX.connect :user => user, :pw => pw, :server => JSS::CONFIG.db_server_name
        rescue Mysql::ServerError::AccessDeniedError
          return false
        end
        JSS::DB_CNX.disconnect
        return true
      end

      ### Check a passwd for rw access to the master distribution point in the JSS
      ###
      ### @param pw[String] the password to try
      ###
      ### @return [Boolean] was the password valid?
      ###
      def check_dist_credentials(pw)
        D3::Admin::Auth.connect
        ok = JSS::DistributionPoint.master_distribution_point.check_pw :rw, pw
        D3::Admin::Auth.disconnect
        ok
      end

      ### Save a user and password to the login keychain
      ###
      ### Note: assumes the validity of the credentials
      ###
      ### @param kind[Symbol] which kind of credentials? :jss, :db, or :dist
      ###
      ### @param user[String] the username to check
      ###
      ### @param pw[String] the password to try with the username
      ###
      ### @return [Boolean] were the user and  password valid?
      ###
      def save_credentials(kind, user = "", pw = "")
        case kind
        when :jss then save_jss_rw_credentials(user,pw)
        when :db then save_db_rw_credentials(user,pw)
        when :dist then save_dist_rw_credentials(pw)
        else raise JSS::InvalidDataError, "First argument must be one of :#{RW_CREDENTIAL_KINDS.join ', :'}"
        end # case kind
      end

      ### Save the credentials for read-write access to the JSS API in the login keychain
      ###
      ### Note: assumes the validity of the user and passwd. See {#check_jss_pw}
      ###
      ### @param user[String] the username to save
      ###
      ### @param pw[String] the password to save with the username
      ###
      ### @return [void]
      ###
      def save_jss_rw_credentials(user, pw)
        pw_item = Keychain.default.generic_passwords.where(:service => KEYCHAIN_JSS_SERVICE, :label => KEYCHAIN_JSS_LABEL, :account => user).first
        pw_item.delete  if pw_item
        Keychain.default.generic_passwords.create :service => KEYCHAIN_JSS_SERVICE, :label => KEYCHAIN_JSS_LABEL, :account => user, :password => pw
      end

      ### Save the credentials for read-write access to the JSS DB in the login keychain
      ###
      ### Note: assumes the validity of the user and passwd. See {#check_db_pw}
      ###
      ### @param user[String] the username to save
      ###
      ### @param pw[String] the password to save with the username
      ###
      ### @return [void]
      ###
      def save_db_rw_credentials(user, pw)
        pw_item = Keychain.default.generic_passwords.where(:service => KEYCHAIN_DB_SERVICE, :label => KEYCHAIN_DB_LABEL, :account => user).first
        pw_item.delete  if pw_item
        Keychain.default.generic_passwords.create :service => KEYCHAIN_DB_SERVICE, :label => KEYCHAIN_DB_LABEL, :account => user, :password => pw
      end

      ### Save the credentials for read-write access to the JSS  master dist. point
      ### in the login keychain
      ###
      ### Note: assumes the validity of the passwd. See {#check_dist_rw_pw}
      ###
      ### @param pw[String] the password to save with the username
      ###
      ### @return [void]
      ###
      def save_dist_rw_credentials(pw)
        pw_item = Keychain.default.generic_passwords.where(:service => KEYCHAIN_DIST_SERVICE, :label => KEYCHAIN_DIST_LABEL, :account => KEYCHAIN_DIST_ACCT).first
        pw_item.delete  if pw_item
        Keychain.default.generic_passwords.create :service => KEYCHAIN_DIST_SERVICE, :label => KEYCHAIN_DIST_LABEL, :account => KEYCHAIN_DIST_ACCT, :password => pw
      end

      ### Prompt the user to unlock the default keychain
      ###
      ### @return [void]
      ###
      def unlock_keychain
        return true unless Keychain.default.locked?
        begin
          unlocked = false
          tries = 0
          until unlocked or tries == 3
            puts "Please enter the password for your default keychain"
            puts "(#{Keychain.default.path})"
            print "Keychain password: "
            system "stty -echo"
            pw = $stdin.gets.chomp
            system "stty echo"
            begin
              Keychain.default.unlock! pw
              unlocked = true
            rescue Keychain::AuthFailedError
              puts
              puts "Sorry that was incorrect"
              tries += 1
            end # begin..rescue
          end # until
        ensure
          system "stty echo"
        end #begin..ensure

        raise JSS::AuthenticationError, "Three incorrect attempts to unlock keychain" if tries == 3
        return true
      end # unlock keychain


    end # module Auth

    ### @see D3::Admin::Auth.connect
    ###
    def self.connect (alt_db = false)
      Auth.connect alt_db
    end

    ### @see D3::Admin::Auth.disconnect
    ###
    def self.disconnect
      Auth.disconnect
    end

  end # module Admin
end # module D3

