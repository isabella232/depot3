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
    module Report
      extend self

      REPORT_TYPES = %w{pilot frozen deprecated installed puppies receipts}
      DFT_REPORT_TYPE = "installed"

      SHOW_TYPES = %w{all pilot live deprecated skipped missing auto excluded}
      DFT_SHOW_TYPE = "all"

      ### TODO add report of last_usage for expirable rcpts

      ###### Reports for 'd3admin report'

      ### Show a report of all computers with a given basename installed,
      ### possibly limited to pilots or deprecated pkgs
      ###
      ### @param basename[Array<String>] the basenames to report on
      ###
      ### @param type[Symbol] the type of install to report, either :all,
      ###   :pilot, :deprecated
      ###
      ### @return [void]
      ###
      def report_installs (basenames, type = :all)
        connect_for_reports
        report_data, data_source = client_install_report_data
        basenames.each do |basename|

          unless  D3::Package.all_basenames.include? basename
            puts "# No basename '#{basename}' in d3"
            next
          end

          # what are we reporting
          case type
          when :all
            title = "All machines with '#{basename}' installed"
          when :pilot
            title = "All machines piloting '#{basename}'"
          when :frozen
            if data_source != :ea
              puts "Reports of frozen packages require a special Extension Attribute. Please see the d3 documentation"
              return false
            end
            title = "All machines with '#{basename}' frozen"
          when :deprecated
            title = "All machines with a deprecated '#{basename}'"
          end  # case type

          # start building the report
          if data_source == :ea
            header = %w{Computer User Edition Status Installed By As_of }
            title += " (^=frozen)" unless type == :frozen
          else
            header = %w{Computer User Edition Status As_of }
          end
          lines = []

          report_data.each do |computer_to_report|
            this_rcpt = computer_to_report[:rcpts][basename]
            # skip those without this basename
            next unless this_rcpt
            case type
            when :pilot
              next unless this_rcpt[:status] == :pilot
            when :deprecated
              next unless this_rcpt[:status] == :deprecated
            when :frozen
              next unless this_rcpt[:frozen]
            end # case type

            edition = "#{basename}-#{this_rcpt[:version]}-#{this_rcpt[:revision]}"
            edition += "^" if this_rcpt[:frozen] and type != :frozen
            as_of = computer_to_report[:as_of].strftime "%Y-%m-%d"

            if data_source == :ea
              installed_at = this_rcpt[:installed_at].strftime "%Y-%m-%d"
              line = [computer_to_report[:computer], computer_to_report[:user], edition, this_rcpt[:status], installed_at, this_rcpt[:admin], as_of]
            else
              line = [computer_to_report[:computer], computer_to_report[:user], edition, this_rcpt[:status], as_of]
            end
            lines << line
          end


          if lines.empty?
            puts "# No matching installs of '#{basename}' were found"
          else
            D3.less_text D3.generate_report lines, header_row: header, title: title
          end # if lines emtpy?
          puts  # blank line between, for readability

        end # do basename
      end # report_installs (basename)

      def basename_installs (basenames)
        self.report_installs basenames, :all
      end # basename_installs

      def pilot_installs (basenames)
        basenames = D3::Package.pilot_data.values.map{|pp| pp[:basename]}.sort.uniq if basenames.include? "all"
        self.report_installs basenames, :pilot
      end # pilot installs

      def deprecated_installs (basenames)
        basenames = D3::Package.deprecated_data.values.map{|pp| pp[:basename]}.uniq.sort if basenames.include? "all"
        self.report_installs basenames, :deprecated
      end # deprecated_installs

      def frozen_installs (basenames)
        self.report_installs basenames, :frozen
      end # frozen_installs

      def puppy_installs (basenames)
        connect_for_reports
        report_data = Report.client_puppyq_report_data
        unless report_data
          puts "Reports of pending puppies require a special Extension Attribute. Please see the d3 documentation"
          return false
        end
        basenames.each do |basename|

          title = "All machines with '#{basename}' in the puppy queue"
          header = %w{Computer User Edition Status Queued By As_of}
          lines = []

          report_data.each do |computer_to_report|
            this_pup = computer_to_report[:pups][basename]
            next unless this_pup
            edition = "#{basename}-#{this_pup[:version]}-#{this_pup[:revision]}"
            qd_at = this_pup[:queued_at].strftime "%Y-%m-%d"
            as_of = computer_to_report[:as_of].strftime "%Y-%m-%d"
            lines << [computer_to_report[:computer], computer_to_report[:user], edition, this_pup[:status], qd_at, this_pup[:admin], as_of]
          end # report_data.each do |computer_to_report|
          if lines.empty?
            puts "# No computers with '#{basename}' queued."
          else
            D3.less_text D3.generate_report lines, header_row: header, title: title
          end # if lines emtpy?
          puts  # blank line between, for readability
        end # basenames.each do |basename|
      end # ef puppy_installs (basenames)

      ### Show a report of all current d3 rcpts on a given computer
      ###
      ### @param client[String] the name of the computer to report on
      ###
      ### @return [void]
      ###
      def client_receipts (clients)
        connect_for_reports
        clients.each do |client|
          unless JSS::Computer.all_names.include? client
            puts "# No computer named '#{client}' in the JSS"
            next
          end

          computer = JSS::Computer.new name: client
          rcpts = nil
          full_rcpts = false
          if D3::CONFIG.report_receipts_ext_attr_name
            idx = computer.extension_attributes.index{|ea| ea[:name] == D3::CONFIG.report_receipts_ext_attr_name }
            if idx
              raw_rcpts = computer.extension_attributes[idx][:value]
              if raw_rcpts.start_with? "---\n"
                rcpts = YAML.load raw_rcpts
                full_rcpts = true
              end if raw_rcpts.start_with? "---\n"
            end # if idx
          end #  if D3::CONFIG.report_receipts_ext_attr_name

          # didn't get any rcpts from the ext attr, so use the JAMF rcpts on the client
          # to match with d3 pkgs.
          unless rcpts
            rcpts = computer.software[:installed_by_casper].sort
          end

          lines = []
          last_recon = computer.last_recon.strftime "%Y-%m-%d %H:%M:%S"

          # if full rcpts, via the ext attr, we have all rcpt data as of the last recon
          if full_rcpts
            title = "Packages installed on '#{client}' as of #{last_recon} (^=frozen)"
            header = %w{Basename Edition Status Installed By}

            ordered_basenames = rcpts.keys.sort

            ordered_basenames.each do |basename|
              rcpt = rcpts[basename]
              installed_at = rcpt.installed_at.strftime "%Y-%m-%d"
              bname = basename
              bname += "^" if  rcpt.frozen?
              lines << [bname, rcpt.edition, rcpt.status, installed_at, rcpt.admin ]
            end

          # otherwise we only know what jamf receipts are on the machine, no info
          # about when it was installed or anyting like that.
          else
            title = "Packages installed on #{client} as of #{last_recon}"
            header = %w{Basename Edition Status}
            d3_filenames_to_ids = D3::Package.all_filenames.invert
            rcpts.each do |rcpt|
               id = d3_filenames_to_ids[rcpt]
               id ||= d3_filenames_to_ids["#{rcpt}.zip"]
               next unless id
               d3_data = D3::Package.package_data[id]
               next unless d3_data
               lines << [d3_data[:basename], d3_data[:edition], d3_data[:status]]
            end
          end

          if lines.empty?
            puts "# No d3 installs on '#{client}'"
          else
            D3.less_text D3.generate_report lines, header_row: header, title: title
          end
        end # each do client
      end # def client_receipts (clients

      ###### Lists for d3admin walkthru

      ### Show a list of all package editions, pkg names and filenames
      ### known to d3 along with their status
      ###
      ### @return [void]
      ###
      def show_existing_package_ids
        # get them in alphabetical order
        #sorted_pkgs = D3::Package.package_data.values.sort{|a,b| a[:name] <=> b[:name]}
        sorted_pkgs = D3::Package.package_data.values.sort_by{|p| p[:name].downcase}

        # here's the columns we care about
        header = %w{ edition pkg_name filename JSS_id status}

        # map each one to an array of desired data
        lines = sorted_pkgs.map{|p|
          [ p[:edition],
            p[:name],
            D3::Package.all_filenames[p[:id]],
            p[:id],
            p[:status]
          ] }


        D3.less_text D3.generate_report lines, header_row: header, title: "Packages in d3"
      end

      ### Show a list of all basenames known to d3
      ### along with the status of the most recent package with that basename
      ###
      ### This is generally used with walkthrus.
      ###
      def show_all_basenames_and_editions
        sorted_data = D3::Package.package_data.values.sort_by{|p| p[:edition] }

        # here's the columns we care about
        header = %w{basename edition status}

        # map each one to an array of desired data
        lines = sorted_data.map{ |p| [ p[:basename], p[:edition], p[:status]] }

        D3.less_text D3.generate_report lines, header_row: header, title: "Basenames and Editions in d3."
      end

      ### Show a list of JSS package names that are NOT in d3.
      ###
      ### @return [void]
      def show_pkgs_available_for_import
        lines = (JSS::Package.all_names -  D3::Package.all_names).sort.map{|p| [p]}
        header = ['Package name']
        D3.less_text D3.generate_report lines, header_row: header, title: "JSS Packages available for importing to d3"
      end


      ### Show a list of computers in the JSS, to select one for reporting
      ###
      ### @return [void]
      ###
      def show_available_computers_for_reports
        lines = JSS::Computer.all_names.sort.map{|c| [c]}
        header = ['Computer name']
        D3.less_text D3.generate_report lines, header_row: header, title: "Computers in the JSS"
      end

      ###### Reports for 'd3admin show'

      ### Display a list of pkgs on the server
      ###
      ### @param title[String] the title of the displayed list
      ###
      ### @param ids[Array] an array of pkgs id's about which to
      ###   display info.
      ###
      ### @return [void]
      ###
      def display_list (title, ids, no_match_text = "No matchings packages in d3" )
        date_fmt = "%Y-%m-%d"
        header =  %w{ Edition Status Added By Released By }
        lines = []
        ids.each do |pkgid|
          p = D3::Package.package_data[pkgid]
          next unless p
          date_added = p[:added_date] ? p[:added_date].strftime(date_fmt) : "-"
          date_released = p[:release_date] ? p[:release_date].strftime(date_fmt) : "-"
          rel_by = p[:released_by] ? p[:released_by] : "-"
          lines << [p[:edition], p[:status], date_added, p[:added_by], date_released, rel_by]
        end

        puts

        if lines.empty?
          puts no_match_text
          puts
          return
        end
        lines.sort_by! {|l| l[0]}
        D3.less_text D3.generate_report(lines, header_row: header, title: title)
        puts # empty line between
      end # display list

      ### Show a list of pkgs from the d3admin 'show' action
      ###
      ### @param what_to_show[Symbol] which kind of pkgs to show
      ###
      ### @return [void]
      ###
      def show_list(what_to_show = :all)
        what_to_show = :all if what_to_show.to_s.empty?

        if what_to_show == :all
          display_list "All packages in d3", D3::Package.package_data.keys
        else
          title = "All #{what_to_show} packages in d3"
          ids = D3::Package.package_data.values.select{|p| p[:status] == what_to_show }.map{|p| p[:id]}
          display_list title, ids, "No #{what_to_show} packages in d3"
        end # if what_to_show == :all
      end # def show_list(what_to_show = :all)s

      ### list packages that auto-install onto machines
      ### in one or more given groups
      ###
      ### @param groups[String,Array<String>] the group or groups to show.
      ###
      ### @return [void]
      ###
      def list_auto_installs(groups)
        groups = JSS.to_s_and_a(groups)[:arrayform]
        groups.each do |group|
          unless JSS::ComputerGroup.all_names.include? group
            puts
            puts "No computer group named '#{group}'"
            puts
            next
          end
          ids =  D3::Package.auto_install_ids_for_group group
          title = "Editions that auto-install for group '#{group}'"
          display_list title, ids, "No packages in d3 auto-install for group '#{group}'"
        end # do group
      end # list_auto_installs

      ### list packages that are excluded for machines in one
      ### or more given groups
      ###
      ### @param groups[String,Array<String>] the group or groups to show.
      ###
      ### @return [void]
      ###
      def list_excl_installs(groups)
        groups = JSS.to_s_and_a(groups)[:arrayform]
        groups.each do |group|
           unless JSS::ComputerGroup.all_names.include? group
            puts
            puts "No computer group named '#{group}'"
            puts
            next
          end
          ids =  D3::Package.exclude_ids_for_group group
          title = "Editions that are excluded for group '#{group}'"
          display_list title, ids, "No packages in d3 are excluded for group '#{group}'"
        end # do group
      end # list_excl_installs

      ###### Data gathering

      ### Reconnect to both the API and DB with a much larger timeout, and
      ### using an alternate DB server if one is defined.
      ###
      ### @return [Hash<String>] the hostnames of the connected JSS & MySQL servers
      ###
      def connect_for_reports
        api = D3::Admin::Auth.rw_credentials :jss
        db = D3::Admin::Auth.rw_credentials :db
        D3.connect_for_reports  api[:user], api[:password], db[:user], db[:password]
      end # connect for report

      ### Get the raw data for a client-install report, from the EA if available
      ### or from the JAMF receipts if not.
      ###
      ### Returns a two item array, the first is the report data (see
      ### client_install_ea_report_data and client_install_jamf_rcpt_report_data)
      ### The second is :ea or :jamf_rcpts,  indicating the data source
      ###
      ### @return  [Array<Array<Hash>, Symbol>] The data for doing client install reports, and the
      ###   data source
      ###
      def client_install_report_data
        puts "Querying Casper computers for report data..."

        if the_data = client_install_ea_report_data
          src = :ea
        else
          the_data = [client_install_jamf_rcpt_report_data, :jamf_rcpts]
          the_data ||= []
          src = :jamf_rcpts
        end
        return [the_data.sort_by{|c|c[:computer]}, src]
      end

      ### Get the latest data from the D3::CONFIG.report_receipts_ext_attr_name
      ### if that EA exists, nil otherwise
      ###
      ### The result is and Array of Hashes, one for each computer in Casper.
      ### Each hash contains these keys:
      ###   :computer - the name of the computer
      ###   :user - the name of the comptuer's user
      ###   :as_of - the Time when the data was gathered
      ###   :rcpts - a Hash of receipt data for the computer, keyed by basename.
      ###
      ### Each receipt in the :rcpts hash contains these keys
      ###   :version
      ###   :revision
      ###   :status
      ###   :installed_at
      ###   :admin
      ###   :frozen
      ###   :manual
      ###   :custom_expiration
      ###   :last_usage
      ###
      ### @return [Array<Hash>] The data from the extension attribute
      ###
      def client_install_ea_report_data
        return nil unless D3::CONFIG.report_receipts_ext_attr_name
        connect_for_reports

        ea = JSS::ComputerExtensionAttribute.new :name => D3::CONFIG.report_receipts_ext_attr_name

        # while we could get the data via the API by calling: result = ea.latest_values
        # but thats very slow, because it creates a temporary AdvancedSearch,
        # and retrieves it's results, and API access is always pretty slow
        # Going directly to SQL is WAY faster and since this is D3, we can.

        #

        q = <<-ENDQ
