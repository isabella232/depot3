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


###
module D3

  module Database

    ################# Module Constants #################


    ### Booleans are stored as 1's and 0's in the db.
    TRUE_VAL = 1
    FALSE_VAL = 0

    # This table has info about the JSS schema
    SCHEMA_TABLE = "db_schema_information"

    # the minimum JSS schema version allower
    MIN_SCHEMA_VERSION = "9.4"

    # the minimum JSS schema version allower
    MAX_SCHEMA_VERSION = "9.93"

    ### these Proc objects allow us to encapsulate and pass around various
    ### blocks of code more easily for converting data between their mysql
    ### representation and the Ruby classses we use internally.

    ### Ruby Time objects are stored as JSS epochs (unix epoch plus milliseconds)
    EPOCH_TO_TIME = Proc.new{|v| (v.nil? or v.to_s.empty?) ? nil : JSS.epoch_to_time(v) }

    ### JSS epochs (unix epoch plus milliseconds) as used as Ruby Time objects
    TIME_TO_EPOCH = Proc.new{|v|(v.nil? or v.to_s.empty?) ? nil :  v.to_jss_epoch }

    ### Integers come from the database as strings, but empty ones should be nil, not zero, as #to_i would do
    STRING_TO_INT = Proc.new{|v| (v.nil? or v.to_s.empty?) ? nil : v.to_i}

    ### Some values are stored as comma-separated strings, but used as Arrays
    COMMA_STRING_TO_ARRAY = Proc.new{|v| JSS.to_s_and_a(v)[:arrayform] }

    ### Some values are used as Arrays but stored as comma-separated strings
    ARRAY_TO_COMMA_STRING = Proc.new{|v| JSS.to_s_and_a(v)[:stringform] }

    ### Some values are stored in the DB as YAML dumps
    RUBY_TO_YAML = Proc.new{|v| YAML.dump v }

    YAML_TO_RUBY = Proc.new{|v| YAML.load v.to_s }

    ### Booleans are stored as zero and one
    BOOL_TO_INT = Proc.new{|v| v == true ? TRUE_VAL : FALSE_VAL}

    ### Booleans are stored as zero and one
    INT_TO_BOOL = Proc.new{|v| v.to_i == FALSE_VAL ? false : true}

    ### Regexps are stored as strings
    STRING_TO_REGEXP = Proc.new{|v| v.to_s.empty? ? nil : Regexp.new(v.to_s) }

    ### Regexps are stored as strings
    REGEXP_TO_STRING = Proc.new{|v| v.to_s }

    ### Status values are stored as strings, but used as symbols
    STATUS_TO_STRING = Proc.new{|v| v.to_s }
    STRING_TO_STATUS = Proc.new{|v| v.to_sym }

    ### Expiration paths are stored as strings, but used as Pathnames
    STRING_TO_PATHNAME = Proc.new{|v| Pathname.new v.to_s}
    PATHNAME_TO_STRING = Proc.new{|v| v.to_s}


    ### The MySQL table that defines which JSS Packages are a part of d3
    ###
    ### This complex Hash contains all the data needed to create and work with the
    ### d3 Packages table.
    ###
    ### The Hash contains these keys & values:
    ###
    ### - :table_name [String] the name of the table in the database
    ###
    ### - :other_indexes [Array<String>] SQL clauses for defining multi-field indexes
    ###   in the CREATE TABLE statement. Single-field indexes are defined in the field definitions.
    ###
    ### - :field_definitions [Hash<Hash>] The definitions of the fields in the table, used throughout the D3 module to
    ###   refer to the data from the database. The keys are also used as the attribute names of {DD3::Package} objects
    ###   Each field definition is a subHash with these keys:
    ### - - :field_name [String] the name of the field in the table
    ### - - :sql_type [String] The SQL data type clause and options for creating the field in the table
    ### - - :index [Boolean,Symbol] How should the field be indexed in the table? One of: true, :primary, :unique or nil/false
    ### - - :to_sql [Proc] the Proc to call with a Ruby object, to convert it to the storable format for the field.
    ###     Integers and Strings don't need conversion. Mysql.encode will be called on all values automatically.
    ### - - :to_ruby [Proc] The Proc to call with a MySQL return value, to convert it to the Ruby class
    ###     used by this module. nil if the value should be a String in Ruby.
    ###
    ### The fields in the table, their Ruby classes, and their meanings are:
    ###
    ### - :id [Integer] the JSS::Package id of this package
    ###
    ### - :basename [String] the basename to which this pkg belongs
    ###
    ### - :version [String] the version number for this basename, installed by this package
    ###
    ### - :revision [Integer] the d3 pkg-revision number of this version. I.e. how many times has this basename-version
    ###   been added to d3?
    ###
    ### - :apple_receipt_data [Array<Hash>] the apple package data for this pkg and all it's sub-pkgs
    ###   Each Hash contains these keys for each pkg installed
    ###     - :apple_pkg_id  The identifier for the item, e.g. com.avid.edlmanager.pkg
    ###     - :version  The version installed, which might not match the version of the metapkg
    ###     - :installed_kb  The disk spaced used by this pkg when installed
    ###   When .[m]pkgs are installed, the identifiers and metadata for each are recorded in the OS's receipts database
    ###   and are accessible via the pkgutil command. (e.g. pkgutil --pkg-info com.company.application). Storing the apple rcpt
    ###   data in the DB allows us to do uninstalls and other client tasks without needing to index the pkg in casper. This is
    ###   stored in the DB as a YAML string
    ###
    ### - :added_date [Time] when was this package was added to d3
    ###
    ### - :added_by [String,nil] the login name of the admin who added this packge to d3
    ###
    ### - :status [Integer] the status of this pkg, one of {D3::Basename::STATUSES}
    ###
    ### - :release_date [Time,nil] when was this package made live in d3
    ###
    ### - :released_by [String,nil] the login name of the admin who made it live
    ###
    ### - :auto_groups [Array] a list of JSS::ComputerGroup names whose members get this
    ###   package installed automatically. The special value :standard means all computers
    ###   get this package automatically, except those in excluded groups.
    ###
    ### - :excluded_groups [Array] a list of JSS::ComputerGroup names for whose members this
    ###   package is not available without force
    ###
    ### - :triggers_swu [Boolean] when installed, will this package trigger a GUI software update check,
    ###   either immediately if there's a console user, or at the next console login?
    ###
    ### - :prohibiting_process [String] a string for matching to the output lines
    ###   of '/bin/ps -A -c -o comm'. If there's a matching line, this pkg won't be installed
    ###
    ### - :remove_first [Boolean] should any currently installed versions of this basename
    ###   be uninstalled (if possible) before installing this package?
    ###
    ### - :pre_install_id [Integer,nil] the JSS::Script id of the pre-install script, if any
    ###
    ### - :post_install_id [Integer,nil] the JSS::Script id of the post-install script, if any
    ###
    ### - :pre_remove_id [Integer,nil] the JSS::Script id of the pre-remove script, if any
    ###
    ### - :post_remove_id [Integer,nil] the JSS::Script id of the post-remove script, if any
    ###
    ### See also the attributes of {D3::Package}, which mostly mirror the
    ###
    PACKAGE_TABLE = { :table_name => 'd3_packages',

      :field_definitions => {

        :id => {
          :field_name => "package_id",
          :sql_type => 'int(11) NOT NULL',
          :index => :unique,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :basename => {
          :field_name => "basename",
          :sql_type => 'varchar(60) NOT NULL',
          :index => true,
          :to_sql => nil,
          :to_ruby => nil
        },

        :version => {
          :field_name => "version",
          :sql_type => 'varchar(30) NOT NULL',
          :index => nil,
          :to_sql => nil,
          :to_ruby => nil
        },

        :revision => {
          :field_name => "revision",
          :sql_type => 'int(4) NOT NULL',
          :index => nil,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :apple_receipt_data => {
          :field_name => "apple_receipt_data",
          :sql_type => "text",
          :index => nil,
          :to_sql  => RUBY_TO_YAML,
          :to_ruby => YAML_TO_RUBY
        },

        :added_date => {
          :field_name => "added_date_epoch",
          :sql_type => "bigint(32) DEFAULT NULL",
          :index => nil,
          :to_sql => TIME_TO_EPOCH,
          :to_ruby => EPOCH_TO_TIME
        },

        :added_by => {
          :field_name => "added_by",
          :sql_type => 'varchar(30)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => nil
        },

        :status => {
          :field_name => "status",
          :sql_type => "varchar(30) DEFAULT 'pilot'",
          :index => nil,
          :to_sql => STATUS_TO_STRING,
          :to_ruby => STRING_TO_STATUS
        },

        :release_date => {
          :field_name => "release_date_epoch",
          :sql_type => "bigint(32)  DEFAULT NULL",
          :index => nil,
          :to_sql => TIME_TO_EPOCH,
          :to_ruby => EPOCH_TO_TIME
        },

        :released_by => {
          :field_name => "released_by",
          :sql_type => 'varchar(30)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => nil
        },

        :auto_groups => {
          :field_name => 'auto_install_groups',
          :sql_type => 'text',
          :index => nil,
          :to_sql => ARRAY_TO_COMMA_STRING,
          :to_ruby => COMMA_STRING_TO_ARRAY
        },

        :excluded_groups => {
          :field_name => 'excluded_groups',
          :sql_type => 'text',
          :index => nil,
          :to_sql =>  ARRAY_TO_COMMA_STRING,
          :to_ruby => COMMA_STRING_TO_ARRAY
        },

        :prohibiting_process => {
          :field_name => "prohibiting_process",
          :sql_type => 'varchar(100)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => nil
        },

        :remove_first => {
          :field_name => "remove_first",
          :sql_type => "tinyint(1) DEFAULT '0'",
          :index => nil,
          :to_sql => BOOL_TO_INT,
          :to_ruby => INT_TO_BOOL
        },

        :pre_install_script_id => {
          :field_name => "pre_install_id",
          :sql_type => 'int(11)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :post_install_script_id => {
          :field_name => "post_install_id",
          :sql_type => 'int(11)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :pre_remove_script_id => {
          :field_name => "pre_remove_id",
          :sql_type => 'int(11)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :post_remove_script_id => {
          :field_name => "post_remove_id",
          :sql_type => 'int(11)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :expiration => {
          :field_name => "expiration",
          :sql_type => 'int(11)',
          :index => nil,
          :to_sql => nil,
          :to_ruby => STRING_TO_INT
        },

        :expiration_path => {
          :field_name => "expiration_app_path",
          :sql_type => 'varchar(300)',
          :index => nil,
          :to_sql => PATHNAME_TO_STRING,
          :to_ruby => STRING_TO_PATHNAME
        }
      },

      :other_indexes => [
        "UNIQUE KEY `edition` (`basename`,`version`,`revision`)"
      ]
    }  # end PACKAGE_TABLE



    ################# Module Methods #################

    ### Retrieve all records for one of the tables defined in D3::Database
    ###
    ### This is generally used by the method {D3::Package.package_data},
    ###
    ### Returns an Array of Hashes, one for each record in the desired table.
    ### The keys of each hash are the keys of the :field_definitions hash from
    ### the table definition.
    ###
    ### @param table_def[Hash] one of the d3 mysql table definitions, currently only
    ###   {D3::Database::PACKAGE_TABLE}
    ###
    ### @return [Array<Hash>] the records from the desired table, with all values converted to
    ###   appropriate Ruby classes as defined in the table_def
    ###
    ###
    def self.table_records(table_def)

      recs = []

      result = JSS.db.query "SELECT * FROM #{table_def[:table_name]}"

      # parse each record into a hash
      result.each_hash do |record|

        rec = {}

        # go through each field in the record, adding it to the hash
        # converting it to its ruby data type if defined in field conversions
        table_def[:field_definitions].each_pair do |key,field_def|

          # do we convert the value from the DB to something else in ruby?
          if field_def[:to_ruby]
            rec[key] = field_def[:to_ruby].call record[field_def[:field_name]]

          # or do we use the value as it comes from the DB?
          else
            rec[key] = record[field_def[:field_name]]
          end # if

        end # do key, field_def

        recs << rec

      end # do record

      return recs
    end # self.table_records(table_def)

    ### Print the sql for creating the d3_packages table
    ### as defined in the PACKAGE_TABLE constant
    ###
    ### @return [void]
    ###
    def self.table_creation_sql
      puts  self.create_table(:display)
    end


    ### Raise an exception if JSS schema is to old or too new
    def self.check_schema_version
      raw = JSS::DB_CNX.db.query("SELECT version FROM #{SCHEMA_TABLE}").fetch[0]
      current = JSS.parse_jss_version(raw)[:version]
      min = JSS.parse_jss_version(MIN_SCHEMA_VERSION)[:version]
      max = JSS.parse_jss_version(MAX_SCHEMA_VERSION)[:version]
      raise JSS::InvalidConnectionError, "Invalid JSS database schema version: #{raw}, min: #{MIN_SCHEMA_VERSION}, max: #{MAX_SCHEMA_VERSION}" if current < min or current > max
      return true
    end

    private


    ### Given a table constant defining a d3 table (PACKAGES_TABLE, at this point),
    ### create the table in the database.
    ###
    ### @param table_constant[Hash] one of the d3 table definition constants, currently only
    ###   {D3::Database::PACKAGE_TABLE}
    ###
    ### @param print[Boolean] just print to stdout the SQL statement for creating the table, don't execute it.
    ###
    ### @return [void]
    ###
    def self.create_table(display=false)

      # as of now, only one table.
      table_constant = PACKAGE_TABLE

      sql = "CREATE TABLE `#{table_constant[:table_name]}` ("
      indexes = ''

      table_constant[:field_definitions].keys.sort.each do |key|

        field = table_constant[:field_definitions][key]

        sql += "\n  `#{field[:field_name]}` #{field[:sql_type]},"

        indexes += case field[:index]
          when :primary
            "\n  PRIMARY KEY (`#{field[:field_name]}`),"
          when :unique
            "\n  UNIQUE KEY (`#{field[:field_name]}`),"
          when true
            "\n  KEY (`#{field[:field_name]}`),"
          else
            ''
        end # indexes +=  case
      end #each do key

      sql += indexes

      table_constant[:other_indexes].each do |idx|
        sql += "\n  #{idx},"
      end

      sql.chomp! ","
      sql += "\n) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"

      if display
        puts sql
        return
      end

      stmt = JSS::DB_CNX.db.prepare sql
      stmt.execute

    end # create d3 table



    ### @return [Array<String>] A list of all d3-related tables in the database
    ###
    def self.tables
      res = JSS::DB_CNX.db.query "show tables"
      d3_tables = []
      res.each do |t|
        d3_tables << t[0] if t[0].start_with? 'd3_'
      end #  res.each do |t|
      res.free
      d3_tables
    end

  end # module Database
end # module D3


