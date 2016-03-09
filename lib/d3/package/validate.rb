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
  class Package < JSS::Package

    ### General validation checks for the package as a whole,
    ### For individual attribute validation, see the
    ### D3::Package::Validate module.

    ### Check that there's not a newwer version of this thing alreay installed
    ### Raise an exception if so.
    ###
    ### return [void]
    ###
    def check_for_newer_version
      if D3::Client::Receipt.basenames.include? @basename and D3::Client::Receipt.all[@basename].id >= @id
          raise D3::InstallError, "The installed #{@basename} (#{D3::Client::Receipt.all[@basename].edition}) is the same or newer. \nUse --force to re-install."
      end
    end # check for newer version

    ### Check that we're not deprecated, and raise an exception if we are.
    ###
    ### return [void]
    ###
    def check_for_deprecation
      raise D3::InstallError, "'#{edition}' is deprecated.\nUse 'd3 install #{@basename}' to install the live edition or --force to install this one." if deprecated?
    end

    ### Check that we're not skipped, and raise an exception if we are.
    ### Used if we try to pilot something that's older than the current live.
    ###
    ### return [void]
    ###
    def check_for_skipped
      raise D3::InstallError, "#{edition} was never made live and a newer edition was.\nUse 'd3 install #{@basename}' to install it or 'd3 install <edition>' to pilot an unreleased edition or --force to install this one." if skipped?
    end

    ### Check if this machine is in an excluded group.
    ### Raise an exception if so.
    ###
    ### return [void]
    ###
    def check_for_exclusions
      excl_grps = D3::Client.computer_groups & @excluded_groups
      raise D3::InstallError,  "This machine is in these excluded groups for #{self.edition}: #{excl_grps.join ', '}.\nUse --force to install anyway." unless excl_grps.empty?
    end # check for exclusions
    
    ### Check if this machine is OK wrt to the os limitations
    ### Raise an exception if not
    ###
    ### return [void]
    ###
    def check_oses
       my_os = `/usr/bin/sw_vers -productVersion`.chomp
       raise D3::InstallError,  "This machine doesn't have the correct OS to install #{self.edition}." unless JSS.os_ok?  @os_requirements, my_os
    end
    
    ### Check if this machine is OK wrt to the processor limitations
    ### Raise an exception if not
    ###
    ### return [void]
    ###
    def check_cpu
       my_cpu = `/usr/bin/uname -p`.chomp
       raise D3::InstallError,  "This machine doesn't have the correct OS to install #{self.edition}." unless  JSS.processor_ok?  @required_processor, my_cpu
    end
    

    ### Raise an exception if this is pkg is live
    ### (used when installing pilots)
    ###
    ### return [void]
    ###
    def check_for_invalid_live_install
      raise D3::InstallError, "'#{edition}' is currently live, use 'd3 install #{@basename}'" if live?
    end

    ### Raise an exception if this is pkg is pilot
    ###
    ### return [void]
    ###
    def check_for_invalid_pilot_install
      raise D3::InstallError,  "'#{edition}' is currently in pilot, use 'd3 pilot #{edition}'" if pilot?
    end

    ### Raise an exception if this is basename is being piloted now
    ### on this machine
    ###
    ### return [void]
    ###
    def check_for_already_piloting
      if D3::Client::Receipt.pilots.keys.include? @basename
        raise D3::InstallError, "#{@basename} is being piloted on this machine, can't do a normal install."
      end
    end

    ### This module contains methods for validating attribute
    ### values in d3 Packages
    ###
    ### Each method takes an argument, and either raises an exception
    ### if the argument isn't valid for its destination, or
    ### converts it to the proper type for its destination.
    ###
    ### For example, the {#validate_groups} takes either a comma-seprated String
    ### or an Array of computer group names, converts the String to an Array
    ### if needed, and then confirms that each group exists in the JSS
    ### If they all do, the Array is returned.
    ###
    module Validate
      extend self

      ### Check the existence of a basename in d3.
      ###
      ### @param name[String] the basename to check
      ###
      ### @return [Boolean] does that basename exist in d3?
      ###
      def basename_exist? (name)
        D3::Package.all_basenames.include? name
      end

      ### Check the existence of an edition in d3.
      ###
      ### @param name[String] the edition to check
      ###
      ### @return [Boolean] does that edition exist in d3?
      ###
      def edition_exist? (edition)
        D3::Package.all_editions.include? edition
      end

      ### Check the existence of a filename in the JSS.
      ###
      ### @param name[String] the name to check
      ###
      ### @return [Boolean] does that package filename exist in d3?
      ###
      def filename_exist? (name)
        D3::Package.all_filenames.values.include? name
      end


      ### check that the given package name doesn't already exist
      ###
      ### @see {JSS::Package.validate_package_name}
      ###
      def validate_package_name(name)
        raise JSS::AlreadyExistsError, "There's already a package in the JSS with the name '#{name}'" if JSS::Package.all_names.include? name
        name
      end

      ### check that the given filename doesn't already exist
      ###
      ### @param name[String] the name to check
      ###
      ### @return [String] the valid new file name
      ###
      def validate_filename(name)
        raise JSS::AlreadyExistsError, "There's already a package in the JSS with the filename '#{name}'" if self.filename_exist? name
        name
      end

      ### Check if an edition exists and raise an exception if so
      ### Also check that it contains at least two hyphens
      ###
      ### @param edition[String] the edition to check
      ###
      ### @return [String] the valid, unique edition
      ###
      def validate_edition (edition)
        raise JSS::AlreadyExistsError, "There's already a package in the JSS with the edition '#{edition}'" if edition_exist? edition
        raise JSS::InvalidDataError, "'#{edition}' doesn't seem like a valid edition" unless edition.count("-") >= 2
        edition
      end



      ### Confirm the validity of a version. Raise an exception if invalid.
      ###
      ### @param vers[String] the version to check
      ###
      ### @return [String] An error message, or true if the value is ok
      ###
      def validate_version (vers)
        raise JSS::InvalidDataError, "Version must be a String." unless vers.is_a? String
        raise JSS::InvalidDataError, "Version can't be empty." if vers.empty?
        return vers.gsub(" ", "_")
      end

      ### Confirm the validity of a revision.
      ### Raise an exception if invalid.
      ###
      ### @param rev[Integer] the revision to check
      ###
      ### @return [Integer] the valid revision
      ###
      def validate_revision (rev)
        raise JSS::InvalidDataError, "Revision must be an Integer." unless rev.to_s =~ /^\d+$/
        rev.to_i
      end

      ### Check the validity of a pre_install script
      ###
      ### @see #validate_script
      ###
      def validate_pre_install_script (script)
        validate_script script
      end

      ### Check the validity of a post_install script
      ###
      ### @see #validate_script
      ###
      def validate_post_install_script (script)
        validate_script script
      end

      ### Check the validity of a pre_remove script
      ###
      ### @see #validate_script
      ###
      def validate_pre_remove_script (script)
        validate_script script
      end

      ### Check the validity of a pre_remove script
      ###
      ### @see #validate_script
      ###
      def validate_post_remove_script (script)
        validate_script script
      end

      ### Check the validity of a script, either Pathname, JSS id, or JSS name
      ### Raise an exception if not valid
      ###
      ### @param script[Pathname, Integer, String] the script to check
      ###
      ### @return [Pathname, String] the valid local path or JSS name of the script
      ###
      def validate_script (script)
        script = nil if script.to_s =~ /^n(one)?$/i
        return nil if script.to_s.empty?
        script = script.to_s.strip

        if script =~ /^\d+$/
          script = script.to_i
          return JSS::Script.map_all_ids_to(:name)[script] if JSS::Script.all_ids.include? script
          raise JSS::NoSuchItemError, "No JSS script with id '#{script}'"

        else
          # if its a file path, return it fully expanded
          path = Pathname.new script
          return path.expand_path if path.file?

          # otherwise, its a JSS Script name,return its id
          if JSS::Script.all_names.include? script.to_s
            return script
          end

          raise JSS::NoSuchItemError, "No local file or JSS script named '#{script}'"
        end # if a fixnum
      end

      ### @see #validate_groups
      def validate_auto_groups (groups)
        validate_groups groups, :check_for_std
      end

      ### @see #validate_groups
      def validate_excluded_groups (groups)
        validate_groups groups
      end

      ### Confirm the existence of a list of Computer Group names
      ### (String or Array) and return them as an Array
      ###
      ### If "n", "", "none" or nil are passed, an empty array is returned.
      ###
      ### Raise an exception if any group is not valid.
      ###
      ### @param groups[String, Array<String>]
      ###
      ### @param check_for_std[Boolean] should we check for the D3::STANDARD_AUTO_GROUP?
      ###
      ### @return [Array] The valid groups as an array
      ###
      def validate_groups (groups, check_for_std = false)
        groups = [] if groups.to_s =~ /^n(one)?$/i
        group_array = JSS.to_s_and_a(groups)[:arrayform].compact
        return [] if group_array.empty?
        return [] if group_array.reject{|g| g =~ /^n(one)$/i }.empty? # ['n'], ['None'], case-free
        return [D3::STANDARD_AUTO_GROUP] if check_for_std and group_array.include?(D3::STANDARD_AUTO_GROUP)

        group_array.each do |group|
          raise JSS::NoSuchItemError, "No ComputerGroup named '#{group}' in the JSS" unless JSS::ComputerGroup.all_names.include? group
        end
        group_array
      end

      ### Make sure auto and excluded groups don't have any
      ### members in common, raise an exception if they do.
      ###
      ### @param auto[Array] the array of auto groups
      ###
      ### @param excl[Array] the array of excluded groups
      ###
      ### @return [True] true if there are no groups in common
      ###
      def validate_non_overlapping_groups (auto, excl)
        return nil unless auto and excl
        auto = JSS.to_s_and_a(auto)[:arrayform]
        excl = JSS.to_s_and_a(excl)[:arrayform]
        raise JSS::InvalidDataError, "Auto and Excluded group-lists can't contain groups in common." unless (auto & excl).empty?
        true
      end

      ### Check the validity of a list of OSes
      ### Raise an exception if not valid
      ###
      ### @param [String,Array] Array or comma-separated list of OSes to check
      ###
      ### @return [Array] the valid OS list
      ###
      def validate_oses (os_list)
        os_list = nil if os_list.to_s =~ /^n(one)?$/i
        return [] if os_list.to_s.empty?
         ### if any value starts with >=, expand it
        case os_list
          when String
            os_list = JSS.expand_min_os(os_list) if os_list =~ /^>=/
          when Array
            os_list.map!{|a|  a =~ /^>=/ ? JSS.expand_min_os(a) : a }
            os_list.flatten!
            os_list.uniq!
          else
            raise JSS::InvalidDataError, "os_list must be a String or an Array of strings"
        end
        ### return the array version
        JSS.to_s_and_a(os_list)[:arrayform]
      end

      ### Check the validity of a CPU type
      ### Raise an exception if not valid
      ###
      ### @param [Symbol] the CPU type to check
      ###
      ### @return [Symbol] the valid CPU type
      ###
      def validate_cpu_type (type)
        type = JSS::Package::DEFAULT_CPU_TYPE if type.to_s.empty?
        type = "None" if type =~ /^n(one)?$/i
        type = "x86" if type.casecmp('intel') == 0
        type = "ppc" if type.casecmp('ppc') == 0
        unless JSS::Package::CPU_TYPES.include? type
          raise JSS::InvalidDataError, "CPU type must be one of: #{JSS::Package::CPU_TYPES.join ', '}"
        end
        type
      end

      ### Check the validity of a category name
      ### Raise an exception if not valid.
      ### nil and empty strings are acceptable to unset the category.
      ###
      ### @param cat[String] the category to check
      ###
      ### @return [String] the valid category name
      ###
      def validate_category (cat)
        cat = nil if cat.to_s =~ /^n(one)?$/i
        return "" if  cat.to_s.empty?
        raise JSS::NoSuchItemError, "No category '#{cat}' in the JSS" unless JSS::Category.all_names.include? cat
        cat
      end

      ### Check the offered prohibiting process pattern
      ###
      ### @param match_string[String] the data entered by the user
      ###
      ### @return [String, nil] the regexp used to do the match
      ###
      def validate_prohibiting_process (match_string)
        match_string = nil if match_string.to_s =~ /^n(one)?$/i
        return nil if match_string.nil? or match_string.empty?
        match_string.to_s
      end

      ### check the validity of a yes/no,true/false,1/0 input value
      ###
      ### TrueClass, "true", "y","yes", and 1 are true
      ###
      ### FalseClass, nil, "false", "n", "no", and 0 are false
      ###
      ### (Strings are case-insensitive)
      ### Anything else raises an exception.
      ###
      ### @param type[String,Boolean,Integer] the value to check
      ###
      ### @return [Boolean]
      ###
      def validate_yes_no (yn)
        case yn
        when Fixnum
          return true if yn == 1
          return false if yn == 0
        when String
          return true if yn.strip =~ /^y(es)?$/i
          return false if yn.strip =~ /^no?$/i
        when TrueClass
          return true
        when FalseClass
          return false
        when nil
          return false
        end
        raise JSS::InvalidDataError, "Value must be one of: 'yes', 'y', 'true', '1', 'no', 'n', 'false', '0'"
      end

      ### Confirm the validity of an expiration.
      ### Raise an exception if invalid.
      ###
      ### @param exp[Integer] the expiration to check
      ###
      ### @return [Integer] the valid expiration
      ###
      def validate_expiration (exp)
        exp ||= '0'
        raise JSS::InvalidDataError, "Expiration must be an Integer." unless exp.to_s =~ /^\d+$/
        exp = 0 if exp.to_i < 0
        exp.to_i
      end

      ### Confirm the validity of an expiration path.
      ### any string that starts with a / is valid.
      ###
      ### @param path[Pathname, String] the path to check
      ###
      ### @return [Pathname, nil] the valid path
      ###
      def validate_expiration_path (path)
        path = path.to_s
        return nil if path.empty?
        raise JSS::InvalidDataError, "Expiration Path must be a full path starting with /." unless path.start_with? "/"
        Pathname.new path
      end


    end # module Validate

  end # class package
end # module D3
