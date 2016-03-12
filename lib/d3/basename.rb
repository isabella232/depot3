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

  ###
  ### This mixin module provides attributes and methods for
  ### dealing with d3 basenames, i.e. package families.
  ### It's used by the {D3::Package}, {D3::Client::Receipt}, and {D3::Client::PendingPuppy} classes.
  ###
  module Basename
    include Comparable

    ### The status of D3::Package & D3::Client::Receipt objects, and the integers stored
    ### in the DB for each D3::Package
    ###
    ###  - :unsaved
    ###      D3::Package: a Ruby object that hasn't yet been created  on the server
    ###      D3::Client::Receipt: a Ruby object that hasn't yet been saved to the local
    ###        receipt datastore
    ###
    ###  - :pilot
    ###      D3::Package: on the server, but not yet been made live,1
    ###      D3::Client::Receipt: installed when the pkg was in that state.
    ###
    ###  - :live
    ###      D3::Package: the currently active pkg for a given basename,
    ###      D3::Client::Receipt: the matching pkg is current live on the server
    ###
    ###  - :deprecated
    ###      D3::Package: was once live, now superseded by a new version, but
    ###        still on the server
    ###      D3::Client::Receipt: the rcpt is older than the currently live pkg &
    ###        will be upgraded at sync unless it was installed as a pilot
    ###
    ###  - :skipped
    ###      D3::Package: never made live, but older than the current live
    ###        installer, still on the server, probably should be deleted
    ###
    ###  - :missing
    ###      D3::Package: the data is in the D3 Packages table, but the pkg is
    ###        not in the JSS
    ###      D3::Client::Receipt: No matching :pilot, :live, or :deprecated pkg on
    ###        the server
    ###
    ###  - :deleted
    ###      D3::Package: the matching d3 data has been deleted from the server
    ###      D3::Client::Receipt: the matching receipt has been deleted from the client
    ###
    STATUSES =  [
      :unsaved,
      :pilot,
      :live,
      :deprecated,
      :skipped,
      :missing,
      :deleted
    ]

    ################# Attributes #################

    ### @return [String] the basname of the thing installed
    attr_reader :basename

    ### @return [String] the version of the thing installed
    attr_reader :version

    ### @return [Integer]  the d3 release number of the thing installed
    attr_reader :revision

    ### @return [String]  who's uploading, releasing, installing, or archiving this thing?
    attr_reader :admin

    ### @return [Integer] the JSS id of this package
    attr_reader :id

    ### @return [Symbol] whats the d3 status of this package? One of the values of D3::Basename::STATUSES
    attr_reader :status

    # @return [Symbol] Is this package a .dmg or .pkg?
    attr_reader :package_type

    ### @return [String] a string for matching to the output lines
    ###   of '/bin/ps -A -c -o comm'. If there's a match, this pkg won't be
    ###   installed or uninstalled
    attr_reader :prohibiting_process

    # @return [nil,Integer] The number of days of disuse before an expiring package is uninstalled
    #  nil or zero mean don't expire ever
    attr_reader :expiration

    # @return [String] the path to the executable that needs come to the foreground to prevent expiration
    attr_reader :expiration_path


    ################# Public Instance Methods #################

    ### While several packages can have the same basename,
    ### the combination of basename, version, and revision
    ### (called the 'edition') must be unique
    ### among the d3 packages.
    ###
    ### @return [String] the basename, version ,and revision of this package, joined with hyphens
    ###
    def edition
      return @edition if @edition
      @edition = "#{@basename}-#{@version}-#{@revision}"
    end

    ### expiration should always return an integer, so if it's nil,
    ### return zero. (we assume anything non-nil is an Integer)
    ### due to input validation)
    ###
    ### @return[Interger]  the expiration period in days
    ###
    def expiration
      @expiration.to_i
    end

    ### Use comparable to give sortability
    ### and equality.
    ###
    ###
    def <=> (other)
     self.edition <=> other.edition
    end # <=>

    ### Is the status :saved?
    ###
    ### @return [Boolean]
    ###
    def saved?
      @status != :unsaved
    end

    ### Is the status :pilot?
    ###
    ### @return [Boolean]
    ###
    def pilot?
      @status == :pilot
    end

    ### Is the status :live?
    ###
    ### @return [Boolean]
    ###
    def live?
      @status == :live
    end

    ### @return [Boolean] Is this pkg skipped?
    ###   See {D3::Database::PACKAGE_STATUSES} for details
    ###
    def skipped?
      @status == :skipped
    end

    ### Is the status :deprecated?
    ###
    ### @return [Boolean]
    ###
    def deprecated?
      @status == :deprecated
    end


    ### Is the status :missing?
    ###
    ### @return [Boolean]
    ###
    def missing?
      @status == :missing
    end

    ### Is the status :deleted?
    ###
    ### @return [Boolean]
    ###
    def deleted?
      @status == :deleted
    end

    private

    ### set the status
    ###
    ### @param new_status[Symnol]  one of the  valid STATUSES
    ###
    ### @return [Symbol] the new status
    ###
    def status= (new_status)
      raise JSS::InvalidDataError, "status must be one of :#{STATUSES.join(', :')}" unless STATUSES.include? new_status
      @status = new_status
    end

  end # module Basename
end # module PixD3
