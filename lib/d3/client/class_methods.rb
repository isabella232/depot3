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
  class Client < JSS::Client

    ################# Class Methods #################

    ### Install one or more packages from the command-line
    ### by basename, or edition (or name, filename, id)
    ###
    ### This method is only used by manual installs (i.e. not
    ### automated via d3 sync)
    ###
    ### Basenames always gets the live pkg for that basename
    ###
    ### Editions install the package regardless of status.
    ###
    ### @param pkgs[Array<String,Int>] The packages to install
    ###
    ### @param options[OpenStruct] the d3 client cli options
    ###
    ### @return [void]
    ###
    def self.install(pkgs, options = {})

      pkgs = [pkgs] if pkgs.is_a? String

      pkgs.each do |pkg_to_search|
        begin
          # get a D3::Package object
          desired_pkg = D3::Package.find_package(pkg_to_search)

          raise JSS::NoSuchItemError, "No d3 package matching #{pkg_to_search}" unless desired_pkg

          # are we manually installing over a frozen rcpt?
          curr_rcpt = D3::Client::Receipt.all[desired_pkg.basename]
          if curr_rcpt && curr_rcpt.frozen?
            D3.log "Un-freezing #{curr_rcpt.edition} by installing #{desired_pkg.edition} manually", :warn
          end

          installing = desired_pkg.live?  \
            ? "currently live #{desired_pkg.basename}"  \
            : "#{desired_pkg.edition} (#{desired_pkg.status})"

          D3.log "Installing #{installing}...", :warn

          desired_pkg.install(
            :force => options.force,
            :admin => self.get_admin(desired_pkg, options),
            :puppywalk => options.puppies,
            :expiration => options.custom_expiration,
            :verbose => options.verbose,
            :alt_download_url => self.cloud_dist_point_to_use
            )

          D3.log "Finished installing #{installing}", :info

        rescue JSS::MissingDataError, JSS::InvalidDataError, D3::InstallError
          D3.log "Skipping installation of #{pkg_to_search}:\n   #{$!}", :error
          D3.log_backtrace
        rescue D3::PreInstallError
          D3.log "There was an error with the pre-install script for #{desired_pkg.edition}:\n   #{$!}", :error
          D3.log_backtrace
        rescue D3::PostInstallError
          D3.log "There was an error with the post-install script for #{desired_pkg.edition}:\n   #{$!}", :error
          D3.log "   NOTE: it was installed, but may have problems.", :error
          D3.log_backtrace
        end # begin
      end # args.each
    end # install

    ### uninstall one or more packages from the commandline
    ###
    ### @param pkgs[Array<String,Int>] The packages to uninstall
    ###
    ### @return [void]
    ###
    def self.uninstall(rcpts, options)
      rcpts = [rcpts] if rcpts.is_a? String
      rcpts.each do |rcpt_to_remove|
        begin

          rcpt = D3::Client::Receipt.find_receipt rcpt_to_remove
          raise D3::UninstallError, "No receipt for '#{rcpt_to_remove}', can't uninstall." unless rcpt

          D3.log "Uninstalling #{rcpt.edition}...", :info
          rcpt.uninstall options.verbose, options.force
          D3.log "Finished uninstalling #{rcpt.edition}.", :info

        rescue JSS::MissingDataError, D3::UninstallError, JSS::InvalidDataError
          D3.log "Skipping uninstall of #{rcpt_to_remove}:\n   #{$!}", :error
          D3.log_backtrace
          next
        end # begin
      end # rcpts.each

    end #uninstall_manual

    ### Return a valid, possibly-default, admin name for
    ### installing a package. Since the admin name is stored in
    ### the packages in the puppy-q, use that one if it's there.
    ###
    ### @param pkg[D3::Package] the pkg being installed, which might contain an
    ###   admin name
    ###
    ### @return [String] a valid admin name to use for the install
    ###
    def self.get_admin(pkg_to_install, options)

      # is this puppy already in the queue? If so,
      # the queue has our admin_name
      if options.puppies and D3::PUPPY_Q.q[pkg_to_install.basename] then

        admin = D3::PUPPY_Q.q[pkg_to_install.basename].admin
        admin ||= D3::DFT_PUPPY_ADMIN

      # not a puppy pkg
      else
        # start with the cli options
        admin = options.admin
        # then do a lookup if no cli option
        admin ||= D3.admin

      end # if @options.puppies

      return admin
    end # get admin name

    ### Remove one or more puppies from the puppy queue
    ###
    ### @param puppies[String, Array<String>] the basenames to remove from the queue
    ###
    ### @return [void]
    ###
    def self.dequeue_puppies (puppies)
      puppies = [puppies] if puppies.is_a? String
      puppies = D3::PUPPY_Q.pups if puppies.include? "all"
      puppies.each do |pup|
        unless the_puppy = D3::PUPPY_Q.q[pup]
          D3.log "No pkg for basename '#{pup}' in the puppy queue.", :warn
          next
        end # unless
        begin
          D3.log "Removing '#{the_puppy.edition}' from the puppy queue.", :warn
          D3::PUPPY_Q - the_puppy
        rescue
          D3.log  "Couldn't remove #{the_puppy.edition} from the puppy queue: #{$!}", :error
        end # begin
      end
    end

    ### Sync this machine
    ###
    ### @param options[OpenStruct] the options from the commandline
    ###
    ### @return [void]
    ###
    def self.sync (options = OpenStruct.new)
      D3::Client.set_env :sync
      D3.log "Starting sync", :warn
      begin
        # update rcpts
        update_rcpts
        
        # clean out any invalid puppies from the queue
        clean_doghouse
        
        # install puppies now?
        do_puppy_queue_installs_from_sync options

        # updates/patches?
        update_installed_pkgs options

        # new auto-installs?
        do_auto_installs options

        # expirations
        do_expirations

        D3.log "Finished sync", :warn
      ensure
        D3::Client.unset_env :sync
      end
    end # def sync

    ### Update any receipt data that might be changed in the matching package
    ### on the server, including:
    ### - status
    ### - pre- or post-remove scripts
    ### - removability
    ### - prohibiting process
    ### - expiration details
    ###
    ### Also update
    ### - last usage for expiring pkgs
    ###
    ### @return [void]
    ###
    def self.update_rcpts
      D3.log "Updating d3 receipts", :info
      need_saving = false

      D3::Client::Receipt.all.each do |basename, rcpt|
        pkgdata = D3::Package.find_package rcpt.edition, :hash

        unless pkgdata
          # if this pkg is missing, mark it so...
          D3.log "Receipt '#{rcpt.edition}' is missing from d3. Updating receipt.", :info
          rcpt.status = :missing
          rcpt.update
          next
        end

        # status - this will also 'enliven' pilots that have
        # gone live.
        if rcpt.status != pkgdata[:status]
          rcpt.status = pkgdata[:status]
          D3.log "Updating status for #{rcpt.edition} to #{pkgdata[:status]}", :info
          rcpt.update
        end # if

        # pre-remove script
        if rcpt.pre_remove_script_id != pkgdata[:pre_remove_script_id]
          rcpt.pre_remove_script_id = pkgdata[:pre_remove_script_id]
          D3.log "Updating pre-remove script for #{rcpt.edition}", :info
          rcpt.update
        end # if

        # post-remove script
        if rcpt.post_remove_script_id != pkgdata[:post_remove_script_id]
          rcpt.post_remove_script_id = pkgdata[:post_remove_script_id]
          D3.log "Updating post-remove script for #{rcpt.edition}", :info
          rcpt.update
        end # if

        # removability
        if rcpt.removable? != pkgdata[:removable]
          rcpt.removable = pkgdata[:removable]
          D3.log "Updating removability for #{rcpt.edition}", :info
          unless rcpt.removable?
            rcpt.expiration = 0
            D3.log "#{rcpt.edition} is not expirable now that it's not removable", :info
          end
          rcpt.update
        end # if

        # expiration
        if rcpt.removable?
          if rcpt.expiration_path != pkgdata[:expiration_path]
            rcpt.expiration_path = pkgdata[:expiration_path]
            D3.log "Updating expiration path for #{rcpt.edition}", :info
            rcpt.update
          end # if

          if (rcpt.expiration != pkgdata[:expiration].to_i) and (not rcpt.custom_expiration)
            rcpt.expiration = pkgdata[:expiration].to_i
            D3.log "Updating expiration for #{rcpt.edition}", :info
            rcpt.update
          end # if
        end # if removable

        # prohibiting_process
        if rcpt.prohibiting_process != pkgdata[:prohibiting_process]
          rcpt.prohibiting_process = pkgdata[:prohibiting_process]
          D3.log "Updating prohibiting_process for #{rcpt.edition}", :info
          rcpt.update
        end # if

        # last usage
        # this will update the last_usage value stored in the rcpt (for reporting only)
        # (expiration only looks at current usage data)
        if rcpt.expiration_path
          rcpt.last_usage
          rcpt.update
        end

        end # each do basename, rcpt
    end # update
    
    ### remove any invalid puppies from the queue
    ### invalid = id is no longer in d3, or status is missing
    ###
    ### @return [void]
    ###
    def self.clean_doghouse
      D3.log "Checking for invalid puppies in the queue", :info
      D3::PuppyQueue.pending_puppies.each do |basename, pup|
        unless D3::Package.all_ids.include? pup.id
          D3.log "Removing #{pup.edition} from puppy queue: no longer in d3", :info
          D3::PuppyQueue - pup 
          next
        end
        if D3::Package.missing_data.keys.include? pup.id
          D3.log "Removing #{pup.edition} from puppy queue: status is 'missing'", :info
          D3::PuppyQueue - pup 
        end
      end
    end
    
    ### Install any new live pkgs scoped for autoinstall on this machine.
    ###
    ### @param options[OpenStruct] the options from the commandline
    ###
    ### @return [void]
    ###
    def self.do_auto_installs (options)
      verbose = options.verbose
      force =  options.force or D3.forced?
      D3.log "Checking for new pkgs to auto-install", :info
      D3::Client.set_env :auto_install
      begin # for ensure below
        installed_basenames = D3::Client::Receipt.basenames :refresh

        # loop through the groups for this machine
        auto_groups = D3::Client.computer_groups.dup
        auto_groups.unshift D3::STANDARD_AUTO_GROUP
        auto_groups.each do |group|
          # this is the intersection of all pkg ids that get auto-installed
          # for the group, and all live pkg ids...
          # meaning this machine should have these pkg ids.
          live_ids_for_group = ( D3::Package.live_data.keys &  D3::Package.auto_install_ids_for_group(group))

          live_ids_for_group.each do |live_id|

            # skip thos not available
            next unless self.available_pkg_ids.include? live_id

            auto_install_basename = D3::Package.live_data[live_id][:basename]

            # skip if this basename is installed already - it'll be handled with
            # the update_installed_pkgs method during sync.
            next if D3::Client::Receipt.all.keys.include? auto_install_basename

            new_pkg = D3::Package.new :id => live_id
            begin
              D3.log "Auto-installing #{new_pkg.basename} for group '#{group}'", :info
              new_pkg.install(
                :admin => D3::AUTO_INSTALL_ADMIN,
                :verbose => verbose,
                :force => force,
                :puppywalk => options.puppies,
                :alt_download_url => self.cloud_dist_point_to_use
              )
              D3.log "Auto-installed #{new_pkg.basename}", :debug
            rescue JSS::MissingDataError, JSS::InvalidDataError, D3::InstallError
              D3.log "Skipping auto-install of #{new_pkg.edition}:\n   #{$!}", :error
              D3.log_backtrace
            rescue D3::PreInstallError
              D3.log "There was an error with the pre-install script for #{new_pkg.edition}:\n   #{$!}", :error
              D3.log_backtrace
            rescue D3::PostInstallError
              D3.log "There was an error with the post-install script for #{new_pkg.edition}:\n   #{$!}", :error
              D3.log "   NOTE: #{new_pkg.edition} was installed, but may not work.", :error
              D3.log_backtrace
            end #begin
          end # live_ids_for_group.each do |live_id|
        end # each group
      ensure
        D3::Client.unset_env :auto_install
      end
    end

    ### Update any currently installed pkgs as needed
    ### skipping any basenames currently in pilot
    ###
    ### @param options[OpenStruct] the options from the commandline
    ###
    ### @return [void]
    ###
    def self.update_installed_pkgs (options)
      verbose = options.verbose
      force =  options.force or D3.forced?
      D3.log "Checking for updates to installed packages", :info
      D3::Client.set_env :auto_update
      begin # see ensure below
        # get the current list of live basenames and the ids of the live editions
        live_basenames_to_ids = D3::Package.basenames_to_live_ids

        # loop through the install pkgs
        D3::Client::Receipt.all.values.each do |rcpt|
          
          # skip unless the live id is higher than the rcpt id
          unless live_basenames_to_ids[rcpt.basename] > rcpt.id
            D3.log "No update for #{rcpt.edition}", :debug
            next
          end
          
          # skip any frozen receipts
          if rcpt.frozen?
            D3.log "Skipping update check for #{rcpt.edition}: currently frozen on this machine.", :debug
            next
          end
          
          # skip installed pilots
          if rcpt.pilot?
            D3.log "Skipping update for #{rcpt.edition}: currently in pilot", :debug
            next
          end
          
          # skip skipped pkgs
          if rcpt.skipped?
            D3.log "Skipping update for #{rcpt.edition}: piloted edition was skipped.", :debug
            # TO DO - some kind of notification policy ??
            next
          end
          
          # skip any installed basename that doesn't have a live id
          unless live_basenames_to_ids.keys.include? rcpt.basename
            D3.log "Skipping update check for #{rcpt.edition}: no currently live package for basename", :debug
            next
          end
          
          # if we're here, there's a new version to install
          new_pkg = D3::Package.new :id => live_basenames_to_ids[rcpt.basename]

          # are we bringing over a custom expiration period?
          expiration = rcpt.custom_expiration ? rcpt.expiration : nil

          begin
            D3.log "Attempting to update #{rcpt.edition} to #{new_pkg.edition}", :info
            new_pkg.install(
              :admin => rcpt.admin,
              :expiration => expiration,
              :verbose => verbose,
              :force => force,
              :puppywalk => options.puppies,
              :alt_download_url => self.cloud_dist_point_to_use
              )
            D3.log "Updated #{rcpt.edition} to #{new_pkg.edition}", :debug
          rescue JSS::MissingDataError, JSS::InvalidDataError, D3::InstallError
            D3.log "Skipping update of #{rcpt.edition} to #{new_pkg.edition}:\n   #{$!}", :error
            D3.log_backtrace
          rescue D3::PreInstallError
            D3.log "There was an error with the pre-install script for #{new_pkg.edition}:\n   #{$!}", :error
            D3.log_backtrace
          rescue D3::PostInstallError
            D3.log "There was an error with the post-install script for #{new_pkg.edition}:\n   #{$!}", :error
            D3.log "   NOTE: #{new_pkg.edition} was installed, but may not work.", :error
            D3.log_backtrace
          end # begin
        end # D3::Client::Receipt.all.values.each
      ensure
        D3::Client.unset_env :auto_update
      end # begin..ensure
    end

    ### Freeze one or more receipts
    ###
    ### @param basenames[Array] the basenames of the rcpts to freeze
    ###
    ### @return [void]
    ###
    def self.freeze_receipts (basenames)
      basenames.each do |bn|
        rcpt = D3::Client::Receipt.all[bn]
        next unless rcpt
        if rcpt.frozen
          D3.log "Can't freeze receipt for #{rcpt.edition}: already frozen.", :warn
          next
        end
        rcpt.freeze
        rcpt.update
        D3.log "Freezing receipt for #{rcpt.edition}, will no longer auto-update during sync", :warn
      end
    end # freeze receipts

    ### Thaw one or more receipts
    ###
    ### @param basenames[Array] the basenames of the rcpts to thaw
    ###
    ### @return [void]
    ###
    def self.thaw_receipts (basenames)
      basenames.each do |bn|
        rcpt = D3::Client::Receipt.all[bn]
        next unless rcpt
        unless rcpt.frozen
          D3.log "Can't thaw receipt for #{rcpt.edition}: not frozen.", :warn
          next
        end
        rcpt.thaw
        rcpt.update
        D3.log "Thawing receipt for #{rcpt.edition}, will resume auto-update during sync", :warn
      end
    end # freeze receipts

    ### Do any pending puppy installs right now, because we're
    ### syncing and --puppies option was given
    ###
    def self.do_puppy_queue_installs_from_sync (options)
      return unless options.puppies
      return if  D3::PUPPY_Q.q.empty?
      D3.log "Installing all pkgs from puppy-queue during sync with --puppies", :info
      D3::PUPPY_Q.q.each do |basename, puppy|
        begin
          D3.log "Installing #{puppy.edition} from puppy-queue during sync with --puppies", :debug
          new_pkg = D3::Package.new :id => puppy.id
          new_pkg.install(
            :admin => puppy.admin,
            :verbose => options.verbose,
            :force => puppy.force,
            :puppywalk => true,
            :expiration => puppy.expiration,
            :alt_download_url => self.cloud_dist_point_to_use
            )

          D3::PUPPY_Q - puppy
        rescue JSS::NoSuchItemError
          D3.log "Skipping install of #{new_pkg.edition} from queue:\n   no longer in d3.", :error
          D3.log_backtrace
          D3::PUPPY_Q - puppy
        rescue JSS::MissingDataError, JSS::InvalidDataError, D3::InstallError
          D3.log "Skipping install of #{new_pkg.edition} from queue:\n   #{$!}", :error
          D3.log_backtrace
        rescue D3::PreInstallError
          D3.log "There was an error with the pre-install script for #{new_pkg.edition}:\n   #{$!}", :error
          D3.log_backtrace
        rescue D3::PostInstallError
          D3.log "There was an error with the post-install script for #{new_pkg.edition}:\n   #{$!}", :error
          D3.log "   NOTE: #{new_pkg.edition} was installed, but may not work.", :error
          D3.log_backtrace
          D3::PUPPY_Q - puppy
        end # begin
      end # each do puppy
    end

    ### Was the --no-puppy-notification option given by the admin?
    ###
    ### @return [Boolean]
    ###
    def self.puppy_notification_ok_with_admin?
      @@puppy_notification_ok_with_admin
    end

    ### Set the --no-puppy-notification option as given by the admin
    ###
    ### @param bool[Boolean] did the admin give the option?
    ###
    ### @return [void]
    ###
    def self.puppy_notification_ok_with_admin= (bool)
      @@puppy_notification_ok_with_admin = bool
    end

    ### Expire any pkgs that are due for expiration,
    ### and if any are expired, run the expiration policy.
    ###
    ### @param verbose[Boolean] should operations be verbose?
    ###
    ### @param force[Boolean] should operations be forced?
    ###
    ### @return [void]
    ###
    def self.do_expirations (verbose = false, force = D3.forced?)
      @@editions_expired = []
      D3.log "Starting expiration check", :info

      D3::Client::Receipt.all.values.each do |rcpt|
        begin
          # rcpt.expire only does anything if expiration is appropriate.
          expired_edition = rcpt.expire verbose, force
          @@editions_expired << expired_edition if expired_edition
        rescue
          D3.log "There was an error expiring #{rcpt.edition}:\n   #{$!}", :error
          D3.log_backtrace
        end
      end

      return true if @@editions_expired.empty?

      D3::Client.set_env :finished_expirations, @@editions_expired.join(" ")

      if policy = D3::CONFIG.client_expiration_policy
        D3.run_policy policy, :expiration, verbose
      end # if D3::CONFIG.client exp policy

      D3::Client.unset_env :finished_expirations
      @@editions_expired = []
    end

    ### An array of package ids that are available for installing
    ### or piloting (i.e. not excluded, right OS, right cpu) for this machine.
    ###
    ### @param refresh[Boolean] re-read the data from the server?
    ###
    ### @return [Array<Integer>]
    ###
    def self.available_pkg_ids (refresh = false)
      @@available_pkg_ids = nil if refresh
      return @@available_pkg_ids if @@available_pkg_ids

      self.computer_groups(:refresh) if refresh

      my_cpu = `/usr/bin/uname -p`
      my_os = `/usr/bin/sw_vers -productVersion`.chomp

      @@available_pkg_ids = []

      D3::Package.package_data.values.each do |pkg|
        next unless JSS.os_ok? pkg[:oses], my_os
        next unless JSS.processor_ok? pkg[:required_processor], my_cpu
        @@available_pkg_ids << pkg[:id] if (pkg[:excluded_groups] & self.computer_groups).empty?
      end # do pkg
      @@available_pkg_ids
    end

    ### An array of JSS::ComputerGroup names to which this computer belongs
    ###
    ### @param refresh[Boolean] re-read the data from the server?
    ###
    ### @return [Array<String>] the JSS groups to which this machine belongs
    ###
    def self.computer_groups (refresh = false)
      @@computer_groups = nil if refresh
      return @@computer_groups if @@computer_groups
      @@computer_groups = JSS::Computer.new(:udid => JSS::Client.udid).computer_groups
    end

    ### The cloud dist point to use for installs
    ### Returns a URL if:
    ###   - current dist point isn't reachable for downloads
    ###   - D3::CONFIG.client_try_cloud_distpoint is true
    ###   - a Cloud Dist Point is defined in the JSS
    ###
    ### otherwise nil
    ###
    ### @return [String, nil] The download url for the cloud dist point,
    ###   if we should use one, or nil.
    ###
    def self.cloud_dist_point_to_use(refresh = false)
      @@cloud_dist_url == :unknown if refresh
      return @@cloud_dist_url unless @@cloud_dist_url == :unknown

      mdp = JSS::DistributionPoint.my_distribution_point

      unless D3::CONFIG.client_try_cloud_distpoint
        D3.log "Config is not to try cloud, using only Distribution Point '#{mdp.name}'", :info
        return @@cloud_dist_url =  nil
      end

      if mdp.reachable_for_download?(self.get_ro_pass :http) or mdp.reachable_for_download?(self.get_ro_pass :dist)
        D3.log "Distribution Point '#{mdp.name}' is reachable, no need for cloud", :info
        return @@cloud_dist_url =  nil
      end
      cloud_url = self.cloud_distribution_point_url
      if cloud_url
        D3.log "Cloud distribution URL found '#{cloud_url}', will use for pkg installs", :info
      else
        D3.log "No cloud distribution URL found.", :info
      end
      @@cloud_dist_url = cloud_url
    end

    ### Is a Cloud Distribution Point available for pkg downloads?
    ### If so, return the url for downloading pkg files
    ### (the filename will be appended during install)
    ###
    ### @return [String, nil]
    ###
    def self.cloud_distribution_point_url
      result = JSS::DB_CNX.db.query "SELECT download_url, cdn_url FROM cloud_distribution_point"
      urls = result.fetch
      result.free
      return nil if urls.nil?
      return nil if urls[0].empty? and urls[1].empty?
      return urls[0].empty? ? urls[1] : urls[0]
    end

  end # class
end # module D3