SELECT c.computer_id, c.computer_name, c.username, c.last_report_date_epoch AS as_of, eav.value_on_client AS value
FROM computers_denormalized c
  JOIN extension_attribute_values eav
    ON c.last_report_id = eav.report_id
WHERE eav.extension_attribute_id = #{ea.id}
        ENDQ

        result = JSS::DB_CNX.db.query q

        report_data = []
        result.each_hash do |ea_result|
          rcpts ={}
          if ea_result['value'].start_with? '{"'
            # the ea contains the full receipt YAML.
            # for now we only need this subset of it.
            rcpt_data = JSON.load ea_result['value']
            rcpt_data.each do |basename, raw|
              this_r = {}
              this_r[:version] = raw["version"]
              this_r[:revision] = raw["revision"].to_i
              this_r[:status] = raw["status"].to_sym
              this_r[:installed_at] = raw["installed_at"] ? Time.parse(raw["installed_at"]) : nil
              this_r[:admin] = raw["admin"]
              this_r[:frozen] = raw["frozen"]
              this_r[:manual] = raw["manual"]
              this_r[:custom_expiration] = raw["custom_expiration"]
              this_r[:last_usage] = raw["last_usage"] ? Time.parse(raw["last_usage"]) : nil

              rcpts[basename] = this_r
            end # each do r

          end # if ea_result['value'].start_with?  '{"'
          report_data << {
            :computer => ea_result["computer_name"],
            :user => ea_result["username"],
            :rcpts => rcpts,
            :as_of =>  (JSS.epoch_to_time ea_result["as_of"])
          }

        end # result.each_hash do |ea_result|

        return report_data.sort_by!{|v| v[:computer]}
      end # def ea_report_data

      ### get the latest receipt data from Caspers receipts table
      ### This is used if the D3::CONFIG.report_receipts_ext_attr_name is not set
      ### and the data it returns is less useful.
      ###
      ### The result is and Array of Hashes, one for each computer in Casper.
      ### Each hash contains these keys:
      ###   :computer - the name of the computer
      ###   :user - the name of the comptuer's user
      ###   :as_of - the Time when the data was gathered
      ###   :rcpts - a Hash of receipt data for the computer, keyed by basename.
      ###
      ### Each receipt in the :rcpts hash contains these keys
      ###   :version
      ###   :revision
      ###   :status
      ###
      ### @return [Array<Hash>] The data from the extension attribute
      def client_install_jamf_rcpt_report_data
        q = <<-ENDQ
SELECT c.computer_name, c.username, GROUP_CONCAT(r.package_name) AS jamf_receipts, c.last_report_date_epoch AS as_of
FROM computers_denormalized c JOIN package_receipts r ON c.computer_id = r.computer_id
WHERE r.type = 'jamf'
GROUP BY c.computer_id
ENDQ

        res = JSS::DB_CNX.db.query q

        report_data = []

        pkg_filenames_to_ids = D3::Package.all_filenames.invert

        res.each_hash do |record|
          computer_data = {:computer => record['computer_name']}
          computer_data[:as_of] = JSS.epoch_to_time record['as_of']
          computer_data[:user] = record['username']
          computer_data[:rcpts] = {}
          record['jamf_receipts'].split(',').each do |jrcpt|

            rcpt_id = pkg_filenames_to_ids[jrcpt]
            # some might be zipped
            rcpt_id ||= pkg_filenames_to_ids[jrcpt + ".zip"]

            next unless rcpt_id
            pkg_data = D3::Package.package_data[rcpt_id]
            next unless pkg_data
            computer_data[:rcpts][pkg_data[:basename]] = {:version =>pkg_data[:version], :revision => pkg_data[:revision], :status => pkg_data[:status]}
          end  #record['jamf_receipts'].split(',').each do
          report_data << computer_data
        end # res.each_hash do |record|
        res.free
        return report_data.sort_by! {|v| v[:computer]}
      end # def jamf_rcpt_report_data


      ### get the latest puppy queue data from the puppy q EA, if available.
      def client_puppyq_report_data
        return nil unless D3::CONFIG.report_puppyq_ext_attr_name
        connect_for_reports
        ea = JSS::ComputerExtensionAttribute.new :name => D3::CONFIG.report_puppyq_ext_attr_name
        q = <<-ENDQ
SELECT c.computer_id, c.computer_name, c.username, c.last_report_date_epoch AS as_of, eav.value_on_client AS value
FROM computers_denormalized c
  JOIN extension_attribute_values eav
    ON c.last_report_id = eav.report_id
WHERE eav.extension_attribute_id = #{ea.id}
        ENDQ

        result = JSS::DB_CNX.db.query q

        report_data = []
        result.each_hash do |ea_result|
          pups ={}
          if ea_result['value'].start_with? '{"'
            # the ea contains the full receipt YAML.
            # for now we only need this subset of it.
            pup_data = JSON.load ea_result['value']
            pup_data.each do |basename, raw|
              this_p = {}
              this_p[:version] = raw["version"]
              this_p[:revision] = raw["revision"].to_i
              this_p[:status] = raw["status"].to_sym
              this_p[:queued_at] = raw["queued_at"] ? Time.parse(raw["queued_at"]) : nil
              this_p[:admin] = raw["admin"]
              this_p[:custom_expiration] = raw["custom_expiration"]
              pups[basename] = this_p
            end # each do r

          end # if ea_result['value'].start_with?  '{"'
          report_data << {
            :computer => ea_result["computer_name"],
            :user => ea_result["username"],
            :pups => pups,
            :as_of =>  (JSS.epoch_to_time ea_result["as_of"])
          }

        end # result.each_hash do |ea_result|

        return report_data.sort_by!{|v| v[:computer]}
      end # def client_puppyq_report_data

    end # module Report
  end # module Admin
end # module D3

